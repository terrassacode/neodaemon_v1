#!/usr/bin/env bash
set -euo pipefail

die() {
  echo "BLOCK: $*" >&2
  exit 1
}

usage() {
  cat <<'USAGE'
NEODAEMON_AUTOPILOT_APPLY_FILE_V1

Usage:
  OK_GITHUB=1 tools/neodaemon_autopilot_apply_file_v1.sh <branch> <title> <body_file> <commit_message> <target_file> <content_file>

Purpose:
  Apply one allowed file change, validate, commit, push and create PR.

Safety:
  - one target file only
  - no merge
  - no branch deletion
  - no force push
  - no secrets
  - no protected paths
USAGE
}

[ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] && {
  usage
  exit 0
}

[ "$#" -eq 6 ] || die "requires: <branch> <title> <body_file> <commit_message> <target_file> <content_file>"

branch="$1"
title="$2"
body_file="$3"
message="$4"
target_file="$5"
content_file="$6"

case "$branch" in
  ""|main|master|origin/*|*..*|*/../*|../*|/*|*~*|*^*|*:*|*\\*|*" "*)
    die "unsafe branch"
    ;;
esac

printf '%s' "$branch" | grep -Eq '^[A-Za-z0-9._/-]+$' || die "invalid branch"

[ -f "$body_file" ] || die "body_file not found"
case "$body_file" in /tmp/*.md) ;; *) die "body_file must be /tmp/*.md" ;; esac

[ -f "$content_file" ] || die "content_file not found"
case "$content_file" in /tmp/*) ;; *) die "content_file must be under /tmp" ;; esac

case "$target_file" in
  .env|*.env|*/.env|*token*|*secret*|*password*|*credential*|*apikey*|*api_key*|*auth*)
    die "protected or sensitive path blocked"
    ;;
  logs/*|backups/*|snapshots/*|sessions/*|*/sessions/*|*.log|*.jsonl|*.jsonl.*)
    die "logs/backups/snapshots/sessions are blocked"
    ;;
  dashboard-v2/data/*|outputs/*)
    die "generated data manual write blocked"
    ;;
  projects/openclaw-knowledge-wiki/raw/*)
    die "protected raw project path blocked"
    ;;
  gateway*|routing*|models*|systemd*|*.service|*.timer)
    die "core/routing/model/systemd path blocked"
    ;;
esac

[ -n "$title" ] || die "title required"
[ -n "$message" ] || die "commit_message required"

[ "$(git branch --show-current)" = "main" ] || die "must start from main"

if [ -n "$(git status --porcelain)" ]; then
  git status --short >&2
  die "repo is not clean"
fi

git switch -c "$branch"

mkdir -p "$(dirname "$target_file")"
cp "$content_file" "$target_file"

case "$target_file" in
  *.py) python3 -m py_compile "$target_file" ;;
  *.sh) bash -n "$target_file" ;;
  *.json) python3 -m json.tool "$target_file" >/dev/null ;;
  *) test -f "$target_file" ;;
esac

git diff --stat
git add -- "$target_file"

if git diff --cached -- . | grep -Eiq 'ghp_|github_pat_|secret=|password=|credential=|authorization:|bearer [A-Za-z0-9]|refresh_token=|client_secret=|api[_-]?key='; then
  die "sensitive pattern detected in staged diff"
fi

git commit -m "$message"

OK_GITHUB=1 tools/github_pr_publisher_token.sh "$branch"
OK_GITHUB=1 tools/github_pr_publisher.sh "$branch" "$title" "$body_file"

echo "FEATURE_AUTOPILOT_APPLY_FILE_DONE"
echo "branch: $branch"
echo "target_file: $target_file"
echo "commit: $(git log --oneline -1)"
echo "ssh_manual_count: 1"
echo "approval_count: 0"
echo "human_intervention_count: 1"
