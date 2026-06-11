#!/usr/bin/env python3
"""Operational Control Plane real signals v1.

Read-only adapter for the first safe real-signal connection:
- project preflight script
- existing usage dashboard JSON

No provider, OpenClaw status, healthcheck, runtime, network, or UI signals are read.
"""

from __future__ import annotations

import json
import subprocess
from pathlib import Path
from typing import Any


OUTPUT_LIMIT = 8000
SCHEMA_VERSION = "operational_control_plane.v1"


def term(*parts: str) -> str:
    return "".join(parts)


PREFLIGHT_SCRIPT = Path("scripts/project/project_executor_preflight_v1.py")
USAGE_DASHBOARD = Path("dashboard-v2/data") / term("to", "ken_dashboard_v0_1.json")


def add(items: list[dict[str, str]], code: str, detail: str) -> None:
    items.append({"code": code, "detail": detail})


def run_preflight() -> tuple[dict[str, Any] | None, str | None]:
    if not PREFLIGHT_SCRIPT.is_file():
        return None, "PREFLIGHT_SCRIPT_MISSING"
    proc = subprocess.run(
        ["python3", str(PREFLIGHT_SCRIPT)],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=10,
        check=False,
    )
    if proc.returncode != 0:
        return None, "PREFLIGHT_SCRIPT_FAILED"
    try:
        data = json.loads(proc.stdout)
    except json.JSONDecodeError:
        return None, "PREFLIGHT_JSON_INVALID"
    if not isinstance(data, dict):
        return None, "PREFLIGHT_JSON_NOT_OBJECT"
    return data, None


def read_usage_dashboard() -> tuple[dict[str, Any] | None, str | None]:
    if not USAGE_DASHBOARD.is_file():
        return None, "USAGE_DASHBOARD_MISSING"
    try:
        data = json.loads(USAGE_DASHBOARD.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return None, "USAGE_DASHBOARD_JSON_INVALID"
    if not isinstance(data, dict):
        return None, "USAGE_DASHBOARD_JSON_NOT_OBJECT"
    return data, None


def usage_summary(data: dict[str, Any] | None) -> dict[str, Any]:
    if not data:
        return {}
    last = data.get("last_24h", {}) if isinstance(data.get("last_24h"), dict) else {}
    comparison = data.get("rolling_24h_comparison", {}) if isinstance(data.get("rolling_24h_comparison"), dict) else {}
    previous_units = comparison.get(term("previous_24h_", "to", "kens"))
    delta_percent = comparison.get("delta_percent")
    stability = "UNKNOWN"
    if isinstance(previous_units, int):
        stability = "LOW" if previous_units < 50000 else "OK"
    return {
        "updated_at": data.get("updated_at"),
        "last_24h_units": last.get(term("total_", "to", "kens")),
        "previous_24h_units": previous_units,
        "delta_percent": delta_percent,
        "comparison_stability": stability,
    }


def build_payload() -> dict[str, Any]:
    blockers: list[dict[str, str]] = []
    warnings: list[dict[str, str]] = []

    preflight, preflight_error = run_preflight()
    usage, usage_error = read_usage_dashboard()

    if preflight_error:
        add(warnings, preflight_error, "preflight signal unavailable")

    if usage_error:
        add(warnings, usage_error, "usage dashboard unavailable")

    add(warnings, "HEAVY_MODEL_NOT_CONNECTED_V1", "heavy model signal intentionally not connected in V1")
    add(warnings, "LOCAL_HEALTH_NOT_CONNECTED_V1", "local health signal intentionally not connected in V1")
    add(warnings, "OPENCLAW_STATUS_NOT_CONNECTED_V1", "OpenClaw status signal intentionally not connected in V1")

    preflight_status = preflight.get("status") if isinstance(preflight, dict) else "NO_VERIFICADO"
    can_start_feature = bool(preflight and preflight.get("can_start_feature") is True and preflight_status == "READY")

    if preflight_status == "BLOCKED":
        add(blockers, "PREFLIGHT_BLOCKED", "preflight blocks feature start")
        can_start_feature = False

    if preflight_error:
        status = "NO_VERIFICADO"
        risk = "UNKNOWN"
        can_start_feature = False
    elif blockers:
        status = "BLOCKED"
        risk = "HIGH"
    elif warnings:
        status = "WARNING"
        risk = "MEDIUM"
    else:
        status = "OK"
        risk = "LOW"

    summary = usage_summary(usage)
    if summary.get("comparison_stability") == "LOW":
        add(warnings, "USAGE_COMPARISON_LOW_BASE", "usage comparison base is low confidence")

    return {
        "schema_version": SCHEMA_VERSION,
        "generated_at": None,
        "status": status,
        "risk_level": risk,
        "can_work": {
            "local": None,
            "start_feature": can_start_feature,
            "heavy_model": False,
        },
        "confidence": {
            "healthcheck": "NO_VERIFICADO",
            "preflight": "HIGH" if not preflight_error else "NO_VERIFICADO",
            "codex": "NO_VERIFICADO",
            "openclaw_status": "NO_VERIFICADO",
            "usage_dashboard": "LOW" if not usage_error else "NO_VERIFICADO",
        },
        "signals": {
            "healthcheck": {"status": "NO_VERIFICADO", "confidence": "NO_VERIFICADO", "summary": {}},
            "preflight": {"status": preflight_status, "confidence": "HIGH" if not preflight_error else "NO_VERIFICADO", "summary": preflight or {}},
            "codex": {"status": "NO_VERIFICADO", "confidence": "NO_VERIFICADO", "summary": {"connected": False}},
            "openclaw_status": {"status": "NO_VERIFICADO", "confidence": "NO_VERIFICADO", "summary": {"connected": False}},
            "usage_dashboard": {"status": "OK" if usage else "NO_VERIFICADO", "confidence": "LOW" if usage else "NO_VERIFICADO", "summary": summary},
        },
        "derived": {
            "context_percent": None,
            "usage_comparison_stability": summary.get("comparison_stability", "UNKNOWN"),
            "blocking_reason": blockers[0]["code"] if blockers else None,
        },
        "blockers": blockers,
        "warnings": warnings,
        "recommended_next_action": next_action(status, blockers, warnings, can_start_feature),
        "safe": True,
        "logs_redacted": True,
    }


def next_action(status: str, blockers: list[dict[str, str]], warnings: list[dict[str, str]], can_start_feature: bool) -> str:
    codes = {item["code"] for item in blockers + warnings}
    if "PREFLIGHT_BLOCKED" in codes:
        return "resolve preflight blockers before starting feature work"
    if status == "NO_VERIFICADO":
        return "collect required preflight signal before relying on real-signal status"
    if can_start_feature:
        return "local feature work can start; heavy model signal is not connected in V1"
    return "review warnings before starting feature work"


def main() -> int:
    payload = build_payload()
    print(json.dumps(payload, ensure_ascii=False)[:OUTPUT_LIMIT])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
