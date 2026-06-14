# Project Scoped Perimeter Contract

## 1. Purpose

Allow each project to have an approved working perimeter.

A project perimeter defines where NeoDaemon may work, what must remain blocked, and when the project must return to review instead of expanding by accident.

## 2. Problem

The current system often requires allowlists to be expanded file by file.

That creates:

- repetitive small PRs;
- unnecessary blockers;
- slow project flow;
- unclear boundaries between approved work and new risk.

A project-scoped perimeter solves this by approving a minimum viable set of paths and rules before implementation work starts.

## 3. Project Scope

Each `PROJECT_SCOPE` must include:

- `project_id`
- `objective`
- `allowed_paths`
- `blocked_paths`
- `max_prs`
- `max_risk`
- `validation_rules`
- `exit_conditions`

The scope is a contract. It is not permission to work outside the listed paths or outside the stated risk limit.

## 4. Roles

### NeoDaemon

NeoDaemon:

- proposes `PROJECT_SCOPE`;
- works only inside the approved scope;
- returns `PROJECT_REVIEW_REQUIRED` if it needs to leave the approved scope.

### GPT

GPT:

- audits `PROJECT_SCOPE`;
- validates whether the scope is too broad;
- detects risks;
- may request perimeter reduction;
- recommends accepting or rejecting the scope.

### Albert

Albert:

- does not interpret technical routes directly;
- decides whether to continue or stop based on GPT's audit;
- keeps final veto authority.

### PR Guardian

PR Guardian:

- checks that every PR respects the approved scope;
- blocks PRs outside the perimeter.

## 5. Approval Flow

NeoDaemon proposes:

```text
PROJECT_SCOPE_PROPOSAL
```

GPT responds with one of:

```text
SCOPE_APPROVED
SCOPE_REDUCE_REQUIRED
SCOPE_REJECTED
PROJECT_REVIEW_REQUIRED
```

Albert responds with one of:

```text
OK PROJECT SCOPE
STOP PROJECT
```

Only after `OK PROJECT SCOPE` may NeoDaemon execute implementation work inside the approved perimeter.

## 6. Rules

- deny-by-default;
- scope must be minimum viable;
- no broad wildcards;
- no gateway, runtime, or model changes unless specially confirmed;
- no other plugins;
- no private config material;
- if uncertain, return `PROJECT_REVIEW_REQUIRED`.

## 7. Example: PROJECT_IMAGE_INBOX

Example `allowed_paths`:

```text
extensions/image-inbox/**
scripts/project/image_inbox_*.py
dashboard-v2/operational-control-plane/**
OpenClaw-NeoDaemon-Skill/references/image_inbox_*.md
```

Example `blocked_paths`:

```text
gateway/**
runtime/**
models/**
other plugins
environment configuration files
global package-lock
```

The example does not approve implementation by itself. It shows the intended shape of a project perimeter that GPT must audit and Albert must approve.

## 8. Permanent Rule

A project must not expand perimeters by accident.

The perimeter is proposed by NeoDaemon, audited by GPT, and accepted only when the risk is low enough. If GPT does not approve the scope, the decision returns to Albert to continue, reduce, or stop the project.
