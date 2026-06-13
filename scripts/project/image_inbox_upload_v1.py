#!/usr/bin/env python3
"""Controlled Image Inbox upload action v1.

Copies exactly one pre-existing local image from the fixed incoming directory into
/openclaw/workspace/main/uploads/images and records minimal metadata.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import sys
import tempfile
import uuid
from datetime import datetime, timezone
from pathlib import Path

ACTION = "image_inbox_upload_v1"
INCOMING_ROOT = Path("/openclaw/workspace/main/uploads/incoming").resolve()
DEST_ROOT = Path("/openclaw/workspace/main/uploads/images").resolve()
METADATA_PATH = DEST_ROOT / "metadata.json"
ALLOWED_EXTENSIONS = {"jpg", "jpeg", "png", "webp"}
MAX_BYTES = 5 * 1024 * 1024
ALLOWED_STATUSES = {"pending", "viewed", "processed"}


def emit(payload: dict, rc: int = 0) -> None:
    payload.setdefault("action", ACTION)
    payload.setdefault("safe", True)
    payload.setdefault("logs_redacted", True)
    print(json.dumps(payload, ensure_ascii=False, separators=(",", ":")))
    raise SystemExit(rc)


def blocked(summary: str, **extra: object) -> None:
    emit({"status": "BLOCKED", "summary": summary, **extra}, 1)


def fail(summary: str, **extra: object) -> None:
    emit({"status": "FAIL", "summary": summary, **extra}, 1)


def resolve_inside(path_text: str, root: Path) -> Path:
    if not path_text or "\x00" in path_text:
        blocked("invalid source path")
    source = Path(path_text)
    if not source.is_absolute():
        blocked("source path must be absolute")
    resolved = source.resolve(strict=False)
    try:
        resolved.relative_to(root)
    except ValueError:
        blocked("source path outside fixed incoming directory")
    if not resolved.is_file():
        blocked("source file not found")
    return resolved


def sanitized_display_name(name: str) -> str:
    base = Path(name).name
    base = re.sub(r"[^A-Za-z0-9._-]+", "_", base).strip("._-")
    if not base:
        base = "image"
    return base[:120]


def extension_for(path: Path) -> str:
    suffix = path.suffix.lower().lstrip(".")
    if suffix not in ALLOWED_EXTENSIONS:
        blocked("extension not allowed", extension=suffix)
    return suffix


def load_metadata() -> list[dict]:
    if not METADATA_PATH.exists():
        return []
    try:
        data = json.loads(METADATA_PATH.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        fail("metadata corrupt")
    if not isinstance(data, list):
        fail("metadata must be a list")
    for item in data:
        if not isinstance(item, dict):
            fail("metadata item invalid")
        if item.get("status") not in ALLOWED_STATUSES:
            fail("metadata status invalid")
    return data


def atomic_write_metadata(records: list[dict]) -> None:
    DEST_ROOT.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(prefix="metadata.", suffix=".tmp", dir=str(DEST_ROOT))
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            json.dump(records, fh, ensure_ascii=False, indent=2)
            fh.write("\n")
        os.replace(tmp_name, METADATA_PATH)
    except Exception:
        try:
            os.unlink(tmp_name)
        except OSError:
            pass
        raise


def upload(source_text: str, uploaded_by: str) -> None:
    source = resolve_inside(source_text, INCOMING_ROOT)
    ext = extension_for(source)
    size = source.stat().st_size
    if size > MAX_BYTES:
        blocked("file too large", max_bytes=MAX_BYTES, size_bytes=size)

    safe_name = sanitized_display_name(source.name)
    if not safe_name.lower().endswith(f".{ext}"):
        safe_name = f"{safe_name}.{ext}"

    image_id = uuid.uuid4().hex
    stored_name = f"{image_id}_{safe_name}"
    dest = (DEST_ROOT / stored_name).resolve(strict=False)
    try:
        dest.relative_to(DEST_ROOT)
    except ValueError:
        blocked("destination path escaped fixed directory")
    if dest.exists():
        blocked("destination already exists")

    records = load_metadata()
    if any(item.get("filename") == stored_name or item.get("id") == image_id for item in records):
        blocked("metadata collision")

    DEST_ROOT.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, dest)

    record = {
        "id": image_id,
        "filename": stored_name,
        "uploaded_at": datetime.now(timezone.utc).isoformat(),
        "uploaded_by": uploaded_by or "Albert",
        "status": "pending",
    }
    records.append(record)
    try:
        atomic_write_metadata(records)
    except Exception as exc:
        fail("metadata write failed", error=type(exc).__name__)

    emit({
        "status": "PASS",
        "image": record,
        "size_bytes": size,
        "destination_dir": str(DEST_ROOT),
        "metadata": str(METADATA_PATH),
    })


def main() -> None:
    parser = argparse.ArgumentParser(description="Controlled Image Inbox upload action v1")
    parser.add_argument("--source", required=True, help="absolute file path under fixed incoming directory")
    parser.add_argument("--uploaded-by", default="Albert")
    args = parser.parse_args()
    upload(args.source, args.uploaded_by)


if __name__ == "__main__":
    main()
