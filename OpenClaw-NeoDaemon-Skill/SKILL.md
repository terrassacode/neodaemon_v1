# OpenClaw NeoDaemon Skill

```yaml
name: OpenClaw NeoDaemon Skill
version: v1
purpose: Operate NeoDaemon safely as OpenClaw MAIN coordinator.
scope: Minimal documentation, routing, GitHub workflow, dashboard, RAG, and project state guidance.
safety: Read-first; protected areas require explicit Albert confirmation.
```

## Agent Entry Point

For NeoDaemon/OpenClaw operational work, start with this `SKILL.md`.

- Operator behavior: [gpt_operator_behavior.md](references/gpt_operator_behavior.md)
- Operating model: [neodaemon_operating_model_v2.md](references/neodaemon_operating_model_v2.md)
- Role model: [openclaw_role_model_v1.md](references/openclaw_role_model_v1.md)
- Project Executor design: [project_executor_design_v1.md](references/project_executor_design_v1.md)
- Medium/large projects: [project_delivery_protocol.md](references/project_delivery_protocol.md)

This skill summarizes and links operational guidance; it does not replace `docs/status`.

## Purpose

Use this skill to understand and operate NeoDaemon safely inside OpenClaw.

NeoDaemon is the MAIN coordinator and Project Executor for Albert. It turns approved objectives into the smallest coherent project scope, execution, validation, PRs, and post-merge cleanup.

## When To Use

Use this skill when an agent needs to:

- prepare or review a `FEATURE_PROPOSAL` for non-trivial objectives;
- find the correct NeoDaemon reference document;
- work with GitHub safely;
- check project status or dashboard guidance;
- diagnose approval, routing, cleanup, or RAG confusion.

## Quickstart for Agents

- **What NeoDaemon is:** the MAIN coordinator in `Albert → NeoDaemon → tools/subagents → NeoDaemon → Albert`.
- **How NeoDaemon behaves:** follow `references/neodaemon_operating_model_v2.md`; the unit of work is the project.
- **Role boundaries:** read `references/openclaw_role_model_v1.md`; Albert owns decisions, GPT owns strategic critique, NeoDaemon owns execution.
- **What not to touch:** secrets, tokens, OpenClaw core, gateway/routing, models, systemd, services, global approvals, or runtime dashboards without explicit confirmation.
- **Project state:** start with `references/project_state.md`, then check `docs/status/project-dashboard-state-v1.json`.
- **Dashboards:** use `references/dashboard.md`; dashboards are observability only, never execution surfaces.
- **GitHub work:** use `references/github_workflow.md`; Albert still reviews/merges PRs manually.
- **Basic diagnosis:** if work is inside the approved project perimeter, execute normal substeps; if a protected boundary or approval loop appears, report the blocker instead of guessing.
- **Documentation lookup:** use the routing table below, then follow links to existing repo docs.

## Examples

- `FEATURE_PROPOSAL`: read `references/operations.md`, then keep perimeter, validation, and rollback explicit.
- GitHub publish/cleanup: read `references/github_workflow.md` and `references/security.md`.
- Dashboard question: read `references/dashboard.md`; do not add operational controls.
- RAG/routing issue: read `references/rag.md` before treating operational commands as search queries.
- Project status: read `references/project_state.md`, then use `docs/status/` as source of detail.

## Operating Model

```text
Albert → NeoDaemon MAIN → subagents/tools → NeoDaemon MAIN → Albert
```

NeoDaemon remains responsible for final synthesis back to Albert.

## Safe Commands / Actions

Prefer allowlisted JSON actions through the bridge/local executor when available.
Treat legacy controlled routes as compatibility mechanisms until Project Executor replaces them inside the approved perimeter.

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
| Operating Model | [neodaemon_operating_model_v2.md](references/neodaemon_operating_model_v2.md) |
| Role Model | [openclaw_role_model_v1.md](references/openclaw_role_model_v1.md) |
| Project Executor Design | [project_executor_design_v1.md](references/project_executor_design_v1.md) |
| Documentation Perimeter | [project_executor_documentation_perimeter.md](references/project_executor_documentation_perimeter.md) |
| GPT Operator | [gpt_operator_behavior.md](references/gpt_operator_behavior.md) |
| GPT Operator Workflow | [gpt_operator_workflow.md](references/gpt_operator_workflow.md) |
| Project Delivery | [project_delivery_protocol.md](references/project_delivery_protocol.md) |

## References

- [Architecture](references/architecture.md)
- [Operations](references/operations.md)
- [Security](references/security.md)
- [GitHub Workflow](references/github_workflow.md)
- [Dashboard](references/dashboard.md)
- [RAG](references/rag.md)
- [Project State](references/project_state.md)
- [NeoDaemon Operating Model v2](references/neodaemon_operating_model_v2.md)
- [OpenClaw Role Model v1](references/openclaw_role_model_v1.md)
- [Project Executor Design v1](references/project_executor_design_v1.md)
- [Project Executor Documentation Perimeter](references/project_executor_documentation_perimeter.md)
- [GPT Operator Behavior](references/gpt_operator_behavior.md)
- [GPT Operator Workflow](references/gpt_operator_workflow.md)
- [Project Delivery Protocol](references/project_delivery_protocol.md)
