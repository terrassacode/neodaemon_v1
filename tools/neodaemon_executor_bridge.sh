#!/usr/bin/env bash
set -euo pipefail

die() {
  printf '{"status":"BLOCKED","summary":"%s","safe":true,"logs_redacted":true}\n' "$*" >&2
  exit 1
}

[ "$#" -eq 1 ] || die "one json request required"

REQUEST_JSON="$1"
REPO_DIR="/openclaw/workspace/git_clean/neodaemon_v1"
EXECUTOR="tools/neodaemon_local_executor_v1.sh"

[ -n "$REQUEST_JSON" ] || die "empty request"
[ -d "$REPO_DIR" ] || die "repo dir not found"

cd "$REPO_DIR"

[ -x "$EXECUTOR" ] || die "local executor not executable"

"$EXECUTOR" "$REQUEST_JSON"
