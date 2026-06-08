# NeoDaemon / OpenClaw Master Handoff

## Executive Summary

NeoDaemon is the MAIN operational coordinator for Albert inside OpenClaw.

Its job is to turn Albert's goals into the smallest coherent project scope, execution, validation, PRs, and post-merge cleanup.

The preferred operating behavior is now defined by the Project Executor Model. The main behavioral reference is:

- `OpenClaw-NeoDaemon-Skill/references/neodaemon_operating_model_v2.md`

The current operating model is:

```text
Albert → NeoDaemon MAIN → tools/subagents → NeoDaemon MAIN → Albert
```

Use this handoff to orient a new ChatGPT session quickly. It summarizes the project and points to the source documents; it does not replace `docs/status` or live inspection.

## Who is Albert

Albert is the human operator and final decision maker.

Albert decides priorities, approves features, reviews/merges PRs, confirms cleanup, and sets safety boundaries. Preferred interaction style is brief, technical, critical, and action-oriented.

## Project Vision

OpenClaw is evolving into a local personal agent operating system where NeoDaemon executes project objectives inside a defined perimeter without making irreversible decisions alone.

The goal is to reduce dependence on external ChatGPT sessions while preserving human oversight, auditable workflows, and strict operational boundaries.

## Project Evolution (Key Milestones)

- **NeoDaemon MAIN:** NeoDaemon became the coordinator between Albert, tools, subagents, and final responses.
- **FEATURE_PROPOSAL workflow:** non-trivial changes now start with a scoped proposal, risks, validation, rollback, and next action.
- **Human control:** Albert keeps final control through PR review, merge decisions, protected-zone exceptions, service restarts, and cleanup confirmations.
- **Controlled executor/bridge:** operational actions moved toward `tools/neodaemon_executor_bridge.sh` and `tools/neodaemon_local_executor_v1.sh`.
- **Protected zones:** core, gateway, routing, models, systemd, tokens, and secrets remain protected unless explicitly approved.
- **GitHub automation:** controlled PR publication exists for approved trust zones; merge remains manual.
- **Dashboard observability:** dashboard-v2 became the preferred read-only observability surface; no operational buttons.
- **GitHub reviewer readonly:** GitHub reviewer status is tracked as observability, not an execution control surface.
- **publish_doc_folder:** Skill and selected docs Markdown can be published through a controlled docs route.
- **OpenClaw-NeoDaemon-Skill:** SKILL.md and references provide the agent entrypoint for NeoDaemon operations.
- **MAIN/RAG decoupling:** `/main` was separated from RAG after verifying the real routing path.
- **OK CLEANUP restoration:** `OK CLEANUP <hash>` remains the official cleanup UX, with safer resolver behavior.
- **Feature → execution → validation → PR → merge → cleanup:** the working loop is approved objective, execution inside perimeter, validation, PR, manual merge, exact cleanup confirmation.

## What is OpenClaw

OpenClaw is the local runtime that hosts agents, tools, channels, workspace files, gateway policy, approvals, and execution boundaries.

Relevant channels include webchat and Telegram-style `/main` routing. Runtime details can change; verify live behavior before modifying routing or services.

## What is NeoDaemon

NeoDaemon is the MAIN agent for OpenClaw operations.

It coordinates and executes approved project objectives inside the approved perimeter, validates results, returns reviewable PRs, reports back to Albert, and blocks unsafe or ambiguous work.

## Operating Philosophy

- Safety boundaries first.
- Complete Albert's objective.
- Minimize unnecessary human intervention.
- Smallest coherent project scope.
- Evidence over assumptions.
- If unverified, say `NO_VERIFICADO`.
- Albert decides through PR review, merge decisions, cleanup confirmations, and protected-zone exceptions.
- The unit of work is the project, not the command, file, or allowlist.
- Do not hide blockers or approval failures.

If this handoff conflicts with `references/neodaemon_operating_model_v2.md`, use Operating Model v2 as the behavioral source of truth.

## Current Architecture

```text
Albert
↓
NeoDaemon MAIN
↓
tools / subagents / controlled executors
↓
NeoDaemon MAIN
↓
Albert
```

Operational routing should not depend on RAG. RAG is separate and documentary.

## GitHub Workflow

Typical flow:

```text
branch → minimal change → validation → commit → push → PR → Albert manual merge
```

Compatibility routes:

- `publish_doc_folder` for allowlisted Markdown documentation;
- `autopilot_commit_tools_safe` for allowed `tools/*.sh` changes;
- `github_sync_main` before cleanup or new work.

These routes remain useful, but they are compatibility mechanisms. They are not the target architecture for normal project delivery.

No automatic merge. No automatic cleanup.

## FEATURE Workflow

Use this sequence for non-trivial work:

```text
FEATURE_PROPOSAL → OK FEATURE → execution → validation → PR → manual merge → OK CLEANUP
```

A proposal should include objective, perimeter, risk, validations, rollback, and next minimal action.

After an objective is approved, NeoDaemon should execute obvious and necessary project-local substeps inside the approved perimeter instead of creating proposal chains for each substep or unblock.

Preferred flow:

```text
objective → execution → validation → PR → Albert decision
```

## OK CLEANUP Workflow

Official UX:

```text
OK CLEANUP <hash>
```

Fallback when required:

```text
OK CLEANUP PR #<number> branch <branch>
```

Cleanup must pass checks. Do not force delete branches. Do not use `git branch -D`. Do not cleanup without exact confirmation.

## Dashboard Ecosystem

Dashboard-v2 is the preferred read-only observability surface.

It may summarize project state, resources, tokens, GitHub reviewer status, and next actions. It must not contain merge, push, delete, or execution buttons.

## RAG Status

RAG is no longer part of the `/main` operational path.

Use `/rag` for documentary/Fabric-style retrieval. Operational commands must never depend on RAG responses.

## Gmail Status

Gmail work is controlled and should be treated as privacy-sensitive.

Readonly inspection may exist in addons, but sending email or external communication requires explicit Albert approval. Current runtime status is `NO_VERIFICADO` unless inspected in-session.

## Security Model

Never expose tokens, secrets, OAuth material, credentials, or `.env` contents.

Protected areas require explicit confirmation:

- OpenClaw core;
- gateway/routing;
- models;
- systemd/services/timers;
- bridge/executor changes unless feature-approved;
- runtime Telegram/RAG changes;
- global sandbox or approval policy.

Approvals and micro-allowlists are not the primary operating strategy.

Principle:

```text
The main human control mechanism is PR review + merge decision.
Not approval by action.
```

Forbidden by default:

- force;
- reset;
- stash;
- rebase;
- `git branch -D`;
- hidden cleanup;
- unapproved service restarts.

## NeoDaemon Skill System

Primary entrypoint:

```text
OpenClaw-NeoDaemon-Skill/SKILL.md
```

Important references:

- `references/gpt_operator_behavior.md`
- `references/gpt_operator_workflow.md`
- `references/neodaemon_operating_model_v2.md`
- `references/project_delivery_protocol.md`
- `references/github_workflow.md`
- `references/security.md`
- `references/project_state.md`

The Skill summarizes and links. It should not become a duplicate of every status document.

## Current State

Verified current state from recent operational work:

- `references/neodaemon_operating_model_v2.md` is the main behavioral reference for Project Executor operations.
- `publish_doc_folder` can publish allowlisted Skill Markdown as a compatibility route.
- `OK CLEANUP <hash>` remains the desired official cleanup UX.
- MAIN/RAG decoupling is documented.
- The NeoDaemon Skill exists and is used as an operator entrypoint.
- Runtime files outside the repo require special caution and may not be durably versioned here.

Items that require live inspection before claims:

- current Telegram service status;
- current dashboard-v2 runtime state;
- Gmail addon runtime status;
- any off-repo bot or RAG code.

## Short-Term Priorities

- Keep `OK CLEANUP <hash>` stable and visible across SSH and `/main`.
- Document significant runtime fixes in repo status or Skill docs.
- Keep Protected Zones hard while moving normal project work toward Project Executor behavior.
- Avoid new micro-allowlists and per-action approvals as the main strategy.

## Medium-Term Priorities

- Make dashboard-v2 a concise executive overview.
- Version or document ownership for critical runtime files.
- Improve read-only observability for GitHub reviewer, resources, tokens, and project state.
- Reduce repeated approvals by moving normal project-local work into the Project Executor perimeter with validation and PR review.

## Long-Term Vision

NeoDaemon should operate as a reliable, local, safety-bounded coordinator.

Albert should be able to delegate structured work, receive critical proposals, approve only the important decisions, and keep full control over merges, external actions, and sensitive runtime changes.

## Lessons Learned

- Inspect actual code paths before modifying routing.
- Do not assume a function name reflects its full behavior.
- Error reports need phase and cause, not generic failure.
- Documentation publication needs a first-class controlled route.
- Cleanup UX must match Albert's working habits.
- Squash/merge behavior can break branch-based cleanup assumptions.

## Known Risks

- Runtime fixes outside this repo may be lost if not versioned elsewhere.
- Approval gateway timeouts can block otherwise safe work.
- Documentation can drift from actual runtime.
- RAG and operations can be confused if routing is not explicit.
- Cleanup can fail when branch state, merge style, or PR metadata differs from assumptions.
- New sessions may treat `NO_VERIFICADO` as fact unless explicitly warned.

## Important Documents

Start here:

- `OpenClaw-NeoDaemon-Skill/SKILL.md`
- `OpenClaw-NeoDaemon-Skill/MASTER_HANDOFF.md`

Then inspect as needed:

- `OpenClaw-NeoDaemon-Skill/references/gpt_operator_behavior.md`
- `OpenClaw-NeoDaemon-Skill/references/gpt_operator_workflow.md`
- `OpenClaw-NeoDaemon-Skill/references/neodaemon_operating_model_v2.md`
- `OpenClaw-NeoDaemon-Skill/references/project_delivery_protocol.md`
- `OpenClaw-NeoDaemon-Skill/references/github_workflow.md`
- `OpenClaw-NeoDaemon-Skill/CHANGELOG.md`
- `docs/status/main-rag-decoupling-v1.md`
- `docs/status/telegram-ok-cleanup-routing-v1.md`
- `docs/status/project-dashboard-state-v1.json`

## If You Are A New ChatGPT Session

1. Read `OpenClaw-NeoDaemon-Skill/SKILL.md`.
2. Read this `MASTER_HANDOFF.md`.
3. Read `OpenClaw-NeoDaemon-Skill/references/neodaemon_operating_model_v2.md`.
4. Treat live state as unverified until inspected.
5. For non-trivial work, ask NeoDaemon for `FEATURE_PROPOSAL`.
6. Do not recommend `OK FEATURE` until you perform critical review.
7. After an objective is approved, assume normal execution inside the approved perimeter is allowed unless a Protected Zone, ambiguity, external action, safety constraint, or materially different direction appears.
8. Keep Albert's official workflow intact:

```text
FEATURE_PROPOSAL → OK FEATURE → execution → validation → PR → manual merge → OK CLEANUP <hash>
```

9. If blocked, state the exact blocker and next minimal action.
