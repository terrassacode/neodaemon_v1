#!/usr/bin/env python3
"""
SAFE_EXECUTOR_V1_LOCAL_DOCS

Local-only executor for controlled documentation changes.

Allowed:
- inspect repository metadata read-only
- create a local branch
- create or edit one Markdown file under docs/
- insert content before a unique target in one Markdown file under docs/
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
from dataclasses import dataclass
from pathlib import Path
from typing import Any


REPO_ROOT = Path.cwd()

ACTION_CREATE_DOC_COMMIT = "create_doc_commit"
ACTION_INSERT_BEFORE = "insert_before"
ACTION_INSPECT_REPO = "inspect_repo"
SUPPORTED_ACTIONS = {
    ACTION_CREATE_DOC_COMMIT,
    ACTION_INSERT_BEFORE,
    ACTION_INSPECT_REPO,
}

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

DOCS_RELEVANT_PATTERNS = (
    "FEATURE_WORKFLOW",
    "GITHUB_OPERATOR",
    "EXECUTOR",
    "executor",
    "workflow",
    "gmail",
)


@dataclass(frozen=True)
class ExecutorRequest:
    action: str
    branch: str | None = None
    file_path: str | None = None
    content: str | None = None
    commit_message: str | None = None
    target: str | None = None


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


def load_raw_request(path: Path) -> dict[str, Any]:
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        deny(f"invalid json input: {exc}")

    if not isinstance(raw, dict):
        deny("request must be a json object")

    action = raw.get("action")
    if not isinstance(action, str) or not action:
        deny("missing or invalid action")

    if action not in SUPPORTED_ACTIONS:
        deny(f"unsupported action: {action}")

    return raw


def require_fields(raw: dict[str, Any], required: set[str], allowed: set[str]) -> None:
    extra = sorted(set(raw) - allowed)
    if extra:
        deny(f"unexpected fields for {raw.get('action')}: {extra}")

    missing = sorted(required - set(raw))
    if missing:
        deny(f"missing fields for {raw.get('action')}: {missing}")


def load_request(path: Path) -> ExecutorRequest:
    raw = load_raw_request(path)
    action = str(raw["action"])

    if action == ACTION_INSPECT_REPO:
        require_fields(
            raw,
            required={"action"},
            allowed={"action"},
        )
        return ExecutorRequest(action=action)

    if action == ACTION_CREATE_DOC_COMMIT:
        require_fields(
            raw,
            required={"action", "branch", "file_path", "content", "commit_message"},
            allowed={"action", "branch", "file_path", "content", "commit_message"},
        )
        return ExecutorRequest(
            action=action,
            branch=str(raw["branch"]),
            file_path=str(raw["file_path"]),
            content=str(raw["content"]),
            commit_message=str(raw["commit_message"]),
        )

    if action == ACTION_INSERT_BEFORE:
        require_fields(
            raw,
            required={"action", "branch", "file_path", "target", "content", "commit_message"},
            allowed={"action", "branch", "file_path", "target", "content", "commit_message"},
        )
        return ExecutorRequest(
            action=action,
            branch=str(raw["branch"]),
            file_path=str(raw["file_path"]),
            target=str(raw["target"]),
            content=str(raw["content"]),
            commit_message=str(raw["commit_message"]),
        )

    deny(f"unsupported action: {action}")


def validate_branch(branch: str | None) -> None:
    if branch is None:
        deny("missing branch")

    if not re.fullmatch(r"[A-Za-z0-9._/-]+", branch):
        deny("invalid branch name")

    if branch.startswith("-") or ".." in branch:
        deny("unsafe branch name")


def validate_docs_markdown_path(file_path: str | None) -> None:
    if file_path is None:
        deny("missing file_path")

    if not file_path.startswith(DOCS_PREFIX):
        deny("file_path must start with docs/")

    if not file_path.endswith(MARKDOWN_SUFFIX):
        deny("file_path must end with .md")

    if ".." in Path(file_path).parts:
        deny("file_path cannot contain ..")

    if Path(file_path).is_absolute():
        deny("file_path must be relative")


def validate_commit_message(commit_message: str | None) -> None:
    if commit_message is None:
        deny("missing commit_message")

    if not commit_message.startswith("docs(") and not commit_message.startswith("feat("):
        deny("commit message must start with docs( or feat(")


def validate_secret_free(*values: str | None) -> None:
    blob = "\n".join(value or "" for value in values).lower()
    for pattern in BLOCKED_SECRET_PATTERNS:
        if pattern.lower() in blob:
            deny(f"blocked secret-like pattern: {pattern}")


def validate_write_request(req: ExecutorRequest) -> None:
    validate_branch(req.branch)
    validate_docs_markdown_path(req.file_path)
    validate_commit_message(req.commit_message)

    if req.content is None or not req.content.strip():
        deny("content cannot be empty")

    validate_secret_free(
        req.branch,
        req.file_path,
        req.target,
        req.content,
        req.commit_message,
    )


def validate_insert_before_request(req: ExecutorRequest) -> None:
    validate_write_request(req)

    if req.target is None or not req.target:
        deny("target cannot be empty")


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


def insert_before(file_path: str, target_text: str, content: str) -> Path:
    target = REPO_ROOT / file_path

    if not target.exists():
        deny("file_path does not exist for insert_before")

    text = target.read_text(encoding="utf-8")

    target_count = text.count(target_text)
    if target_count == 0:
        deny("target not found")
    if target_count > 1:
        deny("target appears more than once")

    if content in text:
        deny("content already exists")

    target.write_text(text.replace(target_text, content.rstrip() + "\n\n" + target_text, 1), encoding="utf-8")
    return target


def commit_file(file_path: str, commit_message: str) -> str:
    run_git(["add", file_path])
    diff_stat = run_git(["diff", "--stat", "--cached"])
    if not diff_stat:
        deny("no staged changes")

    staged_files = run_git(["diff", "--cached", "--name-only"]).splitlines()
    if staged_files != [file_path]:
        deny(f"unexpected staged files: {staged_files}")

    run_git(["commit", "-m", commit_message])
    commit_sha = run_git(["rev-parse", "--short", "HEAD"])
    return commit_sha


def build_feature_ready(req: ExecutorRequest, commit_sha: str) -> dict[str, Any]:
    status = run_git(["status", "--short"])
    changed_file = req.file_path or ""

    return {
        "status": "FEATURE_READY_FOR_GITHUB",
        "mode": "LOCAL_ONLY",
        "action": req.action,
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


def docs_relevant_files(limit: int = 50) -> list[str]:
    docs_root = REPO_ROOT / "docs"
    if not docs_root.exists():
        return []

    results: list[str] = []
    for path in sorted(docs_root.rglob("*")):
        if not path.is_file():
            continue
        rel = path.relative_to(REPO_ROOT).as_posix()
        if any(pattern in rel for pattern in DOCS_RELEVANT_PATTERNS):
            results.append(rel)
        if len(results) >= limit:
            break
    return results


def inspect_repo() -> dict[str, Any]:
    before = run_git(["status", "--short"])
    branch = run_git(["branch", "--show-current"])
    last_commit = run_git(["log", "--oneline", "-1"])
    branches = run_git(["branch", "--format", "%(refname:short)"]).splitlines()
    after = run_git(["status", "--short"])

    return {
        "status": "INSPECT_REPO_RESULT",
        "mode": "READ_ONLY",
        "branch": branch,
        "git_status_short": before,
        "last_commit": last_commit,
        "docs_relevant_files": docs_relevant_files(),
        "local_branches": branches,
        "validations": {
            "read_only": before == after,
            "no_write_required": True,
            "no_commit_created": True,
        },
        "not_included": [
            "write",
            "branch creation",
            "commit",
            "push",
            "PR",
            "merge",
            "Gmail",
            "OAuth",
            "tokens",
            "systemd",
            "services",
            "core changes",
        ],
    }


def run_create_doc_commit(req: ExecutorRequest) -> dict[str, Any]:
    validate_write_request(req)
    ensure_clean_start()
    create_branch(req.branch or "")
    write_doc(req.file_path or "", req.content or "")
    commit_sha = commit_file(req.file_path or "", req.commit_message or "")
    return build_feature_ready(req, commit_sha)


def run_insert_before(req: ExecutorRequest) -> dict[str, Any]:
    validate_insert_before_request(req)
    ensure_clean_start()
    create_branch(req.branch or "")
    insert_before(req.file_path or "", req.target or "", req.content or "")
    commit_sha = commit_file(req.file_path or "", req.commit_message or "")
    return build_feature_ready(req, commit_sha)


def main() -> None:
    parser = argparse.ArgumentParser(description="Safe Executor V1 local docs")
    parser.add_argument("--input", required=True, help="Path to JSON request")
    args = parser.parse_args()

    req = load_request(Path(args.input))

    if req.action == ACTION_INSPECT_REPO:
        print(json.dumps(inspect_repo(), indent=2, ensure_ascii=False))
        return

    if req.action == ACTION_CREATE_DOC_COMMIT:
        print(json.dumps(run_create_doc_commit(req), indent=2, ensure_ascii=False))
        return

    if req.action == ACTION_INSERT_BEFORE:
        print(json.dumps(run_insert_before(req), indent=2, ensure_ascii=False))
        return

    deny(f"unsupported action: {req.action}")


if __name__ == "__main__":
    main()
