#!/usr/bin/env python3
"""Project Executor Preflight v1.

Offline-only, read-only readiness gate for starting a Project Executor feature.
"""

from __future__ import annotations

import json
import shutil
import subprocess
from pathlib import Path


CRITICAL_TOOLS = (
    "tools/neodaemon_executor_bridge.sh",
    "tools/neodaemon_local_executor_v1.sh",
    "tools/github_controlled_pr_assistant.sh",
)

CRITICAL_SCRIPTS = (
    "scripts/project/protected_zone_scanner_v1.py",
    "scripts/project/neodaemon_healthcheck_v1.py",
    "scripts/project/project_executor_preflight_v1.py",
)

OUTPUT_LIMIT = 4000


def add(items: list[dict[str, str]], code: str, detail: str) -> None:
    items.append({"code": code, "detail": detail})


def run_cmd(args: list[str], cwd: Path, timeout: int = 5) -> tuple[int, str, str]:
    try:
        proc = subprocess.run(
            args,
            cwd=str(cwd),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return 124, "", "timeout"
    return proc.returncode, proc.stdout.strip(), proc.stderr.strip()


def main() -> int:
    cwd = Path.cwd()
    blockers: list[dict[str, str]] = []
    warnings: list[dict[str, str]] = []
    evidence: list[dict[str, str]] = []

    result: dict[str, object] = {
        "status": "BLOCKED",
        "can_start_feature": False,
        "checks": {
            "offline_only": True,
            "git_available": False,
            "repo_valid": False,
            "branch": None,
            "worktree_clean": None,
            "critical_tools_present": False,
            "critical_scripts_present": False,
            "healthcheck_json_valid": False,
        },
        "blockers": blockers,
        "warnings": warnings,
        "evidence": evidence,
        "recommended_next_action": "review preflight result",
        "safe": True,
        "logs_redacted": True,
    }

    git_path = shutil.which("git")
    result["checks"]["git_available"] = bool(git_path)
    if not git_path:
        add(blockers, "git_not_available", "git executable not found")
        result["recommended_next_action"] = "restore git before starting Project Executor work"
        print(json.dumps(result, ensure_ascii=False)[:OUTPUT_LIMIT])
        return 0

    rc, root_out, _ = run_cmd(["git", "rev-parse", "--show-toplevel"], cwd)
    if rc != 0 or not root_out:
        add(blockers, "not_git_repo", "current directory is not inside a git repository")
        result["recommended_next_action"] = "run preflight from the neodaemon repository"
        print(json.dumps(result, ensure_ascii=False)[:OUTPUT_LIMIT])
        return 0

    repo_root = Path(root_out).resolve()
    result["checks"]["repo_valid"] = True
    add(evidence, "repo_valid", "repository root detected")

    rc, status_out, _ = run_cmd(["git", "status", "--short"], repo_root)
    if rc != 0:
        add(blockers, "git_status_failed", "git status --short failed")
        result["recommended_next_action"] = "repair git state before starting Project Executor work"
        print(json.dumps(result, ensure_ascii=False)[:OUTPUT_LIMIT])
        return 0

    worktree_clean = not bool(status_out)
    result["checks"]["worktree_clean"] = worktree_clean
    if worktree_clean:
        add(evidence, "worktree_clean", "worktree is clean")
    else:
        add(blockers, "worktree_dirty", "worktree must be clean before starting a feature")

    rc, branch_out, _ = run_cmd(["git", "branch", "--show-current"], repo_root)
    branch = branch_out if rc == 0 and branch_out else None
    result["checks"]["branch"] = branch
    if branch == "main":
        add(evidence, "branch_main", "current branch is main")
    elif branch:
        add(blockers, "branch_not_main", "feature start requires main")
    else:
        add(warnings, "branch_unknown", "branch could not be determined")

    missing_tools = [path for path in CRITICAL_TOOLS if not (repo_root / path).is_file()]
    result["checks"]["critical_tools_present"] = not missing_tools
    if missing_tools:
        add(blockers, "critical_tools_missing", "one or more required tool files are absent")
    else:
        add(evidence, "critical_tools_present", "required tool files are present")

    missing_scripts = [path for path in CRITICAL_SCRIPTS if not (repo_root / path).is_file()]
    result["checks"]["critical_scripts_present"] = not missing_scripts
    if missing_scripts:
        add(blockers, "critical_scripts_missing", "one or more required project scripts are absent")
    else:
        add(evidence, "critical_scripts_present", "required project scripts are present")

    health_path = repo_root / "scripts/project/neodaemon_healthcheck_v1.py"
    if health_path.is_file():
        rc, health_out, _ = run_cmd(["python3", str(health_path.relative_to(repo_root))], repo_root, timeout=10)
        if rc == 0:
            try:
                health = json.loads(health_out)
                result["checks"]["healthcheck_json_valid"] = isinstance(health, dict)
                add(evidence, "healthcheck_json_valid", "healthcheck produced JSON")
            except json.JSONDecodeError:
                add(warnings, "healthcheck_json_invalid", "healthcheck output was not JSON")
        else:
            add(warnings, "healthcheck_failed", "healthcheck did not complete successfully")

    if blockers:
        result["status"] = "BLOCKED"
        result["can_start_feature"] = False
        if not worktree_clean:
            result["recommended_next_action"] = "clean or inspect the worktree before starting a feature"
        elif branch != "main":
            result["recommended_next_action"] = "switch to main and sync before starting a feature"
        else:
            result["recommended_next_action"] = "resolve blockers before starting a feature"
    elif warnings:
        result["status"] = "DEGRADED"
        result["can_start_feature"] = False
        result["recommended_next_action"] = "review warnings before starting a feature"
    else:
        result["status"] = "READY"
        result["can_start_feature"] = True
        result["recommended_next_action"] = "start the approved feature using Project Executor workflow"

    print(json.dumps(result, ensure_ascii=False)[:OUTPUT_LIMIT])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
