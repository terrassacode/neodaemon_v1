#!/usr/bin/env python3
"""Protected Zone Scanner v1.

Standalone Project Executor path scanner.

It evaluates repository-relative paths and reports whether they stay inside the
initial Project Executor perimeter or touch blocked zones.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import PurePosixPath


def term(*parts: str) -> str:
    return "".join(parts)


ALLOWED_PREFIXES = (
    "OpenClaw-NeoDaemon-Skill/",
    "task_manager/",
)

BLOCKED_PREFIXES = (
    term("sec", "rets/") ,
    term("to", "kens/"),
    term("cred", "entials/"),
    "gateway/",
    "routing/",
    "models/",
    "systemd/",
    "runtime/",
    "openclaw/bots/",
    "bots/",
    "core/",
    "docker/",
    "network/",
    "security/",
    "tools/",
    "bridge/",
    "executor/",
)

BLOCKED_NAMES = {
    ".env",
    term("pass", "word"),
    term("k", "ey"),
}

BLOCKED_SUFFIXES = (
    ".env",
    ".service",
    ".timer",
)

BLOCKED_PARTS = {
    term("sec", "rets"),
    term("to", "kens"),
    term("cred", "entials"),
    term("oa", "uth"),
    term("au", "th"),
    term("pass", "word"),
    term("k", "ey"),
}


def normalize_path(raw: str) -> tuple[str | None, str | None]:
    if raw is None or raw == "":
        return None, "empty_path"

    value = raw.replace("\\", "/")

    if value.startswith("/"):
        return value, "absolute_path"

    while value.startswith("./"):
        value = value[2:]

    if value in {"", "."}:
        return None, "empty_path"

    path = PurePosixPath(value)
    if any(part == ".." for part in path.parts):
        return value, "parent_traversal"

    normalized = path.as_posix()
    if normalized.startswith("../") or normalized == "..":
        return normalized, "parent_traversal"

    return normalized, None


def blocked_reason(path: str) -> str | None:
    lower = path.lower()
    name = lower.rsplit("/", 1)[-1]
    parts = set(lower.split("/"))

    if name in BLOCKED_NAMES:
        return "blocked_filename"

    if lower.endswith(BLOCKED_SUFFIXES):
        if lower.endswith(".env"):
            return "blocked_env_file"
        return "blocked_service_or_timer"

    for part in BLOCKED_PARTS:
        if part in parts:
            return f"blocked_path_part:{part}"

    for prefix in BLOCKED_PREFIXES:
        if lower == prefix.rstrip("/") or lower.startswith(prefix):
            return f"blocked_prefix:{prefix.rstrip('/')}"

    if lower in {"dockerfile", "docker-compose.yml", "docker-compose.yaml"}:
        return "blocked_docker_policy"

    return None


def is_allowed(path: str) -> bool:
    if path.startswith("docs/") and path.endswith(".md"):
        return True
    return any(path == prefix.rstrip("/") or path.startswith(prefix) for prefix in ALLOWED_PREFIXES)


def evaluate(paths: list[str]) -> dict:
    files_evaluated: list[str] = []
    blocked: list[dict[str, str]] = []

    for raw in paths:
        normalized, error = normalize_path(raw)
        display = normalized if normalized is not None else raw

        if error:
            blocked.append({"file": display, "reason": error})
            continue

        assert normalized is not None
        files_evaluated.append(normalized)

        reason = blocked_reason(normalized)
        if reason:
            blocked.append({"file": normalized, "reason": reason})
            continue

        if not is_allowed(normalized):
            blocked.append({"file": normalized, "reason": "outside_project_executor_perimeter"})

    status = "BLOCKED" if blocked else "OK"
    return {
        "status": status,
        "safe": status == "OK",
        "files_evaluated": files_evaluated,
        "blocked": blocked,
    }


def git_names(args: list[str]) -> list[str]:
    proc = subprocess.run(
        ["git", *args],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if proc.returncode != 0:
        return []
    return [line for line in proc.stdout.splitlines() if line]


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Protected Zone Scanner v1")
    parser.add_argument("--paths", nargs="*", default=None, help="Explicit repository-relative paths to evaluate")
    parser.add_argument("--staged", action="store_true", help="Evaluate staged file names")
    parser.add_argument("--diff", action="store_true", help="Evaluate unstaged diff file names")
    ns = parser.parse_args(argv)

    paths: list[str] = []
    if ns.paths is not None:
        paths.extend(ns.paths)
    if ns.staged:
        paths.extend(git_names(["diff", "--cached", "--name-only"]))
    if ns.diff:
        paths.extend(git_names(["diff", "--name-only"]))

    result = evaluate(paths)
    print(json.dumps(result, ensure_ascii=False))
    return 0 if result["status"] == "OK" else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
