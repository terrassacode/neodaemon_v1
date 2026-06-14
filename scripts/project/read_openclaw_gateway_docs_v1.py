#!/usr/bin/env python3
"""Controlled read-only OpenClaw gateway/runtime docs discovery v1."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

ACTION = "read_openclaw_gateway_docs"
MAX_LINES = 250
MAX_FILES = 16
ALLOWED_PATHS = {
    "/usr/lib/node_modules/openclaw/package.json",
    "/usr/lib/node_modules/openclaw/docs/gateway/configuration.md",
    "/usr/lib/node_modules/openclaw/docs/gateway/config-tools.md",
    "/usr/lib/node_modules/openclaw/docs/plugins/architecture.md",
    "/usr/lib/node_modules/openclaw/docs/plugins/architecture-internals.md",
    "/usr/lib/node_modules/openclaw/docs/plugins/building-plugins.md",
    "/usr/lib/node_modules/openclaw/docs/plugins/sdk-channel-plugins.md",
    "/usr/lib/node_modules/openclaw/docs/plugins/sdk-overview.md",
    "/usr/lib/node_modules/openclaw/docs/plugins/sdk-setup.md",
    "/usr/lib/node_modules/openclaw/docs/tools/plugin.md",
    "/usr/lib/node_modules/openclaw/dist/plugin-sdk/plugin-entry.js",
    "/usr/lib/node_modules/openclaw/dist/plugins/api-builder.js",
    "/usr/lib/node_modules/openclaw/dist/plugins/registry.js",
    "/usr/lib/node_modules/openclaw/src/plugins/api-builder.ts",
    "/usr/lib/node_modules/openclaw/src/plugins/registry.ts",
}


def emit(payload: dict, rc: int = 0) -> None:
    payload.setdefault("action", ACTION)
    payload.setdefault("safe", True)
    payload.setdefault("logs_redacted", True)
    print(json.dumps(payload, ensure_ascii=False, separators=(",", ":")))
    raise SystemExit(rc)


def blocked(summary: str, **extra: object) -> None:
    emit({"status": "BLOCKED_WITH_REASON", "summary": summary, **extra}, 1)


def normalize_requested(paths: list[str]) -> list[str]:
    if not paths:
        return sorted(ALLOWED_PATHS)
    if len(paths) > MAX_FILES:
        blocked("too many files requested", max_files=MAX_FILES)
    normalized: list[str] = []
    for raw in paths:
        if not isinstance(raw, str) or not raw:
            blocked("invalid path")
        path = str(Path(raw))
        if path not in ALLOWED_PATHS:
            blocked("path not allowed", path=raw)
        if path not in normalized:
            normalized.append(path)
    return normalized


def read_file(path_text: str) -> dict:
    path = Path(path_text)
    if path.is_symlink():
        return {
            "path": path_text,
            "exists": True,
            "status": "BLOCKED_WITH_REASON",
            "reason": "symlink not allowed",
            "first_lines": [],
            "truncated": False,
        }
    if not path.exists():
        return {
            "path": path_text,
            "exists": False,
            "status": "NO_VERIFICADO",
            "first_lines": [],
            "truncated": False,
        }
    if not path.is_file():
        return {
            "path": path_text,
            "exists": True,
            "status": "BLOCKED_WITH_REASON",
            "reason": "not a regular file",
            "first_lines": [],
            "truncated": False,
        }
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return {
            "path": path_text,
            "exists": True,
            "status": "BLOCKED_WITH_REASON",
            "reason": "not utf-8",
            "first_lines": [],
            "truncated": False,
        }
    lines = text.splitlines()
    return {
        "path": path_text,
        "exists": True,
        "status": "PASS",
        "first_lines": lines[:MAX_LINES],
        "truncated": len(lines) > MAX_LINES,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Read exact OpenClaw gateway/runtime docs")
    parser.add_argument("--path", action="append", default=[], help="exact allowed path; repeat up to 3 times")
    args = parser.parse_args()

    requested = normalize_requested(args.path)
    files = [read_file(path) for path in requested]
    overall = "PASS"
    if any(item["status"] == "BLOCKED_WITH_REASON" for item in files):
        overall = "BLOCKED_WITH_REASON"
    elif any(item["status"] == "NO_VERIFICADO" for item in files):
        overall = "NO_VERIFICADO"

    emit({
        "status": overall,
        "files_read": len(files),
        "max_lines_per_file": MAX_LINES,
        "files": files,
    }, 0 if overall in {"PASS", "NO_VERIFICADO"} else 1)


if __name__ == "__main__":
    main()
