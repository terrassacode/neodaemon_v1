#!/usr/bin/env python3
"""
SAFE_EXECUTOR_V1_LOCAL_DOCS

Local-only executor for controlled documentation changes.

Allowed:
- create a local branch
- create or edit one Markdown file under docs/
- git add the approved file only
- git commit locally
- prepare FEATURE_READY_FOR_GITHUB output

Blocked:
- push
- PR
- merge
- shell free execution
- files outside docs/
- non-Markdown files
- git add .
- git add -A
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


REPO_ROOT = Path.cwd()
ALLOWED_ACTION = "create_doc_commit"
DOCS_PREFIX = "docs/"
MARKDOWN_SUFFIX = ".md"

BLOCKED_SECRET_PATTERNS = [
    "token",
    "refresh_token",
    "client_secret",
    "private_key",
    "BEGIN PRIVATE KEY",
    "oauth",
    "credential",
    "password",
]


@dataclass(frozen=True)
class ExecutorRequest:
    action: str
    branch: str
    file_path: str
    content: str
    commit_message: str


def deny(message: str) -> None:
    print(json.dumps({
        "status": "DENY",
        "reason": message,
    }, indent=2, ensure_ascii=False))
    raise SystemExit(1)


def run_git(args: list[str]) -> str:
    if not args:
        deny("empty git command")

    blocked = [
        ["add", "."],
        ["add", "-A"],
        ["push"],
        ["merge"],
        ["pull"],
        ["fetch"],
    ]

    for blocked_args in blocked:
        if args[: len(blocked_args)] == blocked_args:
            deny(f"blocked git command: git {' '.join(args)}")

    result = subprocess.run(
        ["git", *args],
        cwd=REPO_ROOT,
        text=True,
        capture_output=True,
        check=False,
    )

    if result.returncode != 0:
        deny(result.stderr.strip() or f"git command failed: git {' '.join(args)}")

    return result.stdout.strip()


def load_request(path: Path) -> ExecutorRequest:
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        deny(f"invalid json input: {exc}")

    required = ["action", "branch", "file_path", "content", "commit_message"]
    missing = [key for key in required if key not in raw]
    if missing:
        deny(f"missing fields: {missing}")

    return ExecutorRequest(
        action=str(raw["action"]),
        branch=str(raw["branch"]),
        file_path=str(raw["file_path"]),
        content=str(raw["content"]),
        commit_message=str(raw["commit_message"]),
    )


def validate_request(req: ExecutorRequest) -> None:
    if req.action != ALLOWED_ACTION:
        deny(f"unsupported action: {req.action}")

    if not re.fullmatch(r"[A-Za-z0-9._/-]+", req.branch):
        deny("invalid branch name")

    if req.branch.startswith("-") or ".." in req.branch:
        deny("unsafe branch name")

    if not req.file_path.startswith(DOCS_PREFIX):
        deny("file_path must start with docs/")

    if not req.file_path.endswith(MARKDOWN_SUFFIX):
        deny("file_path must end with .md")

    if ".." in Path(req.file_path).parts:
        deny("file_path cannot contain ..")

    if Path(req.file_path).is_absolute():
        deny("file_path must be relative")

    if not req.content.strip():
        deny("content cannot be empty")

    if not req.commit_message.startswith("docs("):
        deny("commit message must start with docs(")

    lower_blob = f"{req.file_path}\n{req.content}\n{req.commit_message}".lower()
    for pattern in BLOCKED_SECRET_PATTERNS:
        if pattern.lower() in lower_blob:
            deny(f"blocked secret-like pattern: {pattern}")


def ensure_clean_start() -> None:
    status = run_git(["status", "--short"])
    if status:
        deny("working tree is not clean before execution")


def create_branch(branch: str) -> None:
    run_git(["checkout", "-b", branch])


def write_doc(file_path: str, content: str) -> Path:
    target = REPO_ROOT / file_path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content.rstrip() + "\n", encoding="utf-8")
    return target


def commit_file(file_path: str, commit_message: str) -> str:
    run_git(["add", file_path])
    diff_stat = run_git(["diff", "--stat", "--cached"])
    if not diff_stat:
        deny("no staged changes")

    run_git(["commit", "-m", commit_message])
    commit_sha = run_git(["rev-parse", "--short", "HEAD"])
    return commit_sha


def build_feature_ready(req: ExecutorRequest, commit_sha: str) -> dict[str, Any]:
    status = run_git(["status", "--short"])
    changed_file = req.file_path

    return {
        "status": "FEATURE_READY_FOR_GITHUB",
        "mode": "LOCAL_ONLY",
        "branch": req.branch,
        "commit": commit_sha,
        "file": changed_file,
        "included": [
            "created local branch",
            "created/edited Markdown file under docs/",
            "validated git status",
            "validated git diff",
            "git add explicit approved file only",
            "created local commit",
            "prepared PR summary",
        ],
        "not_included": [
            "push",
            "pull",
            "fetch",
            "open PR",
            "merge",
            "GitHub remote operation",
            "Gmail",
            "OAuth",
            "tokens",
            "systemd",
            "services",
            "core changes",
        ],
        "validations": {
            "working_tree_clean_after_commit": status == "",
            "file_path_allowed": changed_file.startswith(DOCS_PREFIX),
            "markdown_only": changed_file.endswith(MARKDOWN_SUFFIX),
            "local_only": True,
        },
        "pr_summary": {
            "title": req.commit_message,
            "body": (
                "## Summary\n\n"
                f"Adds or updates `{changed_file}`.\n\n"
                "## Scope\n\n"
                "Documentation only.\n\n"
                "## Safety\n\n"
                "- Local commit only\n"
                "- No push executed\n"
                "- No PR opened automatically\n"
                "- No Gmail/OAuth/tokens/systemd/services/core touched\n"
            ),
        },
        "rollback": f"git revert {commit_sha}",
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Safe Executor V1 local docs")
    parser.add_argument("--input", required=True, help="Path to JSON request")
    args = parser.parse_args()

    req = load_request(Path(args.input))
    validate_request(req)
    ensure_clean_start()
    create_branch(req.branch)
    write_doc(req.file_path, req.content)
    commit_sha = commit_file(req.file_path, req.commit_message)

    print(json.dumps(build_feature_ready(req, commit_sha), indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()


