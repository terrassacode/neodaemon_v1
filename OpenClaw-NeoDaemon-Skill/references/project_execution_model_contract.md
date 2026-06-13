# Project Execution Model Contract

## Status

Contract only.

This document does not create a Job Engine, scheduler, queue, superagent, autonomous runtime, gateway behavior, runtime behavior, or functional change.

## Purpose

Answer one question:

```text
Who does what during a complete project?
```

The current ecosystem may already be a distributed project execution system:

```text
Albert ↔ GPT ↔ NeoDaemon ↔ PR Guardian ↔ Project Registry
```

This contract defines that model before adding any new component.

## Actors

### Albert

Human operator and final authority.

### GPT

Design, audit, and reasoning layer.

### NeoDaemon

Implementation and validation layer.

### PR Guardian

Main protection and PR finalization layer.

### Project Registry

Project memory, state, risk, and next-action layer.

## Responsibilities

### Albert

- defines objectives;
- approves exceptions;
- can abort.

### GPT

- designs;
- audits;
- detects blockers;
- proposes improvements.

### NeoDaemon

- implements;
- creates PR;
- validates.

### PR Guardian

- check;
- apply;
- auto;
- merge;
- cleanup.

### Project Registry

- project memory;
- state;
- risks;
- next action.

## Execution Flow

```text
Albert
↓
GPT
↓
NeoDaemon
↓
PR Guardian
↓
GitHub
↓
Project Registry
↓
GPT
↓
Next Action
```

## Evidence

The current model is supported by these existing contracts and proofs:

- Workflow Protocol;
- Approval Strategy;
- Project Registry;
- PR Guardian;
- Auto Merge Eligibility;
- Workflow Full Cycle Proof.

Together they define objective intake, design, implementation, verification, PR protection, controlled merge, cleanup, memory, risk, and next action.

## What Is NOT Needed

No Job Engine.

No Scheduler.

No Queue.

No Superagent.

No Autonomous Runtime.

A new component is not justified merely because a workflow is repeated.

## Permanent Rule

```text
Create new components
only
if there is objective evidence
that the current system is not enough.
```

Until that evidence exists, prefer improving contracts, validation, and controlled routes inside the existing ecosystem.
