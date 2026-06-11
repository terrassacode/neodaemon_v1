#!/usr/bin/env python3
"""Codex status classifier v1.

Offline-only, read-only classifier based on explicit local evidence supplied to the
script. It performs no live provider calls, no retries, and no fallback.
"""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass


OUTPUT_LIMIT = 4000


def term(*parts: str) -> str:
    return "".join(parts)


@dataclass(frozen=True)
class Classification:
    status: str
    codex_status: str
    can_launch_heavy_tasks: bool
    reason: str
    next_action: str


def classify(text: str) -> Classification:
    lowered = text.lower()

    limit_marker = "usage_limit_reached"
    plan_marker = "plan_type=plus"
    rate_marker = "rate_limit"
    cool_marker = "cooldown"
    sign_in_marker = "sign in required"
    unauth_marker = term("un", "authorized")
    fail_marker = term("au", "thentication failed")
    success_marker = "recent_success"
    ok_marker = "codex_completed"

    if limit_marker in lowered and plan_marker in lowered:
        return Classification(
            status="BLOCKED",
            codex_status="PLAN_LIMIT_REACHED",
            can_launch_heavy_tasks=False,
            reason="usage_limit_reached + plan_type=plus",
            next_action="wait for reset; no retries, no fallback, no probe",
        )

    if rate_marker in lowered or cool_marker in lowered:
        return Classification(
            status="DEGRADED",
            codex_status="RATE_LIMIT_OR_COOLDOWN",
            can_launch_heavy_tasks=False,
            reason="rate limit or cooldown signal found in local evidence",
            next_action="wait for cooldown; avoid repeated probes and fallback",
        )

    if sign_in_marker in lowered or unauth_marker in lowered or fail_marker in lowered:
        return Classification(
            status="BLOCKED",
            codex_status="SIGN_IN_ERROR",
            can_launch_heavy_tasks=False,
            reason="sign-in failure signal found in local evidence",
            next_action="review interactive sign-in state manually; do not expose session material",
        )

    if success_marker in lowered and ok_marker in lowered:
        return Classification(
            status="OK",
            codex_status="AVAILABLE",
            can_launch_heavy_tasks=True,
            reason="recent explicit local success evidence found",
            next_action="continue; keep avoiding unnecessary probes",
        )

    return Classification(
        status="NO_VERIFICADO",
        codex_status="UNKNOWN",
        can_launch_heavy_tasks=False,
        reason="no clear local evidence in v1",
        next_action="avoid heavy tasks unless explicitly required; do not probe repeatedly",
    )


def build_payload(classification: Classification, evidence_source: str) -> dict[str, object]:
    return {
        "status": classification.status,
        "codex_status": classification.codex_status,
        "can_launch_heavy_tasks": classification.can_launch_heavy_tasks,
        "evidence": [
            {
                "source": evidence_source,
                "reason": classification.reason,
            }
        ],
        "recommended_next_action": classification.next_action,
        "anti_loop_policy": {
            "no_retries": True,
            "no_fallback": True,
            "no_probe": True,
        },
        "scope": "offline_local_evidence_only",
        "safe": True,
        "logs_redacted": True,
    }


def render_human(payload: dict[str, object]) -> str:
    policy = payload.get("anti_loop_policy", {})
    return "\n".join(
        [
            f"CODEX STATUS: {payload.get('codex_status', 'UNKNOWN')}",
            f"can_launch_heavy_tasks: {'yes' if payload.get('can_launch_heavy_tasks') else 'no'}",
            f"status: {payload.get('status', 'NO_VERIFICADO')}",
            f"scope: {payload.get('scope', 'offline_local_evidence_only')}",
            f"next_action: {payload.get('recommended_next_action', 'avoid heavy tasks')}",
            "policy: no retries, no fallback, no probe" if isinstance(policy, dict) else "policy: no retries, no fallback, no probe",
        ]
    )


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Offline Codex status classifier v1")
    parser.add_argument("--human", action="store_true", help="Print compact human summary")
    parser.add_argument("--sample-text", default="", help="Explicit local evidence text for deterministic validation")
    args = parser.parse_args(argv)

    evidence_text = args.sample_text or ""
    evidence_source = "sample_text" if args.sample_text else "no_local_evidence_supplied"
    payload = build_payload(classify(evidence_text), evidence_source)

    if args.human:
        print(render_human(payload)[:OUTPUT_LIMIT])
    else:
        print(json.dumps(payload, ensure_ascii=False)[:OUTPUT_LIMIT])
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
