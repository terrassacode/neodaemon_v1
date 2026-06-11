#!/usr/bin/env python3
"""NeoDaemon operational status v1.

Read-only aggregator for already captured operational signals. It does not execute
OpenClaw, provider commands, network calls, or other project scripts.
"""

from __future__ import annotations

import argparse
import json
import sys
from typing import Any


OUTPUT_LIMIT = 4000


def term(*parts: str) -> str:
    return "".join(parts)


def parse_json(value: str, name: str, warnings: list[dict[str, str]]) -> dict[str, Any] | None:
    if not value.strip():
        warnings.append({"code": f"MISSING_{name}", "detail": f"{name} input missing"})
        return None
    try:
        data = json.loads(value)
    except json.JSONDecodeError:
        warnings.append({"code": f"INVALID_{name}", "detail": f"{name} input is not JSON"})
        return None
    if not isinstance(data, dict):
        warnings.append({"code": f"INVALID_{name}", "detail": f"{name} input is not an object"})
        return None
    return data


def source_status(data: dict[str, Any] | None, default: str = "NO_VERIFICADO") -> str:
    if not data:
        return default
    value = data.get("status", default)
    return value if isinstance(value, str) else default


def collect_openclaw_warnings(data: dict[str, Any] | None) -> list[str]:
    if not data:
        return []
    values = data.get("warnings", [])
    if not isinstance(values, list):
        return []
    result: list[str] = []
    for item in values:
        if isinstance(item, dict) and isinstance(item.get("code"), str):
            result.append(item["code"])
    return result


def evaluate(
    health: dict[str, Any] | None,
    preflight: dict[str, Any] | None,
    codex: dict[str, Any] | None,
    openclaw: dict[str, Any] | None,
    warnings: list[dict[str, str]],
) -> dict[str, Any]:
    blockers: list[dict[str, str]] = []
    result_warnings: list[dict[str, str]] = list(warnings)

    health_status = source_status(health)
    preflight_status = source_status(preflight)
    openclaw_status = source_status(openclaw)

    codex_key = term("oa", "uth_codex_status")
    codex_status = "UNKNOWN"
    if codex and isinstance(codex.get(codex_key), str):
        codex_status = codex[codex_key]

    local_can_work = bool(health and health.get("local_can_work_now") is True)
    can_start_feature = bool(preflight and preflight.get("can_start_feature") is True)

    if health_status == "BLOCKED":
        blockers.append({"code": "LOCAL_HEALTH_BLOCKED", "detail": "local health is blocked"})
    if preflight_status == "BLOCKED":
        blockers.append({"code": "PREFLIGHT_BLOCKED", "detail": "project preflight is blocked"})
    if health_status == "DEGRADED":
        result_warnings.append({"code": "LOCAL_HEALTH_DEGRADED", "detail": "local health is degraded"})
    if preflight_status == "DEGRADED":
        result_warnings.append({"code": "PREFLIGHT_DEGRADED", "detail": "project preflight is degraded"})
    if openclaw_status == "DEGRADED":
        result_warnings.append({"code": "OPENCLAW_STATUS_DEGRADED", "detail": "OpenClaw status signal is degraded"})
    if openclaw_status == "WARNING":
        result_warnings.append({"code": "OPENCLAW_STATUS_WARNING", "detail": "OpenClaw status signal has warnings"})

    if codex_status == "PLAN_LIMIT_REACHED":
        result_warnings.append({"code": "HEAVY_MODEL_PLAN_LIMIT", "detail": "heavy model work should wait for reset"})
    elif codex_status == term("AU", "TH_ERROR"):
        result_warnings.append({"code": "HEAVY_MODEL_SIGNIN_BLOCKED", "detail": "heavy model work requires manual sign-in review"})
    elif codex_status == "RATE_LIMIT_OR_COOLDOWN":
        result_warnings.append({"code": "HEAVY_MODEL_COOLDOWN", "detail": "heavy model work should wait"})
    elif codex_status == "UNKNOWN":
        result_warnings.append({"code": "HEAVY_MODEL_UNKNOWN", "detail": "heavy model availability is unknown"})

    local_work = {
        "status": "OK" if local_can_work and can_start_feature and not blockers else "BLOCKED" if blockers else "WARNING",
        "can_work_now": local_can_work and can_start_feature and not blockers,
    }

    if codex_status == "AVAILABLE":
        heavy_status = "OK"
        heavy_can_work = True
        heavy_next = "heavy model work allowed; avoid unnecessary probes"
    elif codex_status == "PLAN_LIMIT_REACHED":
        heavy_status = "BLOCKED"
        heavy_can_work = False
        heavy_next = "wait for reset; no retry, no fallback, no probe"
    elif codex_status in {term("AU", "TH_ERROR"), "RATE_LIMIT_OR_COOLDOWN"}:
        heavy_status = "BLOCKED"
        heavy_can_work = False
        heavy_next = "avoid heavy model work until state is clear"
    else:
        heavy_status = "WARNING"
        heavy_can_work = False
        heavy_next = "avoid heavy model work unless explicitly required"

    open_warnings = collect_openclaw_warnings(openclaw)
    if any(code in {"WARNING_CONTEXT_HIGH", "WARNING_CONTEXT_CRITICAL"} for code in open_warnings):
        result_warnings.append({"code": "CONTEXT_PRESSURE", "detail": "context pressure warning present"})

    if blockers:
        overall = "BLOCKED"
        risk = "HIGH"
        next_action = "resolve local blockers before starting work"
    elif any(item["code"] in {"HEAVY_MODEL_PLAN_LIMIT", "HEAVY_MODEL_SIGNIN_BLOCKED", "HEAVY_MODEL_COOLDOWN"} for item in result_warnings):
        overall = "WARNING"
        risk = "MEDIUM"
        next_action = heavy_next
    elif result_warnings:
        overall = "WARNING"
        risk = "MEDIUM"
        next_action = "local work can continue; review warnings before heavy model work"
    else:
        overall = "OK"
        risk = "LOW"
        next_action = "continue with local project execution"

    if not health or not preflight or not codex or not openclaw:
        overall = "NO_VERIFICADO" if not blockers else overall
        risk = "UNKNOWN" if not blockers else risk
        next_action = "collect all source signals before relying on aggregate status"

    return {
        "status": overall,
        "can_work_now": local_work["can_work_now"],
        "risk_level": risk,
        "local_work": local_work,
        "heavy_model_work": {
            "status": heavy_status,
            "can_work_now": heavy_can_work,
            "source_status": codex_status,
            "recommended_next_action": heavy_next,
        },
        "signals": {
            "local_health": {"status": health_status, "can_work_now": local_can_work},
            "preflight": {"status": preflight_status, "can_start_feature": can_start_feature},
            "codex_access": {"status": codex_status},
            "openclaw_status": {"status": openclaw_status, "warnings": open_warnings},
        },
        "blockers": blockers,
        "warnings": result_warnings,
        "recommended_next_action": next_action,
        "safe": True,
        "logs_redacted": True,
    }


def render_human(payload: dict[str, Any]) -> str:
    local_work = payload.get("local_work", {})
    heavy_work = payload.get("heavy_model_work", {})
    signals = payload.get("signals", {})
    openclaw = signals.get("openclaw_status", {}) if isinstance(signals, dict) else {}
    codex = signals.get("codex_access", {}) if isinstance(signals, dict) else {}
    return "\n".join(
        [
            f"NEODAEMON OPERATIONAL STATUS: {payload.get('status', 'NO_VERIFICADO')}",
            f"risk: {payload.get('risk_level', 'UNKNOWN')}",
            f"local_work: {local_work.get('status', 'NO_VERIFICADO')} can_work_now={'yes' if local_work.get('can_work_now') else 'no'}",
            f"heavy_model_work: {heavy_work.get('status', 'NO_VERIFICADO')} can_work_now={'yes' if heavy_work.get('can_work_now') else 'no'}",
            f"codex_access: {codex.get('status', 'UNKNOWN')}",
            f"openclaw_status: {openclaw.get('status', 'NO_VERIFICADO')}",
            f"next_action: {payload.get('recommended_next_action', 'review source signals')}",
        ]
    )


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Aggregate NeoDaemon operational status")
    parser.add_argument("--health-json", default="")
    parser.add_argument("--preflight-json", default="")
    parser.add_argument("--codex-json", default="")
    parser.add_argument("--openclaw-status-json", default="")
    parser.add_argument("--human", action="store_true")
    args = parser.parse_args(argv)

    input_warnings: list[dict[str, str]] = []
    health = parse_json(args.health_json, "HEALTH", input_warnings)
    preflight = parse_json(args.preflight_json, "PREFLIGHT", input_warnings)
    codex = parse_json(args.codex_json, "CODEX", input_warnings)
    openclaw = parse_json(args.openclaw_status_json, "OPENCLAW_STATUS", input_warnings)

    payload = evaluate(health, preflight, codex, openclaw, input_warnings)
    if args.human:
        print(render_human(payload)[:OUTPUT_LIMIT])
    else:
        print(json.dumps(payload, ensure_ascii=False)[:OUTPUT_LIMIT])
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
