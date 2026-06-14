# Project Scope Proposal Contract

## 1. Purpose

When Albert wants to start a new project, NeoDaemon must propose a `PROJECT_SCOPE_PROPOSAL` before implementation work begins.

The proposal exists to prevent accidental perimeter growth, repeated allowlist PRs, technical path decisions by Albert, and discovery loops.

## 2. Input

A project can start from a short project identifier or a natural-language request.

Examples:

```text
PROJECT_IMAGE_INBOX
```

```text
Quiero crear Image Inbox
```

NeoDaemon converts the input into a scoped proposal instead of immediately creating implementation PRs.

## 3. PROJECT_SCOPE_PROPOSAL

A `PROJECT_SCOPE_PROPOSAL` must contain:

- `project_id`
- `objective`
- `allowed_paths`
- `blocked_paths`
- `max_prs`
- `max_risk`
- `validations`
- `exit_conditions`
- `next_action`

The proposal must be specific enough for GPT to audit and narrow enough for PR Guardian to enforce.

## 4. Roles

### NeoDaemon

NeoDaemon:

- proposes the scope;
- does not auto-approve the scope;
- does not work outside the approved scope.

### GPT

GPT:

- audits the scope;
- detects risks;
- proposes reducing or accepting the scope.

### Albert

Albert:

- does not interpret technical routes directly;
- decides one of:

```text
OK PROJECT SCOPE
STOP PROJECT
```

Albert keeps final authority, but GPT carries the technical audit burden.

## 5. Outputs

Allowed outputs are:

```text
PROJECT_SCOPE_PROPOSAL
SCOPE_APPROVED
SCOPE_REDUCE_REQUIRED
SCOPE_REJECTED
PROJECT_REVIEW_REQUIRED
```

Meanings:

- `PROJECT_SCOPE_PROPOSAL`: NeoDaemon proposes the project perimeter.
- `SCOPE_APPROVED`: GPT considers the proposed scope acceptable.
- `SCOPE_REDUCE_REQUIRED`: GPT requires a narrower perimeter.
- `SCOPE_REJECTED`: GPT finds the proposal unsafe or unsuitable.
- `PROJECT_REVIEW_REQUIRED`: the project cannot proceed without review.

## 6. Rules

- deny-by-default;
- use the minimum viable scope;
- block sensitive routes and materials;
- block broad wildcards;
- if there is doubt, return:

```text
PROJECT_REVIEW_REQUIRED
```

No project should start from improvised allowlist expansion.

## 7. Example: PROJECT_IMAGE_INBOX

Example proposal shape:

```text
project_id: PROJECT_IMAGE_INBOX
objective: create a minimal Image Inbox flow for controlled image intake
allowed_paths:
  - extensions/image-inbox/**
  - scripts/project/image_inbox_*.py
  - dashboard-v2/operational-control-plane/**
  - OpenClaw-NeoDaemon-Skill/references/image_inbox_*.md
blocked_paths:
  - gateway/**
  - runtime/**
  - models/**
  - other plugins
  - environment configuration files
  - global package-lock
max_prs: 4
max_risk: MEDIUM
validations:
  - PR Guardian scope check
  - checks SUCCESS
  - mergeability CLEAN
  - no upload before explicit route validation
exit_conditions:
  - health route validated
  - upload route validated
  - Control Panel integration validated
  - or PROJECT_REVIEW_REQUIRED
next_action: GPT_SCOPE_AUDIT
```

This example is not automatic approval. GPT must audit it and Albert must decide whether to continue.

## 8. Permanent Rule

Projects are born through `PROJECT_SCOPE_PROPOSAL`.

They must never start through improvised allowlist expansion.
