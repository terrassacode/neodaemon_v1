#!/usr/bin/env python3
"""Write Operational Control Plane snapshot v1.

Generates the active live artifact for future dashboard consumers.
The only source of truth is operational_control_plane_real_signals_v1.py.
This script does not duplicate or recalculate Operational Control Plane rules.
"""

from __future__ import annotations

import json
import subprocess
from pathlib import Path
from typing import Any


SCHEMA_VERSION = "operational_control_plane.v1"
SOURCE_SCRIPT = Path("scripts/project/operational_control_plane_real_signals_v1.py")
SNAPSHOT_PATH = Path("/openclaw/workspace/main/dashboard-v2/data/operational_control_plane_v1.json")
REQUIRED_KEYS = {
    "schema_version",
    "status",
    "risk_level",
    "can_work",
    "signals",
    "warnings",
    "blockers",
    "recommended_mode",
    "staleness",
}


def fail(summary: str) -> int:
    print(
        json.dumps(
            {
                "status": "BLOCKED",
                "summary": summary,
                "snapshot_path": str(SNAPSHOT_PATH),
                "safe": True,
                "logs_redacted": True,
            },
            ensure_ascii=False,
        )
    )
    return 1


def load_payload() -> tuple[dict[str, Any] | None, str | None]:
    if not SOURCE_SCRIPT.is_file():
        return None, "SOURCE_SCRIPT_MISSING"

    proc = subprocess.run(
        ["python3", str(SOURCE_SCRIPT)],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=10,
        check=False,
    )
    if proc.returncode != 0:
        return None, "SOURCE_SCRIPT_FAILED"

    try:
        payload = json.loads(proc.stdout)
    except json.JSONDecodeError:
        return None, "SOURCE_JSON_INVALID"

    if not isinstance(payload, dict):
        return None, "SOURCE_JSON_NOT_OBJECT"

    return payload, None


def validate_payload(payload: dict[str, Any]) -> str | None:
    if payload.get("schema_version") != SCHEMA_VERSION:
        return "SCHEMA_VERSION_MISMATCH"

    missing = sorted(key for key in REQUIRED_KEYS if key not in payload)
    if missing:
        return "MISSING_REQUIRED_KEYS:" + ",".join(missing)

    return None


def write_snapshot(payload: dict[str, Any]) -> None:
    SNAPSHOT_PATH.parent.mkdir(parents=True, exist_ok=True)
    text = json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    temp_path = SNAPSHOT_PATH.with_suffix(SNAPSHOT_PATH.suffix + ".tmp")
    temp_path.write_text(text, encoding="utf-8")
    temp_path.replace(SNAPSHOT_PATH)


def main() -> int:
    payload, error = load_payload()
    if error or payload is None:
        return fail(error or "SOURCE_UNKNOWN_ERROR")

    validation_error = validate_payload(payload)
    if validation_error:
        return fail(validation_error)

    write_snapshot(payload)
    print(
        json.dumps(
            {
                "status": "OK",
                "schema_version": payload.get("schema_version"),
                "snapshot_path": str(SNAPSHOT_PATH),
                "source_script": str(SOURCE_SCRIPT),
                "written": True,
                "version_snapshot": False,
                "safe": True,
                "logs_redacted": True,
            },
            ensure_ascii=False,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
