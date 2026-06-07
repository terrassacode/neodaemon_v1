# GitHub Workflow

## Current Capabilities

- Docs/data publication: `docs-autopilot-commit`.
- Tools publication: `autopilot_commit_tools_safe` via bridge.
- Main sync: `github_sync_main`.
- Post-merge cleanup: `github_post_merge_cleanup_assistant`.
- Cleanup by hash: `OK CLEANUP <short_hash>`.

## Merge Policy

Use Merge commit for operational features until squash-aware cleanup exists.

## Human Control

Albert still reviews and merges PRs manually. NeoDaemon does not auto-merge.

## Sources To Read

- `docs/GITHUB_EXECUTOR_V1.md`
- `docs/status/ssh-and-hash-cleanup-workflow-v1.md`
- `docs/status/autopilot-docs-publish-v1.md` if present
