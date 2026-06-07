# Security

## Hard Limits

Do not touch without explicit confirmation:

- OpenClaw core;
- gateway/routing;
- models;
- systemd/services/timers;
- secrets/tokens/OAuth/credentials;
- global sandbox or approvals config.

## Git Safety

Forbidden by default:

- force;
- reset;
- stash;
- rebase;
- `git branch -D`;
- branch cleanup without validated confirmation.

## Cleanup Safety

Accepted confirmations:

```text
OK CLEANUP PR #<number> branch <branch>
OK CLEANUP <short_hash>
```

The assistant must prove a unique candidate and `cleanup_ready=true`; otherwise block.

## Sources To Read

- `docs/GITHUB_OPERATOR_SKILL_V1.md`
- `docs/status/ssh-and-hash-cleanup-workflow-v1.md`
