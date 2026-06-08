# Operations

## Normal Feature Flow

```text
FEATURE_PROPOSAL → OK FEATURE → execution → validation → PR → Albert merge → OK CLEANUP
```

Use `OPERATOR_CHATGPT_V1` for structured proposals and concise validation output.

For current behavior, use `neodaemon_operating_model_v2.md` as the primary reference. After an objective is approved, NeoDaemon should execute obvious and necessary project-local substeps inside the approved perimeter.

## Rules Of Thumb

- Act only inside the approved scope.
- Use the smallest coherent project scope.
- Treat existing allowlisted actions as compatibility routes, not the target model for normal project delivery.
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
- `OpenClaw-NeoDaemon-Skill/references/neodaemon_operating_model_v2.md`
- `OpenClaw-NeoDaemon-Skill/references/openclaw_role_model_v1.md`
