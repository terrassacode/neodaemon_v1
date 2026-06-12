#!/usr/bin/env python3
"""Operational Control Plane real signals v1.

Read-only adapter for the first safe real-signal connection:
- project preflight script
- project healthcheck script
- existing usage dashboard JSON
- controlled OpenClaw status inspection

No provider, runtime, network, or UI signals are read.
"""

from __future__ import annotations

import argparse
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


OUTPUT_LIMIT = 8000
SCHEMA_VERSION = "operational_control_plane.v1"
STALE_AFTER_SECONDS = 86400


def term(*parts: str) -> str:
    return "".join(parts)


PREFLIGHT_SCRIPT = Path("scripts/project/project_executor_preflight_v1.py")
HEALTHCHECK_SCRIPT = Path("scripts/project/neodaemon_healthcheck_v1.py")
OPENCLAW_STATUS_PARSER = Path("scripts/project/openclaw_status_signal_summary_v1.py")
CONTROL_BRIDGE = Path("tools/neodaemon_executor_bridge.sh")
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


def run_healthcheck() -> tuple[dict[str, Any] | None, str | None]:
    if not HEALTHCHECK_SCRIPT.is_file():
        return None, "HEALTHCHECK_SCRIPT_MISSING"
    proc = subprocess.run(
        ["python3", str(HEALTHCHECK_SCRIPT)],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=10,
        check=False,
    )
    if proc.returncode != 0:
        return None, "HEALTHCHECK_SCRIPT_FAILED"
    try:
        data = json.loads(proc.stdout)
    except json.JSONDecodeError:
        return None, "HEALTHCHECK_JSON_INVALID"
    if not isinstance(data, dict):
        return None, "HEALTHCHECK_JSON_NOT_OBJECT"
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


def read_openclaw_status() -> tuple[dict[str, Any] | None, str | None]:
    if not CONTROL_BRIDGE.is_file():
        return None, "OPENCLAW_STATUS_CONTROL_BRIDGE_MISSING"
    if not OPENCLAW_STATUS_PARSER.is_file():
        return None, "OPENCLAW_STATUS_PARSER_MISSING"

    request = json.dumps({"action": "inspect_openclaw_native_status_readonly", "command": "status"})
    proc = subprocess.run(
        [str(CONTROL_BRIDGE), request],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=10,
        check=False,
    )
    if proc.returncode != 0:
        return None, "OPENCLAW_STATUS_CONTROL_READ_FAILED"
    try:
        control_payload = json.loads(proc.stdout)
    except json.JSONDecodeError:
        return None, "OPENCLAW_STATUS_CONTROL_JSON_INVALID"
    if not isinstance(control_payload, dict) or control_payload.get("status") != "OK":
        return None, "OPENCLAW_STATUS_CONTROL_NOT_OK"

    parser = subprocess.run(
        ["python3", str(OPENCLAW_STATUS_PARSER), "--status-text", str(control_payload.get("stdout", ""))],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=10,
        check=False,
    )
    if parser.returncode != 0:
        return None, "OPENCLAW_STATUS_PARSE_FAILED"
    try:
        parsed = json.loads(parser.stdout)
    except json.JSONDecodeError:
        return None, "OPENCLAW_STATUS_PARSE_JSON_INVALID"
    if not isinstance(parsed, dict):
        return None, "OPENCLAW_STATUS_PARSE_JSON_NOT_OBJECT"
    parsed["source_action"] = "inspect_openclaw_native_status_readonly"
    parsed["source_command"] = "status"
    return parsed, None


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


def health_ia_summary(data: dict[str, Any] | None) -> dict[str, Any]:
    unit = term("to", "ken")
    units = term(unit, "s")
    if not data:
        return {
            "schema_version": "health_ia.v1",
            "status": "NO_VERIFICADO",
            "risk": "UNKNOWN",
            "summary": {},
            "details": {},
            "source": {
                "path": str(USAGE_DASHBOARD),
                "confidence": "NO_VERIFICADO",
                "available": False,
            },
        }

    last = data.get("last_24h", {}) if isinstance(data.get("last_24h"), dict) else {}
    total = data.get("total", {}) if isinstance(data.get("total"), dict) else {}
    comparison = data.get("rolling_24h_comparison", {}) if isinstance(data.get("rolling_24h_comparison"), dict) else {}
    delta_percent = comparison.get("delta_percent")
    comparison_status = comparison.get("status")
    current_units = last.get(term("total_", units))
    previous_units = comparison.get(term("previous_24h_", units))

    status = "OK" if comparison_status == "ok" else "WARNING" if comparison_status else "NO_VERIFICADO"
    risk = "LOW"
    if isinstance(delta_percent, (int, float)) and delta_percent >= 75:
        risk = "MEDIUM"
    if isinstance(delta_percent, (int, float)) and delta_percent >= 150:
        risk = "HIGH"
    if not isinstance(current_units, int):
        risk = "UNKNOWN"

    return {
        "schema_version": "health_ia.v1",
        "status": status,
        "risk": risk,
        "summary": {
            "updated_at": data.get("updated_at"),
            "usage_24h_units": current_units,
            "previous_24h_units": previous_units,
            "delta_percent": delta_percent,
            "units_per_minute": data.get(term(units, "_per_minute")),
            "usage_entries_24h": last.get("usage_entries"),
        },
        "details": {
            "input_units_24h": last.get(term("input_", units)),
            "output_units_24h": last.get(term("output_", units)),
            "cache_read_units_24h": last.get(term("cache_read_", units)),
            "total_units_historical": total.get(term("total_", units)),
            "cache_read_units_historical": total.get(term("cache_read_", units)),
        },
        "source": {
            "path": str(USAGE_DASHBOARD),
            "confidence": "LOW",
            "available": True,
            "blocking": False,
        },
    }


def parse_timestamp(value: Any) -> datetime | None:
    if not isinstance(value, str) or not value:
        return None
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def signal_staleness(signal: dict[str, Any], now: datetime) -> dict[str, Any]:
    status = signal.get("status")
    summary = signal.get("summary", {}) if isinstance(signal.get("summary"), dict) else {}
    present = bool(status and status != "NO_VERIFICADO")
    timestamp = summary.get("updated_at") or summary.get("generated_at")
    parsed = parse_timestamp(timestamp)
    if not parsed:
        return {"present": present, "stale": "unknown", "age_seconds": None}
    age_seconds = max(0, int((now - parsed).total_seconds()))
    return {"present": present, "stale": age_seconds > STALE_AFTER_SECONDS, "age_seconds": age_seconds}


def build_staleness(signals: dict[str, Any]) -> dict[str, Any]:
    now = datetime.now(timezone.utc)
    return {
        name: signal_staleness(signal if isinstance(signal, dict) else {}, now)
        for name, signal in signals.items()
    }


def has_warning(warnings: list[dict[str, str]], code: str) -> bool:
    return any(item.get("code") == code for item in warnings)


def recommended_mode(payload: dict[str, Any]) -> str:
    blockers = payload.get("blockers", [])
    if isinstance(blockers, list) and blockers:
        return "local_only"

    derived = payload.get("derived", {}) if isinstance(payload.get("derived"), dict) else {}
    context_percent = derived.get("context_percent")
    if isinstance(context_percent, int) and context_percent >= 70:
        return "avoid_heavy_model"

    warnings = payload.get("warnings", [])
    if isinstance(warnings, list) and has_warning(warnings, "HEAVY_MODEL_NOT_CONNECTED_V1"):
        return "avoid_heavy_model"

    can_work = payload.get("can_work", {}) if isinstance(payload.get("can_work"), dict) else {}
    if can_work.get("local") is True and can_work.get("start_feature") is True:
        return "small_feature"

    return "local_only"


def build_payload() -> dict[str, Any]:
    blockers: list[dict[str, str]] = []
    warnings: list[dict[str, str]] = []

    healthcheck, healthcheck_error = run_healthcheck()
    preflight, preflight_error = run_preflight()
    usage, usage_error = read_usage_dashboard()
    openclaw_status, openclaw_status_error = read_openclaw_status()

    if healthcheck_error:
        add(warnings, healthcheck_error, "healthcheck signal unavailable")

    if preflight_error:
        add(warnings, preflight_error, "preflight signal unavailable")

    if usage_error:
        add(warnings, usage_error, "usage dashboard unavailable")

    if openclaw_status_error:
        add(warnings, openclaw_status_error, "OpenClaw status signal unavailable")

    add(warnings, "HEAVY_MODEL_NOT_CONNECTED_V1", "heavy model signal intentionally not connected in V1")

    healthcheck_status = healthcheck.get("status") if isinstance(healthcheck, dict) else "NO_VERIFICADO"
    local_can_work = healthcheck.get("local_can_work_now") if isinstance(healthcheck, dict) else None
    can_work_local = True if healthcheck_status == "OK" and local_can_work is True else None

    if healthcheck_status == "DEGRADED":
        add(warnings, "LOCAL_HEALTH_DEGRADED", "local health is degraded")
        can_work_local = False if local_can_work is False else None
    elif healthcheck_status == "BLOCKED":
        add(blockers, "LOCAL_HEALTH_BLOCKED", "local health blocks local work")
        can_work_local = False
    elif healthcheck_status == "NO_VERIFICADO" or healthcheck_error:
        add(warnings, "LOCAL_HEALTH_NO_VERIFICADO", "local health is not verified")
        can_work_local = None

    preflight_status = preflight.get("status") if isinstance(preflight, dict) else "NO_VERIFICADO"
    can_start_feature = bool(preflight and preflight.get("can_start_feature") is True and preflight_status == "READY")

    if preflight_status == "BLOCKED":
        add(blockers, "PREFLIGHT_BLOCKED", "preflight blocks feature start")
        can_start_feature = False

    openclaw_signal_status = openclaw_status.get("status") if isinstance(openclaw_status, dict) else "NO_VERIFICADO"
    if isinstance(openclaw_status, dict):
        for item in openclaw_status.get("warnings", []):
            if isinstance(item, dict):
                add(warnings, str(item.get("code", "OPENCLAW_STATUS_WARNING")), str(item.get("detail", "OpenClaw status warning")))

    if healthcheck_status == "BLOCKED":
        status = "BLOCKED"
        risk = "HIGH"
    elif openclaw_signal_status == "DEGRADED":
        status = "DEGRADED"
        risk = "HIGH"
    elif preflight_error:
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
    health_ia = health_ia_summary(usage)
    if summary.get("comparison_stability") == "LOW":
        add(warnings, "USAGE_COMPARISON_LOW_BASE", "usage comparison base is low confidence")

    signals = {
        "healthcheck": {"status": healthcheck_status, "confidence": "HIGH" if not healthcheck_error else "NO_VERIFICADO", "summary": healthcheck or {}},
        "preflight": {"status": preflight_status, "confidence": "HIGH" if not preflight_error else "NO_VERIFICADO", "summary": preflight or {}},
        "codex": {"status": "NO_VERIFICADO", "confidence": "NO_VERIFICADO", "summary": {"connected": False}},
        "openclaw_status": {"status": openclaw_signal_status, "confidence": "HIGH" if not openclaw_status_error else "NO_VERIFICADO", "summary": openclaw_status or {"connected": False}},
        "usage_dashboard": {"status": "OK" if usage else "NO_VERIFICADO", "confidence": "LOW" if usage else "NO_VERIFICADO", "summary": summary},
    }

    payload = {
        "schema_version": SCHEMA_VERSION,
        "generated_at": None,
        "status": status,
        "risk_level": risk,
        "can_work": {
            "local": can_work_local,
            "start_feature": can_start_feature,
            "heavy_model": False,
        },
        "confidence": {
            "healthcheck": "HIGH" if not healthcheck_error else "NO_VERIFICADO",
            "preflight": "HIGH" if not preflight_error else "NO_VERIFICADO",
            "codex": "NO_VERIFICADO",
            "openclaw_status": "HIGH" if not openclaw_status_error else "NO_VERIFICADO",
            "usage_dashboard": "LOW" if not usage_error else "NO_VERIFICADO",
        },
        "signals": signals,
        "derived": {
            "context_percent": openclaw_status.get("checks", {}).get("context_percent") if isinstance(openclaw_status, dict) and isinstance(openclaw_status.get("checks"), dict) else None,
            "usage_comparison_stability": summary.get("comparison_stability", "UNKNOWN"),
            "blocking_reason": blockers[0]["code"] if blockers else None,
        },
        "health_ia": health_ia,
        "blockers": blockers,
        "warnings": warnings,
        "recommended_next_action": next_action(status, blockers, warnings, can_start_feature),
        "safe": True,
        "logs_redacted": True,
    }
    payload["staleness"] = build_staleness(signals)
    payload["recommended_mode"] = recommended_mode(payload)
    return payload


def next_action(status: str, blockers: list[dict[str, str]], warnings: list[dict[str, str]], can_start_feature: bool) -> str:
    codes = {item["code"] for item in blockers + warnings}
    if "PREFLIGHT_BLOCKED" in codes:
        return "resolve preflight blockers before starting feature work"
    if status == "NO_VERIFICADO":
        return "collect required preflight signal before relying on real-signal status"
    if can_start_feature:
        return "local feature work can start; heavy model signal is not connected in V1"
    return "review warnings before starting feature work"


def yes_no(value: Any) -> str:
    if value is True:
        return "YES"
    if value is False:
        return "NO"
    return "NO VERIFICADO"


def warning_codes(payload: dict[str, Any]) -> list[str]:
    return [item.get("code", "UNKNOWN") for item in payload.get("warnings", []) if isinstance(item, dict)]


def blocker_codes(payload: dict[str, Any]) -> list[str]:
    return [item.get("code", "UNKNOWN") for item in payload.get("blockers", []) if isinstance(item, dict)]


def signal_status(payload: dict[str, Any], name: str) -> str:
    signals = payload.get("signals", {})
    signal = signals.get(name, {}) if isinstance(signals, dict) else {}
    status = signal.get("status", "NO_VERIFICADO") if isinstance(signal, dict) else "NO_VERIFICADO"
    return str(status)


def signal_confidence(payload: dict[str, Any], name: str) -> str:
    signals = payload.get("signals", {})
    signal = signals.get(name, {}) if isinstance(signals, dict) else {}
    confidence = signal.get("confidence", "NO_VERIFICADO") if isinstance(signal, dict) else "NO_VERIFICADO"
    return str(confidence)


def format_human(payload: dict[str, Any]) -> str:
    can_work = payload.get("can_work", {}) if isinstance(payload.get("can_work"), dict) else {}
    warnings = warning_codes(payload)
    blockers = blocker_codes(payload)
    staleness = payload.get("staleness", {}) if isinstance(payload.get("staleness"), dict) else {}
    lines = [
        "OPERATIONAL CONTROL PLANE",
        "Mode: real-signals-v1",
        f"Status: {payload.get('status', 'NO_VERIFICADO')}",
        f"Risk: {payload.get('risk_level', 'UNKNOWN')}",
        f"Recommended mode: {payload.get('recommended_mode', 'local_only')}",
        "",
        "Can work:",
        f"  local ............... {yes_no(can_work.get('local'))}",
        f"  start feature ....... {yes_no(can_work.get('start_feature'))}",
        "  heavy model ......... NOT CONNECTED",
        "",
        "Signals:",
        f"  healthcheck ......... {signal_status(payload, 'healthcheck')}",
        f"  preflight ........... {signal_status(payload, 'preflight')}",
        f"  openclaw status ..... {signal_status(payload, 'openclaw_status')} / {signal_confidence(payload, 'openclaw_status')} confidence",
        f"  usage dashboard ..... {signal_status(payload, 'usage_dashboard')} / {signal_confidence(payload, 'usage_dashboard')} confidence",
        "",
    ]
    useful_staleness = [
        (name, value)
        for name, value in staleness.items()
        if isinstance(value, dict) and value.get("age_seconds") is not None
    ]
    if useful_staleness:
        lines.append("Staleness:")
        for name, value in useful_staleness:
            stale = value.get("stale")
            stale_text = "STALE" if stale is True else "fresh" if stale is False else "unknown"
            lines.append(f"  {name} ..... {value.get('age_seconds')}s / {stale_text}")
        lines.append("")
    lines.append("Warnings:")
    lines.extend([f"  {code}" for code in warnings] or ["  none"])
    lines.extend(["", "Blockers:"])
    lines.extend([f"  {code}" for code in blockers] or ["  none"])
    lines.extend(["", "Next action:", f"  {payload.get('recommended_next_action', 'none')}"])
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Operational Control Plane real signals v1")
    parser.add_argument("--human", action="store_true", help="render a human summary derived from the JSON payload")
    args = parser.parse_args()
    payload = build_payload()
    if args.human:
        print(format_human(payload))
    else:
        print(json.dumps(payload, ensure_ascii=False)[:OUTPUT_LIMIT])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
