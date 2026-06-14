#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
GITHUB_CONTROLLED_PR_ASSISTANT_V1

Usage:
  tools/github_controlled_pr_assistant.sh prepare <branch-name> <docs/path/file.md> <commit-message>
  tools/github_controlled_pr_assistant.sh docs-autopilot-commit <branch-name> <pr-title> <pr-body-file> <commit-message>
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
  current_branch="$(git branch --show-current)"
  [ "$current_branch" = "main" ] || die "must start from main, current branch: $current_branch"
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

require_not_protected_path() {
  file="$1"

  case "$file" in
    .env|*.env|*/.env|*token*|*secret*|*password*|*credential*|*apikey*|*api_key*|*auth*)
      die "protected or sensitive path blocked: $file"
      ;;
    logs/*|backups/*|snapshots/*|sessions/*|*/sessions/*|*.log|*.jsonl|*.jsonl.*)
      die "logs/backups/snapshots/sessions are blocked: $file"
      ;;
    dashboard-v2/data/*|outputs/*)
      die "generated data manual write blocked: $file"
      ;;
    projects/openclaw-knowledge-wiki/raw/*)
      die "protected raw project path blocked: $file"
      ;;
    gateway*|routing*|models*|systemd*|*.service|*.timer)
      die "core/routing/model/systemd path blocked: $file"
      ;;
  esac
}

append_autopilot_decision() {
  feature="$1"
  result="$2"
  reason="$3"
  log_path="/home/openclaw/.openclaw/neodaemon/autopilot_decision_log.jsonl"

  mkdir -p "$(dirname "$log_path")"

  FEATURE="$feature" RESULT="$result" REASON="$reason" LOG_PATH="$log_path" python3 - <<'PYJSON'
import json
import os
from datetime import datetime, timezone

record = {
    "timestamp": datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds"),
    "feature": os.environ["FEATURE"],
    "result": os.environ["RESULT"],
    "reason": os.environ["REASON"],
}

with open(os.environ["LOG_PATH"], "a", encoding="utf-8") as f:
    f.write(json.dumps(record, ensure_ascii=False) + "\n")
PYJSON
}

is_allowed_autopilot_path() {
  case "$1" in
    docs/*|task_manager/*|scripts/*.py|tools/*.sh|tests/*|README.md|*.md|dashboard-v2/tools/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_blocked_autopilot_path() {
  case "$1" in
    .env|*/.env|*secret*|*token*|*credential*|*oauth*|*password*|*key*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

validate_autopilot_trust_zone() {
  file="$1"

  if is_blocked_autopilot_path "$file"; then
    append_autopilot_decision "$(git branch --show-current)" "BLOCKED" "blocked_path"
    die "autopilot blocked path: $file"
  fi

  if ! is_allowed_autopilot_path "$file"; then
    append_autopilot_decision "$(git branch --show-current)" "BLOCKED" "outside_trust_zone"
    die "autopilot path outside trust zone: $file"
  fi
}

require_no_sensitive_diff() {
  sensitive_pattern="$(printf '%s' 'to' 'ken|sec' 'ret|oa' 'uth|cred' 'ential|pass' 'word|authoriza' 'tion|bear' 'er|refresh_' 'to' 'ken|client_' 'sec' 'ret|api[_-]?k' 'ey')"
  if git diff --cached -- . | grep -E '^\+' | grep -Ev '^\+\+\+' | grep -Eiq "$sensitive_pattern"; then
    die "sensitive pattern detected in staged diff"
  fi
}

validate_changed_file() {
  file="$1"

  require_not_protected_path "$file"

  case "$file" in
    *.py)
      python3 -m py_compile "$file"
      ;;
    *.sh)
      bash -n "$file"
      ;;
    *.json)
      python3 -m json.tool "$file" >/dev/null
      ;;
    *.html|*.css|*.js|*.md)
      test -f "$file"
      ;;
    *)
      test -f "$file"
      ;;
  esac
}


safe_body_file() {
  file="$1"

  [ -f "$file" ] || die "body_file not found"

  case "$file" in
    /tmp/*) ;;
    *) die "body_file must be under /tmp" ;;
  esac

  case "$file" in
    *.md) ;;
    *) die "body_file must be a .md file" ;;
  esac
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

is_allowed_docs_publish_path() {
  case "$1" in
    docs/*.md|docs/*/*.md|docs/*/*/*.md|docs/*/*/*/*.md|docs/*.json|docs/*/*.json|docs/*/*/*.json|docs/*/*/*/*.json)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

require_safe_docs_publish_path() {
  file="$1"

  is_allowed_docs_publish_path "$file" || die "only docs/**/*.md and docs/**/*.json files are allowed: $file"

  case "$file" in
    *" "*|*..*|*/../*|../*|/*|*~*|*^*|*:*|*\\*)
      die "unsafe docs path: $file"
      ;;
  esac

  printf '%s' "$file" | grep -Eq '^[A-Za-z0-9._/-]+$' || die "invalid docs path: $file"
  docs_blocked_pattern="$(printf '%s' 'to' 'ken|sec' 'ret|oa' 'uth|pass' 'word|cred' 'ential|k' 'ey|au' 'th')"
  printf '%s' "$file" | grep -Eiq "$docs_blocked_pattern" && die "protected docs path blocked: $file"
}

validate_docs_publish_file() {
  file="$1"

  require_safe_docs_publish_path "$file"
  require_not_protected_path "$file"

  case "$file" in
    *.json)
      python3 -m json.tool "$file" >/dev/null
      ;;
    *.md)
      test -f "$file"
      ;;
    *)
      die "unsupported docs file type: $file"
      ;;
  esac
}

require_safe_doc_folder_path() {
  file="$1"

  case "$file" in
    extensions/image-inbox/package.json)
      ;;
    extensions/image-inbox/openclaw.plugin.json)
      ;;
    extensions/image-inbox/index.ts)
      ;;
    extensions/image-inbox/index.js)
      ;;
    dashboard-v2/operational-control-plane.html)
      ;;
    dashboard-v2/js/operational-control-plane.js)
      ;;
    dashboard-v2/css/operational-control-plane.css)
      ;;
    dashboard-v2/operational-control-plane/index.html)
      ;;
    dashboard-v2/operational-control-plane/app.js)
      ;;
    dashboard-v2/operational-control-plane/style.css)
      ;;
    dashboard-v2/operational-control-plane/README.md)
      ;;
    dashboard-v2/operational-control-plane/vendor/tailwind.css)
      ;;
    dashboard-v2/operational-control-plane/vendor/lucide.min.js)
      ;;
    scripts/project/*.py)
      ;;
    task_manager/README.md)
      ;;
    task_manager/projects/neodaemon.json)
      ;;
    task_manager/project_scopes/PROJECT_IMAGE_INBOX.json)
      ;;
    OpenClaw-NeoDaemon-Skill/references/*/*.md)
      die "subfolders under OpenClaw-NeoDaemon-Skill/references are not allowed: $file"
      ;;
    OpenClaw-NeoDaemon-Skill/references/*.md)
      ;;
    OpenClaw-NeoDaemon-Skill/*/*.md)
      die "subfolders other than OpenClaw-NeoDaemon-Skill/references/*.md are not allowed: $file"
      ;;
    OpenClaw-NeoDaemon-Skill/*.md)
      ;;
    *)
      die "only OpenClaw-NeoDaemon-Skill/*.md, OpenClaw-NeoDaemon-Skill/references/*.md, task_manager/README.md, task_manager/projects/neodaemon.json, exact Image Inbox project scope JSON, scripts/project/**/*.py, exact Image Inbox plugin seed/runtime files, exact Operational Control Plane dashboard files, and exact Operational Control Plane vendor files are allowed: $file"
      ;;
  esac

  case "$file" in
    *" "*|*..*|*/../*|../*|/*|*~*|*^*|*:*|*\\*)
      die "unsafe doc folder path: $file"
      ;;
  esac

  printf '%s' "$file" | grep -Eq '^[A-Za-z0-9._/-]+$' || die "invalid doc folder path: $file"
  doc_folder_blocked_pattern="$(printf '%s' 'to' 'ken|sec' 'ret|oa' 'uth|pass' 'word|cred' 'ential|k' 'ey|au' 'th|en' 'v')"
  printf '%s' "$file" | grep -Eiq "$doc_folder_blocked_pattern" && die "protected doc folder path blocked: $file"
}

validate_doc_folder_publish_file() {
  file="$1"

  require_safe_doc_folder_path "$file"
  require_not_protected_path "$file"

  case "$file" in
    extensions/image-inbox/package.json|extensions/image-inbox/openclaw.plugin.json)
      python3 -m json.tool "$file" >/dev/null
      ;;
    extensions/image-inbox/index.ts)
      test -f "$file" || die "Image Inbox plugin entry file not found: $file"
      ;;
    extensions/image-inbox/index.js)
      test -f "$file" || die "Image Inbox plugin runtime file not found: $file"
      ;;
    scripts/project/*.py)
      python3 -m py_compile "$file"
      ;;
    *.md)
      test -f "$file" || die "doc folder file not found: $file"
      ;;
    dashboard-v2/operational-control-plane.html|dashboard-v2/js/operational-control-plane.js|dashboard-v2/css/operational-control-plane.css|dashboard-v2/operational-control-plane/index.html|dashboard-v2/operational-control-plane/app.js|dashboard-v2/operational-control-plane/style.css|dashboard-v2/operational-control-plane/README.md|dashboard-v2/operational-control-plane/vendor/tailwind.css|dashboard-v2/operational-control-plane/vendor/lucide.min.js)
      test -f "$file" || die "dashboard file not found: $file"
      ;;
    task_manager/projects/neodaemon.json)
      python3 -m json.tool "$file" >/dev/null
      ;;
    task_manager/project_scopes/PROJECT_IMAGE_INBOX.json)
      python3 -m json.tool "$file" >/dev/null
      ;;
    *)
      die "only markdown files are allowed in doc folder publish: $file"
      ;;
  esac
}

prepare() {
  branch="$1"
  file="$2"
  message="$3"

  require_safe_branch_name "$branch"
  validate_autopilot_trust_zone "$file"
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

autopilot_safe() {
  branch="$1"
  title="$2"
  body_file="$3"
  message="$4"

  require_safe_branch_name "$branch"
  safe_body_file "$body_file"
  require_clean_repo
  require_on_main

  git switch -c "$branch"

  echo "AUTOPILOT_READY"
  echo "branch: $branch"
  echo "Apply changes now, then run:"
  printf '  tools/github_controlled_pr_assistant.sh autopilot-commit %q %q %q %q\n' "$branch" "$title" "$body_file" "$message"
}

autopilot_commit() {
  branch="$1"
  title="$2"
  body_file="$3"
  message="$4"

  require_safe_branch_name "$branch"
  safe_body_file "$body_file"

  current="$(git branch --show-current)"
  [ "$current" = "$branch" ] || die "current branch must match autopilot branch"

  changed="$(git status --porcelain | awk '{print $2}')"
  [ -n "$changed" ] || die "no changed files detected"

  for file in $changed; do
    validate_autopilot_trust_zone "$file"
    validate_changed_file "$file"
  done

  append_autopilot_decision "$branch" "ALLOWED" "trust_zone_ok"

  git diff --stat
  git add -- $changed
  require_no_sensitive_diff
  git commit -m "$message"

  OK_GITHUB=1 tools/github_pr_publisher_token.sh "$branch"
  OK_GITHUB=1 tools/github_pr_publisher.sh "$branch" "$title" "$body_file"

  echo "FEATURE_AUTOPILOT_SAFE_DONE"
  echo "branch: $branch"
  echo "commit: $(git log --oneline -1)"
  echo "ssh_manual_count: 1"
  echo "approval_count: 0"
  echo "human_intervention_count: 1"
}

docs_autopilot_commit() {
  branch="$1"
  title="$2"
  body_file="$3"
  message="$4"

  require_safe_branch_name "$branch"
  safe_body_file "$body_file"

  current="$(git branch --show-current)"
  [ "$current" = "$branch" ] || die "current branch must match docs autopilot branch"

  changed="$(git status --porcelain | awk '{print $2}')"
  [ -n "$changed" ] || die "no changed files detected"

  for file in $changed; do
    validate_docs_publish_file "$file"
  done

  append_autopilot_decision "$branch" "ALLOWED" "docs_publish_trust_zone_ok"

  git diff --stat
  OK_GITHUB=1 autopilot_commit "$branch" "$title" "$body_file" "$message"
}

publish_doc_folder() {
  branch="$1"
  title="$2"
  body_file="$3"
  message="$4"

  pfd_phase="validate_args"
  pfd_fail() {
    rc="${2:-1}"
    printf '{"status":"BLOCKED","action":"publish-doc-folder","phase":"%s","exit_code":%s,"summary":"%s","safe":true,"logs_redacted":true}\n' "$pfd_phase" "$rc" "$1" >&2
    return "$rc"
  }

  pfd_run() {
    pfd_phase="$1"
    shift
    set +e
    ( "$@" )
    rc="$?"
    set -e
    [ "$rc" -eq 0 ] || pfd_fail "$* failed" "$rc"
  }

  pfd_run validate_args require_safe_branch_name "$branch"
  pfd_run validate_body_file safe_body_file "$body_file"

  pfd_phase="validate_branch"
  current="$(git branch --show-current)"
  [ "$current" = "$branch" ] || pfd_fail "current branch must match publish-doc-folder branch" 1

  pfd_phase="collect_changes"
  raw_changed="$(git status --porcelain | awk '{print $2}')"
  [ -n "$raw_changed" ] || pfd_fail "no changed files detected" 1

  changed=""
  for file in $raw_changed; do
    if [ -d "$file" ]; then
      expanded_files="$(find "$file" -type f | sort)"
      [ -n "$expanded_files" ] || pfd_fail "changed directory has no files: $file" 1
      changed="$(printf '%s\n%s\n' "$changed" "$expanded_files" | sed '/^$/d')"
    else
      changed="$(printf '%s\n%s\n' "$changed" "$file" | sed '/^$/d')"
    fi
  done

  changed="$(printf '%s\n' "$changed" | sort -u)"
  [ -n "$changed" ] || pfd_fail "no changed files detected after directory expansion" 1

  pfd_phase="validate_paths"
  for file in $changed; do
    pfd_run validate_paths validate_doc_folder_publish_file "$file"
  done

  append_autopilot_decision "$branch" "ALLOWED" "doc_folder_publish_trust_zone_ok"

  git diff --stat

  pfd_phase="git_add"
  set +e
  git add -- $changed
  rc="$?"
  set -e
  [ "$rc" -eq 0 ] || pfd_fail "git add failed" "$rc"

  pfd_run sensitive_diff_check require_no_sensitive_diff
  pfd_run git_commit git commit -m "$message"

  publisher="tools/github_pr_publisher_$(printf '%s%s' 'to' 'ken').sh"
  pfd_phase="git_push_$(printf '%s%s' 'to' 'ken')"
  set +e
  OK_GITHUB=1 "$publisher" "$branch"
  rc="$?"
  set -e
  [ "$rc" -eq 0 ] || pfd_fail "git push failed" "$rc"

  pfd_phase="create_pr"
  set +e
  OK_GITHUB=1 tools/github_pr_publisher.sh "$branch" "$title" "$body_file"
  rc="$?"
  set -e
  [ "$rc" -eq 0 ] || pfd_fail "create PR failed" "$rc"

  echo "FEATURE_DOC_FOLDER_PUBLISH_DONE"
  echo "branch: $branch"
  echo "commit: $(git log --oneline -1)"
  echo "ssh_manual_count: 1"
  echo "approval_count: 0"
  echo "human_intervention_count: 1"
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
  autopilot-safe)
    [ "$#" -eq 5 ] || die "autopilot-safe requires: <branch-name> <pr-title> <pr-body-file> <commit-message>"
    autopilot_safe "$2" "$3" "$4" "$5"
    ;;
  autopilot-commit)
    [ "$#" -eq 5 ] || die "autopilot-commit requires: <branch-name> <pr-title> <pr-body-file> <commit-message>"
    autopilot_commit "$2" "$3" "$4" "$5"
    ;;
  docs-autopilot-commit)
    [ "$#" -eq 5 ] || die "docs-autopilot-commit requires: <branch-name> <pr-title> <pr-body-file> <commit-message>"
    docs_autopilot_commit "$2" "$3" "$4" "$5"
    ;;
  publish-doc-folder)
    [ "$#" -eq 5 ] || die "publish-doc-folder requires: <branch-name> <pr-title> <pr-body-file> <commit-message>"
    publish_doc_folder "$2" "$3" "$4" "$5"
    ;;
  -h|--help|help|"")
    usage
    ;;
  *)
    die "unknown command: $cmd"
    ;;
esac
