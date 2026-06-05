#!/usr/bin/env bash
set -euo pipefail

branch="$1"
title="$2"
body_file="$3"

OK_GITHUB=1 tools/github_pr_publisher_token.sh "$branch"
OK_GITHUB=1 tools/github_pr_publisher.sh "$branch" "$title" "$body_file"
