#!/usr/bin/env python3
"""
GITHUB_REVIEWER_READONLY_V0_2

Manual local-only Git reviewer with minimal snapshot comparison.

Read-only for repository:
- current branch
- git status --short
- last commit
- local branches
- known remote branches
- branches not merged into main

Writes only snapshot outside repo:
~/.openclaw/neodaemon/github_reviewer_state_v0_2.json

No gh.
No fetch.
No pull.
No push.
No merge.
No files edited inside repo.
No secret scanning.
No diffs.
"""

from __future__ import annotations

import json
import subprocess
from pathlib import Path
from datetime import datetime, timezone


REPO_ROOT = Path.cwd()
SNAPSHOT_PATH = Path.home() / ".openclaw" / "neodaemon" / "github_reviewer_state_v0_2.json"

COMPARE_FIELDS = [
    "branch",
    "last_commit",
    "working_tree_clean",
    "local_branches",
    "remote_branches",
    "unmerged_branches",
    "warnings",
]


def git(args: list[str]) -> str:
    allowed = [
        ["branch", "--show-current"],
        ["status", "--short"],
        ["log", "--oneline", "-1"],
        ["branch"],
        ["branch", "-r"],
        ["branch", "--no-merged", "main"],
    ]

    if args not in allowed:
        raise SystemExit(f"BLOCK: forbidden git command: git {' '.join(args)}")

    result = subprocess.run(
        ["git", *args],
        cwd=REPO_ROOT,
        text=True,
        capture_output=True,
        check=False,
    )

    if result.returncode != 0:
        return ""

    return result.stdout.strip()


def clean_branch_lines(raw: str) -> list[str]:
    branches = []
    for line in raw.splitlines():
        value = line.replace("*", "").strip()
        if value:
            branches.append(value)
    return branches


def load_snapshot() -> dict:
    if not SNAPSHOT_PATH.exists():
        return {}

    try:
        data = json.loads(SNAPSHOT_PATH.read_text(encoding="utf-8"))
    except Exception:
        return {}

    return data if isinstance(data, dict) else {}


def save_snapshot(state: dict) -> None:
    SNAPSHOT_PATH.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "updated_at": datetime.now(timezone.utc).isoformat(),
        "state": state,
    }
    SNAPSHOT_PATH.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")


def build_state() -> dict:
    before = git(["status", "--short"])

    branch = git(["branch", "--show-current"])
    status_short = before
    last_commit = git(["log", "--oneline", "-1"])
    local_branches = clean_branch_lines(git(["branch"]))
    remote_branches = clean_branch_lines(git(["branch", "-r"]))
    unmerged_branches = clean_branch_lines(git(["branch", "--no-merged", "main"]))

    after = git(["status", "--short"])

    warnings = []
    if status_short:
        warnings.append("working_tree_not_clean")
    if branch != "main":
        warnings.append("not_on_main")
    if unmerged_branches:
        warnings.append("unmerged_branches_detected")
    if before != after:
        warnings.append("repo_changed_during_review")

    return {
        "branch": branch,
        "last_commit": last_commit,
        "working_tree_clean": status_short == "",
        "local_branches": local_branches,
        "remote_branches": remote_branches,
        "unmerged_branches": unmerged_branches,
        "warnings": warnings,
        "read_only": before == after,
    }


def compare_states(previous: dict, current: dict) -> tuple[bool, list[dict]]:
    previous_state = previous.get("state", {}) if previous else {}
    changes = []

    for field in COMPARE_FIELDS:
        old = previous_state.get(field)
        new = current.get(field)

        if old != new:
            changes.append({
                "field": field,
                "old": old,
                "new": new,
            })

    return bool(changes), changes


def main() -> None:
    current = build_state()
    previous = load_snapshot()
    changed, changes = compare_states(previous, current)

    save_snapshot(current)

    report = {
        "report": "GITHUB_REVIEW_REPORT_V0_2",
        "status": "OK" if not current["warnings"] else "WARNING",
        "summary": {
            "branch": current["branch"],
            "last_commit": current["last_commit"],
            "working_tree_clean": current["working_tree_clean"],
            "local_branch_count": len(current["local_branches"]),
            "remote_branch_count": len(current["remote_branches"]),
            "unmerged_branch_count": len(current["unmerged_branches"]),
        },
        "local_branches": current["local_branches"],
        "remote_branches": current["remote_branches"],
        "unmerged_branches": current["unmerged_branches"],
        "warnings": current["warnings"],
        "changed_since_last_run": changed,
        "changes": changes,
        "snapshot_updated": True,
        "snapshot_path": str(SNAPSHOT_PATH),
        "forbidden_actions": [
            "gh",
            "fetch",
            "pull",
            "push",
            "merge",
            "commit",
            "add",
            "delete_branch",
            "write_files_inside_repo",
            "systemd",
            "services",
            "gmail",
            "oauth",
            "tokens",
            "secret_scanning",
            "diffs",
        ],
        "validations": {
            "read_only": current["read_only"],
            "local_only": True,
            "snapshot_outside_repo": not str(SNAPSHOT_PATH).startswith(str(REPO_ROOT)),
            "no_fetch": True,
            "no_gh": True,
        },
    }

    print(json.dumps(report, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
