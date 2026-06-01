#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="/openclaw/workspace/git_clean/neodaemon_repo"
OUTPUT_FILE="$REPO_DIR/dashboard-v2/data/token_dashboard_v0_1.json"

cd "$REPO_DIR"

python3 scripts/generate_token_dashboard_v0_1.py

if [[ ! -f "$OUTPUT_FILE" ]]; then
  echo "ERROR: token dashboard JSON was not generated: $OUTPUT_FILE" >&2
  exit 1
fi

echo "Token dashboard updated: $OUTPUT_FILE"
