#!/usr/bin/env python3
"""Controlled read-only runtime proof for Image Inbox health route."""

from __future__ import annotations

import json
import sys
import urllib.error
import urllib.request

ACTION = "image_inbox_health_runtime_proof_v1"
SERVICE = "openclaw-gateway"
ENDPOINT = "/plugin/image-inbox/health"
TIMEOUT_SECONDS = 3
BASE_URL = "http://127.0.0.1:3000"
EXPECTED = {"status": "PASS", "plugin": "image-inbox"}


def emit(payload: dict, rc: int = 0) -> None:
    payload.setdefault("action", ACTION)
    payload.setdefault("service", SERVICE)
    payload.setdefault("endpoint", ENDPOINT)
    payload.setdefault("restart_performed", False)
    payload.setdefault("safe", True)
    payload.setdefault("logs_redacted", True)
    print(json.dumps(payload, ensure_ascii=False, separators=(",", ":")))
    raise SystemExit(rc)


def blocked(summary: str, **extra: object) -> None:
    payload = {"status": "RUNTIME_BLOCKED_WITH_REASON", "summary": summary}
    payload.update(extra)
    emit(payload, 1)


def main(argv: list[str]) -> None:
    if argv:
        blocked("script accepts no parameters", received_args=argv)

    url = BASE_URL + ENDPOINT
    req = urllib.request.Request(
        url,
        method="GET",
        headers={"accept": "application/json"},
    )

    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT_SECONDS) as response:
            http_status = int(response.status)
            content_type = response.headers.get("content-type", "")
            raw = response.read(4096)
    except urllib.error.HTTPError as exc:
        body = exc.read(512).decode("utf-8", errors="replace") if exc.fp else ""
        blocked("http error", http_status=exc.code, error=str(exc), body=body[:512])
    except urllib.error.URLError as exc:
        blocked("request failed", error=str(exc.reason))
    except TimeoutError:
        blocked("request timeout", timeout_seconds=TIMEOUT_SECONDS)
    except Exception as exc:  # defensive: keep structured failure only
        blocked("request exception", error=type(exc).__name__)

    if http_status != 200:
        blocked("unexpected http status", http_status=http_status)

    try:
        payload = json.loads(raw.decode("utf-8"))
    except Exception as exc:
        blocked(
            "invalid json response",
            http_status=http_status,
            content_type=content_type,
            error=type(exc).__name__,
        )

    if not isinstance(payload, dict):
        blocked("json response is not object", http_status=http_status, json_type=type(payload).__name__)

    if payload.get("status") != EXPECTED["status"] or payload.get("plugin") != EXPECTED["plugin"]:
        blocked("unexpected json response", http_status=http_status, json=payload)

    emit(
        {
            "status": "RUNTIME_PASS",
            "http_status": http_status,
            "json": EXPECTED,
        },
        0,
    )


if __name__ == "__main__":
    main(sys.argv[1:])
