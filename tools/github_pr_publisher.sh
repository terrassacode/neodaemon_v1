#!/usr/bin/env bash
set -euo pipefail

die() {
  echo "BLOCK: $*" >&2
  exit 1
}

usage() {
  cat <<'USAGE'
GITHUB_PR_PUBLISHER

Usage:
  OK_GITHUB=1 tools/github_pr_publisher.sh <branch-name> <pr-title> <pr-body-file>

Purpose:
  Push the current approved branch and create a pull request against main.

Safety:
  - Requires OK_GITHUB=1.
  - Does not merge.
  - Does not delete branches.
  - Does not force push.
  - Does not print token.
  - Requires clean repo.
  - Requires current branch to match branch-name.
USAGE
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

json_escape() {
  python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
}

api_get() {
  url="$1"
  curl -sS \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    "$url"
}

api_post() {
  url="$1"
  payload="$2"
  curl -sS \
    -X POST \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "Content-Type: application/json" \
    "$url" \
    --data "$payload"
}

main() {
  [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] && {
    usage
    exit 0
  }

  [ "$#" -eq 3 ] || die "requires: <branch-name> <pr-title> <pr-body-file>"

  branch="$1"
  title="$2"
  body_file="$3"

  require_safe_branch_name "$branch"

  [ "${OK_GITHUB:-0}" = "1" ] || die "publish requires OK_GITHUB=1"
  [ -f "$body_file" ] || die "PR body file not found: $body_file"

  current="$(git branch --show-current)"
  [ "$current" = "$branch" ] || die "current branch must match branch-name. current=$current expected=$branch"

  [ "$branch" != "main" ] || die "refusing to publish main"

  if [ -n "$(git status --porcelain)" ]; then
    git status --short >&2
    die "repo must be clean before publish"
  fi

  [ -f "$HOME/.openclaw/neodaemon/secrets/github.env" ] || die "missing github.env"

  perms="$(stat -c '%a' "$HOME/.openclaw/neodaemon/secrets/github.env")"
  [ "$perms" = "600" ] || die "github.env must have chmod 600"

  set -a
  # shellcheck disable=SC1090
  source "$HOME/.openclaw/neodaemon/secrets/github.env"
  set +a

  [ -n "${GITHUB_TOKEN:-}" ] || die "missing GITHUB_TOKEN"
  [ -n "${GITHUB_USER:-}" ] || die "missing GITHUB_USER"

  repo="${GITHUB_REPO:-terrassacode/neodaemon_v1}"
  owner="${repo%%/*}"

  echo "PUBLISH_CHECKS_OK"
  echo "repo: $repo"
  echo "branch: $branch"
  echo "base: main"

  existing_prs="$(api_get "https://api.github.com/repos/${repo}/pulls?head=${owner}:${branch}&base=main&state=open")"
  existing_url="$(printf '%s' "$existing_prs" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d[0].get("html_url","") if isinstance(d,list) and d else "")')"

  if [ -n "$existing_url" ]; then
    echo "PR_EXISTS"
    echo "url: $existing_url"
    unset GITHUB_TOKEN
    unset GITHUB_USER
    exit 0
  fi

  if ! git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
  echo "BLOCKED: branch '$branch' does not exist on origin. Run github_pr_publisher_token.sh first." >&2
  exit 1
    fi

  body="$(cat "$body_file")"
  title_json="$(printf '%s' "$title" | json_escape)"
  body_json="$(printf '%s' "$body" | json_escape)"
  head_json="$(printf '%s' "$branch" | json_escape)"

  payload="$(cat <<EOF
{
  "title": ${title_json},
  "head": ${head_json},
  "base": "main",
  "body": ${body_json}
}
EOF
)"

  response="$(api_post "https://api.github.com/repos/${repo}/pulls" "$payload")"

  pr_number="$(printf '%s' "$response" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("number",""))')"
  pr_url="$(printf '%s' "$response" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("html_url",""))')"
  pr_base="$(printf '%s' "$response" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("base",{}).get("ref",""))')"
  pr_head="$(printf '%s' "$response" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("head",{}).get("ref",""))')"

  [ -n "$pr_number" ] || {
    echo "BLOCK: PR creation failed" >&2
    printf '%s\n' "$response" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("message","unknown error"))' >&2
    unset GITHUB_TOKEN
    unset GITHUB_USER
    exit 1
  }

  [ "$pr_base" = "main" ] || die "created PR base is not main"
  [ "$pr_head" = "$branch" ] || die "created PR head does not match branch"

  echo "PR_CREATED"
  echo "number: $pr_number"
  echo "url: $pr_url"
  echo "base: $pr_base"
  echo "head: $pr_head"
  echo "No merge performed."
  echo "No branch deletion performed."

  unset GITHUB_TOKEN
  unset GITHUB_USER
}

main "$@"

