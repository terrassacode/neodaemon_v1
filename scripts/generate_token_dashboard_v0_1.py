#!/usr/bin/env python3
import json
from pathlib import Path
from datetime import datetime, timezone, timedelta

SOURCE_DIR = Path.home() / ".openclaw" / "agents" / "main" / "sessions"
OUTPUT_FILE = Path("dashboard-v2/data/token_dashboard_v0_1.json")

EXCLUDE = ("checkpoint", "backup", "bak", "archive")
WINDOW_MINUTES = 60
WINDOW_24H = 24

def is_excluded(path: Path) -> bool:
    text = str(path).lower()
    return any(x in text for x in EXCLUDE)

def get_usage(entry):
    usage = entry.get("usage") or entry.get("message", {}).get("usage")
    return usage if isinstance(usage, dict) else None

def get_timestamp(entry):
    raw = entry.get("timestamp")
    if not raw:
        return None
    try:
        return datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except Exception:
        return None

def empty_bucket():
    return {
        "input_tokens": 0,
        "output_tokens": 0,
        "total_tokens": 0,
        "usage_entries": 0
    }

def add_usage(bucket, usage):
    inp = usage.get("input") or usage.get("inputTokens") or 0
    out = usage.get("output") or usage.get("outputTokens") or 0
    raw_total = usage.get("totalTokens") or usage.get("total_tokens") or 0

    if not isinstance(inp, (int, float)):
        inp = 0
    if not isinstance(out, (int, float)):
        out = 0
    if not isinstance(raw_total, (int, float)):
        raw_total = 0

    # For the simple dashboard, total_tokens means visible input + output.
    # Some providers include cacheRead/cacheWrite inside totalTokens, which would
    # make total_tokens inconsistent with the displayed input/output counters.
    total = int(inp) + int(out)
    if total == 0:
        total = int(raw_total)

    bucket["input_tokens"] += int(inp)
    bucket["output_tokens"] += int(out)
    bucket["total_tokens"] += int(total)
    bucket["usage_entries"] += 1

def main():
    now = datetime.now(timezone.utc)
    window_60m_start = now - timedelta(minutes=WINDOW_MINUTES)
    window_24h_start = now - timedelta(hours=WINDOW_24H)
    previous_24h_start = now - timedelta(hours=WINDOW_24H * 2)

    total = empty_bucket()
    last_24h = empty_bucket()
    previous_24h = empty_bucket()
    last_60m = empty_bucket()
    latest = None

    files_read = 0
    files_skipped_old = 0
    files_error = 0
    lines_seen = 0

    if SOURCE_DIR.exists():
        for path in SOURCE_DIR.glob("*.jsonl"):
            if is_excluded(path):
                continue

            try:
                mtime = datetime.fromtimestamp(path.stat().st_mtime, timezone.utc)
            except Exception:
                files_error += 1
                continue

            if mtime < previous_24h_start:
                files_skipped_old += 1
                continue

            files_read += 1

            try:
                with path.open("r", encoding="utf-8", errors="ignore") as f:
                    for line in f:
                        if not line.strip():
                            continue

                        lines_seen += 1

                        try:
                            entry = json.loads(line)
                        except Exception:
                            continue

                        usage = get_usage(entry)
                        if not usage:
                            continue

                        ts = get_timestamp(entry)

                        add_usage(total, usage)

                        if ts and ts >= window_24h_start:
                            add_usage(last_24h, usage)

                        if ts and ts >= window_60m_start:
                            add_usage(last_60m, usage)

                        if ts:
                            if latest is None or ts > latest["timestamp"]:
                                b = empty_bucket()
                                add_usage(b, usage)
                                latest = {
                                    "timestamp": ts,
                                    "input_tokens": b["input_tokens"],
                                    "output_tokens": b["output_tokens"],
                                    "total_tokens": b["total_tokens"]
                                }
            except Exception:
                files_error += 1
                continue

    current_tokens = last_24h["total_tokens"]
    previous_tokens = previous_24h["total_tokens"]

    if current_tokens == 0 and previous_tokens == 0:
        rolling_status = "sin datos suficientes"
        delta_tokens = 0
        delta_percent = None
    elif previous_tokens == 0:
        rolling_status = "sin base anterior"
        delta_tokens = current_tokens
        delta_percent = None
    else:
        delta_tokens = current_tokens - previous_tokens
        delta_percent = round((delta_tokens / previous_tokens) * 100, 1)
        rolling_status = "ok"

    data = {
        "updated_at": now.isoformat(),
        "total": total,
        "last_24h": last_24h,
        "rolling_24h_comparison": {
            "current_24h_tokens": current_tokens,
            "previous_24h_tokens": previous_tokens,
            "delta_tokens": delta_tokens,
            "delta_percent": delta_percent,
            "status": rolling_status,
            "window_current": {
                "from": window_24h_start.isoformat(),
                "to": now.isoformat()
            },
            "window_previous": {
                "from": previous_24h_start.isoformat(),
                "to": window_24h_start.isoformat()
            }
        },
        "last_iteration": {
            "timestamp": latest["timestamp"].isoformat() if latest else None,
            "input_tokens": latest["input_tokens"] if latest else 0,
            "output_tokens": latest["output_tokens"] if latest else 0,
            "total_tokens": latest["total_tokens"] if latest else 0
        },
        "tokens_per_minute": int(last_60m["total_tokens"] / WINDOW_MINUTES),
        "quality": {
            "source": str(SOURCE_DIR),
            "files_read": files_read,
            "files_skipped_old": files_skipped_old,
            "files_error": files_error,
            "lines_seen": lines_seen,
            "window_minutes": WINDOW_MINUTES,
            "window_24h": WINDOW_24H
        }
    }

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_FILE.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")

if __name__ == "__main__":
    main()
