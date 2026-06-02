#!/usr/bin/env bash
set -euo pipefail

REPO="/openclaw/workspace/git_clean/neodaemon_v1"

echo "GITHUB_LOCAL_EXECUTOR_MVP_V0_1"
echo

if [ "$#" -ne 0 ]; then
  echo "result: BLOCKED"
  echo "reason: arguments_not_allowed"
  exit 2
fi

if [ ! -d "$REPO" ]; then
  echo "result: BLOCKED"
  echo "reason: repo_not_found"
  exit 2
fi

if ! git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "result: BLOCKED"
  echo "reason: not_a_git_repo"
  exit 2
fi

echo "repo:"
echo "$REPO"
echo

echo "current_branch:"
git -C "$REPO" branch --show-current
echo

STATUS="$(git -C "$REPO" status --short)"

echo "working_tree:"
if [ -z "$STATUS" ]; then
  echo "clean"
else
  echo "dirty"
fi
echo

echo "status_short:"
if [ -z "$STATUS" ]; then
  echo "(clean)"
else
  printf '%s\n' "$STATUS"
fi
echo

echo "recent_commits:"
git -C "$REPO" log --oneline -5
echo

echo "local_branches:"
git -C "$REPO" branch --list
echo

echo "remote_branches:"
git -C "$REPO" branch -r
echo

echo "result: OK"
