#!/usr/bin/env python3
"""Operational Control Plane Aggregator v1.

Fixtures-only validator for the Operational Control Plane contract.
It does not consume live OpenClaw/Codex/dashboard signals.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any


SCHEMA_VERSION = "operational_control_plane.aggregator_validation.v1"
CONTROL_SCHEMA = "operational_control_plane.v1"
FIXTURE_PATH = Path("OpenClaw-NeoDaemon-Skill/references/operational_control_plane_fixtures_v1.md")
OUTPUT_LIMIT = 12000


def load_fixture_doc(path: Path) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8")
    match = re.search(r"```json\s*(\{.*?\})\s*```", text, re.DOTALL)
    if not match:
        raise ValueError("fixture JSON block not found")
    data = json.loads(match.group(1))
    if not isinstance(data, dict):
        raise ValueError("fixture JSON root must be object")
    return data


def warn(warnings: list[dict[str, str]], code: str, detail: str) -> None:
    warnings.append({"code": code, "detail": detail})


def block(blockers: list[dict[str, str]], code: str, detail: str) -> None:
    blockers.append({"code": code, "detail": detail})


def aggregate(inputs: dict[str, Any]) -> dict[str, Any]:
    warnings: list[dict[str, str]] = []
    blockers: list[dict[str, str]] = []

    health = inputs.get("healthcheck")
    preflight = inputs.get("preflight")
    codex = inputs.get("codex")
    openclaw = inputs.get("openclaw_status")
    usage = inputs.get("usage_dashboard")

    missing = []
    for name, value in (
        ("healthcheck", health),
        ("preflight", preflight),
        ("codex", codex),
        ("openclaw_status", openclaw),
        ("usage_dashboard", usage),
    ):
        if not isinstance(value, dict):
            missing.append(name)
            warn(warnings, f"MISSING_{name.upper()}", f"{name} signal missing or invalid")

    health = health if isinstance(health, dict) else {}
    preflight = preflight if isinstance(preflight, dict) else {}
    codex = codex if isinstance(codex, dict) else {}
    openclaw = openclaw if isinstance(openclaw, dict) else {}
    usage = usage if isinstance(usage, dict) else {}

    local_ok = health.get("status") == "OK" and health.get("local_can_work_now") is True
    start_ok = preflight.get("status") == "READY" and preflight.get("can_start_feature") is True
    heavy_ok = codex.get("status") == "AVAILABLE"

    if preflight.get("status") == "BLOCKED":
        block(blockers, "PREFLIGHT_BLOCKED", "preflight blocks feature start")
        start_ok = False

    codex_status = codex.get("status", "UNKNOWN")
    if codex_status == "PLAN_LIMIT_REACHED":
        block(blockers, "HEAVY_MODEL_PLAN_LIMIT", "heavy model work blocked by plan limit")
        heavy_ok = False
    elif codex_status == "RATE_LIMIT_OR_COOLDOWN":
        block(blockers, "HEAVY_MODEL_COOLDOWN", "heavy model work blocked by cooldown")
        heavy_ok = False
    elif codex_status == "SIGNIN_ERROR":
        block(blockers, "HEAVY_MODEL_SIGNIN", "heavy model work blocked by sign-in state")
        heavy_ok = False
    elif codex_status == "UNKNOWN":
        warn(warnings, "HEAVY_MODEL_UNKNOWN", "heavy model availability unknown")
        heavy_ok = False

    if openclaw.get("status") == "WARNING":
        for item in openclaw.get("warnings", []):
            if isinstance(item, dict) and isinstance(item.get("code"), str):
                warn(warnings, item["code"], "openclaw status warning")
        if not any(item["code"].startswith("WARNING_CONTEXT_") for item in warnings):
            warn(warnings, "OPENCLAW_STATUS_WARNING", "openclaw status warning")
    elif openclaw.get("status") == "DEGRADED":
        warn(warnings, "OPENCLAW_STATUS_DEGRADED", "openclaw status degraded")

    usage_summary = usage.get("summary", {}) if isinstance(usage.get("summary"), dict) else {}
    if usage.get("confidence") == "LOW" and usage_summary.get("comparison_stability") == "LOW":
        warn(warnings, "USAGE_COMPARISON_LOW_BASE", "usage comparison base is low confidence")

    if missing:
        status = "NO_VERIFICADO"
        risk = "UNKNOWN"
    elif any(item["code"] == "PREFLIGHT_BLOCKED" for item in blockers):
        status = "BLOCKED"
        risk = "HIGH"
    elif any(item["code"] == "HEAVY_MODEL_PLAN_LIMIT" for item in blockers):
        status = "WARNING"
        risk = "HIGH"
    elif blockers:
        status = "WARNING"
        risk = "HIGH"
    elif warnings:
        status = "WARNING"
        risk = "MEDIUM"
    else:
        status = "OK"
        risk = "LOW"

    return {
        "schema_version": CONTROL_SCHEMA,
        "generated_at": None,
        "status": status,
        "risk_level": risk,
        "can_work": {
            "local": bool(local_ok),
            "start_feature": bool(start_ok),
            "heavy_model": bool(heavy_ok),
        },
        "confidence": {
            "healthcheck": "HIGH",
            "preflight": "HIGH",
            "codex": "MEDIUM",
            "openclaw_status": "MEDIUM",
            "usage_dashboard": "LOW",
        },
        "signals": {
            "healthcheck": {"status": health.get("status", "NO_VERIFICADO"), "confidence": "HIGH", "summary": health},
            "preflight": {"status": preflight.get("status", "NO_VERIFICADO"), "confidence": "HIGH", "summary": preflight},
            "codex": {"status": codex_status, "confidence": "MEDIUM", "summary": codex},
            "openclaw_status": {"status": openclaw.get("status", "NO_VERIFICADO"), "confidence": "MEDIUM", "summary": openclaw},
            "usage_dashboard": {"status": usage.get("status", "NO_VERIFICADO"), "confidence": "LOW", "summary": usage_summary},
        },
        "derived": {
            "context_percent": (openclaw.get("checks") or {}).get("context_percent") if isinstance(openclaw.get("checks"), dict) else None,
            "usage_comparison_stability": usage_summary.get("comparison_stability", "UNKNOWN"),
            "blocking_reason": blockers[0]["code"] if blockers else None,
        },
        "blockers": blockers,
        "warnings": warnings,
        "recommended_next_action": next_action(status, blockers, warnings),
        "safe": True,
        "logs_redacted": True,
    }


def next_action(status: str, blockers: list[dict[str, str]], warnings: list[dict[str, str]]) -> str:
    codes = {item["code"] for item in blockers + warnings}
    if "PREFLIGHT_BLOCKED" in codes:
        return "resolve preflight blocker before starting feature work"
    if "HEAVY_MODEL_PLAN_LIMIT" in codes:
        return "continue local work if needed; wait before heavy model work"
    if "MISSING_PREFLIGHT" in codes:
        return "collect missing preflight signal before relying on aggregate status"
    if status == "WARNING":
        return "local work may continue; review warnings before heavier work"
    if status == "OK":
        return "continue"
    return "review aggregate status"


def codes(items: list[dict[str, str]]) -> set[str]:
    return {item.get("code", "") for item in items if isinstance(item, dict)}


def validate_expected(output: dict[str, Any], expected: dict[str, Any]) -> list[str]:
    failures: list[str] = []
    if output.get("status") != expected.get("status"):
        failures.append(f"status expected {expected.get('status')} got {output.get('status')}")
    if output.get("risk_level") != expected.get("risk_level"):
        failures.append(f"risk_level expected {expected.get('risk_level')} got {output.get('risk_level')}")
    for key, value in expected.get("can_work", {}).items():
        got = (output.get("can_work") or {}).get(key)
        if got is not value:
            failures.append(f"can_work.{key} expected {value} got {got}")
    blocker_codes = codes(output.get("blockers", []))
    warning_codes = codes(output.get("warnings", []))
    for code in expected.get("blockers_include", []):
        if code not in blocker_codes:
            failures.append(f"missing blocker {code}")
    for code in expected.get("warnings_include", []):
        if code not in warning_codes:
            failures.append(f"missing warning {code}")
    return failures


def run_validation() -> dict[str, Any]:
    doc = load_fixture_doc(FIXTURE_PATH)
    fixtures = doc.get("fixtures", [])
    if not isinstance(fixtures, list):
        raise ValueError("fixtures must be a list")

    results = []
    passed = 0
    for fixture in fixtures:
        fixture_id = fixture.get("id", "unknown") if isinstance(fixture, dict) else "invalid"
        if not isinstance(fixture, dict):
            results.append({"id": fixture_id, "status": "FAIL", "failures": ["fixture is not object"]})
            continue
        output = aggregate(fixture.get("inputs", {}))
        failures = validate_expected(output, fixture.get("expected", {}))
        ok = not failures
        if ok:
            passed += 1
        results.append({
            "id": fixture_id,
            "status": "PASS" if ok else "FAIL",
            "failures": failures,
            "output_summary": {
                "status": output.get("status"),
                "risk_level": output.get("risk_level"),
                "can_work": output.get("can_work"),
                "blockers": sorted(codes(output.get("blockers", []))),
                "warnings": sorted(codes(output.get("warnings", []))),
            },
        })

    total = len(fixtures)
    failed = total - passed
    return {
        "status": "PASS" if failed == 0 else "FAIL",
        "schema_version": SCHEMA_VERSION,
        "contract": CONTROL_SCHEMA,
        "fixtures_total": total,
        "fixtures_passed": passed,
        "fixtures_failed": failed,
        "results": results,
        "safe": True,
        "logs_redacted": True,
    }


def main() -> int:
    try:
        payload = run_validation()
        print(json.dumps(payload, ensure_ascii=False)[:OUTPUT_LIMIT])
        return 0 if payload["status"] == "PASS" else 1
    except Exception as exc:
        payload = {
            "status": "FAIL",
            "schema_version": SCHEMA_VERSION,
            "summary": str(exc),
            "safe": True,
            "logs_redacted": True,
        }
        print(json.dumps(payload, ensure_ascii=False)[:OUTPUT_LIMIT])
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
