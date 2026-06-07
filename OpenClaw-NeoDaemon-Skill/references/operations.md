# Operations

## Normal Feature Flow

```text
FEATURE_PROPOSAL → OK FEATURE → implement minimal change → validate → PR → Albert merge → OK CLEANUP
```

Use `OPERATOR_CHATGPT_V1` for structured proposals and concise validation output.

## Rules Of Thumb

- Act only inside the approved scope.
- Prefer existing allowlisted actions.
- Report blockers instead of guessing approval routes.
- Keep final reports short: result, branch, commit, PR, files, validations.

## Troubleshooting

- Approval timeout: do not retry blindly; use bridge/action route or report blocked.
- Dirty repo: stop and diagnose before switching branches.
- Cleanup blocked: trust the executor; ask for manual review.

## Sources To Read

- `docs/FEATURE_WORKFLOW_V1.md`
- `docs/OPERATOR_CHATGPT_V1.md`
- `docs/status/post-merge-cleanup-assistant-handoff-v1.md`
