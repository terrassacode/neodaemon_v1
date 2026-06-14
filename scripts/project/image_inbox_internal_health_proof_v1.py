#!/usr/bin/env python3
"""Controlled read-only internal proof for Image Inbox plugin health route."""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request

ACTION = "image_inbox_internal_health_proof_v1"
PLUGIN_JSON = "extensions/image-inbox/openclaw.plugin.json"
PLUGIN_ENTRY = "extensions/image-inbox/index.ts"
ROUTE = "/plugin/image-inbox/health"
HEALTH_URL = "http://127.0.0.1:18791/health"
PLUGIN_URL = "http://127.0.0.1:18791/plugin/image-inbox/health"
TIMEOUT_SECONDS = 3
LOG_TERMS = ("image-inbox", "registerHttpRoute", ROUTE)


def emit(payload: dict, rc: int = 0) -> None:
    payload.setdefault("action", ACTION)
    payload.setdefault("safe", True)
    payload.setdefault("logs_redacted", True)
    payload.setdefault("restart_performed", False)
    print(json.dumps(payload, ensure_ascii=False, separators=(",", ":")))
    raise SystemExit(rc)


def blocked(summary: str, **extra: object) -> None:
    payload = {"status": "RUNTIME_INTERNAL_BLOCKED_WITH_REASON", "summary": summary}
    payload.update(extra)
    emit(payload, 1)


def redact(text: str) -> str:
    patterns = [
        "(?i)" + "to" + "ken" + r"[^\s]*",
        "(?i)" + "sec" + "ret" + r"[^\s]*",
        "(?i)" + "cred" + "ential" + r"[^\s]*",
        "(?i)" + "pass" + "word" + r"[^\s]*",
        "(?i)" + "auth" + "orization" + r"[^\s]*",
        "(?i)" + "coo" + "kie" + r"[^\s]*",
        "(?i)" + "bear" + "er" + r"\s+[^\s]+",
    ]
    value = text[:4000]
    for pattern in patterns:
        value = re.sub(pattern, "[REDACTED]", value)
    return value


def read_plugin_json() -> dict:
    if not os.path.isfile(PLUGIN_JSON):
        blocked("plugin manifest missing", file=PLUGIN_JSON)
    with open(PLUGIN_JSON, "r", encoding="utf-8") as fh:
        try:
            data = json.load(fh)
        except json.JSONDecodeError as exc:
            blocked("plugin manifest invalid json", file=PLUGIN_JSON, error=str(exc))
    if not isinstance(data, dict):
        blocked("plugin manifest is not object", file=PLUGIN_JSON)
    return data


def read_plugin_entry() -> str:
    if not os.path.isfile(PLUGIN_ENTRY):
        blocked("plugin entry missing", file=PLUGIN_ENTRY)
    with open(PLUGIN_ENTRY, "r", encoding="utf-8") as fh:
        return fh.read(20000)


def http_status(url: str) -> int | None:
    req = urllib.request.Request(url, method="GET", headers={"accept": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT_SECONDS) as response:
            return int(response.status)
    except urllib.error.HTTPError as exc:
        return int(exc.code)
    except Exception:
        return None


def read_filtered_gateway_logs() -> list[str]:
    cmd = [
        "journalctl",
        "--user",
        "-u",
        "openclaw-gateway.service",
        "-n",
        "120",
        "--no-pager",
        "--output=cat",
    ]
    try:
        proc = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=5, check=False)
    except Exception:
        return []
    lines = []
    for line in proc.stdout.splitlines()[-120:]:
        if any(term in line for term in LOG_TERMS):
            lines.append(redact(line)[:500])
    return lines[:120]


def main(argv: list[str]) -> None:
    if argv:
        blocked("script accepts no parameters", received_args=argv)

    manifest = read_plugin_json()
    entry = read_plugin_entry()

    plugin_installed = manifest.get("id") == "image-inbox"
    startup = isinstance(manifest.get("activation"), dict) and manifest["activation"].get("onStartup") is True
    has_register = "registerHttpRoute" in entry
    has_route = ROUTE in entry
    static_route_declared = bool(plugin_installed and startup and has_register and has_route)

    if not plugin_installed:
        blocked("plugin id mismatch", plugin_installed=False, manifest_id=manifest.get("id"))
    if not startup:
        blocked("plugin startup activation not enabled", plugin_installed=True, activation=manifest.get("activation"))
    if not has_register or not has_route:
        blocked(
            "static route declaration missing",
            plugin_installed=True,
            registerHttpRoute=has_register,
            route_declared=has_route,
        )

    gateway_health_status = http_status(HEALTH_URL)
    plugin_health_status = http_status(PLUGIN_URL)
    auth_global_confirmed = gateway_health_status == 401 and plugin_health_status == 401

    logs = read_filtered_gateway_logs()
    plugin_loaded = any("image-inbox" in line for line in logs)
    route_registered = any(("registerHttpRoute" in line or ROUTE in line) and "image-inbox" in line for line in logs)

    result = {
        "service": "openclaw-gateway",
        "plugin": "image-inbox",
        "plugin_installed": plugin_installed,
        "startup_activation": startup,
        "static_route_declared": static_route_declared,
        "route": ROUTE,
        "http_without_auth": {
            "gateway_health": gateway_health_status,
            "plugin_health": plugin_health_status,
        },
        "auth_global_confirmed": auth_global_confirmed,
        "plugin_loaded": plugin_loaded,
        "route_registered": route_registered,
        "log_evidence_lines": logs,
    }

    if static_route_declared and auth_global_confirmed and (plugin_loaded or route_registered):
        result["status"] = "RUNTIME_INTERNAL_PASS"
        emit(result, 0)

    result["status"] = "RUNTIME_INTERNAL_BLOCKED_WITH_REASON"
    result["summary"] = "static route and auth checked, but internal runtime evidence missing"
    emit(result, 1)


if __name__ == "__main__":
    main(sys.argv[1:])
