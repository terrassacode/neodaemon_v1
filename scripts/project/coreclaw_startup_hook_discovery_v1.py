#!/usr/bin/env python3
"""Read-only CORECLAW startup hook discovery.

Scans non-sensitive repository files for references that may indicate an
existing startup/context assembly point for future CORECLAW integration.

This script is read-only: it does not modify files, start services, call the
network, or inspect secrets.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Dict, Iterable, List, Tuple

REPO_ROOT = Path(__file__).resolve().parents[2]
MAX_FILE_BYTES = 256 * 1024
MAX_MATCHES_PER_FILE = 20

EXCLUDED_DIR_NAMES = {
    ".git",
    "node_modules",
    "dist",
    "vendor",
    "logs",
    "backups",
    "backup",
    "sessions",
    ".sessions",
    "__pycache__",
    ".pytest_cache",
    ".mypy_cache",
    ".ruff_cache",
}

EXCLUDED_FILE_NAMES = {
    ".env",
    ".env.local",
    ".env.production",
    ".env.development",
}

SENSITIVE_NAME_PARTS = (
    ".env",
    "secret",
    "secrets",
    "token",
    "credential",
    "credentials",
    "private_key",
    "id_rsa",
    "id_ed25519",
)

ALLOWED_SUFFIXES = {
    ".md",
    ".py",
    ".js",
    ".ts",
    ".json",
    ".yaml",
    ".yml",
    ".sh",
    ".txt",
}

SEARCH_TERMS = (
    "startup",
    "start up",
    "context assembly",
    "context_assembly",
    "assemble context",
    "agent context",
    "agent_context",
    "session context",
    "session_context",
    "bootstrap",
    "loader",
    "load context",
    "startup context",
    "coreclaw",
)

STARTUP_HOOK_HINTS = (
    "startup",
    "bootstrap",
    "assemble",
    "assembly",
    "agent context",
    "agent_context",
    "session context",
    "session_context",
    "load_context",
    "loader",
)

DOCUMENTATION_SUFFIXES = {".md", ".txt"}
VALIDATION_HINTS = (
    "audit",
    "validate",
    "validation",
    "healthcheck",
    "proof",
    "scanner",
    "check",
)


def is_sensitive_path(path: Path) -> bool:
    rel_parts = path.relative_to(REPO_ROOT).parts
    for part in rel_parts[:-1]:
        if part in EXCLUDED_DIR_NAMES:
            return True
    name = path.name.lower()
    if name in EXCLUDED_FILE_NAMES:
        return True
    return any(part in name for part in SENSITIVE_NAME_PARTS)


def iter_candidate_files(root: Path) -> Iterable[Path]:
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        if is_sensitive_path(path):
            continue
        if path.suffix.lower() not in ALLOWED_SUFFIXES:
            continue
        try:
            if path.stat().st_size > MAX_FILE_BYTES:
                continue
        except OSError:
            continue
        yield path


def classify(path: Path, line: str) -> str:
    rel = path.relative_to(REPO_ROOT).as_posix().lower()
    text = line.lower()

    if path.suffix.lower() in DOCUMENTATION_SUFFIXES or rel.startswith("docs/") or "/references/" in rel:
        return "documentation_only"

    if any(hint in rel for hint in VALIDATION_HINTS) or any(hint in text for hint in VALIDATION_HINTS):
        return "validation_tool"

    if any(hint in text for hint in STARTUP_HOOK_HINTS):
        if any(token in rel for token in ("runtime", "gateway", "agent", "session", "startup", "bootstrap", "context")):
            return "possible_startup_hook"
        if path.suffix.lower() in {".py", ".js", ".ts"}:
            return "possible_startup_hook"

    return "unknown"


def scan_file(path: Path) -> List[Dict[str, object]]:
    try:
        content = path.read_text(encoding="utf-8", errors="ignore")
    except OSError as exc:
        return [
            {
                "path": path.relative_to(REPO_ROOT).as_posix(),
                "line": None,
                "term": None,
                "classification": "unknown",
                "excerpt": f"unreadable: {exc.__class__.__name__}",
            }
        ]

    matches: List[Dict[str, object]] = []
    for number, line in enumerate(content.splitlines(), start=1):
        lowered = line.lower()
        hit_terms = [term for term in SEARCH_TERMS if term in lowered]
        if not hit_terms:
            continue
        excerpt = line.strip()
        if len(excerpt) > 180:
            excerpt = excerpt[:177] + "..."
        matches.append(
            {
                "path": path.relative_to(REPO_ROOT).as_posix(),
                "line": number,
                "term": hit_terms[0],
                "classification": classify(path, line),
                "excerpt": excerpt,
            }
        )
        if len(matches) >= MAX_MATCHES_PER_FILE:
            break
    return matches


def build_report() -> Dict[str, object]:
    findings: List[Dict[str, object]] = []
    scanned_files = 0
    skipped_sensitive_policy = sorted(EXCLUDED_DIR_NAMES | EXCLUDED_FILE_NAMES)

    for path in iter_candidate_files(REPO_ROOT):
        scanned_files += 1
        findings.extend(scan_file(path))

    counts = {
        "possible_startup_hook": 0,
        "documentation_only": 0,
        "validation_tool": 0,
        "unknown": 0,
    }
    for finding in findings:
        classification = str(finding.get("classification", "unknown"))
        counts[classification] = counts.get(classification, 0) + 1

    return {
        "status": "OK",
        "script": "coreclaw_startup_hook_discovery_v1",
        "read_only": True,
        "parameters_supported": 0,
        "repo_root": str(REPO_ROOT),
        "scope": "non-sensitive repository text files only",
        "excluded": skipped_sensitive_policy,
        "search_terms": list(SEARCH_TERMS),
        "classification_counts": counts,
        "findings": findings,
        "limits": [
            "Does not prove runtime loading.",
            "Does not inspect secrets, .env files, sessions, logs, vendor, dist, node_modules, or .git.",
            "Does not modify runtime, gateway, executor, systemd, MEMORY.md, or knowledge/.",
            "Findings are candidates for human review, not implementation approval.",
        ],
        "summary": {
            "files_scanned": scanned_files,
            "findings_total": len(findings),
        },
    }


def main() -> int:
    if len(sys.argv) != 1:
        print(
            json.dumps(
                {
                    "status": "ERROR",
                    "error": "This read-only discovery accepts zero parameters.",
                    "parameters_supported": 0,
                },
                ensure_ascii=False,
                sort_keys=True,
            )
        )
        return 2

    print(json.dumps(build_report(), ensure_ascii=False, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
