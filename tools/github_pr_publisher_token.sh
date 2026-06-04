#!/usr/bin/env bash
set -euo pipefail

die() {
  echo "BLOCK: $*" >&2
  exit 1
}

usage() {
  cat <<'USAGE'
GITHUB_PR_PUBLISHER_TOKEN

Usage:
  OK_GITHUB=1 tools/github_pr_publisher_token.sh <branch-name>

Purpose:
  Push a branch using GitHub token via temporary GIT_ASKPASS.

Safety:
  - Requires OK_GITHUB=1
  - No token printing
  - No git config --global
  - No credential persistence
  - No force push
  - No merge
  - No branch deletion
USAGE
}

[ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] && {
  usage
  exit 0
}

[ "$#" -eq 1 ] || die "requires: <branch-name>"

branch="$1"

[ "${OK_GITHUB:-0}" = "1" ] || die "publish requires OK_GITHUB=1"

current="$(git branch --show-current)"
[ "$current" = "$branch" ] || die "current branch must match branch-name"

[ "$branch" != "main" ] || die "refusing to push main"

if [ -n "$(git status --porcelain)" ]; then
  git status --short >&2
  die "repo must be clean"
fi

SECRET_FILE="$HOME/.openclaw/neodaemon/secrets/github.env"

[ -f "$SECRET_FILE" ] || die "missing github.env"

perms="$(stat -c '%a' "$SECRET_FILE")"
[ "$perms" = "600" ] || die "github.env must have chmod 600"

set -a
# shellcheck disable=SC1090
source "$SECRET_FILE"
set +a

[ -n "${GITHUB_TOKEN:-}" ] || die "missing GITHUB_TOKEN"
[ -n "${GITHUB_USER:-}" ] || die "missing GITHUB_USER"

ASKPASS_FILE="$(mktemp)"

cat > "$ASKPASS_FILE" <<EOF
#!/usr/bin/env bash
case "\$1" in
  *Username*) echo "${GITHUB_USER}" ;;
  *Password*) echo "${GITHUB_TOKEN}" ;;
  *) echo "" ;;
esac
EOF

chmod 700 "$ASKPASS_FILE"

cleanup() {
  rm -f "$ASKPASS_FILE"
  unset GITHUB_TOKEN
  unset GITHUB_USER
}

trap cleanup EXIT

echo "TOKEN_PUSH_CHECKS_OK"
echo "branch: $branch"

GIT_ASKPASS="$ASKPASS_FILE" \
GIT_TERMINAL_PROMPT=0 \
git push -u origin "$branch"

echo "PUSH_OK"
echo "branch: $branch"
echo "No merge performed."
echo "No branch deletion performed."
