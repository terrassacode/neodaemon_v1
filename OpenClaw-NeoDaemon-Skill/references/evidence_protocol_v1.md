# NeoDaemon Evidence Protocol V1

## Status

Design only.

This document does not change runtime behavior.

## Goal

Define how NeoDaemon should answer GPT when asked about project decisions, rules, or current project state.

GPT should reason, criticize, and explain.

NeoDaemon should gather evidence, read canonical documents, and return verifiable sources.

This protocol does not introduce RAG, embeddings, runtime loading, or a new knowledge system implementation.

## When to use this protocol

Use this protocol when GPT or Albert asks about:

- a project decision;
- an operating rule;
- a safety boundary;
- a workflow state;
- whether something is implemented or only designed;
- which source is authoritative;
- conflicts between memory, project files, PR history, or runtime evidence.

Do not use this protocol for simple execution acknowledgements, exact merge confirmations, or trivial file existence checks unless evidence is explicitly requested.

## Source hierarchy

NeoDaemon should prefer sources in this order:

1. Runtime evidence from controlled read-only checks.
2. Merged PR evidence and PR Guardian output.
3. Project registry files such as `task_manager/projects/neodaemon.json`.
4. Skill references under `OpenClaw-NeoDaemon-Skill/references/`.
5. Root CORECLAW files such as `AGENTS.md`, `SOUL.md`, `USER.md`, `TOOLS.md`, and main/private `MEMORY.md` when allowed.
6. Daily notes or conversational summaries.

If a lower source conflicts with a higher source, report `CONFLICT` unless the lower source is clearly stale.

## Response format

NeoDaemon should return structured evidence:

```text
status: VERIFIED | PARTIAL | NOT_FOUND | CONFLICT
summary: short answer
confidence: HIGH | MEDIUM | LOW
canonical_sources:
  - path or PR reference
related_sources:
  - path or PR reference
findings:
  - concise evidence item
limits:
  - what is not proven
next_action:
  - minimal safe next action
```

## Status values

### VERIFIED

Use when the answer is supported by canonical evidence and no relevant conflict is found.

### PARTIAL

Use when some evidence exists, but one requested part is missing or runtime proof is absent.

### NOT_FOUND

Use when NeoDaemon checked the expected canonical places and found no evidence.

### CONFLICT

Use when two credible sources disagree, or when design says one thing but runtime evidence says another.

## canonical_sources

`canonical_sources` must contain only the strongest sources used to answer.

Canonical sources are the primary sources that directly support the answer.

There may be more than one canonical source when the sources are complementary.

If candidate canonical sources conflict, apply `coreclaw_source_hierarchy_v1.md` and report `CONFLICT` unless one source is clearly stale.

Examples:

- merged PR number;
- PR Guardian output;
- project registry JSON;
- specific Skill reference file;
- runtime proof output.

Do not place weak or merely related context in `canonical_sources`.

Do not inflate `canonical_sources` with tangential documents.

If an expected source is missing, return `PARTIAL` or explain why the source was omitted.

## related_sources

`related_sources` may contain helpful context that is not the authority.

Related sources are useful but secondary.

They may explain history, implementation attempts, or background, but they should not be treated as the basis for `VERIFIED` unless promoted by the source hierarchy.

Examples:

- design documents;
- historical PRs;
- MEMORY.md summaries;
- daily notes.

## summary

The summary should answer directly.

It should not hide uncertainty.

If evidence is partial, say what is missing.

## confidence

Use:

- `HIGH` when canonical evidence is current and direct;
- `MEDIUM` when evidence is indirect but consistent;
- `LOW` when evidence is old, incomplete, or inferred.

## Conflict handling

If there is conflict:

1. Report `status: CONFLICT`.
2. Name the conflicting sources.
3. Prefer the source hierarchy.
4. Do not silently reconcile contradictions.
5. Recommend the smallest action to resolve the conflict.

## What NeoDaemon must not do

NeoDaemon must not:

- invent sources;
- claim runtime proof from design documents;
- treat MEMORY.md as public/shared context;
- expose private memory in group/shared contexts;
- expand scope while answering evidence questions;
- create RAG, embeddings, or knowledge documents unless explicitly approved;
- modify runtime, gateway, scripts, executor, or project files while only answering an evidence query;
- report `VERIFIED` without canonical evidence.

## Example: Human Approval

```text
status: VERIFIED
summary: Human Approval exists to prevent unsafe external or sensitive mutations without Albert's explicit confirmation.
confidence: HIGH
canonical_sources:
  - OpenClaw-NeoDaemon-Skill/references/approval_strategy_contract.md
  - OpenClaw-NeoDaemon-Skill/references/approval_exit_policy.md
related_sources:
  - OpenClaw-NeoDaemon-Skill/references/project_delivery_protocol.md
findings:
  - Sensitive or external actions require explicit approval.
  - Controlled routes should replace repeated approval loops.
limits:
  - This answer does not inspect current pending approvals.
next_action:
  - Use exact approval/merge confirmations only when required.
```

## Example: CORECLAW runtime bridge

```text
status: PARTIAL
summary: CORECLAW source files and project reference bridge exist, but runtime loading is not verified.
confidence: HIGH
canonical_sources:
  - task_manager/projects/neodaemon.json
  - scripts/project/coreclaw_startup_context_audit_v1.py output
  - OpenClaw-NeoDaemon-Skill/references/coreclaw_startup_context_loader_design_v1.md
related_sources:
  - OpenClaw-NeoDaemon-Skill/references/coreclaw_source_hierarchy_v1.md
  - OpenClaw-NeoDaemon-Skill/references/neodaemon_knowledge_system_design_v1.md
findings:
  - AGENTS.md, SOUL.md, USER.md, TOOLS.md, and MEMORY.md exist.
  - Project reference bridge records expected CORECLAW startup references.
  - runtime_loading_verified=false.
  - missing_runtime_bridge=true.
limits:
  - No runtime loader implementation is proven.
  - MEMORY.md remains main/private only.
next_action:
  - Design or implement the runtime bridge only with explicit approval.
```

## Non-goals

This protocol does not create:

- RAG;
- embeddings;
- automatic source indexing;
- runtime loaders;
- gateway changes;
- new knowledge documents;
- executor actions.
