#!/usr/bin/env bash
set -euo pipefail

REPO="/openclaw/workspace/git_clean/neodaemon_v1"
MODE="${1:-}"

BRANCH="docs/local-executor-feature-test"
FILE="docs/LOCAL_EXECUTOR_FEATURE_TEST.md"
COMMIT_MESSAGE="docs: add local executor feature test"

block() {
  echo "result: BLOCKED"
  echo "reason: $1"
  exit 2
}

echo "GITHUB_LOCAL_EXECUTOR"
echo

if [ "$MODE" != "run-local-feature-test" ]; then
  block "invalid_mode"
fi

if [ ! -d "$REPO" ]; then
  block "repo_not_found"
fi

if ! git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  block "not_a_git_repo"
fi

CURRENT_BRANCH="$(git -C "$REPO" branch --show-current)"
if [ "$CURRENT_BRANCH" != "main" ]; then
  block "not_on_main"
fi

STATUS="$(git -C "$REPO" status --short)"
if [ -n "$STATUS" ]; then
  echo "$STATUS"
  block "working_tree_dirty"
fi

if [ ! -d "$REPO/docs" ]; then
  block "docs_dir_missing"
fi

if git -C "$REPO" branch --list "$BRANCH" | grep -q .; then
  block "branch_already_exists"
fi

if [ -e "$REPO/$FILE" ]; then
  block "file_already_exists"
fi

git -C "$REPO" checkout -b "$BRANCH"

cat > "$REPO/$FILE" <<'DOC'
# LOCAL_EXECUTOR_FEATURE_TEST

Prueba de creación local completa de feature por GitHub Local Executor.
DOC

STATUS_AFTER_WRITE="$(git -C "$REPO" status --short)"
EXPECTED_STATUS="?? $FILE"

if [ "$STATUS_AFTER_WRITE" != "$EXPECTED_STATUS" ]; then
  echo "$STATUS_AFTER_WRITE"
  block "unexpected_status_after_write"
fi

git -C "$REPO" diff --stat
git -C "$REPO" diff -- "$FILE"

git -C "$REPO" add "$FILE"
git -C "$REPO" commit -m "$COMMIT_MESSAGE"

FINAL_STATUS="$(git -C "$REPO" status --short)"
if [ -n "$FINAL_STATUS" ]; then
  echo "$FINAL_STATUS"
  block "working_tree_not_clean_after_commit"
fi

LAST_COMMIT="$(git -C "$REPO" log --oneline -1)"
echo
echo "last_commit:"
echo "$LAST_COMMIT"

if ! echo "$LAST_COMMIT" | grep -F "$COMMIT_MESSAGE" >/dev/null; then
  block "commit_message_mismatch"
fi

echo
echo "current_branch:"
git -C "$REPO" branch --show-current

echo
echo "result: OK"
