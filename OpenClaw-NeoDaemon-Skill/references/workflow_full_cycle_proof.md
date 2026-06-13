# Workflow Full Cycle Proof

## Status

Documentation only.

This document proves the intended full-cycle workflow for the Albert ↔ GPT ↔ NeoDaemon ↔ PR Guardian ecosystem.

It does not implement code, runtime, gateway behavior, dashboard behavior, scheduler behavior, Job Engine behavior, or new actions.

## Purpose

Demonstrate that the ecosystem can complete a full work cycle without breaking rules and without manual steps beyond the explicit human command that starts or finalizes the cycle.

The proof is operational, not theoretical: each actor has a clear role and each transition has an expected result.

## Current Actors

### Albert

Albert defines the objective and keeps final decision authority.

### GPT

GPT designs, reviews, detects loops, and proposes the next action.

### NeoDaemon

NeoDaemon implements approved work, creates PRs, validates outputs, and returns evidence.

### PR Guardian

PR Guardian checks PRs, protects `main`, merges only when safe, cleans exact branches, and returns evidence.

## Full Cycle

```text
GPT
↓
Feature Proposal
↓
NeoDaemon
↓
PR Creation
↓
PR Guardian
↓
CHECK PR #123
↓
PASS_READY_TO_MERGE
↓
MERGE PR #123
↓
PASS_MERGED_AND_CLEANED
↓
GPT
↓
Next Action
```

## Success Criteria

A full cycle is successful when all of these are true:

- PR created;
- `CHECK PR #123` returns `PASS_READY_TO_MERGE`;
- `MERGE PR #123` returns `PASS_MERGED_AND_CLEANED`;
- cleanup returns PASS;
- `main` is clean and synchronized;
- next action is defined.

## Failure Cases

The cycle must stop safely when PR Guardian returns any of these:

### WAITING_FOR_CHECKS

Checks are still pending.

Action:

```text
Wait, then retry CHECK PR #123.
```

### BLOCKED_WITH_REASON

The PR is unsafe or blocked by policy.

Action:

```text
Fix the blocker or escalate to PROJECT_REVIEW_REQUIRED.
```

### NO_VERIFICADO

The PR cannot be verified.

Action:

```text
Do not merge. Restore verifiability or escalate to PROJECT_REVIEW_REQUIRED.
```

### PARTIAL_MERGE_CLEANUP_FAILED

Merge happened, but cleanup or final verification failed.

Action:

```text
Stop. Inspect evidence. Use legacy fallback only if exact branch safety is proven.
```

## Permanent Rule

```text
GPT designs.
NeoDaemon implements.
PR Guardian protects main.
Albert keeps final decision authority.
```

If any actor must take over another actor’s responsibility to continue, the workflow should stop and enter review.

## Use Before Job Engine

Before starting `PROJECT_JOB_ENGINE`, the ecosystem should be able to demonstrate this cycle on small, low-risk documentation changes.

The purpose is to prove the workflow boundary before adding more automation.
