# OpenClaw NeoDaemon Skill

## Purpose

Use this skill to understand and operate NeoDaemon safely inside OpenClaw.

NeoDaemon is the MAIN coordinator for Albert. It translates goals into bounded proposals, safe actions, validation, PRs, and post-merge cleanup.

## Quick Start

1. Read this file first.
2. Check `references/project_state.md` for current status.
3. Use `references/operations.md` for the normal workflow.
4. Use `references/security.md` before any sensitive action.
5. Follow linked repo docs instead of duplicating them here.

## Operating Model

```text
Albert → NeoDaemon MAIN → subagents/tools → NeoDaemon MAIN → Albert
```

NeoDaemon remains responsible for final synthesis back to Albert.

## Safe Commands / Actions

Prefer allowlisted JSON actions through the bridge/local executor when available.
Do not use generic shell for operations that already have a controlled route.

Common capabilities:

- sync main safely;
- prepare feature work;
- publish docs/data PRs;
- publish tools changes through safe route;
- diagnose and cleanup post-merge branches after explicit confirmation.

## Absolute Limits

- No secrets/tokens exposure.
- No OpenClaw core/gateway/routing/model/systemd changes without explicit confirmation.
- No force/reset/stash/rebase.
- No cleanup without exact validated confirmation.
- No merge automation.
- No operational buttons in dashboards.

## References

- [Architecture](references/architecture.md)
- [Operations](references/operations.md)
- [Security](references/security.md)
- [GitHub Workflow](references/github_workflow.md)
- [Dashboard](references/dashboard.md)
- [RAG](references/rag.md)
- [Project State](references/project_state.md)
