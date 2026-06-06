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
  github_post_merge_close
  autopilot_safe
  autopilot_commit

Examples:
  tools/neodaemon_local_executor_v1.sh '{"action":"github_status"}'

  tools/neodaemon_local_executor_v1.sh '{"action":"github_publish_token","branch":"docs/example"}'

  tools/neodaemon_local_executor_v1.sh '{"action":"github_create_pr","branch":"docs/example","title":"docs: example","body_file":"/tmp/pr.md"}'
  tools/neodaemon_local_executor_v1.sh '{"action":"github_post_merge_close","mode":"check","branch":"docs/example","pr_number":"123"}'
  tools/neodaemon_local_executor_v1.sh '{"action":"github_post_merge_close","mode":"list_candidates"}'
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


github_post_merge_close() {
  mode="$1"
  branch="$2"
  pr_number="$3"
  confirmation="$4"

  [ "$mode" = "check" ] || [ "$mode" = "cleanup" ] || [ "$mode" = "list_candidates" ] || die "invalid mode"

  if [ "$mode" = "list_candidates" ]; then
    python3 - <<'PYJSON'
import json
import subprocess

def git_lines(*args):
    result = subprocess.run(["git", *args], check=False, text=True, capture_output=True)
    if result.returncode != 0:
        return []
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]

def git_ok(*args):
    return subprocess.run(["git", *args], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0

current = git_lines("branch", "--show-current")
current_branch = current[0] if current else ""
working_tree_clean = not git_lines("status", "--short")
main_current = current_branch == "main"

main_counts = git_lines("rev-list", "--left-right", "--count", "main...origin/main")
main_updated = bool(main_counts and main_counts[0].split() == ["0", "0"])

local_branches = [
    b for b in git_lines("branch", "--format=%(refname:short)")
    if b not in {"main", "master"}
]

remote_branches = []
for branch in git_lines("branch", "-r", "--format=%(refname:short)"):
    if branch == "origin/HEAD":
        continue
    if branch.startswith("origin/"):
        branch = branch[len("origin/"):]
    if branch not in {"main", "master"}:
        remote_branches.append(branch)

candidates = []
for branch in sorted(set(local_branches) | set(remote_branches)):
    local_exists = branch in local_branches
    remote_exists = branch in remote_branches
    local_merged = local_exists and git_ok("branch", "--merged", "main", "--list", branch)
    cleanup_ready = bool(working_tree_clean and main_current and main_updated and local_merged)
    candidates.append({
        "branch": branch,
        "local_branch_exists": local_exists,
        "remote_branch_exists": remote_exists,
        "local_branch_merged": local_merged,
        "cleanup_ready": cleanup_ready,
        "recommended_next_action": "cleanup allowed only with exact OK CLEANUP confirmation" if cleanup_ready else "manual review required",
    })

print(json.dumps({
    "status": "OK",
    "action": "github_post_merge_close",
    "mode": "list_candidates",
    "current_branch": current_branch,
    "working_tree_clean": working_tree_clean,
    "main_current": main_current,
    "main_updated": main_updated,
    "local_branches": local_branches,
    "remote_branches": remote_branches,
    "candidates": candidates,
    "safe": True,
    "logs_redacted": True,
}, separators=(",", ":")))
PYJSON
    return 0
  fi

  safe_branch "$branch"
  [ -n "$pr_number" ] || die "pr_number required"
  printf '%s' "$pr_number" | grep -Eq '^[0-9]+$' || die "invalid pr_number"

  current_branch="$(git branch --show-current)"
  working_tree="$(git status --short)"

  working_tree_clean=false
  main_current=false
  main_updated=false
  local_branch_exists=false
  remote_branch_exists=false
  local_branch_merged=false
  cleanup_ready=false
  recommended_next_action="manual review required"

  [ -z "$working_tree" ] && working_tree_clean=true
  [ "$current_branch" = "main" ] && main_current=true

  main_counts="$(git rev-list --left-right --count main...origin/main 2>/dev/null || true)"
  [ "$(printf '%s' "$main_counts" | awk '{print $1 " " $2}')" = "0 0" ] && main_updated=true

  git branch --list "$branch" | grep -q . && local_branch_exists=true
  git branch -r --list "origin/$branch" | grep -q . && remote_branch_exists=true
  git branch --merged main --list "$branch" | grep -q . && local_branch_merged=true

  if [ "$working_tree_clean" = "true" ] && [ "$main_current" = "true" ] && [ "$main_updated" = "true" ] && [ "$local_branch_merged" = "true" ]; then
    cleanup_ready=true
    recommended_next_action="cleanup allowed only with exact OK CLEANUP confirmation"
  fi

  if [ "$mode" = "cleanup" ]; then
    expected_confirmation="OK CLEANUP PR #$pr_number branch $branch"

    [ "$confirmation" = "$expected_confirmation" ] || die "missing exact OK CLEANUP confirmation"
    [ "$cleanup_ready" = "true" ] || die "cleanup checks failed"

    if [ "$local_branch_exists" = "true" ]; then
      git branch -d "$branch" >/dev/null
    fi

    if [ "$remote_branch_exists" = "true" ]; then
      git push origin --delete "$branch" >/dev/null
    fi

    final_status="$(git status --short)"
    final_local_exists=false
    final_remote_exists=false
    git branch --list "$branch" | grep -q . && final_local_exists=true
    git branch -r --list "origin/$branch" | grep -q . && final_remote_exists=true

    [ -z "$final_status" ] || die "working tree dirty after cleanup"

    printf '{"status":"OK","action":"github_post_merge_close","mode":"cleanup","branch":"%s","pr_number":%s,"current_branch":"%s","local_branch_exists":%s,"remote_branch_exists":%s,"final_local_branch_exists":%s,"final_remote_branch_exists":%s,"safe":true,"logs_redacted":true}\n' \
      "$branch" "$pr_number" "$current_branch" "$local_branch_exists" "$remote_branch_exists" "$final_local_exists" "$final_remote_exists"
    return 0
  fi

  printf '{"status":"OK","action":"github_post_merge_close","mode":"check","branch":"%s","pr_number":%s,"current_branch":"%s","working_tree_clean":%s,"main_current":%s,"main_updated":%s,"local_branch_exists":%s,"remote_branch_exists":%s,"local_branch_merged":%s,"cleanup_ready":%s,"recommended_next_action":"%s","safe":true,"logs_redacted":true}\n' \
    "$branch" "$pr_number" "$current_branch" "$working_tree_clean" "$main_current" "$main_updated" "$local_branch_exists" "$remote_branch_exists" "$local_branch_merged" "$cleanup_ready" "$recommended_next_action"
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
  mode="$(printf '%s' "$request" | json_get mode || true)"
  pr_number="$(printf '%s' "$request" | json_get pr_number || true)"
  confirmation="$(printf '%s' "$request" | json_get confirmation || true)"

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
    github_post_merge_close)
      [ -z "$title$body_file" ] || die "github_post_merge_close does not accept title/body_file"
      github_post_merge_close "$mode" "$branch" "$pr_number" "$confirmation"
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
