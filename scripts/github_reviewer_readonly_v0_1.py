#!/usr/bin/env python3
"""
GITHUB_REVIEWER_READONLY_V0_1

Manual local-only Git reviewer.

Read-only:
- current branch
- git status --short
- last commit
- local branches
- known remote branches
- branches not merged into main

No gh.
No fetch.
No pull.
No push.
No merge.
No files edited.
No snapshots.
"""

from __future__ import annotations

import json
import subprocess
from pathlib import Path


REPO_ROOT = Path.cwd()


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


def main() -> None:
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

    report = {
        "report": "GITHUB_REVIEW_REPORT_V0_1",
        "status": "OK" if not warnings else "WARNING",
        "summary": {
            "branch": branch,
            "last_commit": last_commit,
            "working_tree_clean": status_short == "",
            "local_branch_count": len(local_branches),
            "remote_branch_count": len(remote_branches),
            "unmerged_branch_count": len(unmerged_branches),
        },
        "local_branches": local_branches,
        "remote_branches": remote_branches,
        "unmerged_branches": unmerged_branches,
        "warnings": warnings,
        "forbidden_actions": [
            "gh",
            "fetch",
            "pull",
            "push",
            "merge",
            "commit",
            "add",
            "delete_branch",
            "write_files",
            "systemd",
            "services",
            "gmail",
            "oauth",
            "tokens",
        ],
        "validations": {
            "read_only": before == after,
            "local_only": True,
            "no_snapshot": True,
            "no_fetch": True,
            "no_gh": True,
        },
    }

    print(json.dumps(report, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
