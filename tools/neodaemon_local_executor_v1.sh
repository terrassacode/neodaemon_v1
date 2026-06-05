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
  autopilot_safe
  autopilot_commit

Examples:
  tools/neodaemon_local_executor_v1.sh '{"action":"github_status"}'

  tools/neodaemon_local_executor_v1.sh '{"action":"github_publish_token","branch":"docs/example"}'

  tools/neodaemon_local_executor_v1.sh '{"action":"github_create_pr","branch":"docs/example","title":"docs: example","body_file":"/tmp/pr.md"}'
  tools/neodaemon_local_executor_v1.sh '{"action":"autopilot_safe","branch":"feature/example","title":"feat: example","body_file":"/tmp/pr.md","message":"feat: example"}'
  tools/neodaemon_local_executor_v1.sh '{"action":"autopilot_commit","branch":"feature/example","title":"feat: example","body_file":"/tmp/pr.md","message":"feat: example"}'
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

github_sync_main() {
  before_status="$(git status --porcelain)"
  if [ -n "$before_status" ]; then
    printf '{"status":"BLOCKED","action":"github_sync_main","summary":"working tree not clean","safe":true,"logs_redacted":true}\n'
    return 1
  fi

  git switch main >/dev/null
  git pull --ff-only origin main >/dev/null

  branch="$(git branch --show-current)"
  after_status="$(git status --porcelain)"

  if [ "$branch" != "main" ]; then
    printf '{"status":"ERROR","action":"github_sync_main","summary":"final branch is not main","safe":true,"logs_redacted":true}\n'
    return 1
  fi

  if [ -n "$after_status" ]; then
    printf '{"status":"ERROR","action":"github_sync_main","summary":"working tree dirty after sync","branch":"%s","safe":true,"logs_redacted":true}\n' "$branch"
    return 1
  fi

  printf '{"status":"OK","action":"github_sync_main","branch":"%s","working_tree":"","safe":true,"logs_redacted":true}\n' "$branch"
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

autopilot_safe() {
  branch="$1"
  title="$2"
  body_file="$3"
  message="$4"

  safe_branch "$branch"
  [ -n "$title" ] || die "title required"
  safe_body_file "$body_file"
  [ -n "$message" ] || die "message required"

  tools/github_controlled_pr_assistant.sh autopilot-safe "$branch" "$title" "$body_file" "$message"
}

autopilot_commit() {
  branch="$1"
  title="$2"
  body_file="$3"
  message="$4"

  safe_branch "$branch"
  [ -n "$title" ] || die "title required"
  safe_body_file "$body_file"
  [ -n "$message" ] || die "message required"

  [ "${OK_GITHUB:-0}" = "1" ] || die "autopilot_commit requires OK_GITHUB=1"

  OK_GITHUB=1 tools/github_controlled_pr_assistant.sh autopilot-commit "$branch" "$title" "$body_file" "$message"
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
    github_sync_main)
      [ -z "$branch$title$body_file" ] || die "github_sync_main does not accept parameters"
      github_sync_main
      ;;
    github_publish_token)
      github_publish_token "$branch"
      ;;
    github_create_pr)
      github_create_pr "$branch" "$title" "$body_file"
      ;;
    autopilot_safe)
      autopilot_safe "$branch" "$title" "$body_file" "$message"
      ;;
    autopilot_commit)
      autopilot_commit "$branch" "$title" "$body_file" "$message"
      ;;
    *)
      die "unknown action"
      ;;
  esac
}

main "$@"
