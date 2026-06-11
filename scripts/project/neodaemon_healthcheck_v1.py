#!/usr/bin/env python3
"""NeoDaemon Healthcheck v1.

Offline-only, read-only, project-local health signal for Project Executor work.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path


CRITICAL_TOOLS = (
    "tools/neodaemon_executor_bridge.sh",
    "tools/neodaemon_local_executor_v1.sh",
    "tools/github_controlled_pr_assistant.sh",
)

CRITICAL_PROJECT_SCRIPTS = (
    "scripts/project/protected_zone_scanner_v1.py",
    "scripts/project/neodaemon_healthcheck_v1.py",
)

OUTPUT_LIMIT = 4000


def run_git(args: list[str], cwd: Path) -> tuple[int, str, str]:
    proc = subprocess.run(
        ["git", *args],
        cwd=str(cwd),
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=5,
        check=False,
    )
    return proc.returncode, proc.stdout.strip(), proc.stderr.strip()


def add(items: list[dict[str, str]], code: str, detail: str) -> None:
    items.append({"code": code, "detail": detail})


def render_human(result: dict[str, object]) -> str:
    checks = result.get("checks", {})
    if not isinstance(checks, dict):
        checks = {}

    can_work = result.get("local_can_work_now")
    can_work_text = "yes" if can_work is True else "no" if can_work is False else "unknown"

    worktree = checks.get("worktree_clean")
    worktree_text = "clean" if worktree is True else "dirty" if worktree is False else "unknown"

    tools = checks.get("critical_tools_present")
    tools_text = "OK" if tools is True else "BLOCKED" if tools is False else "unknown"

    scripts = checks.get("critical_project_scripts_present")
    scripts_text = "OK" if scripts is True else "BLOCKED" if scripts is False else "unknown"

    branch = checks.get("branch") or "unknown"
    notes = "external connectivity omitted in v1"

    return "\n".join(
        [
            f"NEODAEMON LOCAL HEALTH: {result.get('status', 'NO_VERIFICADO')}",
            f"can_work_now: {can_work_text}",
            f"scope: {result.get('health_scope', 'local_offline_only')}",
            f"branch: {branch}",
            f"worktree: {worktree_text}",
            f"critical_tools: {tools_text}",
            f"critical_project_scripts: {scripts_text}",
            f"next_action: {result.get('recommended_next_action', 'review healthcheck result')}",
            f"notes: {notes}",
        ]
    )


def emit(result: dict[str, object], human: bool) -> None:
    if human:
        print(render_human(result)[:OUTPUT_LIMIT])
    else:
        print(json.dumps(result, ensure_ascii=False)[:OUTPUT_LIMIT])


def main(argv: list[str]) -> int:
    if argv not in ([], ["--human"]):
        result = {
            "status": "BLOCKED",
            "health_scope": "local_offline_only",
            "local_can_work_now": False,
            "bottlenecks": [{"code": "unsupported_argument", "detail": "only --human is supported"}],
            "evidence": [],
            "no_verificado": [],
            "recommended_next_action": "run without arguments or with --human",
            "checks": {},
            "safe": True,
            "logs_redacted": True,
        }
        emit(result, "--human" in argv)
        return 0

    human = argv == ["--human"]
    cwd = Path.cwd()
    bottlenecks: list[dict[str, str]] = []
    evidence: list[dict[str, str]] = []
    no_verified: list[dict[str, str]] = []

    result: dict[str, object] = {
        "status": "NO_VERIFICADO",
        "health_scope": "local_offline_only",
        "local_can_work_now": None,
        "bottlenecks": bottlenecks,
        "evidence": evidence,
        "no_verificado": no_verified,
        "recommended_next_action": "review healthcheck result",
        "checks": {},
        "safe": True,
        "logs_redacted": True,
    }

    git_path = shutil.which("git")
    result["checks"] = {
        "git_available": bool(git_path),
        "repo_valid": False,
        "worktree_clean": None,
        "branch": None,
        "critical_tools_present": False,
        "critical_project_scripts_present": False,
    }

    if not git_path:
        add(bottlenecks, "git_not_available", "git executable not found")
        result["status"] = "BLOCKED"
        result["local_can_work_now"] = False
        result["recommended_next_action"] = "restore git availability before project execution"
        emit(result, human)
        return 0

    rc, root_out, _ = run_git(["rev-parse", "--show-toplevel"], cwd)
    if rc != 0 or not root_out:
        add(bottlenecks, "not_git_repo", "current directory is not inside a git repository")
        result["status"] = "BLOCKED"
        result["local_can_work_now"] = False
        result["recommended_next_action"] = "run healthcheck from the neodaemon repository root"
        emit(result, human)
        return 0

    repo_root = Path(root_out).resolve()
    result["checks"]["repo_valid"] = True
    add(evidence, "repo_root_detected", "repository root detected")

    rc, status_out, _ = run_git(["status", "--short"], repo_root)
    if rc != 0:
        add(bottlenecks, "git_status_failed", "git status could not be executed")
        result["status"] = "BLOCKED"
        result["local_can_work_now"] = False
        result["recommended_next_action"] = "repair git repository state before project execution"
        emit(result, human)
        return 0

    worktree_clean = not bool(status_out)
    result["checks"]["worktree_clean"] = worktree_clean
    if worktree_clean:
        add(evidence, "worktree_clean", "git status --short is clean")
    else:
        add(bottlenecks, "worktree_dirty", "git status --short returned entries")

    rc, branch_out, _ = run_git(["branch", "--show-current"], repo_root)
    branch = branch_out if rc == 0 and branch_out else None
    result["checks"]["branch"] = branch
    if branch == "main":
        add(evidence, "branch_main", "current branch is main")
    elif branch:
        add(bottlenecks, "branch_not_main", "current branch is not main")
    else:
        add(bottlenecks, "branch_unknown", "current branch could not be determined")

    missing_tools = [path for path in CRITICAL_TOOLS if not (repo_root / path).is_file()]
    result["checks"]["critical_tools_present"] = not missing_tools
    if missing_tools:
        add(bottlenecks, "critical_tools_missing", "one or more required tool files are absent")
    else:
        add(evidence, "critical_tools_present", "required tool files are present")

    missing_scripts = [path for path in CRITICAL_PROJECT_SCRIPTS if not (repo_root / path).is_file()]
    result["checks"]["critical_project_scripts_present"] = not missing_scripts
    if missing_scripts:
        add(bottlenecks, "critical_project_scripts_missing", "one or more required project scripts are absent")
    else:
        add(evidence, "critical_project_scripts_present", "required project scripts are present")

    add(no_verified, "external_connectivity_omitted_v1", "network and provider checks are intentionally omitted in v1")

    if missing_tools:
        result["status"] = "BLOCKED"
        result["local_can_work_now"] = False
        result["recommended_next_action"] = "restore required tool files before project execution"
    elif not worktree_clean or branch != "main" or missing_scripts:
        result["status"] = "DEGRADED"
        result["local_can_work_now"] = False
        if not worktree_clean:
            result["recommended_next_action"] = "inspect or clean the worktree before execution"
        elif branch != "main":
            result["recommended_next_action"] = "return to main and sync before normal execution"
        else:
            result["recommended_next_action"] = "restore required project scripts before execution"
    else:
        result["status"] = "OK"
        result["local_can_work_now"] = True
        result["recommended_next_action"] = "continue with local project execution"

    emit(result, human)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
