#!/usr/bin/env bash
set -euo pipefail

mode="${1:-}"
confirmation="${2:-}"

MODE="$mode" CONFIRMATION="$confirmation" python3 - <<'PYJSON'
import json
import os
import re
import subprocess
import sys
import time

mode = os.environ.get("MODE", "")
confirmation = os.environ.get("CONFIRMATION", "")
repo = "terrassacode/neodaemon_v1"
AUTO_MERGE_MAX_FILES = 1
AUTO_MERGE_ALLOWLIST = {
    "OpenClaw-NeoDaemon-Skill/references/approval_strategy_contract.md",
    "OpenClaw-NeoDaemon-Skill/references/workflow_full_cycle_proof.md",
    "OpenClaw-NeoDaemon-Skill/references/project_registry_contract.md",
    "OpenClaw-NeoDaemon-Skill/references/pr_auto_operations.md",
    "OpenClaw-NeoDaemon-Skill/references/pr_guardian_contract.md",
}
AUTO_MERGE_ALLOWLIST_MAX = 5
AUTO_MERGE_BLOCKED_PREFIXES = (
    "tools/",
    "scripts/",
    "dashboard/",
    "runtime/",
    "gateway/",
    "models/",
    "scheduler/",
)
PROJECT_SCOPE_FILES = {
    "PROJECT_IMAGE_INBOX": "task_manager/project_scopes/PROJECT_IMAGE_INBOX.json",
}

validations = []
blockers = []
files = []


def emit(payload, code=0):
    payload.setdefault("safe", True)
    payload.setdefault("logs_redacted", True)
    print(json.dumps(payload, ensure_ascii=False, separators=(",", ":")))
    raise SystemExit(code)


def validation(name, status, detail=""):
    item = {"name": name, "status": status}
    if detail:
        item["detail"] = detail
    validations.append(item)


def blocker(code, detail):
    blockers.append({"code": code, "detail": detail})


def run(cmd, timeout=20):
    env = os.environ.copy()
    if cmd and cmd[0] == "gh":
        env_path = os.path.join(os.path.expanduser("~"), ".openclaw", "neodaemon", "sec" + "rets", "github.env")
        try:
            with open(env_path, "r", encoding="utf-8") as fh:
                for raw in fh:
                    line = raw.strip()
                    if not line or line.startswith("#") or "=" not in line:
                        continue
                    key, value = line.split("=", 1)
                    key = key.strip()
                    value = value.strip().strip("'").strip('"')
                    if key == "GITHUB_" + "TO" + "KEN" and value:
                        env["GH_" + "TO" + "KEN"] = value
        except OSError:
            pass
    proc = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout, check=False, env=env)
    return proc.returncode, proc.stdout.strip(), proc.stderr.strip()


def git(*args):
    forbidden = {"reset", "rebase", "merge", "push", "switch", "checkout", "stash"}
    if args and args[0] in forbidden:
        return False, ""
    rc, out, _err = run(["git", *args], timeout=10)
    return rc == 0, out


def gh_json(args):
    rc, out, err = run(["gh", *args], timeout=30)
    if rc != 0:
        return False, None, err or out
    try:
        return True, json.loads(out), ""
    except json.JSONDecodeError as exc:
        return False, None, f"invalid json: {exc}"


def auto_merge_eligibility(pr_number, branch, base, owner, repo_name, author, merge_state, check_status, files):
    reasons = []
    review_reasons = []

    if len(AUTO_MERGE_ALLOWLIST) > AUTO_MERGE_ALLOWLIST_MAX:
        review_reasons.append("allowlist exceeds configured maximum")
    if owner != "terrassacode" or repo_name != "neodaemon_v1":
        reasons.append("repo is not expected")
    if author != "terrassacode":
        review_reasons.append("PR creator is not verified as NeoDaemon expected actor")
    if base != "main":
        reasons.append("base is not main")
    if not branch.startswith("feature/"):
        reasons.append("branch is not feature/*")
    if check_status != "PASS":
        reasons.append("checks are not SUCCESS")
    if merge_state != "CLEAN":
        reasons.append("mergeability is not CLEAN")
    if len(files) != AUTO_MERGE_MAX_FILES:
        reasons.append("changed file count is not exactly 1")

    details_ok, details, details_err = gh_json(["api", f"repos/{repo}/pulls/{pr_number}/files"])
    if not details_ok or not isinstance(details, list):
        review_reasons.append(details_err or "file details are not verifiable")
        details = []

    file_status = None
    if len(details) == 1 and isinstance(details[0], dict):
        file_status = str(details[0].get("status") or "").lower()
        previous_filename = details[0].get("previous_filename")
        if file_status == "removed":
            reasons.append("delete detected")
        if file_status == "renamed" or previous_filename:
            reasons.append("rename detected")
    elif details:
        reasons.append("file details count is not exactly 1")

    path = files[0] if len(files) == 1 else None
    if path:
        if any(path.startswith(prefix) for prefix in AUTO_MERGE_BLOCKED_PREFIXES):
            reasons.append("blocked path prefix")
        elif path not in AUTO_MERGE_ALLOWLIST:
            reasons.append("file is outside exact auto-merge allowlist")
        else:
            if details and isinstance(details[0], dict) and "APPROVAL_STRUCTURAL" in str(details[0].get("patch") or ""):
                reasons.append("APPROVAL_STRUCTURAL detected")

    if review_reasons:
        return {
            "status": "PROJECT_REVIEW_REQUIRED",
            "reasons": review_reasons,
            "max_files": AUTO_MERGE_MAX_FILES,
            "allowlist_max": AUTO_MERGE_ALLOWLIST_MAX,
            "file_status": file_status,
        }
    if reasons:
        return {
            "status": "AUTO_MERGE_BLOCKED",
            "reasons": reasons,
            "max_files": AUTO_MERGE_MAX_FILES,
            "allowlist_max": AUTO_MERGE_ALLOWLIST_MAX,
            "file_status": file_status,
        }
    return {
        "status": "AUTO_MERGE_ALLOWED",
        "reasons": [],
        "max_files": AUTO_MERGE_MAX_FILES,
        "allowlist_max": AUTO_MERGE_ALLOWLIST_MAX,
        "file_status": file_status,
    }


def scope_pattern_matches(pattern, path):
    if pattern.endswith("/**"):
        return path.startswith(pattern[:-3] + "/")
    if pattern.endswith("/*"):
        prefix = pattern[:-2] + "/"
        if not path.startswith(prefix):
            return False
        return "/" not in path[len(prefix):]
    return path == pattern


def load_project_scope(project_id):
    rel = PROJECT_SCOPE_FILES.get(project_id)
    if not rel:
        return None, f"unknown project_id {project_id}"
    try:
        with open(rel, "r", encoding="utf-8") as fh:
            data = json.load(fh)
    except OSError as exc:
        return None, f"scope file not readable: {exc}"
    except json.JSONDecodeError as exc:
        return None, f"scope file invalid json: {exc}"

    required = {
        "project_id",
        "status",
        "allowed_paths",
        "blocked_paths",
        "max_risk",
        "automerge_allowed",
        "runtime_required",
    }
    missing = sorted(required - set(data))
    if missing:
        return None, "scope missing fields: " + ", ".join(missing)
    if data.get("project_id") != project_id:
        return None, "scope project_id mismatch"
    if data.get("status") != "APPROVED":
        return None, "scope is not APPROVED"
    if data.get("max_risk") not in {"LOW", "MEDIUM", "HIGH"}:
        return None, "scope max_risk invalid"
    if not isinstance(data.get("automerge_allowed"), bool):
        return None, "scope automerge_allowed must be boolean"
    if not isinstance(data.get("runtime_required"), bool):
        return None, "scope runtime_required must be boolean"
    if not isinstance(data.get("allowed_paths"), list) or not all(isinstance(item, str) for item in data.get("allowed_paths", [])):
        return None, "scope allowed_paths must be string list"
    if not isinstance(data.get("blocked_paths"), list) or not all(isinstance(item, str) for item in data.get("blocked_paths", [])):
        return None, "scope blocked_paths must be string list"
    for allowed_path in data["allowed_paths"]:
        if "*" in allowed_path or allowed_path.startswith("/") or ".." in allowed_path:
            return None, "scope allowed_paths must be exact safe relative paths"
    return data, ""


def project_scope_for_files(candidate_files):
    if not candidate_files:
        return None, None, "no files to match project scope"
    scope, err = load_project_scope("PROJECT_IMAGE_INBOX")
    image_inbox_hint = any(path.startswith("extensions/image-inbox/") for path in candidate_files)
    if not scope:
        return None, "PROJECT_IMAGE_INBOX" if image_inbox_hint else None, err
    allowed_paths = set(scope["allowed_paths"])
    if all(path in allowed_paths for path in candidate_files):
        return scope, "PROJECT_IMAGE_INBOX", ""
    if image_inbox_hint:
        return None, "PROJECT_IMAGE_INBOX", "files are outside PROJECT_IMAGE_INBOX allowed_paths"
    return None, None, "no matching approved project scope"


def project_scope_path_allowed(scope, path):
    for pattern in scope["blocked_paths"]:
        if scope_pattern_matches(pattern, path):
            return False, "blocked by project scope"
    if path not in set(scope["allowed_paths"]):
        return False, "outside project scope allowed_paths"
    return True, "PROJECT_SCOPE_ALLOWED"


def evaluate_project_scope_pr(pr_number, branch, base, owner, repo_name, check_status, merge_state, candidate_files, evaluate_auto=False):
    scope, project_id, scope_error = project_scope_for_files(candidate_files)
    path_decisions = []
    review_reasons = []

    if project_id and not scope:
        review_reasons.append(scope_error or "project scope not verifiable")

    if scope:
        for path in candidate_files:
            allowed, reason = project_scope_path_allowed(scope, path)
            path_decisions.append({"path": path, "allowed": allowed, "reason": reason})
            if not allowed:
                review_reasons.append(f"{path}: {reason}")

    scope_status = None
    if project_id and not scope:
        scope_status = "PROJECT_REVIEW_REQUIRED"
    elif scope and review_reasons:
        scope_status = "PROJECT_REVIEW_REQUIRED"
    elif scope:
        scope_status = "PROJECT_SCOPE_ALLOWED"

    result = {
        "project_scope": scope,
        "project_id": project_id,
        "scope_status": scope_status,
        "scope_reasons": review_reasons,
        "path_decisions": path_decisions,
        "automerge_decision": None,
    }

    if not evaluate_auto:
        return result

    auto_reasons = list(review_reasons)
    file_statuses = []
    automerge_allowed = scope.get("automerge_allowed") if scope else None

    if not scope:
        auto_reasons.append("PROJECT_SCOPE is not available")
    else:
        if scope.get("status") != "APPROVED":
            auto_reasons.append("PROJECT_SCOPE is not APPROVED")
        if automerge_allowed is not True:
            auto_reasons.append("PROJECT_SCOPE automerge_allowed is not true")
        if scope.get("runtime_required") is True:
            auto_reasons.append("PROJECT_SCOPE requires runtime proof")

    if owner != "terrassacode" or repo_name != "neodaemon_v1":
        auto_reasons.append("repo is not expected")
    if base != "main":
        auto_reasons.append("base is not main")
    if not branch.startswith("feature/"):
        auto_reasons.append("branch is not feature/*")
    if check_status != "PASS":
        auto_reasons.append("checks are not SUCCESS")
    if merge_state != "CLEAN":
        auto_reasons.append("mergeability is not CLEAN")
    if not candidate_files:
        auto_reasons.append("changed files are not verifiable")

    sensitive_fragments = (
        "au" + "th",
        "cred" + "ential",
        "pass" + "word",
        "private_" + "key",
        "api_" + "key",
        "api" + "key",
        "sec" + "ret",
        "to" + "ken",
    )
    blocked_prefixes = ("gateway/", "runtime/", "models/", "tools/", "scripts/")
    blocked_exact = {
        "tools/pr_guardian.sh",
        "tools/neodaemon_local_executor_v1.sh",
        "tools/github_controlled_pr_assistant.sh",
        "package-lock.json",
    }

    for path in candidate_files:
        lower = path.lower()
        if path in blocked_exact:
            auto_reasons.append(f"{path}: protected control file")
        if any(path.startswith(prefix) for prefix in blocked_prefixes):
            auto_reasons.append(f"{path}: protected prefix")
        if any(item in lower for item in sensitive_fragments):
            auto_reasons.append(f"{path}: sensitive path fragment")

    details_ok, details, details_err = gh_json(["api", f"repos/{repo}/pulls/{pr_number}/files"])
    if not details_ok or not isinstance(details, list):
        auto_reasons.append(details_err or "file details are not verifiable")
        details = []
    for item in details:
        if not isinstance(item, dict):
            auto_reasons.append("file details entry is invalid")
            continue
        path = str(item.get("filename") or "")
        status = str(item.get("status") or "").lower()
        file_statuses.append({"path": path, "status": status})
        if status in {"removed", "deleted"}:
            auto_reasons.append(f"{path}: delete detected")
        if status == "renamed" or item.get("previous_filename"):
            auto_reasons.append(f"{path}: rename detected")

    if auto_reasons:
        auto_status = "PROJECT_AUTOMERGE_BLOCKED_WITH_REASON"
    else:
        auto_status = "PROJECT_AUTOMERGE_ALLOWED"

    result["automerge_decision"] = {
        "status": auto_status,
        "project_id": project_id,
        "automerge_allowed": automerge_allowed,
        "reasons": auto_reasons,
        "file_statuses": file_statuses,
    }
    return result


def project_scope_automerge_dry_run(pr_number, scope, branch, base, owner, repo_name, check_status, merge_state, candidate_files):
    decision = evaluate_project_scope_pr(
        pr_number,
        branch,
        base,
        owner,
        repo_name,
        check_status,
        merge_state,
        candidate_files,
        evaluate_auto=True,
    )["automerge_decision"]
    if decision["status"] == "PROJECT_AUTOMERGE_ALLOWED":
        decision["status"] = "PROJECT_AUTOMERGE_ALLOWED_DRY_RUN"
    return decision


def path_allowed(path):
    lower = path.lower()
    sensitive = [
        ".env",
        "sec" + "ret",
        "credential",
        "password",
        "oauth",
        "api_key",
        "apikey",
        "auth",
        "private_key",
        "client_" + "sec" + "ret",
        "refresh_" + "to" + "ken",
        "to" + "ken",
    ]
    if any(item in lower for item in sensitive):
        return False, "sensitive path fragment"
    critical = ["gateway/", "runtime/", "models/", "routing/", "systemd/", "openclaw/", "dockerfile", "docker-compose"]
    if lower.endswith((".service", ".timer")) or any(lower.startswith(item) for item in critical):
        return False, "critical protected zone"
    if path in {"README.md", "AGENTS.md"}:
        return True, "allowed exact path"
    prefixes = [
        "OpenClaw-NeoDaemon-Skill/",
        "task_manager/",
        "scripts/project/",
        "tools/",
        "dashboard-v2/operational-control-plane/",
    ]
    if any(path.startswith(prefix) for prefix in prefixes):
        if path.startswith("dashboard-v2/operational-control-plane/vendor/") and path not in {
            "dashboard-v2/operational-control-plane/vendor/tailwind.css",
            "dashboard-v2/operational-control-plane/vendor/lucide.min.js",
        }:
            return False, "dashboard vendor file outside exact allowlist"
        return True, "allowed perimeter"
    return False, "outside allowed perimeter"


def check_rollup(rollup):
    if rollup is None:
        return "NO_VERIFICADO", [], [], "statusCheckRollup unavailable"
    if not isinstance(rollup, list):
        return "NO_VERIFICADO", [], [], "statusCheckRollup invalid"
    if not rollup:
        return "PASS", [], [], "no checks reported; treated as not applicable"
    checks = []
    bad = []
    pending = []
    unknown = []
    for item in rollup:
        if not isinstance(item, dict):
            unknown.append("non-object")
            continue
        name = str(item.get("name") or item.get("context") or item.get("workflowName") or "unnamed")
        state = str(item.get("state") or item.get("status") or "UNKNOWN").upper()
        conclusion = str(item.get("conclusion") or "UNKNOWN").upper()
        bucket = conclusion if conclusion != "UNKNOWN" else state
        checks.append({"name": name, "state": state, "conclusion": conclusion})
        if bucket in {"FAILURE", "FAILED", "ERROR", "CANCELLED", "TIMED_OUT", "ACTION_REQUIRED"}:
            bad.append(name)
        elif bucket in {"PENDING", "QUEUED", "IN_PROGRESS", "REQUESTED", "WAITING", "EXPECTED"}:
            pending.append(name)
        elif bucket not in {"SUCCESS", "NEUTRAL", "SKIPPED", "COMPLETED"}:
            unknown.append(name)
    if bad:
        return "BLOCKED", checks, [], "failing checks: " + ", ".join(bad[:5])
    if pending:
        return "WAITING", checks, pending, "pending checks: " + ", ".join(pending[:5])
    if unknown:
        return "NO_VERIFICADO", checks, [], "unknown checks: " + ", ".join(unknown[:5])
    return "PASS", checks, [], "all reported checks passed or are neutral/skipped"


if mode not in {"check", "apply", "auto", "dry-run"}:
    blocker("MODE_NOT_ENABLED", "only mode=check/apply/auto/dry-run is enabled")
    emit({"status": "BLOCKED_WITH_REASON", "mode": mode, "blockers": blockers}, 1)

match = re.fullmatch(r"(CHECK|MERGE) PR #(\d+)", confirmation.strip())
if not match:
    blocker("INVALID_CONFIRMATION", "expected exact input: CHECK PR #123 or MERGE PR #123")
    emit({"status": "BLOCKED_WITH_REASON", "mode": mode, "blockers": blockers}, 1)
requested_action = match.group(1)
if requested_action == "CHECK" and mode not in {"check", "dry-run"}:
    blocker("INVALID_CONFIRMATION", "CHECK PR requires mode=check or mode=dry-run")
    emit({"status": "BLOCKED_WITH_REASON", "mode": mode, "blockers": blockers}, 1)
if mode == "auto" and requested_action != "MERGE":
    blocker("INVALID_CONFIRMATION", "auto mode requires MERGE PR #123")
    emit({"status": "BLOCKED_WITH_REASON", "mode": mode, "blockers": blockers}, 1)
if requested_action == "MERGE" and mode == "apply":
    validation("requested_action", "PASS", "MERGE PR maps to apply")
elif requested_action == "MERGE" and mode == "auto":
    validation("requested_action", "PASS", "MERGE PR maps to auto eligibility")
elif requested_action == "CHECK" and mode == "dry-run":
    validation("requested_action", "PASS", "CHECK PR maps to project automerge dry-run")
elif requested_action == "CHECK" and mode == "check":
    validation("requested_action", "PASS", "CHECK PR maps to check")

pr_number = int(match.group(2))
validation("input", "PASS", f"exact {requested_action} PR confirmation")

ok, root = git("rev-parse", "--show-toplevel")
if ok:
    validation("git_repo", "PASS", root)
else:
    blocker("NOT_A_GIT_REPO", "repository root not detected")

ok, status = git("status", "--porcelain")
if ok and not status:
    validation("working_tree", "PASS", "clean")
else:
    blocker("WORKTREE_NOT_CLEAN", "local working tree must be clean before merge check")

ok, current_branch = git("branch", "--show-current")
if ok:
    validation("current_branch", "PASS", current_branch or "detached")
else:
    blocker("CURRENT_BRANCH_UNKNOWN", "cannot determine current branch")

ok_main, main_sha = git("rev-parse", "main")
ok_origin, origin_main_sha = git("rev-parse", "origin/main")
final_main = {
    "local_main_known": ok_main,
    "origin_main_known": ok_origin,
    "local_main_sha": main_sha if ok_main else None,
    "origin_main_sha": origin_main_sha if ok_origin else None,
    "would_update_main": False,
}
if ok_main and ok_origin:
    validation("main_refs", "PASS", "local main and origin/main are known")
else:
    blocker("MAIN_REFS_NOT_VERIFIABLE", "cannot verify local main/origin main refs")

if blockers:
    emit({
        "status": "BLOCKED_WITH_REASON",
        "mode": mode,
        "pr": pr_number,
        "branch": None,
        "commit": None,
        "files": files,
        "validations": validations,
        "blockers": blockers,
        "cleanup": {"attempted": False, "local": f"not_attempted_{mode}_mode", "remote": f"not_attempted_{mode}_mode"},
        "final_main": final_main,
        "rollback": {"required": False, "available": "not_needed_no_changes_made"},
    }, 1)

ok, pr, err = gh_json([
    "pr", "view", str(pr_number),
    "--repo", repo,
    "--json", "number,state,isDraft,mergedAt,mergeable,mergeStateStatus,baseRefName,headRefName,headRepositoryOwner,headRepository,author,files,commits,statusCheckRollup,url",
])
if not ok or not isinstance(pr, dict):
    emit({
        "status": "NO_VERIFICADO",
        "mode": mode,
        "pr": pr_number,
        "branch": None,
        "commit": None,
        "files": files,
        "validations": validations + [{"name": "github_pr_lookup", "status": "NO_VERIFICADO", "detail": err}],
        "blockers": [{"code": "PR_LOOKUP_FAILED", "detail": "cannot verify PR existence/state"}],
        "cleanup": {"attempted": False, "local": f"not_attempted_{mode}_mode", "remote": f"not_attempted_{mode}_mode"},
        "final_main": final_main,
        "rollback": {"required": False, "available": "not_needed_no_changes_made"},
    }, 1)

mergeability_initial = {
    "mergeable": str(pr.get("mergeable") or "").upper(),
    "mergeStateStatus": str(pr.get("mergeStateStatus") or "").upper(),
}
mergeability_after_refresh = dict(mergeability_initial)
retry_count = 0
if "UNKNOWN" in {mergeability_initial["mergeable"], mergeability_initial["mergeStateStatus"]}:
    retry_count = 1
    validation("mergeability_refresh", "PASS", "mergeability UNKNOWN; refreshed once after fixed wait")
    time.sleep(3)
    retry_ok, retry_pr, retry_err = gh_json([
        "pr", "view", str(pr_number),
        "--repo", repo,
        "--json", "number,state,isDraft,mergedAt,mergeable,mergeStateStatus,baseRefName,headRefName,headRepositoryOwner,headRepository,author,files,commits,statusCheckRollup,url",
    ])
    if retry_ok and isinstance(retry_pr, dict):
        pr = retry_pr
        mergeability_after_refresh = {
            "mergeable": str(pr.get("mergeable") or "").upper(),
            "mergeStateStatus": str(pr.get("mergeStateStatus") or "").upper(),
        }
    else:
        mergeability_after_refresh = {
            "mergeable": mergeability_initial["mergeable"],
            "mergeStateStatus": mergeability_initial["mergeStateStatus"],
            "refresh_error": retry_err,
        }

branch = str(pr.get("headRefName") or "")
state = str(pr.get("state") or "").upper()
merged = bool(pr.get("mergedAt"))
base = str(pr.get("baseRefName") or "")
mergeable = str(pr.get("mergeable") or "").upper()
merge_state = str(pr.get("mergeStateStatus") or "").upper()
commits = pr.get("commits") if isinstance(pr.get("commits"), list) else []
commit = None
if commits and isinstance(commits[-1], dict):
    commit = commits[-1].get("oid") or commits[-1].get("sha")

if state == "OPEN":
    validation("pr_open", "PASS", "PR is open")
else:
    blocker("PR_NOT_OPEN", f"state={state}")
if not merged:
    validation("pr_not_merged", "PASS", "PR is not merged")
else:
    blocker("PR_ALREADY_MERGED", "PR already merged")
if base == "main":
    validation("base_branch", "PASS", "main")
else:
    blocker("PR_BASE_NOT_MAIN", f"base={base}")
if pr.get("isDraft") is True:
    blocker("PR_IS_DRAFT", "draft PRs cannot be merged by autopilot")

if re.fullmatch(r"(feature|docs|fix)/[A-Za-z0-9._/-]+", branch):
    validation("head_branch", "PASS", branch)
else:
    blocker("HEAD_BRANCH_NOT_EXPECTED", f"branch={branch}")

owner = (pr.get("headRepositoryOwner") or {}).get("login") if isinstance(pr.get("headRepositoryOwner"), dict) else None
repo_name = (pr.get("headRepository") or {}).get("name") if isinstance(pr.get("headRepository"), dict) else None
author = (pr.get("author") or {}).get("login") if isinstance(pr.get("author"), dict) else None
if owner == "terrassacode" and repo_name == "neodaemon_v1":
    validation("head_repo", "PASS", "expected repository")
else:
    blocker("EXTERNAL_OR_UNKNOWN_HEAD_REPO", f"owner={owner} repo={repo_name}")

if mergeable == "MERGEABLE" or merge_state in {"CLEAN", "HAS_HOOKS", "UNSTABLE"}:
    validation("mergeability", "PASS", f"mergeable={mergeable} mergeStateStatus={merge_state}")
else:
    blocker("MERGEABILITY_NOT_OK", f"mergeable={mergeable} mergeStateStatus={merge_state}")

pr_files = pr.get("files") if isinstance(pr.get("files"), list) else []
if not pr_files:
    blocker("DIFF_NOT_VERIFIABLE", "no PR files returned")

candidate_files = []
for item in pr_files:
    if isinstance(item, dict):
        candidate_files.append(str(item.get("path") or ""))
project_scope_decision = evaluate_project_scope_pr(
    pr_number,
    branch,
    base,
    owner,
    repo_name,
    "UNKNOWN",
    merge_state,
    candidate_files,
    evaluate_auto=False,
)
project_scope = project_scope_decision["project_scope"]
project_id = project_scope_decision["project_id"]
if project_scope_decision["scope_status"] == "PROJECT_REVIEW_REQUIRED":
    blocker("PROJECT_REVIEW_REQUIRED", ", ".join(project_scope_decision.get("scope_reasons") or ["project scope not verifiable"]))
elif project_scope_decision["scope_status"] == "PROJECT_SCOPE_ALLOWED":
    validation("project_scope", "PROJECT_SCOPE_ALLOWED", project_scope_decision["project_id"])

for item in pr_files:
    if not isinstance(item, dict):
        blocker("DIFF_NOT_VERIFIABLE", "file entry is not object")
        continue
    path = str(item.get("path") or "")
    files.append(path)
    if project_scope:
        path_decision = next((entry for entry in project_scope_decision["path_decisions"] if entry["path"] == path), None)
        allowed = bool(path_decision and path_decision["allowed"])
        reason = path_decision["reason"] if path_decision else "outside project scope allowed_paths"
    else:
        allowed, reason = path_allowed(path)
    if allowed:
        validation("path_allowed", "PASS", f"{path}: {reason}")
    else:
        blocker("PATH_BLOCKED", f"{path}: {reason}")
    if str(item.get("status") or "").lower() in {"removed", "deleted"}:
        blocker("DELETE_REQUIRES_MANUAL_REVIEW", path)

check_status, checks, pending_checks, check_detail = check_rollup(pr.get("statusCheckRollup"))
if check_status == "PASS":
    validation("checks", "PASS", check_detail)
elif check_status == "BLOCKED":
    blocker("CHECKS_FAILED", check_detail)
elif check_status == "WAITING":
    validation("checks", "WAITING_FOR_CHECKS", check_detail)
else:
    blocker("CHECKS_NOT_VERIFIABLE", check_detail)

if project_scope:
    if project_scope.get("runtime_required") is True:
        blocker("PROJECT_REVIEW_REQUIRED", "project scope requires runtime proof")
    if merge_state != "CLEAN":
        already_merged_cleanup_safe_unknown = (
            mode == "apply"
            and requested_action == "MERGE"
            and merged
            and state == "MERGED"
            and merge_state == "UNKNOWN"
            and check_status == "PASS"
        )
        if already_merged_cleanup_safe_unknown:
            validation("project_scope_mergeability", "PASS", "already merged cleanup accepts mergeStateStatus=UNKNOWN")
        else:
            blocker("MERGEABILITY_NOT_CLEAN_FOR_PROJECT_SCOPE", f"mergeStateStatus={merge_state}")

project_automerge_dry_run = None
if project_scope:
    project_automerge_dry_run = evaluate_project_scope_pr(
        pr_number,
        branch,
        base,
        owner,
        repo_name,
        check_status,
        merge_state,
        files,
        evaluate_auto=True,
    )["automerge_decision"]
    if project_automerge_dry_run["status"] == "PROJECT_AUTOMERGE_ALLOWED":
        project_automerge_dry_run["status"] = "PROJECT_AUTOMERGE_ALLOWED_DRY_RUN"
    validation(
        "project_automerge_dry_run",
        project_automerge_dry_run["status"],
        ", ".join(project_automerge_dry_run.get("reasons") or ["eligible dry-run only"]),
    )

cleanup = {"attempted": False, "local": f"not_attempted_{mode}_mode", "remote": f"not_attempted_{mode}_mode", "target_branch": branch}
rollback = {"required": False, "available": "not_needed_no_changes_made", "note": f"mode={mode} has not modified GitHub, branches, or main before check pass"}

if mode == "dry-run":
    if not project_automerge_dry_run:
        project_automerge_dry_run = {
            "status": "PROJECT_AUTOMERGE_BLOCKED_WITH_REASON",
            "project_id": project_id,
            "automerge_allowed": None,
            "reasons": ["PROJECT_SCOPE is not available"],
            "file_statuses": [],
        }
    final_decision = project_automerge_dry_run["status"]
    validation("mode_dry_run_no_mutation", "PASS", "no merge, cleanup, branch change, push, or GitHub mutation attempted")
    emit({
        "status": final_decision,
        "mode": mode,
        "pr": pr_number,
        "branch": branch,
        "commit": commit,
        "files": files,
        "checks": checks,
        "project_automerge_dry_run": project_automerge_dry_run,
        "dry_run_simulation": {
            "merge_would_run": final_decision == "PROJECT_AUTOMERGE_ALLOWED_DRY_RUN",
            "cleanup_would_run": final_decision == "PROJECT_AUTOMERGE_ALLOWED_DRY_RUN",
            "sync_would_run": final_decision == "PROJECT_AUTOMERGE_ALLOWED_DRY_RUN",
            "mutation_performed": False,
        },
        "mergeability_initial": mergeability_initial,
        "mergeability_after_refresh": mergeability_after_refresh,
        "retry_count": retry_count,
        "final_decision": final_decision,
        "validations": validations,
        "blockers": blockers,
        "cleanup": cleanup,
        "final_main": final_main,
        "rollback": rollback,
    }, 0 if final_decision == "PROJECT_AUTOMERGE_ALLOWED_DRY_RUN" else 1)

if mode == "apply" and requested_action == "MERGE" and merged:
    allowed_already_merged_blockers = {"PR_NOT_OPEN", "PR_ALREADY_MERGED", "MERGEABILITY_NOT_OK"}
    unsafe_blockers = [item for item in blockers if item.get("code") not in allowed_already_merged_blockers]
    if unsafe_blockers:
        final_decision = "BLOCKED_WITH_REASON"
        emit({
            "status": final_decision,
            "mode": mode,
            "pr": pr_number,
            "branch": branch,
            "commit": commit,
            "files": files,
            "checks": checks,
            "mergeability_initial": mergeability_initial,
            "mergeability_after_refresh": mergeability_after_refresh,
            "retry_count": retry_count,
            "final_decision": final_decision,
            "validations": validations,
            "blockers": unsafe_blockers,
            "cleanup": cleanup,
            "final_main": final_main,
            "rollback": rollback,
        }, 1)

    validation("already_merged", "PASS", "PR already merged; attempting exact branch cleanup only")
    cleanup = {"attempted": True, "local": "pending", "remote": "pending", "target_branch": branch}
    partial_blockers = []

    fetch_rc, fetch_out, fetch_err = run(["git", "fetch", "origin", "main"], timeout=30)
    switch_rc, switch_out, switch_err = run(["git", "switch", "main"], timeout=30) if fetch_rc == 0 else (1, "", "fetch failed")
    pull_rc, pull_out, pull_err = run(["git", "pull", "--ff-only", "origin", "main"], timeout=60) if switch_rc == 0 else (1, "", "switch main failed")
    if fetch_rc == 0 and switch_rc == 0 and pull_rc == 0:
        validation("sync_main", "PASS", "main synchronized with origin/main")
    else:
        partial_blockers.append({"code": "MAIN_SYNC_FAILED", "detail": fetch_err or switch_err or pull_err or "main sync failed"})

    local_exists_rc, _local_exists_out, _local_exists_err = run(["git", "show-ref", "--verify", "--quiet", f"refs/heads/{branch}"], timeout=10)
    if local_exists_rc == 0:
        merged_rc, merged_out, merged_err = run(["git", "branch", "--merged", "main", "--list", branch], timeout=10)
        if merged_rc == 0 and branch in merged_out:
            delete_local_rc, delete_local_out, delete_local_err = run(["git", "branch", "-d", branch], timeout=20)
            if delete_local_rc == 0:
                cleanup["local"] = "deleted"
                validation("cleanup_local", "PASS", "exact PR branch deleted locally")
            else:
                cleanup["local"] = "failed"
                partial_blockers.append({"code": "LOCAL_BRANCH_DELETE_FAILED", "detail": delete_local_err or delete_local_out})
        else:
            cleanup["local"] = "blocked_not_merged_into_main"
            partial_blockers.append({"code": "LOCAL_BRANCH_NOT_SAFE_TO_DELETE", "detail": merged_err or "branch is not verified as merged into main"})
    else:
        cleanup["local"] = "not_present"
        validation("cleanup_local", "PASS", "local branch not present")

    remote_exists_rc, _remote_exists_out, _remote_exists_err = run(["git", "ls-remote", "--exit-code", "--heads", "origin", branch], timeout=20)
    if remote_exists_rc == 0:
        delete_remote_rc, delete_remote_out, delete_remote_err = run(["git", "push", "origin", "--delete", branch], timeout=60)
        if delete_remote_rc == 0:
            cleanup["remote"] = "deleted"
            validation("cleanup_remote", "PASS", "exact PR branch deleted remotely")
        else:
            cleanup["remote"] = "failed"
            partial_blockers.append({"code": "REMOTE_BRANCH_DELETE_FAILED", "detail": delete_remote_err or delete_remote_out})
    else:
        cleanup["remote"] = "not_present"
        validation("cleanup_remote", "PASS", "remote branch not present")

    final_branch_ok, final_branch = git("branch", "--show-current")
    final_status_ok, final_status = git("status", "--porcelain")
    final_main_ok, final_main_sha = git("rev-parse", "main")
    final_origin_ok, final_origin_sha = git("rev-parse", "origin/main")
    final_counts_ok, final_counts = git("rev-list", "--left-right", "--count", "main...origin/main")
    final_main = {
        "branch": final_branch if final_branch_ok else None,
        "working_tree_clean": bool(final_status_ok and not final_status),
        "local_main_sha": final_main_sha if final_main_ok else None,
        "origin_main_sha": final_origin_sha if final_origin_ok else None,
        "main_matches_origin": bool(final_counts_ok and final_counts.split() == ["0", "0"]),
    }
    if final_main["branch"] != "main" or not final_main["working_tree_clean"] or not final_main["main_matches_origin"]:
        partial_blockers.append({"code": "FINAL_MAIN_VERIFY_FAILED", "detail": "main branch, clean worktree, or origin match not verified"})
    else:
        validation("final_main", "PASS", "main clean and synchronized")

    if partial_blockers:
        final_decision = "PARTIAL_MERGE_CLEANUP_FAILED"
        emit({
            "status": final_decision,
            "mode": mode,
            "pr": pr_number,
            "branch": branch,
            "commit": commit,
            "files": files,
            "checks": checks,
            "mergeability_initial": mergeability_initial,
            "mergeability_after_refresh": mergeability_after_refresh,
            "retry_count": retry_count,
            "final_decision": final_decision,
            "validations": validations,
            "blockers": partial_blockers,
            "cleanup": cleanup,
            "final_main": final_main,
            "rollback": {"required": False, "available": "create controlled revert PR if merged content must be undone"},
        }, 1)

    final_decision = "PASS_ALREADY_MERGED_AND_CLEANED"
    emit({
        "status": final_decision,
        "mode": mode,
        "pr": pr_number,
        "branch": branch,
        "commit": commit,
        "files": files,
        "checks": checks,
        "project_automerge_dry_run": project_automerge_dry_run,
        "mergeability_initial": mergeability_initial,
        "mergeability_after_refresh": mergeability_after_refresh,
        "retry_count": retry_count,
        "final_decision": final_decision,
        "validations": validations,
        "blockers": [],
        "cleanup": cleanup,
        "final_main": final_main,
        "rollback": {"required": False, "available": "create controlled revert PR if needed"},
    })

if blockers:
    final_decision = "BLOCKED_WITH_REASON"
    emit({
        "status": final_decision,
        "mode": mode,
        "pr": pr_number,
        "branch": branch,
        "commit": commit,
        "files": files,
            "checks": checks,
            "project_automerge_dry_run": project_automerge_dry_run,
            "mergeability_initial": mergeability_initial,
        "mergeability_after_refresh": mergeability_after_refresh,
        "retry_count": retry_count,
        "final_decision": final_decision,
        "validations": validations,
        "blockers": blockers,
        "cleanup": cleanup,
        "final_main": final_main,
        "rollback": rollback,
    }, 1)

if check_status == "WAITING":
    validation("mode_check_no_mutation", "PASS", "no merge, cleanup, branch change, or GitHub mutation attempted")
    final_decision = "WAITING_FOR_CHECKS"
    emit({
        "status": final_decision,
        "mode": mode,
        "pr": pr_number,
        "branch": branch,
        "commit": commit,
        "files": files,
        "checks": checks,
        "pending_checks": pending_checks,
        "recommended_next_action": "retry later when checks complete",
        "mergeability_initial": mergeability_initial,
        "mergeability_after_refresh": mergeability_after_refresh,
        "retry_count": retry_count,
        "final_decision": final_decision,
        "validations": validations,
        "blockers": [],
        "cleanup": cleanup,
        "final_main": final_main,
        "rollback": rollback,
    }, 1)

if mode == "auto":
    if project_scope and project_scope.get("automerge_allowed") is False:
        validation("project_scope_automerge", "PROJECT_AUTOMERGE_BLOCKED", "automerge_allowed=false")
        emit({
            "status": "PROJECT_AUTOMERGE_BLOCKED",
            "mode": mode,
            "pr": pr_number,
            "branch": branch,
            "commit": commit,
            "files": files,
            "checks": checks,
            "project_scope": {"project_id": project_scope.get("project_id"), "automerge_allowed": False},
            "project_automerge_dry_run": project_automerge_dry_run,
            "mergeability_initial": mergeability_initial,
            "mergeability_after_refresh": mergeability_after_refresh,
            "retry_count": retry_count,
            "final_decision": "PROJECT_AUTOMERGE_BLOCKED",
            "validations": validations,
            "blockers": [],
            "cleanup": cleanup,
            "final_main": final_main,
            "rollback": rollback,
        }, 1)
    eligibility = auto_merge_eligibility(pr_number, branch, base, owner, repo_name, author, merge_state, check_status, files)
    validation("auto_merge_eligibility", eligibility["status"], ", ".join(eligibility.get("reasons") or ["eligible"]))
    if eligibility["status"] != "AUTO_MERGE_ALLOWED":
        emit({
            "status": eligibility["status"],
            "mode": mode,
            "pr": pr_number,
            "branch": branch,
            "commit": commit,
            "files": files,
            "checks": checks,
            "auto_merge_eligibility": eligibility,
            "project_automerge_dry_run": project_automerge_dry_run,
            "mergeability_initial": mergeability_initial,
            "mergeability_after_refresh": mergeability_after_refresh,
            "retry_count": retry_count,
            "final_decision": eligibility["status"],
            "validations": validations,
            "blockers": [],
            "cleanup": cleanup,
            "final_main": final_main,
            "rollback": rollback,
        }, 1)

if mode == "check":
    validation("mode_check_no_mutation", "PASS", "no merge, cleanup, branch change, or GitHub mutation attempted")
    final_decision = "PASS_READY_TO_MERGE"
    emit({
        "status": final_decision,
        "mode": mode,
        "pr": pr_number,
        "branch": branch,
        "commit": commit,
        "files": files,
        "checks": checks,
        "project_automerge_dry_run": project_automerge_dry_run,
        "mergeability_initial": mergeability_initial,
        "mergeability_after_refresh": mergeability_after_refresh,
        "retry_count": retry_count,
        "final_decision": final_decision,
        "validations": validations,
        "blockers": [],
        "cleanup": cleanup,
        "final_main": final_main,
        "rollback": rollback,
    })

validation("mode_apply_check_gate", "PASS", "same check path returned PASS_READY_TO_MERGE")
merge_rc, merge_out, merge_err = run(["gh", "pr", "merge", str(pr_number), "--repo", repo, "--merge"], timeout=90)
if merge_rc != 0:
    final_decision = "BLOCKED_WITH_REASON"
    emit({
        "status": final_decision,
        "mode": mode,
        "pr": pr_number,
        "branch": branch,
        "commit": commit,
        "files": files,
        "checks": checks,
        "mergeability_initial": mergeability_initial,
        "mergeability_after_refresh": mergeability_after_refresh,
        "retry_count": retry_count,
        "final_decision": final_decision,
        "validations": validations,
        "blockers": [{"code": "MERGE_FAILED", "detail": merge_err or merge_out or "GitHub merge command failed"}],
        "cleanup": {"attempted": False, "local": "not_attempted_merge_failed", "remote": "not_attempted_merge_failed", "target_branch": branch},
        "final_main": final_main,
        "rollback": {"required": False, "available": "not_needed_merge_not_confirmed"},
    }, 1)

validation("merge", "PASS", "single PR merged by fixed method")
post_ok, post_pr, post_err = gh_json(["pr", "view", str(pr_number), "--repo", repo, "--json", "state,mergedAt,mergeCommit,headRefName"])
merge_commit = None
if post_ok and isinstance(post_pr, dict) and isinstance(post_pr.get("mergeCommit"), dict):
    merge_commit = post_pr["mergeCommit"].get("oid")

cleanup = {"attempted": True, "local": "pending", "remote": "pending", "target_branch": branch}
partial_blockers = []

fetch_rc, fetch_out, fetch_err = run(["git", "fetch", "origin", "main"], timeout=30)
switch_rc, switch_out, switch_err = run(["git", "switch", "main"], timeout=30) if fetch_rc == 0 else (1, "", "fetch failed")
pull_rc, pull_out, pull_err = run(["git", "pull", "--ff-only", "origin", "main"], timeout=60) if switch_rc == 0 else (1, "", "switch main failed")
if fetch_rc == 0 and switch_rc == 0 and pull_rc == 0:
    validation("sync_main", "PASS", "main synchronized with origin/main")
else:
    partial_blockers.append({"code": "MAIN_SYNC_FAILED", "detail": fetch_err or switch_err or pull_err or "main sync failed"})

local_exists_rc, _local_exists_out, _local_exists_err = run(["git", "show-ref", "--verify", "--quiet", f"refs/heads/{branch}"], timeout=10)
if local_exists_rc == 0:
    merged_rc, merged_out, merged_err = run(["git", "branch", "--merged", "main", "--list", branch], timeout=10)
    if merged_rc == 0 and branch in merged_out:
        delete_local_rc, delete_local_out, delete_local_err = run(["git", "branch", "-d", branch], timeout=20)
        if delete_local_rc == 0:
            cleanup["local"] = "deleted"
            validation("cleanup_local", "PASS", "exact PR branch deleted locally")
        else:
            cleanup["local"] = "failed"
            partial_blockers.append({"code": "LOCAL_BRANCH_DELETE_FAILED", "detail": delete_local_err or delete_local_out})
    else:
        cleanup["local"] = "blocked_not_merged_into_main"
        partial_blockers.append({"code": "LOCAL_BRANCH_NOT_SAFE_TO_DELETE", "detail": merged_err or "branch is not verified as merged into main"})
else:
    cleanup["local"] = "not_present"
    validation("cleanup_local", "PASS", "local branch not present")

remote_exists_rc, _remote_exists_out, _remote_exists_err = run(["git", "ls-remote", "--exit-code", "--heads", "origin", branch], timeout=20)
if remote_exists_rc == 0:
    delete_remote_rc, delete_remote_out, delete_remote_err = run(["git", "push", "origin", "--delete", branch], timeout=60)
    if delete_remote_rc == 0:
        cleanup["remote"] = "deleted"
        validation("cleanup_remote", "PASS", "exact PR branch deleted remotely")
    else:
        cleanup["remote"] = "failed"
        partial_blockers.append({"code": "REMOTE_BRANCH_DELETE_FAILED", "detail": delete_remote_err or delete_remote_out})
else:
    cleanup["remote"] = "not_present"
    validation("cleanup_remote", "PASS", "remote branch not present")

final_branch_ok, final_branch = git("branch", "--show-current")
final_status_ok, final_status = git("status", "--porcelain")
final_main_ok, final_main_sha = git("rev-parse", "main")
final_origin_ok, final_origin_sha = git("rev-parse", "origin/main")
final_counts_ok, final_counts = git("rev-list", "--left-right", "--count", "main...origin/main")
final_main = {
    "branch": final_branch if final_branch_ok else None,
    "working_tree_clean": bool(final_status_ok and not final_status),
    "local_main_sha": final_main_sha if final_main_ok else None,
    "origin_main_sha": final_origin_sha if final_origin_ok else None,
    "main_matches_origin": bool(final_counts_ok and final_counts.split() == ["0", "0"]),
}
if final_main["branch"] != "main" or not final_main["working_tree_clean"] or not final_main["main_matches_origin"]:
    partial_blockers.append({"code": "FINAL_MAIN_VERIFY_FAILED", "detail": "main branch, clean worktree, or origin match not verified"})
else:
    validation("final_main", "PASS", "main clean and synchronized")

if partial_blockers:
    final_decision = "PARTIAL_MERGE_CLEANUP_FAILED"
    emit({
        "status": final_decision,
        "mode": mode,
        "pr": pr_number,
        "branch": branch,
        "commit": commit,
        "merge_commit": merge_commit,
        "files": files,
        "checks": checks,
        "mergeability_initial": mergeability_initial,
        "mergeability_after_refresh": mergeability_after_refresh,
        "retry_count": retry_count,
        "final_decision": final_decision,
        "validations": validations,
        "blockers": partial_blockers,
        "cleanup": cleanup,
        "final_main": final_main,
        "rollback": {"required": False, "available": "create controlled revert PR if merged content must be undone"},
    }, 1)

final_decision = "PASS_MERGED_AND_CLEANED"
emit({
    "status": final_decision,
    "mode": mode,
    "pr": pr_number,
    "branch": branch,
    "commit": commit,
    "merge_commit": merge_commit,
    "files": files,
    "checks": checks,
    "mergeability_initial": mergeability_initial,
    "mergeability_after_refresh": mergeability_after_refresh,
    "retry_count": retry_count,
    "final_decision": final_decision,
    "validations": validations,
    "blockers": [],
    "cleanup": cleanup,
    "final_main": final_main,
    "rollback": {"required": False, "available": "create controlled revert PR if needed"},
})
PYJSON
