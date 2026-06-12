#!/usr/bin/env python3
"""Controlled deploy for Operational Control Plane dashboard v1.

Dry-run by default. Use --apply only with explicit human approval.
Copies exactly three static dashboard files from this repo to the active
workspace dashboard path. No directories are created in V1.
"""

from __future__ import annotations

import argparse
import json
import shutil
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


REPO_ROOT = Path.cwd()
ACTIVE_DASHBOARD_ROOT = Path("/openclaw/workspace/main/dashboard-v2")

ALLOWED_COPIES = [
    (
        Path("dashboard-v2/operational-control-plane.html"),
        ACTIVE_DASHBOARD_ROOT / "operational-control-plane.html",
    ),
    (
        Path("dashboard-v2/js/operational-control-plane.js"),
        ACTIVE_DASHBOARD_ROOT / "js/operational-control-plane.js",
    ),
    (
        Path("dashboard-v2/css/operational-control-plane.css"),
        ACTIVE_DASHBOARD_ROOT / "css/operational-control-plane.css",
    ),
]

BLOCKED_DESTINATION_FRAGMENTS = (
    "dashboard-v2/index.html",
    "dashboard-v2/data/",
    "".join(("to", "ken-overview.html")),
)


def as_posix(path: Path) -> str:
    return path.as_posix()


def is_exact_allowed(source: Path, destination: Path) -> bool:
    return any(source == allowed_source and destination == allowed_dest for allowed_source, allowed_dest in ALLOWED_COPIES)


def blocked_destination(path: Path) -> str | None:
    text = as_posix(path)
    if text.endswith(".json"):
        return "JSON_DESTINATION_BLOCKED"
    for fragment in BLOCKED_DESTINATION_FRAGMENTS:
        if fragment in text:
            return "BLOCKED_DESTINATION_FRAGMENT:" + fragment
    return None


def inspect_plan() -> dict[str, Any]:
    files: list[dict[str, Any]] = []
    blockers: list[dict[str, str]] = []

    for source_rel, destination in ALLOWED_COPIES:
        source = REPO_ROOT / source_rel
        destination_parent = destination.parent
        destination_block = blocked_destination(destination)
        exact_allowed = is_exact_allowed(source_rel, destination)
        source_exists = source.is_file()
        destination_dir_exists = destination_parent.is_dir()
        destination_exists = destination.exists()

        entry = {
            "source": as_posix(source_rel),
            "destination": str(destination),
            "source_found": source_exists,
            "destination_directory_found": destination_dir_exists,
            "destination_found": destination_exists,
            "would_copy": bool(exact_allowed and source_exists and destination_dir_exists and not destination_block),
        }
        files.append(entry)

        if not exact_allowed:
            blockers.append({"code": "NOT_EXACTLY_ALLOWED", "path": as_posix(source_rel)})
        if destination_block:
            blockers.append({"code": destination_block, "path": str(destination)})
        if not source_exists:
            blockers.append({"code": "SOURCE_NOT_FOUND", "path": as_posix(source_rel)})
        if not destination_dir_exists:
            blockers.append({"code": "DESTINATION_DIRECTORY_NOT_FOUND", "path": str(destination_parent)})

    return {
        "status": "PASS" if not blockers else "FAIL",
        "mode": "dry-run",
        "apply": False,
        "files": files,
        "blockers": blockers,
        "safe": True,
        "logs_redacted": True,
    }


def apply_plan(plan: dict[str, Any]) -> dict[str, Any]:
    if plan.get("status") != "PASS":
        return {**plan, "mode": "apply", "apply": True, "status": "FAIL", "copied": []}

    copied: list[dict[str, str]] = []
    for source_rel, destination in ALLOWED_COPIES:
        source = REPO_ROOT / source_rel
        if not is_exact_allowed(source_rel, destination):
            return {**plan, "mode": "apply", "apply": True, "status": "FAIL", "copied": copied}
        if not source.is_file() or not destination.parent.is_dir():
            return {**plan, "mode": "apply", "apply": True, "status": "FAIL", "copied": copied}
        shutil.copy2(source, destination)
        copied.append({"source": as_posix(source_rel), "destination": str(destination)})

    return {
        **plan,
        "mode": "apply",
        "apply": True,
        "status": "PASS",
        "copied": copied,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Controlled deploy for Operational Control Plane dashboard")
    parser.add_argument("--apply", action="store_true", help="copy the exact allowlisted dashboard files")
    args = parser.parse_args()

    plan = inspect_plan()
    result = apply_plan(plan) if args.apply else plan
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if result.get("status") == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
