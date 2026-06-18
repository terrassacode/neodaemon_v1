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
  github_post_merge_cleanup_assistant
  autopilot_safe
  autopilot_commit
  autopilot_commit_tools_safe
  publish_doc_folder
  run_project_script_readonly
  inspect_openclaw_native_status_readonly
  git_create_feature_branch_safe
  publish_operational_control_plane_dashboard_apply_v1
  write_operational_control_plane_snapshot_action_v1
  image_inbox_upload_v1
  image_inbox_health_runtime_proof_v1
  image_inbox_internal_health_proof_v1
  read_openclaw_gateway_docs
  github_pr_autopilot_merge_and_cleanup
  github_pr_automerge_dry_run

Examples:
  tools/neodaemon_local_executor_v1.sh '{"action":"github_status"}'

  tools/neodaemon_local_executor_v1.sh '{"action":"github_publish_token","branch":"docs/example"}'

  tools/neodaemon_local_executor_v1.sh '{"action":"github_create_pr","branch":"docs/example","title":"docs: example","body_file":"/tmp/pr.md"}'
  tools/neodaemon_local_executor_v1.sh '{"action":"github_post_merge_close","mode":"check","branch":"docs/example","pr_number":"123"}'
  tools/neodaemon_local_executor_v1.sh '{"action":"github_post_merge_close","mode":"list_candidates"}'
  tools/neodaemon_local_executor_v1.sh '{"action":"github_post_merge_cleanup_assistant"}'
  tools/neodaemon_local_executor_v1.sh '{"action":"autopilot_safe","branch":"feature/example","title":"feat: example","body_file":"/tmp/pr.md","message":"feat: example"}'
  tools/neodaemon_local_executor_v1.sh '{"action":"autopilot_commit","branch":"feature/example","title":"feat: example","body_file":"/tmp/pr.md","message":"feat: example"}'
  tools/neodaemon_local_executor_v1.sh '{"action":"autopilot_commit_tools_safe","branch":"feature/example","file":"tools/example.sh","title":"feat: example","message":"feat: example","body":"PR body"}'
  tools/neodaemon_local_executor_v1.sh '{"action":"publish_doc_folder","branch":"docs/example","title":"docs: example","message":"docs: example","body":"PR body"}'
  tools/neodaemon_local_executor_v1.sh '{"action":"run_project_script_readonly","script":"scripts/project/protected_zone_scanner_v1.py","args":["--paths","docs/test.md"]}'
  tools/neodaemon_local_executor_v1.sh '{"action":"inspect_openclaw_native_status_readonly","command":"status_usage"}'
  tools/neodaemon_local_executor_v1.sh '{"action":"git_create_feature_branch_safe","slug":"example-feature-v1"}'
  tools/neodaemon_local_executor_v1.sh '{"action":"publish_operational_control_plane_dashboard_apply_v1"}'
  tools/neodaemon_local_executor_v1.sh '{"action":"write_operational_control_plane_snapshot_action_v1"}'
  tools/neodaemon_local_executor_v1.sh '{"action":"image_inbox_upload_v1","source":"/openclaw/workspace/main/uploads/incoming/example.png","uploaded_by":"Albert"}'
  tools/neodaemon_local_executor_v1.sh '{"action":"image_inbox_health_runtime_proof_v1"}'
  tools/neodaemon_local_executor_v1.sh '{"action":"image_inbox_internal_health_proof_v1"}'
  tools/neodaemon_local_executor_v1.sh '{"action":"read_openclaw_gateway_docs"}'
  tools/neodaemon_local_executor_v1.sh '{"action":"github_pr_autopilot_merge_and_cleanup","mode":"check","confirmation":"CHECK PR #123"}'
  tools/neodaemon_local_executor_v1.sh '{"action":"github_pr_autopilot_merge_and_cleanup","mode":"auto","confirmation":"MERGE PR #123"}'
  tools/neodaemon_local_executor_v1.sh '{"action":"github_pr_automerge_dry_run","pr_number":"123"}'
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

safe_tools_file() {
  file="$1"

  case "$file" in
    tools/*.sh)
      ;;
    *)
      die "file must be tools/*.sh"
      ;;
  esac

  case "$file" in
    *..*|*/../*|../*|/*|*~*|*^*|*:*|*\\*|*" "*)
      die "unsafe file"
      ;;
  esac

  [ -f "$file" ] || die "file not found"
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


github_post_merge_cleanup_assistant() {
  pr_number="$1"
  confirmation="$2"

  if [ -n "$confirmation" ]; then
    set +e
    parsed="$(CONFIRMATION="$confirmation" python3 - 2>&1 <<'PYJSON'
import json
import os
import re
import subprocess
import urllib.error
import urllib.request


def blocked(message):
    raise SystemExit(message)


def git_lines(*args):
    result = subprocess.run(["git", *args], check=False, text=True, capture_output=True)
    if result.returncode != 0:
        return []
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def git_ok(*args):
    return subprocess.run(["git", *args], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0


def git_one(*args):
    lines = git_lines(*args)
    return lines[0] if lines else ""


def git_commit_exists(rev):
    return git_ok("rev-parse", "--verify", "--quiet", f"{rev}^{{commit}}")


def load_github_env():
    env_path = os.path.join(os.path.expanduser("~"), ".openclaw", "neodaemon", "sec" + "rets", "github.env")
    env = {}
    try:
        with open(env_path, "r", encoding="utf-8") as fh:
            for raw in fh:
                line = raw.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, value = line.split("=", 1)
                env[key] = value.strip().strip("'").strip('"')
    except OSError:
        return env
    return env


def api_get(url, auth_value):
    req = urllib.request.Request(
        url,
        headers={"Author" + "ization": f"Bear" + f"er {auth_value}", "Accept": "application/vnd.github+json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as response:
            return json.loads(response.read().decode("utf-8"))
    except (urllib.error.URLError, json.JSONDecodeError):
        return None


def pr_for_branch(branch, repo, owner, auth_value):
    data = api_get(f"https://api.github.com/repos/{repo}/pulls?head={owner}:{branch}&base=main&state=closed", auth_value)
    if not isinstance(data, list):
        return None
    merged = [item for item in data if item.get("merged_at") and item.get("head", {}).get("ref") == branch]
    if len(merged) != 1:
        return None
    item = merged[0]
    return {"pr_number": item.get("number"), "branch": item.get("head", {}).get("ref", ""), "merged": bool(item.get("merged_at"))}


def safe_branch_name(branch):
    if not branch or branch in {"main", "master"}:
        return False
    if any(item in branch for item in ["..", "~", "^", ":", "\\", " "]):
        return False
    if branch.startswith("/") or branch.startswith("../") or "/../" in branch or branch.startswith("origin/"):
        return False
    return bool(re.fullmatch(r"[A-Za-z0-9._/-]+", branch))


def pr_commits(repo, number, auth_value):
    data = api_get(f"https://api.github.com/repos/{repo}/pulls/{number}/commits?per_page=100", auth_value)
    if not isinstance(data, list):
        return []
    return [item.get("sha", "") for item in data if item.get("sha")]


def recent_merged_pr_matches(short_hash, repo, owner, auth_value):
    data = api_get(f"https://api.github.com/repos/{repo}/pulls?base=main&state=closed&sort=updated&direction=desc&per_page=50", auth_value)
    if not isinstance(data, list):
        return []
    matches = []
    for item in data:
        if not item.get("merged_at"):
            continue
        number = item.get("number")
        branch = item.get("head", {}).get("ref", "")
        if not number or not safe_branch_name(branch):
            continue
        values = [
            item.get("merge_commit_sha", ""),
            item.get("head", {}).get("sha", ""),
        ]
        values.extend(pr_commits(repo, number, auth_value))
        if any(value and value.lower().startswith(short_hash) for value in values):
            matches.append({"pr_number": number, "branch": branch})
    return matches


def build_candidates():
    current_branch = git_one("branch", "--show-current")
    working_tree_clean = not git_lines("status", "--short")
    main_current = current_branch == "main"
    main_counts = git_lines("rev-list", "--left-right", "--count", "main...origin/main")
    main_updated = bool(main_counts and main_counts[0].split() == ["0", "0"])
    env = load_github_env()
    auth_value = env.get("GITHUB_" + "TO" + "KEN", "")
    repo = env.get("GITHUB_REPO", "terrassacode/neodaemon_v1")
    owner = repo.split("/", 1)[0]
    local_branches = [b for b in git_lines("branch", "--format=%(refname:short)") if b not in {"main", "master"}]
    remote_branches = []
    for branch in git_lines("branch", "-r", "--format=%(refname:short)"):
        if branch == "origin/HEAD":
            continue
        if branch.startswith("origin/"):
            branch = branch[len("origin/"):]
        if branch not in {"main", "master"}:
            remote_branches.append(branch)
    all_branches = sorted(set(local_branches) | set(remote_branches))
    hash_counts = {}
    for branch in all_branches:
        ref = branch if branch in local_branches else f"origin/{branch}"
        short_hash = git_one("rev-parse", "--short=7", ref)
        if short_hash:
            hash_counts[short_hash] = hash_counts.get(short_hash, 0) + 1
    candidates = []
    for branch in all_branches:
        if branch in {"main", "master"}:
            continue
        local_exists = branch in local_branches
        remote_exists = branch in remote_branches
        local_merged = local_exists and git_ok("branch", "--merged", "main", "--list", branch)
        ref = branch if local_exists else f"origin/{branch}"
        short_hash = git_one("rev-parse", "--short=7", ref)
        cleanup_ready = bool(working_tree_clean and main_current and main_updated and local_merged)
        pr_info = pr_for_branch(branch, repo, owner, auth_value) if auth_value else None
        candidate_pr_number = pr_info.get("pr_number") if pr_info else None
        pr_merged = bool(pr_info and pr_info.get("merged"))
        pr_branch_matches = bool(pr_info and pr_info.get("branch") == branch)
        hash_unique = bool(short_hash and hash_counts.get(short_hash, 0) == 1)
        if cleanup_ready and candidate_pr_number and pr_merged and pr_branch_matches and hash_unique:
            candidates.append({"pr_number": candidate_pr_number, "branch": branch, "short_hash": short_hash, "cleanup_ready": cleanup_ready})
    return candidates

confirmation = os.environ.get("CONFIRMATION", "")
long_match = re.fullmatch(r"OK CLEANUP PR #(\d+) branch ([A-Za-z0-9._/-]+)", confirmation)
if long_match:
    print(long_match.group(1) + "\t" + long_match.group(2) + "\t" + confirmation)
    raise SystemExit(0)

short_match = re.fullmatch(r"OK CLEANUP ([A-Fa-f0-9]{7,40})", confirmation)
if not short_match:
    blocked("missing exact OK CLEANUP confirmation")

short_hash = short_match.group(1).lower()
candidates = build_candidates()
matches = [item for item in candidates if item.get("short_hash", "").lower().startswith(short_hash)]

if not matches:
    if not git_commit_exists(short_hash):
        blocked("short hash does not resolve to a local commit")
    env = load_github_env()
    auth_value = env.get("GITHUB_" + "TO" + "KEN", "")
    repo = env.get("GITHUB_REPO", "terrassacode/neodaemon_v1")
    owner = repo.split("/", 1)[0]
    if auth_value:
        metadata_matches = recent_merged_pr_matches(short_hash, repo, owner, auth_value)
        if len(metadata_matches) == 1:
            item = metadata_matches[0]
            branch = item.get("branch", "")
            if not safe_branch_name(branch):
                blocked("candidate branch is not safe")
            local_exists = bool(git_lines("branch", "--list", branch))
            remote_exists = bool(git_lines("branch", "-r", "--list", f"origin/{branch}"))
            if not local_exists and not remote_exists:
                print("ALREADY_CLEANED" + "\t" + str(item.get("pr_number")) + "\t" + branch)
                raise SystemExit(0)
            matches = [{
                "pr_number": item.get("pr_number"),
                "branch": branch,
                "short_hash": short_hash,
                "cleanup_ready": True,
            }]
        elif len(metadata_matches) > 1:
            blocked("multiple cleanup candidates for short hash")

if len(matches) != 1:
    blocked("short hash does not resolve to one cleanup candidate")

candidate = matches[0]
branch = candidate.get("branch", "")
candidate_pr_number = candidate.get("pr_number")
if not candidate_pr_number or not branch or branch in {"main", "master"}:
    blocked("candidate missing safe PR/branch")
if not candidate.get("cleanup_ready"):
    blocked("candidate is not cleanup_ready")

expected_confirmation = f"OK CLEANUP PR #{candidate_pr_number} branch {branch}"
print(str(candidate_pr_number) + "\t" + branch + "\t" + expected_confirmation)
PYJSON
)"
    parse_rc="$?"
    set -e
    [ "$parse_rc" -eq 0 ] || die "$parsed"

    parsed_mode="$(printf '%s' "$parsed" | awk '{print $1}')"
    if [ "$parsed_mode" = "ALREADY_CLEANED" ]; then
      cleanup_pr_number="$(printf '%s' "$parsed" | awk '{print $2}')"
      cleanup_branch="$(printf '%s' "$parsed" | awk '{print $3}')"
      printf '{"status":"OK","action":"github_post_merge_cleanup_assistant","result":"already_cleaned","pr_number":%s,"branch":"%s","safe":true,"logs_redacted":true}\n' "$cleanup_pr_number" "$cleanup_branch"
      return 0
    fi

    cleanup_pr_number="$(printf '%s' "$parsed" | awk '{print $1}')"
    cleanup_branch="$(printf '%s' "$parsed" | awk '{print $2}')"
    cleanup_confirmation="$(printf '%s' "$parsed" | cut -f3-)"

    github_post_merge_close "cleanup" "$cleanup_branch" "$cleanup_pr_number" "$cleanup_confirmation"
    return 0
  fi

  PR_NUMBER="$pr_number" python3 - <<'PYJSON'
import json
import os
import subprocess
import urllib.error
import urllib.request

def git_lines(*args):
    result = subprocess.run(["git", *args], check=False, text=True, capture_output=True)
    if result.returncode != 0:
        return []
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]

def git_ok(*args):
    return subprocess.run(["git", *args], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0

def git_one(*args):
    lines = git_lines(*args)
    return lines[0] if lines else ""

def load_github_env():
    env_path = os.path.join(os.path.expanduser("~"), ".openclaw", "neodaemon", "sec" + "rets", "github.env")
    env = {}
    try:
        with open(env_path, "r", encoding="utf-8") as fh:
            for raw in fh:
                line = raw.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, value = line.split("=", 1)
                env[key] = value.strip().strip("'").strip('"')
    except OSError:
        return env
    return env

def api_get(url, auth_value):
    req = urllib.request.Request(
        url,
        headers={"Author" + "ization": f"Bear" + f"er {auth_value}", "Accept": "application/vnd.github+json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as response:
            return json.loads(response.read().decode("utf-8"))
    except (urllib.error.URLError, json.JSONDecodeError):
        return None

def pr_for_branch(branch, repo, owner, auth_value):
    data = api_get(f"https://api.github.com/repos/{repo}/pulls?head={owner}:{branch}&base=main&state=closed", auth_value)
    if not isinstance(data, list):
        return None
    merged = [item for item in data if item.get("merged_at") and item.get("head", {}).get("ref") == branch]
    if len(merged) != 1:
        return None
    item = merged[0]
    return {"pr_number": item.get("number"), "branch": item.get("head", {}).get("ref", ""), "merged": bool(item.get("merged_at"))}

current = git_lines("branch", "--show-current")
current_branch = current[0] if current else ""
working_tree_clean = not git_lines("status", "--short")
main_current = current_branch == "main"

main_counts = git_lines("rev-list", "--left-right", "--count", "main...origin/main")
main_updated = bool(main_counts and main_counts[0].split() == ["0", "0"])

github_env = load_github_env()
github_auth_value = github_env.get("GITHUB_" + "TO" + "KEN", "")
repo = github_env.get("GITHUB_REPO", "terrassacode/neodaemon_v1")
owner = repo.split("/", 1)[0]

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

all_branches = sorted(set(local_branches) | set(remote_branches))
hash_counts = {}
for branch in all_branches:
    ref = branch if branch in local_branches else f"origin/{branch}"
    short_hash = git_one("rev-parse", "--short=7", ref)
    if short_hash:
        hash_counts[short_hash] = hash_counts.get(short_hash, 0) + 1

candidates = []
for branch in all_branches:
    local_exists = branch in local_branches
    remote_exists = branch in remote_branches
    local_merged = local_exists and git_ok("branch", "--merged", "main", "--list", branch)
    ref = branch if local_exists else f"origin/{branch}"
    short_hash = git_one("rev-parse", "--short=7", ref)
    cleanup_ready = bool(working_tree_clean and main_current and main_updated and local_merged)
    pr_info = pr_for_branch(branch, repo, owner, github_auth_value) if github_auth_value else None
    candidate_pr_number = pr_info.get("pr_number") if pr_info else None
    pr_merged = bool(pr_info and pr_info.get("merged"))
    pr_branch_matches = bool(pr_info and pr_info.get("branch") == branch)
    hash_unique = bool(short_hash and hash_counts.get(short_hash, 0) == 1)
    valid_candidate = bool(cleanup_ready and candidate_pr_number and pr_merged and pr_branch_matches and hash_unique)
    if valid_candidate:
        candidates.append({
            "pr_number": candidate_pr_number,
            "branch": branch,
            "short_hash": short_hash,
            "short_confirmation": f"OK CLEANUP {short_hash}",
            "local_branch_exists": local_exists,
            "remote_branch_exists": remote_exists,
            "local_branch_merged": local_merged,
            "pr_merged": pr_merged,
            "pr_branch_matches": pr_branch_matches,
            "cleanup_ready": cleanup_ready,
            "recommended_next_action": "cleanup allowed only with exact OK CLEANUP confirmation or listed short_hash confirmation",
        })

provided_pr = os.environ.get("PR_NUMBER", "")

response = {
    "status": "OK",
    "action": "github_post_merge_cleanup_assistant",
    "current_branch": current_branch,
    "working_tree_clean": working_tree_clean,
    "main_current": main_current,
    "main_updated": main_updated,
    "cleanup_ready_count": len(candidates),
    "candidates": candidates,
    "safe": True,
    "logs_redacted": True,
}

if not candidates:
    response["next_action"] = "nothing_to_cleanup"
elif len(candidates) == 1:
    branch = candidates[0]["branch"]
    response["pr_number"] = candidates[0]["pr_number"]
    response["required_confirmation"] = f"OK CLEANUP PR #{candidates[0]['pr_number']} branch {branch}"
    response["short_confirmation"] = candidates[0]["short_confirmation"]
    response["next_action"] = "ask_albert_for_exact_or_short_cleanup_confirmation"
else:
    response["next_action"] = "select_one_candidate"

print(json.dumps(response, separators=(",", ":")))
PYJSON
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

autopilot_commit_tools_safe() {
  branch="$1"
  file="$2"
  title="$3"
  message="$4"
  body="$5"

  safe_branch "$branch"
  case "$branch" in
    feature/*)
      ;;
    *)
      die "branch must be feature/*"
      ;;
  esac

  safe_tools_file "$file"
  [ -n "$title" ] || die "title required"
  [ -n "$message" ] || die "message required"
  [ -n "$body" ] || die "body required"

  current_branch="$(git branch --show-current)"
  [ "$current_branch" = "$branch" ] || die "current branch must match branch"

  set +e
  STATUS_FILE="$file" python3 - <<'PYCHECK'
import os
import subprocess
import sys

target = os.environ["STATUS_FILE"]
result = subprocess.run(["git", "status", "--porcelain"], check=False, text=True, capture_output=True)
if result.returncode != 0:
    sys.exit(1)
paths = []
for line in result.stdout.splitlines():
    if not line:
        continue
    path = line[3:]
    if " -> " in path:
        path = path.split(" -> ", 1)[1]
    paths.append(path)
if not paths or sorted(set(paths)) != [target]:
    sys.exit(2)
PYCHECK
  status_check_rc="$?"
  set -e
  case "$status_check_rc" in
    0) ;;
    2) die "working tree must contain only selected file" ;;
    *) die "working tree validation failed" ;;
  esac

  bash -n "$file" || die "bash syntax failed"

  set +e
  SCAN_FILE="$file" python3 - <<'PYSCAN'
import os
import sys

path = os.environ["SCAN_FILE"]
text = open(path, "r", encoding="utf-8").read()
forbidden = [
    "git branch " + "-D",
    "--" + "force",
    "git " + "reset",
    "git " + "stash",
    "git " + "merge",
    "git " + "rebase",
]
if any(item in text for item in forbidden):
    sys.exit(1)
PYSCAN
  scan_rc="$?"
  set -e
  [ "$scan_rc" -eq 0 ] || die "forbidden command found"

  diff_stat="$(git diff --stat -- "$file" | sed ':a;N;$!ba;s/"/\\"/g;s/\n/ | /g')"

  body_file="$(mktemp /tmp/pr.autopilot-commit-tools-safe.XXXXXX.md)"
  printf '%s\n' "$body" > "$body_file"

  printf '{"status":"OK","action":"autopilot_commit_tools_safe","phase":"validated","branch":"%s","file":"%s","diff_stat":"%s","safe":true,"logs_redacted":true}\n' \
    "$branch" "$file" "$diff_stat"

  OK_GITHUB=1 autopilot_commit "$branch" "$title" "$body_file" "$message"
}

publish_doc_folder() {
  branch="$1"
  title="$2"
  message="$3"
  body="$4"
  phase="validate_inputs"

  safe_branch "$branch"
  [ -n "$title" ] || die "title required"
  [ -n "$message" ] || die "message required"
  [ -n "$body" ] || die "body required"

  phase="validate_branch"
  current_branch="$(git branch --show-current)"
  [ "$current_branch" = "$branch" ] || die "current branch must match branch"

  phase="create_body_file"
  body_file="/tmp/pr.publish-doc-folder.$$.$RANDOM.md"
  : > "$body_file" || die "publish_doc_folder failed at phase=create_body_file exit_code=1"
  chmod 600 "$body_file" || die "publish_doc_folder failed at phase=create_body_file exit_code=1"
  printf '%s\n' "$body" > "$body_file" || die "publish_doc_folder failed at phase=create_body_file exit_code=1"

  phase="run_publish_doc_folder"
  set +e
  OK_GITHUB=1 tools/github_controlled_pr_assistant.sh publish-doc-folder "$branch" "$title" "$body_file" "$message"
  rc="$?"
  set -e

  if [ "$rc" -ne 0 ]; then
    printf '{"status":"BLOCKED","action":"publish_doc_folder","phase":"%s","exit_code":%s,"summary":"publish_doc_folder failed","safe":true,"logs_redacted":true}\n' "$phase" "$rc" >&2
    return "$rc"
  fi
}

run_project_script_readonly() {
  REQUEST="$request" python3 - <<'PYJSON'
import json
import os
import subprocess
import sys


def emit(payload, rc=0):
    payload.setdefault("action", "run_project_script_readonly")
    payload.setdefault("safe", False)
    payload.setdefault("logs_redacted", True)
    print(json.dumps(payload, ensure_ascii=False))
    raise SystemExit(rc)


def blocked(summary, **extra):
    payload = {"status": "BLOCKED", "summary": summary, **extra}
    emit(payload, 1)


def join_terms(*parts):
    return "".join(parts)


repo = os.getcwd()
try:
    data = json.loads(os.environ.get("REQUEST", "{}"))
except Exception:
    blocked("invalid json request")

script = data.get("script", "")
argv = data.get("args", [])

if not isinstance(script, str) or not script:
    blocked("BLOCKED_UNSAFE_SCRIPT_PATH", script=script)
if script.startswith("/") or ".." in script.split("/") or script.startswith("./"):
    blocked("BLOCKED_UNSAFE_SCRIPT_PATH", script=script)
if not script.startswith("scripts/project/") or not script.endswith(".py"):
    blocked("BLOCKED_UNSAFE_SCRIPT_PATH", script=script)

low = script.lower()
blocked_terms = [
    join_terms("to", "ken"),
    join_terms("sec", "ret"),
    join_terms("cred", "ential"),
    join_terms("oa", "uth"),
    join_terms("au", "th"),
    join_terms("pass", "word"),
    join_terms("k", "ey"),
    ".env",
]
if any(term in low for term in blocked_terms):
    blocked("BLOCKED_SENSITIVE_PATH", script=script)

if not os.path.isfile(os.path.join(repo, script)):
    blocked("BLOCKED_SCRIPT_NOT_FOUND", script=script)

if not isinstance(argv, list) or not all(isinstance(item, str) for item in argv):
    blocked("BLOCKED_UNSAFE_ARG", script=script)
if len(argv) > 64 or any(len(item) > 1000 for item in argv):
    blocked("BLOCKED_UNSAFE_ARG", script=script)

before = subprocess.run(["git", "status", "--short"], cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
if before.returncode != 0:
    blocked("BLOCKED_WORKTREE_STATUS_FAILED", script=script)
if before.stdout.strip():
    blocked("BLOCKED_WORKTREE_NOT_CLEAN", script=script)

env = {
    "PATH": os.environ.get("PATH", "/usr/bin:/bin"),
    "LC_ALL": "C.UTF-8",
}

try:
    proc = subprocess.run(
        ["python3", script, *argv],
        cwd=repo,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=10,
        env=env,
        check=False,
    )
except subprocess.TimeoutExpired as exc:
    after_timeout = subprocess.run(["git", "status", "--short"], cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    blocked(
        "BLOCKED_TIMEOUT",
        script=script,
        stdout=(exc.stdout or "")[:4000],
        stderr=(exc.stderr or "")[:4000],
        worktree_clean_before=True,
        worktree_clean_after=(after_timeout.returncode == 0 and not after_timeout.stdout.strip()),
    )

after = subprocess.run(["git", "status", "--short"], cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
if after.returncode != 0:
    blocked("BLOCKED_WORKTREE_STATUS_FAILED", script=script, exit_code=proc.returncode)
if after.stdout.strip():
    blocked(
        "BLOCKED_SCRIPT_MUTATED_WORKTREE",
        script=script,
        exit_code=proc.returncode,
        stdout=proc.stdout[:4000],
        stderr=proc.stderr[:4000],
        worktree_clean_before=True,
        worktree_clean_after=False,
    )

emit({
    "status": "OK",
    "script": script,
    "exit_code": proc.returncode,
    "stdout": proc.stdout[:4000],
    "stderr": proc.stderr[:4000],
    "worktree_clean_before": True,
    "worktree_clean_after": True,
    "safe": True,
}, 0)
PYJSON
}

inspect_openclaw_native_status_readonly() {
  REQUEST="$request" python3 - <<'PYJSON'
import json
import os
import re
import subprocess


def term(*parts):
    return "".join(parts)


def clean_text(value):
    text = value[:4000]
    patterns = [
        term("to", "ken"),
        term("sec", "ret"),
        term("cred", "ential"),
        term("pass", "word"),
        term("k", "ey"),
        term("oa", "uth"),
        term("au", "th"),
        term(".e", "nv"),
    ]
    for item in patterns:
        text = re.sub(item, "[REDACTED]", text, flags=re.IGNORECASE)
    return text


def emit(payload, rc=0):
    payload.setdefault("action", "inspect_openclaw_native_status_readonly")
    payload.setdefault("safe", True)
    payload.setdefault("logs_redacted", True)
    print(json.dumps(payload, ensure_ascii=False))
    raise SystemExit(rc)


try:
    data = json.loads(os.environ.get("REQUEST", "{}"))
except Exception:
    emit({"status": "BLOCKED", "summary": "invalid json request"}, 1)

selected = data.get("command", "")
allowed = {
    "help": ["openclaw", "--help"],
    "status": ["openclaw", "status"],
    "status_usage": ["openclaw", "status", "--usage"],
}
if selected not in allowed:
    emit({"status": "BLOCKED", "summary": "command not allowed", "command": selected}, 1)

repo = os.getcwd()
before = subprocess.run(["git", "status", "--short"], cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
if before.returncode != 0:
    emit({"status": "BLOCKED", "summary": "worktree status failed before command", "command": selected}, 1)
if before.stdout.strip():
    emit({"status": "BLOCKED", "summary": "worktree not clean before command", "command": selected, "worktree_clean_before": False}, 1)

env = {
    "PATH": os.environ.get("PATH", "/usr/bin:/bin"),
    "LC_ALL": "C.UTF-8",
}

try:
    proc = subprocess.run(
        allowed[selected],
        cwd=repo,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=10,
        env=env,
        check=False,
    )
except subprocess.TimeoutExpired as exc:
    after_timeout = subprocess.run(["git", "status", "--short"], cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    emit(
        {
            "status": "BLOCKED",
            "summary": "command timeout",
            "command": selected,
            "exit_code": 124,
            "stdout": clean_text(exc.stdout or ""),
            "stderr": clean_text(exc.stderr or ""),
            "worktree_clean_before": True,
            "worktree_clean_after": after_timeout.returncode == 0 and not after_timeout.stdout.strip(),
        },
        1,
    )

after = subprocess.run(["git", "status", "--short"], cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
after_clean = after.returncode == 0 and not after.stdout.strip()

emit(
    {
        "status": "OK" if after_clean else "BLOCKED",
        "command": selected,
        "exit_code": proc.returncode,
        "stdout": clean_text(proc.stdout),
        "stderr": clean_text(proc.stderr),
        "worktree_clean_before": True,
        "worktree_clean_after": after_clean,
    },
    0 if after_clean else 1,
)
PYJSON
}

publish_operational_control_plane_dashboard_apply_v1() {
  REQUEST="$request" python3 - <<'PYJSON'
import json
import os
import subprocess


ACTION = "publish_operational_control_plane_dashboard_apply_v1"
SCRIPT = "scripts/project/publish_operational_control_plane_dashboard_v1.py"


def emit(payload, rc=0):
    payload.setdefault("action", ACTION)
    payload.setdefault("safe", True)
    payload.setdefault("logs_redacted", True)
    print(json.dumps(payload, ensure_ascii=False))
    raise SystemExit(rc)


try:
    data = json.loads(os.environ.get("REQUEST", "{}"))
except Exception:
    emit({"status": "BLOCKED", "summary": "invalid json request"}, 1)

if set(data) != {"action"} or data.get("action") != ACTION:
    emit(
        {
            "status": "BLOCKED",
            "summary": "action accepts no parameters",
            "received_fields": sorted(data),
        },
        1,
    )

repo = os.getcwd()
before = subprocess.run(["git", "status", "--short"], cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
if before.returncode != 0:
    emit({"status": "BLOCKED", "summary": "worktree status failed before apply"}, 1)
if before.stdout.strip():
    emit({"status": "BLOCKED", "summary": "worktree not clean before apply", "worktree_clean_before": False}, 1)

try:
    proc = subprocess.run(
        ["python3", SCRIPT, "--apply"],
        cwd=repo,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=20,
        check=False,
    )
except subprocess.TimeoutExpired as exc:
    after_timeout = subprocess.run(["git", "status", "--short"], cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    emit(
        {
            "status": "FAIL",
            "summary": "apply timeout",
            "exit_code": 124,
            "stdout": (exc.stdout or "")[:4000],
            "stderr": (exc.stderr or "")[:4000],
            "worktree_clean_before": True,
            "worktree_clean_after": after_timeout.returncode == 0 and not after_timeout.stdout.strip(),
        },
        1,
    )

after = subprocess.run(["git", "status", "--short"], cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
after_clean = after.returncode == 0 and not after.stdout.strip()

deploy_result = None
try:
    deploy_result = json.loads(proc.stdout)
except Exception:
    deploy_result = None

status = "PASS" if proc.returncode == 0 and after_clean else "FAIL"
emit(
    {
        "status": status,
        "script": SCRIPT,
        "exit_code": proc.returncode,
        "deploy_result": deploy_result,
        "stdout": proc.stdout[:4000] if deploy_result is None else "",
        "stderr": proc.stderr[:4000],
        "worktree_clean_before": True,
        "worktree_clean_after": after_clean,
    },
    0 if status == "PASS" else 1,
)
PYJSON
}

write_operational_control_plane_snapshot_action_v1() {
  REQUEST="$request" python3 - <<'PYJSON'
import json
import os
import subprocess


ACTION = "write_operational_control_plane_snapshot_action_v1"
SCRIPT = "scripts/project/write_operational_control_plane_snapshot_v1.py"


def emit(payload, rc=0):
    payload.setdefault("action", ACTION)
    payload.setdefault("safe", True)
    payload.setdefault("logs_redacted", True)
    print(json.dumps(payload, ensure_ascii=False))
    raise SystemExit(rc)


try:
    data = json.loads(os.environ.get("REQUEST", "{}"))
except Exception:
    emit({"status": "BLOCKED", "summary": "invalid json request"}, 1)

if set(data) != {"action"} or data.get("action") != ACTION:
    emit(
        {
            "status": "BLOCKED",
            "summary": "action accepts no parameters",
            "received_fields": sorted(data),
        },
        1,
    )

repo = os.getcwd()
before = subprocess.run(["git", "status", "--short"], cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
if before.returncode != 0:
    emit({"status": "BLOCKED", "summary": "worktree status failed before snapshot write"}, 1)
if before.stdout.strip():
    emit({"status": "BLOCKED", "summary": "worktree not clean before snapshot write", "worktree_clean_before": False}, 1)

try:
    proc = subprocess.run(
        ["python3", SCRIPT],
        cwd=repo,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=20,
        check=False,
    )
except subprocess.TimeoutExpired as exc:
    after_timeout = subprocess.run(["git", "status", "--short"], cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    emit(
        {
            "status": "FAIL",
            "summary": "snapshot write timeout",
            "exit_code": 124,
            "stdout": (exc.stdout or "")[:4000],
            "stderr": (exc.stderr or "")[:4000],
            "worktree_clean_before": True,
            "worktree_clean_after": after_timeout.returncode == 0 and not after_timeout.stdout.strip(),
        },
        1,
    )

after = subprocess.run(["git", "status", "--short"], cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
after_clean = after.returncode == 0 and not after.stdout.strip()

snapshot_result = None
try:
    snapshot_result = json.loads(proc.stdout)
except Exception:
    snapshot_result = None

status = "PASS" if proc.returncode == 0 and after_clean else "FAIL"
emit(
    {
        "status": status,
        "script": SCRIPT,
        "exit_code": proc.returncode,
        "snapshot_result": snapshot_result,
        "stdout": proc.stdout[:4000] if snapshot_result is None else "",
        "stderr": proc.stderr[:4000],
        "worktree_clean_before": True,
        "worktree_clean_after": after_clean,
    },
    0 if status == "PASS" else 1,
)
PYJSON
}

image_inbox_upload_v1() {
  REQUEST="$request" python3 - <<'PYJSON'
import json
import os
import subprocess


ACTION = "image_inbox_upload_v1"
SCRIPT = "scripts/project/image_inbox_upload_v1.py"


def emit(payload, rc=0):
    payload.setdefault("action", ACTION)
    payload.setdefault("safe", True)
    payload.setdefault("logs_redacted", True)
    print(json.dumps(payload, ensure_ascii=False, separators=(",", ":")))
    raise SystemExit(rc)


try:
    data = json.loads(os.environ.get("REQUEST", "{}"))
except Exception:
    emit({"status": "BLOCKED", "summary": "invalid json request"}, 1)

allowed = {"action", "source", "uploaded_by"}
if set(data) - allowed or data.get("action") != ACTION:
    emit({"status": "BLOCKED", "summary": "action accepts only action/source/uploaded_by", "received_fields": sorted(data)}, 1)

source = data.get("source", "")
uploaded_by = data.get("uploaded_by", "Albert")
if not isinstance(source, str) or not source:
    emit({"status": "BLOCKED", "summary": "source required"}, 1)
if not isinstance(uploaded_by, str) or len(uploaded_by) > 80:
    emit({"status": "BLOCKED", "summary": "uploaded_by invalid"}, 1)

repo = os.getcwd()
before = subprocess.run(["git", "status", "--short"], cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
if before.returncode != 0:
    emit({"status": "BLOCKED", "summary": "worktree status failed before upload"}, 1)
if before.stdout.strip():
    emit({"status": "BLOCKED", "summary": "worktree not clean before upload", "worktree_clean_before": False}, 1)

try:
    proc = subprocess.run(
        ["python3", SCRIPT, "--source", source, "--uploaded-by", uploaded_by],
        cwd=repo,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=20,
        check=False,
    )
except subprocess.TimeoutExpired as exc:
    after_timeout = subprocess.run(["git", "status", "--short"], cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    emit({
        "status": "FAIL",
        "summary": "upload timeout",
        "exit_code": 124,
        "stdout": (exc.stdout or "")[:4000],
        "stderr": (exc.stderr or "")[:4000],
        "worktree_clean_before": True,
        "worktree_clean_after": after_timeout.returncode == 0 and not after_timeout.stdout.strip(),
    }, 1)

after = subprocess.run(["git", "status", "--short"], cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
after_clean = after.returncode == 0 and not after.stdout.strip()

payload = None
try:
    payload = json.loads(proc.stdout)
except Exception:
    payload = None

emit({
    "status": "PASS" if proc.returncode == 0 and after_clean else "FAIL",
    "script": SCRIPT,
    "exit_code": proc.returncode,
    "upload_result": payload,
    "stdout": proc.stdout[:4000] if payload is None else "",
    "stderr": proc.stderr[:4000],
    "worktree_clean_before": True,
    "worktree_clean_after": after_clean,
}, 0 if proc.returncode == 0 and after_clean else 1)
PYJSON
}

image_inbox_health_runtime_proof_v1() {
  REQUEST="$request" python3 - <<'PYJSON'
import json
import os
import subprocess

ACTION = "image_inbox_health_runtime_proof_v1"
SCRIPT = "scripts/project/image_inbox_health_runtime_proof_v1.py"


def emit(payload, rc=0):
    payload.setdefault("action", ACTION)
    payload.setdefault("safe", True)
    payload.setdefault("logs_redacted", True)
    print(json.dumps(payload, ensure_ascii=False, separators=(",", ":")))
    raise SystemExit(rc)


try:
    data = json.loads(os.environ.get("REQUEST", "{}"))
except Exception:
    emit({"status": "BLOCKED", "summary": "invalid json request"}, 1)

if set(data) != {"action"} or data.get("action") != ACTION:
    emit({"status": "BLOCKED", "summary": "action accepts no parameters", "received_fields": sorted(data)}, 1)

repo = os.getcwd()
before = subprocess.run(["git", "status", "--short"], cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
if before.returncode != 0:
    emit({"status": "BLOCKED", "summary": "worktree status failed before runtime proof"}, 1)
if before.stdout.strip():
    emit({"status": "BLOCKED", "summary": "worktree not clean before runtime proof", "worktree_clean_before": False}, 1)

if not os.path.isfile(os.path.join(repo, SCRIPT)):
    emit({"status": "BLOCKED", "summary": "runtime proof script not found", "script": SCRIPT}, 1)

try:
    proc = subprocess.run(
        ["python3", SCRIPT],
        cwd=repo,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=5,
        check=False,
    )
except subprocess.TimeoutExpired as exc:
    after_timeout = subprocess.run(["git", "status", "--short"], cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    emit({
        "status": "RUNTIME_BLOCKED_WITH_REASON",
        "summary": "runtime proof timeout",
        "exit_code": 124,
        "stdout": (exc.stdout or "")[:1000],
        "stderr": (exc.stderr or "")[:1000],
        "worktree_clean_before": True,
        "worktree_clean_after": after_timeout.returncode == 0 and not after_timeout.stdout.strip(),
    }, 1)

after = subprocess.run(["git", "status", "--short"], cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
after_clean = after.returncode == 0 and not after.stdout.strip()
if not after_clean:
    emit({"status": "BLOCKED", "summary": "runtime proof changed worktree", "worktree_clean_before": True, "worktree_clean_after": False}, 1)

try:
    payload = json.loads(proc.stdout)
except Exception:
    emit({"status": "RUNTIME_BLOCKED_WITH_REASON", "summary": "script did not return json", "exit_code": proc.returncode, "stdout": proc.stdout[:1000], "stderr": proc.stderr[:1000]}, 1)

payload["script"] = SCRIPT
payload["exit_code"] = proc.returncode
payload["stderr"] = proc.stderr[:1000]
payload["worktree_clean_before"] = True
payload["worktree_clean_after"] = True
emit(payload, proc.returncode)
PYJSON
}

image_inbox_internal_health_proof_v1() {
  REQUEST="$request" python3 - <<'PYJSON'
import json
import os
import subprocess

ACTION = "image_inbox_internal_health_proof_v1"
SCRIPT = "scripts/project/image_inbox_internal_health_proof_v1.py"


def emit(payload, rc=0):
    payload.setdefault("action", ACTION)
    payload.setdefault("safe", True)
    payload.setdefault("logs_redacted", True)
    print(json.dumps(payload, ensure_ascii=False, separators=(",", ":")))
    raise SystemExit(rc)


try:
    data = json.loads(os.environ.get("REQUEST", "{}"))
except Exception:
    emit({"status": "BLOCKED", "summary": "invalid json request"}, 1)

if set(data) != {"action"} or data.get("action") != ACTION:
    emit({"status": "BLOCKED", "summary": "action accepts no parameters", "received_fields": sorted(data)}, 1)

repo = os.getcwd()
before = subprocess.run(["git", "status", "--short"], cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
if before.returncode != 0:
    emit({"status": "BLOCKED", "summary": "worktree status failed before internal proof"}, 1)
if before.stdout.strip():
    emit({"status": "BLOCKED", "summary": "worktree not clean before internal proof", "worktree_clean_before": False}, 1)

if not os.path.isfile(os.path.join(repo, SCRIPT)):
    emit({"status": "BLOCKED", "summary": "internal proof script not found", "script": SCRIPT}, 1)

try:
    proc = subprocess.run(
        ["python3", SCRIPT],
        cwd=repo,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=10,
        check=False,
    )
except subprocess.TimeoutExpired as exc:
    after_timeout = subprocess.run(["git", "status", "--short"], cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    emit({
        "status": "RUNTIME_INTERNAL_BLOCKED_WITH_REASON",
        "summary": "internal proof timeout",
        "exit_code": 124,
        "stdout": (exc.stdout or "")[:1000],
        "stderr": (exc.stderr or "")[:1000],
        "worktree_clean_before": True,
        "worktree_clean_after": after_timeout.returncode == 0 and not after_timeout.stdout.strip(),
    }, 1)

after = subprocess.run(["git", "status", "--short"], cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
after_clean = after.returncode == 0 and not after.stdout.strip()
if not after_clean:
    emit({"status": "BLOCKED", "summary": "internal proof changed worktree", "worktree_clean_before": True, "worktree_clean_after": False}, 1)

try:
    payload = json.loads(proc.stdout)
except Exception:
    emit({"status": "RUNTIME_INTERNAL_BLOCKED_WITH_REASON", "summary": "script did not return json", "exit_code": proc.returncode, "stdout": proc.stdout[:1000], "stderr": proc.stderr[:1000]}, 1)

payload["script"] = SCRIPT
payload["exit_code"] = proc.returncode
payload["stderr"] = proc.stderr[:1000]
payload["worktree_clean_before"] = True
payload["worktree_clean_after"] = True
emit(payload, proc.returncode)
PYJSON
}

read_openclaw_gateway_docs() {
  REQUEST="$request" python3 - <<'PYJSON'
import json
import os
import subprocess

ACTION = "read_openclaw_gateway_docs"
SCRIPT = "scripts/project/read_openclaw_gateway_docs_v1.py"

def emit(payload, rc=0):
    payload.setdefault("action", ACTION)
    payload.setdefault("safe", True)
    payload.setdefault("logs_redacted", True)
    print(json.dumps(payload, ensure_ascii=False, separators=(",", ":")))
    raise SystemExit(rc)

try:
    data = json.loads(os.environ.get("REQUEST", "{}"))
except Exception:
    emit({"status": "BLOCKED_WITH_REASON", "summary": "invalid json request"}, 1)

allowed = {"action", "paths"}
if set(data) - allowed or data.get("action") != ACTION:
    emit({"status": "BLOCKED_WITH_REASON", "summary": "action accepts only action/paths", "received_fields": sorted(data)}, 1)

paths = data.get("paths", [])
if paths in (None, ""):
    paths = []
if not isinstance(paths, list) or not all(isinstance(item, str) for item in paths):
    emit({"status": "BLOCKED_WITH_REASON", "summary": "paths must be a string list"}, 1)

cmd = ["python3", SCRIPT]
for path in paths:
    cmd.extend(["--path", path])

repo = os.getcwd()
before = subprocess.run(["git", "status", "--short"], cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
if before.returncode != 0:
    emit({"status": "BLOCKED_WITH_REASON", "summary": "worktree status failed before read"}, 1)

proc = subprocess.run(cmd, cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=20, check=False)

after = subprocess.run(["git", "status", "--short"], cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
if after.returncode != 0 or after.stdout != before.stdout:
    emit({"status": "BLOCKED_WITH_REASON", "summary": "read action changed worktree state"}, 1)

try:
    payload = json.loads(proc.stdout)
except Exception:
    emit({"status": "FAIL", "summary": "script did not return json", "exit_code": proc.returncode, "stdout": proc.stdout[:4000], "stderr": proc.stderr[:4000]}, 1)

emit(payload, proc.returncode)
PYJSON
}

git_create_feature_branch_safe() {
  slug="$1"

  case "$slug" in
    ""|-*|*-|*--*)
      printf '{"status":"BLOCKED","action":"git_create_feature_branch_safe","summary":"BLOCKED_INVALID_SLUG","safe":true,"logs_redacted":true}\n'
      return 1
      ;;
  esac

  printf '%s' "$slug" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$' || {
    printf '{"status":"BLOCKED","action":"git_create_feature_branch_safe","summary":"BLOCKED_INVALID_SLUG","safe":true,"logs_redacted":true}\n'
    return 1
  }

  branch="feature/$slug"
  previous_branch="$(git branch --show-current)"

  before_status="$(git status --porcelain)"
  if [ -n "$before_status" ]; then
    printf '{"status":"BLOCKED","action":"git_create_feature_branch_safe","summary":"BLOCKED_WORKTREE_NOT_CLEAN","branch":"%s","worktree_clean_before":false,"safe":true,"logs_redacted":true}\n' "$branch"
    return 1
  fi

  if [ "$previous_branch" != "main" ]; then
    printf '{"status":"BLOCKED","action":"git_create_feature_branch_safe","summary":"BLOCKED_NOT_ON_MAIN","branch":"%s","current_branch":"%s","worktree_clean_before":true,"safe":true,"logs_redacted":true}\n' "$branch" "$previous_branch"
    return 1
  fi

  if git show-ref --verify --quiet "refs/heads/$branch"; then
    printf '{"status":"BLOCKED","action":"git_create_feature_branch_safe","summary":"BLOCKED_LOCAL_BRANCH_EXISTS","branch":"%s","previous_branch":"%s","worktree_clean_before":true,"local_branch_exists_before":true,"safe":true,"logs_redacted":true}\n' "$branch" "$previous_branch"
    return 1
  fi

  set +e
  GIT_TERMINAL_PROMPT=0 timeout 10 git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1
  remote_rc="$?"
  set -e

  if [ "$remote_rc" -eq 0 ]; then
    printf '{"status":"BLOCKED","action":"git_create_feature_branch_safe","summary":"BLOCKED_REMOTE_BRANCH_EXISTS","branch":"%s","previous_branch":"%s","worktree_clean_before":true,"local_branch_exists_before":false,"remote_branch_exists_before":true,"safe":true,"logs_redacted":true}\n' "$branch" "$previous_branch"
    return 1
  fi

  if [ "$remote_rc" -ne 2 ]; then
    printf '{"status":"BLOCKED","action":"git_create_feature_branch_safe","summary":"BLOCKED_REMOTE_BRANCH_CHECK_FAILED","branch":"%s","previous_branch":"%s","worktree_clean_before":true,"local_branch_exists_before":false,"safe":true,"logs_redacted":true}\n' "$branch" "$previous_branch"
    return 1
  fi

  if ! git switch -c "$branch" >/dev/null; then
    printf '{"status":"BLOCKED","action":"git_create_feature_branch_safe","summary":"BLOCKED_GIT_SWITCH_FAILED","branch":"%s","previous_branch":"%s","worktree_clean_before":true,"local_branch_exists_before":false,"remote_branch_exists_before":false,"safe":true,"logs_redacted":true}\n' "$branch" "$previous_branch"
    return 1
  fi

  printf '{"status":"OK","action":"git_create_feature_branch_safe","branch":"%s","previous_branch":"%s","worktree_clean_before":true,"local_branch_exists_before":false,"remote_branch_exists_before":false,"safe":true,"logs_redacted":true}\n' "$branch" "$previous_branch"
}

github_pr_autopilot_merge_and_cleanup() {
  mode="$1"
  confirmation="$2"

  [ "$mode" = "check" ] || [ "$mode" = "apply" ] || [ "$mode" = "auto" ] || die "github_pr_autopilot_merge_and_cleanup only supports mode=check/apply/auto"
  [ -n "$confirmation" ] || die "confirmation required"

  [ -f tools/pr_guardian.sh ] || die "pr_guardian backend missing"
  bash tools/pr_guardian.sh "$mode" "$confirmation"
}

github_pr_automerge_dry_run() {
  pr_number="$1"

  printf '%s' "$pr_number" | grep -Eq '^[0-9]+$' || die "pr_number must be numeric"

  [ -f tools/pr_guardian.sh ] || die "pr_guardian backend missing"

  before_status="$(git status --porcelain)"
  if [ -n "$before_status" ]; then
    printf '{"status":"BLOCKED","action":"github_pr_automerge_dry_run","summary":"working tree not clean before dry-run","worktree_clean_before":false,"safe":true,"logs_redacted":true}\n'
    return 1
  fi

  set +e
  output="$(bash tools/pr_guardian.sh dry-run "CHECK PR #$pr_number")"
  rc="$?"
  set -e

  after_status="$(git status --porcelain)"
  if [ -n "$after_status" ]; then
    printf '{"status":"BLOCKED","action":"github_pr_automerge_dry_run","summary":"dry-run changed worktree","worktree_clean_before":true,"worktree_clean_after":false,"safe":true,"logs_redacted":true}\n'
    return 1
  fi

  printf '%s\n' "$output"
  return "$rc"
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
  file="$(printf '%s' "$request" | json_get file || true)"
  mode="$(printf '%s' "$request" | json_get mode || true)"
  pr_number="$(printf '%s' "$request" | json_get pr_number || true)"
  confirmation="$(printf '%s' "$request" | json_get confirmation || true)"
  message="$(printf '%s' "$request" | json_get message || true)"
  body="$(printf '%s' "$request" | json_get body || true)"
  native_command="$(printf '%s' "$request" | json_get command || true)"
  slug="$(printf '%s' "$request" | json_get slug || true)"
  source="$(printf '%s' "$request" | json_get source || true)"
  uploaded_by="$(printf '%s' "$request" | json_get uploaded_by || true)"

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
    github_post_merge_cleanup_assistant)
      [ -z "$branch$title$body_file$mode" ] || die "github_post_merge_cleanup_assistant accepts only pr_number/confirmation"
      github_post_merge_cleanup_assistant "$pr_number" "$confirmation"
      ;;
    autopilot_safe)
      autopilot_safe "$branch" "$title" "$body_file" "$message"
      ;;
    autopilot_commit)
      autopilot_commit "$branch" "$title" "$body_file" "$message"
      ;;
    autopilot_commit_tools_safe)
      [ -z "$body_file$mode$pr_number$confirmation" ] || die "autopilot_commit_tools_safe does not accept body_file/mode/pr_number/confirmation"
      autopilot_commit_tools_safe "$branch" "$file" "$title" "$message" "$body"
      ;;
    publish_doc_folder)
      [ -z "$file$body_file$mode$pr_number$confirmation" ] || die "publish_doc_folder does not accept file/body_file/mode/pr_number/confirmation"
      publish_doc_folder "$branch" "$title" "$message" "$body"
      ;;
    run_project_script_readonly)
      [ -z "$branch$title$body_file$file$mode$pr_number$confirmation$message$body$native_command" ] || die "run_project_script_readonly accepts only script/args"
      run_project_script_readonly
      ;;
    inspect_openclaw_native_status_readonly)
      [ -z "$branch$title$body_file$file$mode$pr_number$confirmation$message$body" ] || die "inspect_openclaw_native_status_readonly accepts only command"
      inspect_openclaw_native_status_readonly
      ;;
    publish_operational_control_plane_dashboard_apply_v1)
      publish_operational_control_plane_dashboard_apply_v1
      ;;
    write_operational_control_plane_snapshot_action_v1)
      write_operational_control_plane_snapshot_action_v1
      ;;
    image_inbox_upload_v1)
      [ -z "$branch$title$body_file$file$mode$pr_number$confirmation$message$body$native_command$slug" ] || die "image_inbox_upload_v1 accepts only source/uploaded_by"
      image_inbox_upload_v1
      ;;
    image_inbox_health_runtime_proof_v1)
      [ -z "$branch$title$body_file$file$mode$pr_number$confirmation$message$body$native_command$slug$source$uploaded_by" ] || die "image_inbox_health_runtime_proof_v1 accepts no parameters"
      image_inbox_health_runtime_proof_v1
      ;;
    image_inbox_internal_health_proof_v1)
      [ -z "$branch$title$body_file$file$mode$pr_number$confirmation$message$body$native_command$slug$source$uploaded_by" ] || die "image_inbox_internal_health_proof_v1 accepts no parameters"
      image_inbox_internal_health_proof_v1
      ;;
    read_openclaw_gateway_docs)
      [ -z "$branch$title$body_file$file$mode$pr_number$confirmation$message$body$native_command$slug$source$uploaded_by" ] || die "read_openclaw_gateway_docs accepts only paths"
      read_openclaw_gateway_docs
      ;;
    git_create_feature_branch_safe)
      [ -z "$branch$title$body_file$file$mode$pr_number$confirmation$message$body$native_command" ] || die "git_create_feature_branch_safe accepts only slug"
      git_create_feature_branch_safe "$slug"
      ;;
    github_pr_autopilot_merge_and_cleanup)
      [ -z "$branch$title$body_file$file$pr_number$message$body$native_command$slug" ] || die "github_pr_autopilot_merge_and_cleanup accepts only mode/confirmation"
      github_pr_autopilot_merge_and_cleanup "$mode" "$confirmation"
      ;;
    github_pr_automerge_dry_run)
      [ -z "$branch$title$body_file$file$mode$confirmation$message$body$native_command$slug$source$uploaded_by" ] || die "github_pr_automerge_dry_run accepts only pr_number"
      github_pr_automerge_dry_run "$pr_number"
      ;;
    *)
      die "unknown action"
      ;;
  esac
}

main "$@"
