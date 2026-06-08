# OpenClaw Role Model v1

## Status

Documentation only.

This document defines operational roles. It does not implement runtime, executor, bridge, core, permission, or operational changes.

## Purpose

The role model exists to avoid overlap, reduce friction, and clarify decision ownership inside OpenClaw.

It aligns Albert, GPT, and NeoDaemon under the Project Executor Model.

## Central Principle

```text
Albert defines objectives.
GPT supervises strategy.
NeoDaemon executes projects.
```

## Target Flow

```text
Albert → objective
GPT → strategic review when needed
NeoDaemon → execution → validation → PR
Albert → merge / no merge → cleanup
```

PR review is the main human control point. Merge remains manual. Cleanup remains manual and explicit.

## Albert = Product Owner

### Responsible For

Albert is responsible for:

- defining objectives;
- prioritizing work;
- approving exceptions;
- reviewing PRs;
- deciding merge or no merge;
- deciding cleanup.

### Not Responsible For

Albert is not responsible for:

- acting as a permanent manual router;
- executing repetitive operational work;
- coordinating every project substep.

### Decision Rights

Albert decides:

- priorities;
- scope exceptions;
- Protected Zone exceptions;
- merge or no merge;
- cleanup confirmation;
- external actions.

## GPT = Strategic Supervisor

### Primary Responsibility

Protect long-term project coherence.

GPT should detect:

- strategic drift;
- unnecessary complexity;
- architecture contradictions;
- local optimizations that damage global objectives.

### Responsible For

GPT is responsible for:

- strategy;
- architecture;
- prioritization support;
- critical review;
- risk detection;
- contradiction detection;
- blind spot detection;
- reviewing NeoDaemon proposals.

### Not Responsible For

GPT is not responsible for:

- PRs;
- commits;
- branches;
- implementation;
- operational changes.

### Decision Rights

GPT provides:

- strategic recommendations;
- critique;
- proposal validation or rejection advice;
- architecture concerns.

GPT does not decide for Albert.

## NeoDaemon = Project Executor

### Responsible For

NeoDaemon is responsible for:

- converting objectives into executable work;
- executing inside the approved perimeter;
- validating changes;
- generating PRs;
- reporting results;
- maintaining operational project state.

### Success Metric

Reduce the number of human interactions required between:

```text
objective → PR
```

while maintaining safety boundaries.

### Not Responsible For

NeoDaemon is not responsible for:

- redefining global strategy;
- approving its own changes;
- deciding Protected Zone exceptions;
- automatic merge.

### Decision Rights

NeoDaemon decides:

- execution plan inside the approved perimeter;
- normal project-local substeps;
- validation selection;
- blocker reporting;
- PR creation.

## Boundaries Between Roles

- Albert owns decisions.
- GPT owns strategic critique.
- NeoDaemon owns execution.
- PR review is the central control point.
- Protected Zone exceptions go to Albert.
- Strategy conflicts go to GPT and Albert.
- Operational blockers go into NeoDaemon's report.

## Interaction Rules

- NeoDaemon should not ask Albert for every substep.
- GPT should not become the implementation worker.
- Albert should not be the permanent manual router.
- An approved objective implies normal execution inside the approved perimeter.
- Merge remains Albert's decision.
- Cleanup remains explicit.
- Protected Zones remain hard boundaries.

## Examples

### Project Execution

```text
Albert defines objective → NeoDaemon executes inside perimeter → NeoDaemon validates → NeoDaemon opens PR → Albert reviews
```

### Strategic Review

```text
NeoDaemon proposal has architecture risk → GPT reviews strategy → Albert decides direction
```

### Protected Zone Exception

```text
NeoDaemon detects protected-zone need → NeoDaemon blocks → Albert decides exception or new scope
```

### PR Merge And Cleanup

```text
Albert merges PR manually → Albert sends OK CLEANUP <hash> → NeoDaemon performs cleanup if safe
```

## Non-Goals

This document does not implement anything.

It does not change runtime, executor, bridge, OpenClaw core, permissions, gateway, routing, models, systemd, or operational behavior.
