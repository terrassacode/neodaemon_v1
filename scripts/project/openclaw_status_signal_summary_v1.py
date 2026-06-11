#!/usr/bin/env python3
"""OpenClaw status signal summary v1.

Read-only parser for text returned by the controlled OpenClaw status inspection
route. This script does not execute OpenClaw or call external systems.
"""

from __future__ import annotations

import argparse
import json
import re
import sys


OUTPUT_LIMIT = 4000


def add(items: list[dict[str, object]], code: str, detail: str) -> None:
    items.append({"code": code, "detail": detail})


def first_context_percent(text: str) -> int | None:
    usage_matches = re.findall(r"\b\d+k/\d+k\s*\((\d{1,3})%\)", text, re.IGNORECASE)
    usage_values = [int(value) for value in usage_matches if 0 <= int(value) <= 100]
    if usage_values:
        return max(usage_values)

    matches = re.findall(r"(?<!\d)(\d{1,3})%(?!\w)", text)
    values = [int(value) for value in matches if 0 <= int(value) <= 100]
    if not values:
        return None
    return max(values)


def find_model(text: str) -> str | None:
    match = re.search(r"\b(gpt-[A-Za-z0-9_.-]+|claude-[A-Za-z0-9_.-]+|gemini-[A-Za-z0-9_.-]+)\b", text, re.IGNORECASE)
    return match.group(1) if match else None


def parse_tasks(text: str) -> dict[str, int | None]:
    lowered = text.lower()
    result: dict[str, int | None] = {"active": None, "queued": None, "running": None}
    match = re.search(r"(\d+)\s+active\s+.*?(\d+)\s+queued\s+.*?(\d+)\s+running", lowered)
    if match:
        result["active"] = int(match.group(1))
        result["queued"] = int(match.group(2))
        result["running"] = int(match.group(3))
    return result


def gateway_state(text: str) -> bool | None:
    lowered = text.lower()
    if "gateway" not in lowered:
        return None
    if "gateway" in lowered and "unreachable" in lowered:
        return False
    if "gateway" in lowered and "reachable" in lowered:
        return True
    return None


def summarize(status_text: str) -> dict[str, object]:
    signals: list[dict[str, object]] = []
    warnings: list[dict[str, object]] = []
    checks: dict[str, object] = {
        "model_detected": False,
        "model": None,
        "context_percent": None,
        "gateway_reachable": None,
        "tasks_active": None,
        "tasks_queued": None,
        "tasks_running": None,
        "probes_skipped": False,
    }

    if not status_text.strip():
        add(warnings, "NO_STATUS_TEXT", "no status text supplied")
        return {
            "status": "NO_VERIFICADO",
            "signals": signals,
            "warnings": warnings,
            "checks": checks,
            "recommended_next_action": "run controlled status inspection first",
            "safe": True,
            "logs_redacted": True,
        }

    model = find_model(status_text)
    if model:
        checks["model_detected"] = True
        checks["model"] = model
        add(signals, "MODEL_DETECTED", model)
    else:
        add(warnings, "WARNING_MODEL_UNKNOWN", "model not detected")

    context_percent = first_context_percent(status_text)
    checks["context_percent"] = context_percent
    if context_percent is None:
        add(warnings, "WARNING_CONTEXT_UNKNOWN", "context percentage not detected")
    elif context_percent >= 85:
        add(warnings, "WARNING_CONTEXT_CRITICAL", f"context {context_percent}%")
    elif context_percent >= 70:
        add(warnings, "WARNING_CONTEXT_HIGH", f"context {context_percent}%")
    else:
        add(signals, "CONTEXT_OK", f"context {context_percent}%")

    reachable = gateway_state(status_text)
    checks["gateway_reachable"] = reachable
    if reachable is True:
        add(signals, "GATEWAY_REACHABLE", "gateway reachable")
    elif reachable is False:
        add(warnings, "DEGRADED_GATEWAY", "gateway unreachable")
    else:
        add(warnings, "WARNING_GATEWAY_UNKNOWN", "gateway state not detected")

    tasks = parse_tasks(status_text)
    checks["tasks_active"] = tasks["active"]
    checks["tasks_queued"] = tasks["queued"]
    checks["tasks_running"] = tasks["running"]
    if tasks["queued"] is not None and tasks["queued"] > 0:
        add(warnings, "WARNING_TASKS_QUEUED", f"queued={tasks['queued']}")
    if tasks["running"] is not None and tasks["running"] >= 3:
        add(warnings, "WARNING_TASKS_RUNNING_HIGH", f"running={tasks['running']}")
    if tasks["queued"] == 0 and tasks["running"] is not None and tasks["running"] < 3:
        add(signals, "TASKS_OK", f"queued={tasks['queued']} running={tasks['running']}")

    probes_skipped = "probes" in status_text.lower() and "skipped" in status_text.lower()
    checks["probes_skipped"] = probes_skipped
    if probes_skipped:
        add(signals, "PROBES_SKIPPED", "fast status skipped deep probes")

    warning_codes = {str(item["code"]) for item in warnings}
    if "DEGRADED_GATEWAY" in warning_codes:
        status = "DEGRADED"
        next_action = "check local gateway state before heavy work"
    elif not signals and warnings:
        status = "NO_VERIFICADO"
        next_action = "inspect native status output manually"
    elif warnings:
        status = "WARNING"
        next_action = "continue with caution; avoid heavy work if warnings persist"
    else:
        status = "OK"
        next_action = "continue"

    return {
        "status": status,
        "signals": signals,
        "warnings": warnings,
        "checks": checks,
        "recommended_next_action": next_action,
        "source": "openclaw_status_text_only",
        "safe": True,
        "logs_redacted": True,
    }


def render_human(payload: dict[str, object]) -> str:
    checks = payload.get("checks", {})
    if not isinstance(checks, dict):
        checks = {}
    return "\n".join(
        [
            f"OPENCLAW STATUS SIGNAL: {payload.get('status', 'NO_VERIFICADO')}",
            f"model: {checks.get('model') or 'unknown'}",
            f"context: {checks.get('context_percent') if checks.get('context_percent') is not None else 'unknown'}%",
            f"gateway: {'reachable' if checks.get('gateway_reachable') is True else 'unreachable' if checks.get('gateway_reachable') is False else 'unknown'}",
            f"tasks: active={checks.get('tasks_active')} queued={checks.get('tasks_queued')} running={checks.get('tasks_running')}",
            f"next_action: {payload.get('recommended_next_action', 'inspect status')}",
            "note: derived from openclaw status only; status_usage omitted in v1",
        ]
    )


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Summarize OpenClaw status signals")
    parser.add_argument("--human", action="store_true", help="Print compact human summary")
    parser.add_argument("--status-text", default="", help="Text captured from controlled OpenClaw status inspection")
    args = parser.parse_args(argv)

    payload = summarize(args.status_text)
    if args.human:
        print(render_human(payload)[:OUTPUT_LIMIT])
    else:
        print(json.dumps(payload, ensure_ascii=False)[:OUTPUT_LIMIT])
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
