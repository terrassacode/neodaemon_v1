# Approval Strategy Contract

## Status

Contract only.

This document defines the permanent approval strategy for the Albert ↔ GPT ↔ NeoDaemon ↔ PR Guardian ecosystem.

It does not implement code, create actions, modify runtime, modify gateway, modify scheduler, modify PR Guardian behavior, or modify the NeoDaemon executor.

## Purpose

Approvals are safety signals, not routine work units.

The ecosystem must classify every approval before acting. Albert must not be asked to interpret long commands or approve by intuition.

The strategy is:

```text
approve only bounded, validated, low-risk approvals;
reject unsafe approvals;
turn repeated approvals into a controlled system.
```

## Approval Types

Allowed approval classifications:

```text
APPROVAL_CORRECT
APPROVAL_INCORRECT
APPROVAL_STRUCTURAL
```

## APPROVAL_CORRECT

An approval is `APPROVAL_CORRECT` when it is:

- a single command or action;
- exact;
- previously validated;
- free of shell libre;
- free of `&&`;
- free of `;`;
- free of user-controlled variable paths;
- low risk;
- known in purpose and effect.

Action:

```text
May be approved.
```

Examples:

- approve a known controlled action;
- approve a previously validated one-shot read-only check;
- approve an exact cleanup confirmation tied to one PR/branch/hash.

## APPROVAL_INCORRECT

An approval is `APPROVAL_INCORRECT` when it asks Albert to approve unsafe, broad, unclear, or excessive execution.

Examples:

- long shell script;
- chained commands;
- `git reset`;
- force push;
- rebase;
- stash;
- generic `rm`;
- broad `cp`;
- broad `mkdir`;
- broad `find`;
- broad `grep`;
- arbitrary Python;
- runtime changes;
- gateway changes;
- model/routing changes.

Action:

```text
Reject.
Do not approve.
```

NeoDaemon must explain the blocker and propose a safer route if one exists.

## APPROVAL_STRUCTURAL

An approval is `APPROVAL_STRUCTURAL` when it is not just one approval, but evidence of a missing system boundary.

Definition:

```text
A repeated approval, or an approval that exists because there is no controlled action, Job, or project review boundary.
```

Examples:

- repeated approvals for similar read-only checks;
- repeated approvals for the same manual publish step;
- repeated approvals to inspect state that should have a controlled action;
- repeated workarounds caused by missing automation.

Action:

```text
Stop.
Choose one:
- create a controlled action;
- create a Job;
- enter PROJECT_REVIEW_REQUIRED.
```

Structural approvals should not be normalized.

## Repeated Approvals Rule

If two similar structural approvals appear:

```text
PROJECT_REVIEW_REQUIRED
```

The project must stop automatic continuation.

Do not approve the third repetition. Convert the problem into a system.

## Human Rules

### Albert

Albert:

- does not interpret long commands;
- does not approve by intuition;
- may block any approval;
- may require a controlled action, Job, or project review instead.

### GPT

GPT:

- classifies approvals;
- detects repeated approval patterns;
- distinguishes correct, incorrect, and structural approvals;
- proposes controlled actions when repetition appears;
- recommends `PROJECT_REVIEW_REQUIRED` when approvals reveal workflow design failure.

### NeoDaemon

NeoDaemon:

- does not request avoidable approvals;
- does not try to bypass blocked approvals;
- prefers controlled actions over repeated shell approvals;
- reports approval risk clearly;
- stops when approval class is structural or incorrect.

### PR Guardian

PR Guardian:

- never autoapproves;
- never changes approval policy;
- never weakens merge or cleanup safety because approval is inconvenient;
- returns evidence instead of asking Albert to inspect implementation details.

## Out Of Scope

This contract does not define or change:

- implementation;
- scheduler;
- auto approvals;
- runtime;
- gateway;
- PR Guardian code;
- NeoDaemon executor code;
- model routing;
- functional behavior.

## Permanent Rule

If an approval appears repeatedly:

```text
Do not approve more of the same.
Convert the problem into a system.
```

A repeated approval is not friction to tolerate. It is a design signal.
