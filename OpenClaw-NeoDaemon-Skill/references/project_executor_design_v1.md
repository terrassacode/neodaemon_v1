# Project Executor Design v1

## Status

Design document only.

This document does not implement Project Executor and does not change runtime, core, bridge, executor, tools, permissions, approvals, or operational configuration.

## Evidence Base

This design is based on recent real Project Executor-style documentation work:

- `references/neodaemon_operating_model_v2.md`
- `references/openclaw_role_model_v1.md`
- PR #108: Skill documentation audit and alignment across multiple files.
- PR #109: executive project state audit and task_manager update.
- `task_manager/projects/neodaemon.json`

## What Worked In Recent Tests

PR #108 showed that NeoDaemon can complete a coherent multi-file documentation audit inside the Skill perimeter:

- audit existing documents;
- identify objective inconsistencies;
- patch multiple related files;
- validate through the controlled publication route;
- create a PR;
- leave merge and cleanup to Albert.

PR #109 showed that NeoDaemon can update executive state across `task_manager` and Skill references:

- read current state;
- identify obsolete priorities;
- update compact project state;
- update supporting references;
- create a PR with an executive report.

These tests support the Project Executor principle:

```text
objective → execution → validation → PR → Albert decision
```

without intermediate proposal chains for obvious substeps.

## Remaining Friction

Current execution still depends on compatibility routes:

- folder/path-specific publication behavior;
- staged-file edge cases for new directories;
- limited read-only runtime inspection;
- manual route selection by NeoDaemon;
- inability to treat `docs/**` as a fully active documentation perimeter yet;
- no single executor command owns preflight, edit, validation, commit, PR, and report.

The friction is not mainly strategic. It is architectural: there is no single Project Executor component yet.

## What Is Project Executor?

Project Executor is the future NeoDaemon execution mode where an approved objective grants permission for normal project-local execution inside a defined perimeter.

The unit of work is:

```text
the project
```

not:

```text
the command
the file
the folder-specific allowlist
```

Project Executor should turn Albert's objective into:

```text
scoped work → validated diff → PR → evidence report
```

## Problem It Solves

Project Executor solves the Assistant-Controlled Model failure mode:

```text
objective → proposal → proposal for substep → proposal for unblock → execution
```

It replaces that with:

```text
objective → execution → validation → PR → Albert decision
```

It reduces unnecessary human interactions while preserving Protected Zones, PR review, manual merge, and manual cleanup.

## Operating Flow

1. Albert defines an objective.
2. NeoDaemon checks that the objective is inside the approved perimeter.
3. NeoDaemon creates or reuses a safe branch.
4. NeoDaemon audits relevant files.
5. NeoDaemon applies project-local changes.
6. NeoDaemon validates by file type and policy.
7. NeoDaemon creates a PR with a report.
8. Albert reviews and decides merge or no merge.
9. NeoDaemon cleans up only after exact cleanup confirmation.

## Operating Perimeter

Initial real perimeter:

```text
OpenClaw-NeoDaemon-Skill/**
task_manager/**
docs/**/*.md
```

The current evidence strongly supports Skill and task_manager work. `docs/**/*.md` is documented as the desired documentation perimeter, but it still requires implementation before it is fully active.

Out of perimeter by default:

```text
runtime
core
bridge
executor
tools
service configuration
gateway/routing/model areas
host-wide shell
external actions
sensitive material
```

## Protected Zones

Protected Zones are hard boundaries. If a project requires touching one, Project Executor must block and ask Albert for an explicit exception.

Protected Zones include:

- runtime files;
- OpenClaw core;
- bridge/executor/tools;
- service configuration;
- gateway/routing/model areas;
- external communication surfaces;
- private or sensitive material;
- destructive Git operations.

Protected Zones are not soft warnings. They are stop conditions.

## Mandatory Validations

Project Executor must validate:

- branch is not `main`;
- repo starts clean or pre-existing dirty state is explicitly reported;
- changed files stay inside the approved perimeter;
- Protected Zone scanner passes;
- changed Markdown exists and is non-empty;
- changed JSON parses when JSON is in the perimeter;
- changed shell/Python files validate only if those file types are explicitly inside the perimeter;
- staged diff has no sensitive material;
- PR body reports scope, files, validations, blockers, and rollback;
- no merge was performed;
- no cleanup was performed automatically.

## Required Components

### 1. Project Policy

Machine-readable definition of:

- allowed roots;
- blocked roots;
- allowed file types;
- validation rules;
- max files or diff budget;
- PR/report requirements.

### 2. Project Executor Command

One controlled entrypoint responsible for:

```text
preflight → branch → edit support → validation → commit → push → PR → report
```

### 3. Protected Zone Scanner

A hard blocker that runs before commit and before push.

Initial standalone component:

```text
scripts/project/protected_zone_scanner_v1.py
```

This scanner evaluates repository-relative paths, normalizes `./` prefixes, blocks absolute paths and parent traversal, allows the initial Project Executor perimeter, and returns JSON with `status`, `safe`, `files_evaluated`, and `blocked` entries.

It is not integrated automatically yet.

### 3.1 NeoDaemon Healthcheck

Initial standalone component:

```text
scripts/project/neodaemon_healthcheck_v1.py
```

This healthcheck is offline-only and read-only. It gives an SSH-friendly local signal for whether NeoDaemon can perform project execution from the current repository state.

V1 checks only local evidence:

- Git is available;
- current directory is inside the repository;
- `git status --short` can run;
- worktree is clean;
- current branch is `main`;
- required local tool files are present;
- required project scripts are present.

It does not perform network, provider, gateway, model, runtime, or service checks in V1.

It is intended to be executed through:

```text
run_project_script_readonly
```

and returns JSON with `status`, `health_scope`, `local_can_work_now`, `bottlenecks`, `evidence`, `no_verificado`, `recommended_next_action`, and `checks`.

For fast human SSH interpretation, the same script also supports:

```text
--human
```

Human mode uses the same internal health result as JSON mode and prints a compact summary with status, local work capability, scope, branch, worktree state, critical tools, critical project scripts, recommended next action, and the V1 note that external connectivity is omitted.

### 4. Validation Router

Chooses validations by file type and perimeter.

### 5. Execution Report Builder

Generates a consistent PR body and final response:

- result;
- branch;
- commit;
- PR URL;
- files touched;
- validations;
- blockers / NO_VERIFICADO;
- next action.

### 6. State Integrator

Optionally updates `task_manager/projects/neodaemon.json` after meaningful project state changes.

## Components That Could Disappear Or Become Compatibility Only

- folder-specific documentation publication routes;
- per-file publication expansion work;
- approval-driven command execution for normal project-local work;
- manual parking workflows caused by publication constraints;
- proposal chains for obvious project-local substeps;
- separate doc/data publication logic once Project Policy owns perimeter validation.

## Human Control Model

Human control remains:

- Albert defines objectives;
- GPT provides strategic supervision when needed;
- NeoDaemon executes inside perimeter;
- PR review is the main control point;
- merge is manual;
- cleanup is manual and hash-confirmed;
- Protected Zone exceptions go to Albert.

## Success Metrics

Measure Project Executor by:

- number of human interactions between objective and PR;
- percentage of project-local tasks completed without intermediate proposal chains;
- validation pass/fail clarity;
- PR reviewability;
- Protected Zone block accuracy;
- cleanup success after merge;
- reduction in path-specific publication changes;
- task_manager freshness after significant work.

Primary success metric from Role Model v1:

```text
Reduce the number of human interactions required between objective → PR while maintaining safety boundaries.
```

## Risks

Project Executor introduces real risks:

- broad objectives may create too-large PRs;
- perimeter mistakes may allow unsafe files;
- validation gaps may produce false confidence;
- Project Executor could duplicate legacy routes;
- automatic state updates could become noisy;
- runtime state may still be unknown without safe read-only inspection;
- GPT/NeoDaemon role boundaries may blur if strategy and execution mix.

## Risk Controls

Required controls:

- smallest coherent project scope;
- file/diff budget;
- Protected Zone scanner;
- validation router;
- PR-only delivery;
- manual merge;
- manual cleanup;
- explicit `NO_VERIFICADO` reporting;
- GPT strategic review for architecture drift or major design questions.

## Implementation Phases

### Phase 1: Documentation Perimeter Executor

Enable real Project Executor behavior for:

```text
OpenClaw-NeoDaemon-Skill/**
task_manager/**
docs/**/*.md
```

Goal: replace folder-specific documentation publication routes with one project policy.

### Phase 2: Validation Router

Add automatic validation by file type and policy.

Goal: make validation consistent instead of manually selected per task.

### Phase 3: Execution Report Builder

Standardize PR bodies and final responses.

Goal: Albert can review without asking for missing context.

### Phase 4: State Integration

Update `task_manager` only when state changes are meaningful.

Goal: keep executive state current without noise.

### Phase 5: Controlled Project-Local Expansion

Consider adding project-local tests or scripts only if there is evidence of need.

Goal: expand capability without weakening Protected Zones.

## Ready For Real Use Criteria

Project Executor is ready for real use when it can:

- complete a multi-file documentation/state project from objective to PR;
- require no intermediate proposal for obvious substeps;
- block a Protected Zone test case;
- validate changed files consistently;
- generate a complete PR report;
- leave `main` untouched;
- avoid merge and cleanup automation;
- preserve manual cleanup with exact hash;
- update task_manager only when useful.

## Non-Goals

This design does not implement Project Executor.

It does not change runtime, core, bridge, executor, tools, permissions, approvals, service configuration, or gateway behavior.
