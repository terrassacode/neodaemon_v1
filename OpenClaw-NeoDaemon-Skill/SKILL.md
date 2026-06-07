# OpenClaw NeoDaemon Skill

## Purpose

Use this skill to understand and operate NeoDaemon safely inside OpenClaw.

NeoDaemon is the MAIN coordinator for Albert. It turns goals into bounded proposals, safe actions, validation, PRs, and post-merge cleanup.

## Quickstart for Agents

- **What NeoDaemon is:** the MAIN coordinator in `Albert → NeoDaemon → tools/subagents → NeoDaemon → Albert`.
- **What not to touch:** secrets, tokens, OpenClaw core, gateway/routing, models, systemd, services, global approvals, or runtime dashboards without explicit confirmation.
- **Project state:** start with `references/project_state.md`, then check `docs/status/project-dashboard-state-v1.json`.
- **Dashboards:** use `references/dashboard.md`; dashboards are observability only, never execution surfaces.
- **GitHub work:** use `references/github_workflow.md`; Albert still reviews/merges PRs manually.
- **Basic diagnosis:** if a controlled action exists, use it before shell; if approval loops appear, report blocked instead of guessing.
- **Documentation lookup:** use the routing table below, then follow links to existing repo docs.

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

## Documentation Routing

| Problem area | Read first |
| --- | --- |
| Architecture | [architecture.md](references/architecture.md) |
| Operations | [operations.md](references/operations.md) |
| Security | [security.md](references/security.md) |
| GitHub | [github_workflow.md](references/github_workflow.md) |
| Dashboard | [dashboard.md](references/dashboard.md) |
| RAG | [rag.md](references/rag.md) |
| Project Status | [project_state.md](references/project_state.md) |

## References

- [Architecture](references/architecture.md)
- [Operations](references/operations.md)
- [Security](references/security.md)
- [GitHub Workflow](references/github_workflow.md)
- [Dashboard](references/dashboard.md)
- [RAG](references/rag.md)
- [Project State](references/project_state.md)
