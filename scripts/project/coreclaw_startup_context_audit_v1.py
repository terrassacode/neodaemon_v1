#!/usr/bin/env python3
"""Read-only audit for CORECLAW startup-context evidence."""

from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

ACTION = "coreclaw_startup_context_audit_v1"
CORE_FILES = ["AGENTS.md", "SOUL.md", "USER.md", "TOOLS.md", "MEMORY.md"]
PROJECT_FILE = Path("task_manager/projects/neodaemon.json")
SKILL_FILE = Path("OpenClaw-NeoDaemon-Skill/SKILL.md")
SCAN_ROOTS = [Path("scripts"), Path("tools"), Path("OpenClaw-NeoDaemon-Skill"), Path("task_manager")]
BLOCKED_PARTS = {".git", "node_modules", ".venv", "venv", "__pycache__"}
BLOCKED_FILENAMES = {".env"}
MAX_FILE_BYTES = 120_000


def emit(payload: dict, rc: int = 0) -> None:
    payload.setdefault("action", ACTION)
    payload.setdefault("safe", True)
    payload.setdefault("logs_redacted", True)
    print(json.dumps(payload, ensure_ascii=False, separators=(",", ":")))
    raise SystemExit(rc)


def blocked(summary: str, **extra: object) -> None:
    payload = {"status": "AUDIT_BLOCKED_WITH_REASON", "summary": summary}
    payload.update(extra)
    emit(payload, 1)


def safe_text(path: Path) -> str:
    if any(part in BLOCKED_PARTS for part in path.parts) or path.name in BLOCKED_FILENAMES:
        return ""
    try:
        if path.stat().st_size > MAX_FILE_BYTES:
            return ""
        return path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def referenced_files(text: str) -> list[str]:
    return [name for name in CORE_FILES if name in text]


def scan_references() -> dict[str, list[dict[str, object]]]:
    results = {name: [] for name in CORE_FILES}
    read_terms = ("read", "open", "cat", "memory_get", "Path(", "read_text")
    for root in SCAN_ROOTS:
        if not root.exists():
            continue
        for path in root.rglob("*"):
            if not path.is_file():
                continue
            if any(part in BLOCKED_PARTS for part in path.parts) or path.name in BLOCKED_FILENAMES:
                continue
            if path.suffix.lower() not in {".py", ".sh", ".md", ".json", ".ts", ".js"}:
                continue
            text = safe_text(path)
            if not text:
                continue
            for name in CORE_FILES:
                if name not in text:
                    continue
                has_read_signal = any(term in text for term in read_terms)
                results[name].append({
                    "path": str(path),
                    "read_signal": bool(has_read_signal),
                })
    return results


def runtime_evidence_from_refs(script_tool_refs: dict[str, list[dict[str, object]]]) -> dict[str, object]:
    evidence = []
    runtime_terms = re.compile(r"startup|context|bootstrap|load|memory_get|read_text|open\(", re.IGNORECASE)
    for name, refs in script_tool_refs.items():
        for ref in refs:
            path = str(ref.get("path", ""))
            if not (path.startswith("scripts/") or path.startswith("tools/")):
                continue
            text = safe_text(Path(path))
            if name in text and runtime_terms.search(text):
                evidence.append({"file": name, "path": path})
    return {
        "runtime_loading_verified": bool(evidence),
        "evidence": evidence,
    }


def main(argv: list[str]) -> None:
    if argv:
        blocked("script accepts no parameters", received_args=argv)

    core_status = {}
    for name in CORE_FILES:
        path = Path(name)
        core_status[name] = {
            "exists": path.is_file(),
            "size_bytes": path.stat().st_size if path.is_file() else None,
        }

    project_text = safe_text(PROJECT_FILE)
    skill_text = safe_text(SKILL_FILE)
    project_references = referenced_files(project_text)
    skill_references = referenced_files(skill_text)
    script_tool_references = scan_references()
    runtime = runtime_evidence_from_refs(script_tool_references)

    core_files_exist = all(item["exists"] for item in core_status.values())
    runtime_loading_verified = bool(runtime["runtime_loading_verified"])

    emit({
        "status": "AUDIT_PASS",
        "core_files_exist": core_files_exist,
        "core_files": core_status,
        "runtime_loading_verified": runtime_loading_verified,
        "project_file": str(PROJECT_FILE),
        "project_references": project_references,
        "skill_file": str(SKILL_FILE),
        "skill_references": skill_references,
        "script_tool_references": script_tool_references,
        "runtime_evidence": runtime["evidence"],
        "missing_runtime_bridge": not runtime_loading_verified,
        "recommendation": "Create explicit CORECLAW startup context loader or project reference bridge" if not runtime_loading_verified else "Runtime loading evidence found; review evidence before changing behavior",
    })


if __name__ == "__main__":
    main(sys.argv[1:])
