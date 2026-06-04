#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
GITHUB_CONTROLLED_PR_ASSISTANT_V1

Usage:
  tools/github_controlled_pr_assistant.sh prepare <branch-name> <docs/path/file.md> <commit-message>
  tools/github_controlled_pr_assistant.sh publish <branch-name>

V1 safety rules:
  - prepare is local only.
  - publish is blocked unless OK_GITHUB=1 is set.
  - only docs/**/*.md paths are allowed.
  - exactly one documentation file may be affected.
  - no merge.
  - no branch deletion.
  - no force push.
  - no git add .
  - no git add -A.
  - no token printing.
USAGE
}

die() {
  echo "BLOCK: $*" >&2
  exit 1
}

require_clean_repo() {
  if [ -n "$(git status --porcelain)" ]; then
    git status --short >&2
    die "repo is not clean"
  fi
}

require_on_main() {
  branch="$(git branch --show-current)"
  [ "$branch" = "main" ] || die "must start from main, current branch: $branch"
}

is_allowed_doc_path() {
  case "$1" in
    docs/*.md|docs/*/*.md|docs/*/*/*.md|docs/*/*/*/*.md)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

require_allowed_file() {
  file="$1"
  is_allowed_doc_path "$file" || die "only docs/**/*.md files are allowed: $file"
}

require_safe_branch_name() {
  branch="$1"

  case "$branch" in
    ""|main|master|origin/*|*..*|*/../*|../*|/*|*~*|*^*|*:*|*\\*|*' '*)
      die "unsafe branch name: $branch"
      ;;
  esac

  printf '%s' "$branch" | grep -Eq '^[A-Za-z0-9._/-]+$' || die "invalid branch name: $branch"
}

require_single_changed_file() {
  expected="$1"
  changed="$(git status --porcelain | awk '{print $2}')"

  [ -n "$changed" ] || die "no changed files detected"

  count="$(printf '%s\n' "$changed" | sed '/^$/d' | wc -l)"
  [ "$count" = "1" ] || {
    git status --short >&2
    die "expected exactly one changed file"
  }

  [ "$changed" = "$expected" ] || {
    git status --short >&2
    die "changed file does not match expected file: $expected"
  }
}

prepare() {
  branch="$1"
  file="$2"
  message="$3"

  require_safe_branch_name "$branch"
  require_allowed_file "$file"
  require_clean_repo
  require_on_main

  git switch -c "$branch"

  mkdir -p "$(dirname "$file")"

  if [ ! -f "$file" ]; then
    cat > "$file" <<EOF
# $(basename "$file" .md)

Draft document.

EOF
  fi

  echo "PREPARE_READY"
  echo "branch: $branch"
  echo "file: $file"
  echo
  echo "Edit the file now if needed, then run validation manually:"
  echo "  git diff -- $file"
  echo "  git status --short"
  echo
  echo "When reviewed, run:"
  echo "  tools/github_controlled_pr_assistant.sh commit \"$file\" \"$message\""
}

commit_doc() {
  file="$1"
  message="$2"

  require_allowed_file "$file"
  require_single_changed_file "$file"

  git diff -- "$file"
  git add -- "$file"
  git commit -m "$message"

  echo "FEATURE_READY_FOR_GITHUB"
  echo "branch: $(git branch --show-current)"
  echo "commit: $(git log --oneline -1)"
  echo "file: $file"
}

publish() {
  branch="$1"

  require_safe_branch_name "$branch"

  current="$(git branch --show-current)"
  [ "$current" = "$branch" ] || die "current branch must match publish branch"

  [ "${OK_GITHUB:-0}" = "1" ] || die "publish requires OK_GITHUB=1"

  [ -f "$HOME/.openclaw/neodaemon/secrets/github.env" ] || die "missing github.env"

  perms="$(stat -c '%a' "$HOME/.openclaw/neodaemon/secrets/github.env")"
  [ "$perms" = "600" ] || die "github.env must have chmod 600"

  # Load token without printing it.
  set -a
  # shellcheck disable=SC1090
  source "$HOME/.openclaw/neodaemon/secrets/github.env"
  set +a

  [ -n "${GITHUB_TOKEN:-}" ] || die "missing GITHUB_TOKEN"
  [ -n "${GITHUB_USER:-}" ] || die "missing GITHUB_USER"

  git push -u origin "$branch"

  echo "PUBLISH_READY"
  echo "branch pushed: $branch"
  echo "Create PR manually or with a future controlled API step."
  echo "No merge performed."
  echo "No branch deletion performed."

  unset GITHUB_TOKEN
  unset GITHUB_USER
}

cmd="${1:-}"

case "$cmd" in
  prepare)
    [ "$#" -eq 4 ] || die "prepare requires: <branch-name> <docs/path/file.md> <commit-message>"
    prepare "$2" "$3" "$4"
    ;;
  commit)
    [ "$#" -eq 3 ] || die "commit requires: <docs/path/file.md> <commit-message>"
    commit_doc "$2" "$3"
    ;;
  publish)
    [ "$#" -eq 2 ] || die "publish requires: <branch-name>"
    publish "$2"
    ;;
  -h|--help|help|"")
    usage
    ;;
  *)
    die "unknown command: $cmd"
    ;;
esac

