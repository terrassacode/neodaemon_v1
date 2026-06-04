#!/usr/bin/env bash
set -euo pipefail

die() {
  printf '{"status":"BLOCKED","summary":"%s","safe":true,"logs_redacted":true}\n' "$*" >&2
  exit 1
}

json_get() {
  key="$1"
  python3 -c '
import json, sys
key = sys.argv[1]
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(2)
value = data.get(key, "")
if value is None:
    value = ""
print(value)
' "$key"
}

usage() {
  cat <<'USAGE'
NEODAEMON_LOCAL_EXECUTOR_V1

Usage:
  tools/neodaemon_local_executor_v1.sh '<json-request>'

Allowed actions:
  github_status
  github_publish_token
  github_create_pr

Examples:
  tools/neodaemon_local_executor_v1.sh '{"action":"github_status"}'

  tools/neodaemon_local_executor_v1.sh '{"action":"github_publish_token","branch":"docs/example"}'

  tools/neodaemon_local_executor_v1.sh '{"action":"github_create_pr","branch":"docs/example","title":"docs: example","body_file":"/tmp/pr.md"}'
USAGE
}

safe_branch() {
  branch="$1"

  case "$branch" in
    ""|main|master|origin/*|*..*|*/../*|../*|/*|*~*|*^*|*:*|*\\*|*" "*)
      die "unsafe branch"
      ;;
  esac

  printf '%s' "$branch" | grep -Eq '^[A-Za-z0-9._/-]+$' || die "invalid branch"
}

safe_body_file() {
  file="$1"

  case "$file" in
    /tmp/*.md)
      [ -f "$file" ] || die "body_file not found"
      ;;
    *)
      die "body_file must be /tmp/*.md"
      ;;
  esac
}

github_status() {
  branch="$(git branch --show-current)"
  status="$(git status --short | sed ':a;N;$!ba;s/\n/ | /g')"

  printf '{"status":"OK","action":"github_status","branch":"%s","working_tree":"%s","safe":true,"logs_redacted":true}\n' "$branch" "$status"
}

github_publish_token() {
  branch="$1"
  safe_branch "$branch"

  [ "${OK_GITHUB:-0}" = "1" ] || die "github_publish_token requires OK_GITHUB=1"

  tools/github_pr_publisher_token.sh "$branch"
}

github_create_pr() {
  branch="$1"
  title="$2"
  body_file="$3"

  safe_branch "$branch"
  [ -n "$title" ] || die "title required"
  safe_body_file "$body_file"

  [ "${OK_GITHUB:-0}" = "1" ] || die "github_create_pr requires OK_GITHUB=1"

  tools/github_pr_publisher.sh "$branch" "$title" "$body_file"
}

main() {
  [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] && {
    usage
    exit 0
  }

  [ "$#" -eq 1 ] || die "one json request required"

  request="$1"

  action="$(printf '%s' "$request" | json_get action || true)"
  branch="$(printf '%s' "$request" | json_get branch || true)"
  title="$(printf '%s' "$request" | json_get title || true)"
  body_file="$(printf '%s' "$request" | json_get body_file || true)"

  case "$action" in
    github_status)
      github_status
      ;;
    github_publish_token)
      github_publish_token "$branch"
      ;;
    github_create_pr)
      github_create_pr "$branch" "$title" "$body_file"
      ;;
    *)
      die "unknown action"
      ;;
  esac
}

main "$@"
