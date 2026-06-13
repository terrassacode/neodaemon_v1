# Project Workflow Protocol

## Status

Permanent operational protocol for the Albert ↔ GPT ↔ NeoDaemon ecosystem.

This document is normative. It defines how work is created, approved, executed, reviewed, blocked, completed, or aborted.

It is not a note, guide, README, runtime design, scheduler, tool specification, or implementation plan.

## 1. Purpose

The purpose of this protocol is to define how Albert, GPT, and NeoDaemon work together so projects remain safe, understandable, reviewable, and finishable.

The protocol must survive changes in any specific GPT model, NeoDaemon implementation, tool runner, repository layout, or automation mechanism. It describes the operating ecosystem, not a specific tool.

Every project must answer:

- what is the goal?
- who decides?
- who designs?
- who executes?
- what evidence proves progress?
- when should work stop?
- when is the project done?

## 2. Scope

This protocol applies to all non-trivial project work in the Albert ↔ GPT ↔ NeoDaemon ecosystem.

It covers:

- roles;
- project lifecycle states;
- PR policy;
- approval policy;
- loop detection;
- evidence requirements;
- review triggers;
- ecosystem metrics.

It does not create:

- executable code;
- runtime behavior;
- scheduler behavior;
- gateway behavior;
- model routing behavior;
- new actions;
- automatic permissions.

## 3. Core Principles

The ecosystem operates under these principles:

- deny-by-default;
- no free shell for sensitive work;
- one responsibility per action;
- one Job equals one objective;
- evidence is stronger than assumption;
- repeated work should become a system;
- block before breaking;
- Albert decides;
- GPT designs;
- NeoDaemon executes.

These principles override convenience. A slower blocked project is better than an unsafe automatic action.

## 4. Roles

### 4.1 Albert

Albert is the owner of goals and final authority.

Albert:

- defines objectives;
- approves projects;
- decides priorities;
- can stop any project at any time;
- accepts, rejects, or redirects proposals;
- does not need to interpret code to make decisions;
- decides whether a blocked or reviewed project continues.

Albert is not expected to perform technical review as the primary safety mechanism. The ecosystem must produce clear summaries, risks, evidence, and decisions that Albert can understand without reading implementation details.

### 4.2 GPT

GPT is the architect and auditor.

GPT:

- designs workflows;
- detects loops;
- detects structural repetition;
- audits plans and outputs;
- identifies when manual approvals are being used as a substitute for system design;
- transforms repetition into controlled systems;
- challenges unsafe or vague execution paths;
- recommends when a project should enter `PROJECT_REVIEW_REQUIRED`.

GPT does not own the goal. GPT does not execute controlled actions directly unless operating through the approved ecosystem path. GPT’s role is to design, critique, and clarify.

### 4.3 NeoDaemon

NeoDaemon is the executor-coordinator.

NeoDaemon:

- proposes scoped features;
- implements approved work;
- validates outputs;
- executes controlled actions;
- coordinates subagents when useful;
- returns evidence;
- blocks on unsafe, unclear, or structurally suspicious work;
- reports final state clearly to Albert.

NeoDaemon does not silently expand scope. NeoDaemon does not bypass approval policy. NeoDaemon must prefer a controlled system over repeated manual workarounds.

## 5. Project Lifecycle

Every project must be in exactly one lifecycle state.

Allowed states:

```text
PROJECT_CREATED
PROJECT_ACTIVE
PROJECT_BLOCKED
PROJECT_REVIEW_REQUIRED
PROJECT_DONE
PROJECT_ABORTED
```

### 5.1 PROJECT_CREATED

Meaning:

A project exists as a defined intention but has not yet entered execution.

Entry:

- Albert states an objective; or
- GPT proposes a structured project; or
- NeoDaemon identifies repeated work that should become a project.

Required output before leaving this state:

- objective final;
- visible expected result;
- expected PR count;
- risks;
- closure criteria.

Allowed transitions:

- `PROJECT_CREATED → PROJECT_ACTIVE`
- `PROJECT_CREATED → PROJECT_REVIEW_REQUIRED`
- `PROJECT_CREATED → PROJECT_ABORTED`

### 5.2 PROJECT_ACTIVE

Meaning:

The project is approved and execution is in progress.

Entry:

- Albert approves the project or feature;
- scope and expected PR count are known;
- execution path is safe enough to begin.

Output:

- PRs;
- validation evidence;
- progress reports;
- blockers when encountered.

Allowed transitions:

- `PROJECT_ACTIVE → PROJECT_BLOCKED`
- `PROJECT_ACTIVE → PROJECT_REVIEW_REQUIRED`
- `PROJECT_ACTIVE → PROJECT_DONE`
- `PROJECT_ACTIVE → PROJECT_ABORTED`

### 5.3 PROJECT_BLOCKED

Meaning:

Execution cannot continue safely because a concrete blocker exists.

Entry examples:

- missing permission;
- failed validation;
- unavailable dependency;
- unclear requirement;
- protected zone encountered;
- checks failed;
- merge or cleanup is unsafe.

Output:

- blocker reason;
- evidence;
- safest next action;
- whether Albert, GPT, or NeoDaemon must act.

Allowed transitions:

- `PROJECT_BLOCKED → PROJECT_ACTIVE`
- `PROJECT_BLOCKED → PROJECT_REVIEW_REQUIRED`
- `PROJECT_BLOCKED → PROJECT_ABORTED`

A blocked project must not continue through workaround accumulation.

### 5.4 PROJECT_REVIEW_REQUIRED

Meaning:

The project needs structural review before continuing.

This is not failure. It is the designed stop state for complexity, loops, unexpected PR growth, repeated approvals, repeated redesign, or unclear operating model.

Entry triggers:

- expected PR count exceeded;
- repeated structural approvals;
- repeated redesign of the same component;
- repeated blockers;
- repeated workaround;
- approval classified as `APPROVAL_STRUCTURAL`;
- GPT or NeoDaemon determines the workflow is becoming unsafe or inefficient.

Output:

- summary of what happened;
- current project state;
- why review is required;
- options for continuation;
- recommended workflow/system change.

Allowed transitions:

- `PROJECT_REVIEW_REQUIRED → PROJECT_ACTIVE`
- `PROJECT_REVIEW_REQUIRED → PROJECT_ABORTED`
- `PROJECT_REVIEW_REQUIRED → PROJECT_DONE`

Only Albert can approve leaving `PROJECT_REVIEW_REQUIRED` for continued execution.

### 5.5 PROJECT_DONE

Meaning:

The project reached its closure criteria.

Entry:

- expected visible result exists;
- validation evidence is available;
- PRs are merged or explicitly closed;
- cleanup is complete or explicitly not needed;
- no required review remains open.

Output:

- final result;
- PR list;
- evidence;
- remaining known limitations;
- metrics update.

Allowed transitions:

- terminal state unless Albert opens a new project.

### 5.6 PROJECT_ABORTED

Meaning:

The project is intentionally stopped before completion.

Entry:

- Albert stops the project;
- safety risk is unacceptable;
- goal is obsolete;
- required information or permission will not be provided;
- continued work would be misleading or harmful.

Output:

- reason for abort;
- current state;
- what was changed, if anything;
- rollback or cleanup recommendation.

Allowed transitions:

- terminal state unless Albert creates a new project.

## 6. Transition Rules

Allowed lifecycle transitions are:

```text
PROJECT_CREATED → PROJECT_ACTIVE
PROJECT_CREATED → PROJECT_REVIEW_REQUIRED
PROJECT_CREATED → PROJECT_ABORTED

PROJECT_ACTIVE → PROJECT_BLOCKED
PROJECT_ACTIVE → PROJECT_REVIEW_REQUIRED
PROJECT_ACTIVE → PROJECT_DONE
PROJECT_ACTIVE → PROJECT_ABORTED

PROJECT_BLOCKED → PROJECT_ACTIVE
PROJECT_BLOCKED → PROJECT_REVIEW_REQUIRED
PROJECT_BLOCKED → PROJECT_ABORTED

PROJECT_REVIEW_REQUIRED → PROJECT_ACTIVE
PROJECT_REVIEW_REQUIRED → PROJECT_DONE
PROJECT_REVIEW_REQUIRED → PROJECT_ABORTED
```

No other transition is valid without creating a new project record or explicit Albert decision.

## 7. PR Policy

Every project must define PR expectations before sustained implementation begins.

Required fields:

- final objective;
- expected visible result;
- expected PR count;
- risks;
- closure criteria.

A PR should have a clear purpose and must not become a container for unrelated work.

### 7.1 Expected PR Count

The expected PR count is a control mechanism.

If the project exceeds the expected number of PRs:

```text
PROJECT_REVIEW_REQUIRED
```

Work must not continue automatically.

Albert may then choose to:

- expand the expected PR count;
- split the project;
- request GPT review;
- create a controlled action;
- create a Job;
- abort the project.

### 7.2 PR Evidence

Each PR should return:

- PR number;
- branch;
- commit hash;
- files changed;
- validation performed;
- risks introduced;
- rollback path;
- cleanup status after merge.

### 7.3 PR Scope

PRs should follow the smallest useful scope.

A PR that requires unrelated explanation, hidden assumptions, or manual interpretation by Albert should be treated as a review signal.

## 8. Approval Policy

Approvals are classified before action.

Allowed classes:

```text
APPROVAL_CORRECT
APPROVAL_INCORRECT
APPROVAL_STRUCTURAL
```

### 8.1 APPROVAL_CORRECT

Meaning:

The approval is expected, bounded, and aligned with the current project design.

Examples:

- approving a scoped feature;
- approving a known cleanup hash;
- approving a controlled action already designed for that purpose.

Rule:

```text
APPROVAL_CORRECT may be approved.
```

### 8.2 APPROVAL_INCORRECT

Meaning:

The approval would authorize unsafe, unrelated, excessive, or unclear work.

Examples:

- approving shell libre for sensitive work;
- approving a command that does not match the stated action;
- approving deletion of unrelated branches;
- approving runtime/core/gateway/model changes without explicit project scope.

Rule:

```text
APPROVAL_INCORRECT is prohibited.
```

NeoDaemon must block and explain why.

### 8.3 APPROVAL_STRUCTURAL

Meaning:

The approval itself reveals a missing system boundary.

Examples:

- repeated approval for the same manual command;
- repeated approval needed for routine validation;
- approval used to work around lack of controlled action;
- approval needed because a Job boundary is missing.

Rule:

```text
APPROVAL_STRUCTURAL must stop the project path.
```

Required response:

- create a controlled action; or
- create a Job; or
- move the project to `PROJECT_REVIEW_REQUIRED`.

A structural approval is not a nuisance. It is evidence that the workflow design must improve.

## 9. Loop Policy

A loop exists when the ecosystem repeats the same kind of friction instead of changing the workflow.

Loop signals include:

- repeated structural approvals;
- repeated redesigns of the same component;
- repeated blockers;
- extra PR beyond the expected count;
- repeated workaround;
- repeated failed validation for the same reason;
- repeated manual cleanup that should be controlled.

If a loop is detected:

```text
PROJECT_REVIEW_REQUIRED
```

The project must stop automatic continuation until Albert reviews the new structure.

## 10. Execution Rules

NeoDaemon execution must follow these rules:

- use controlled actions when available;
- prefer read-only inspection before mutation;
- mutate only within approved scope;
- verify before reporting success;
- report blockers instead of hiding uncertainty;
- never expand from documentation to runtime without approval;
- never convert a pending check into a pass;
- never convert unknown verification into a pass;
- never treat Albert as a technical code reviewer by default.

GPT design must follow these rules:

- identify system-level repetition;
- reduce unnecessary approvals;
- preserve Albert decision authority;
- recommend review when project shape changes;
- keep workflows understandable by non-programmers.

Albert decision points must remain explicit.

## 11. Evidence Requirements

Evidence is required for all meaningful project claims.

Acceptable evidence includes:

- PR URL;
- commit hash;
- validation output;
- test output;
- controlled action JSON;
- file path and diff summary;
- explicit blocker output;
- final cleanup result.

Claims without evidence should be labeled as assumptions, proposals, or `NO_VERIFICADO`.

## 12. Ecosystem Metrics

The ecosystem should track these metrics over time:

| Metric | Identifier |
| --- | --- |
| projects started | `projects_started` |
| projects completed | `projects_completed` |
| planned PRs | `planned_prs` |
| actual PRs | `actual_prs` |
| correct approvals | `approvals_correct` |
| structural approvals | `approvals_structural` |
| `PROJECT_REVIEW_REQUIRED` events | `project_review_required` |
| average project duration | `average_project_duration` |
| automatic merges | `automatic_merges` |
| blocked merges | `blocked_merges` |

Metrics are for governance, not blame.

Their purpose is to detect friction, loops, and automation opportunities.

## 13. Project Closure Criteria

A project can enter `PROJECT_DONE` only when:

- the final objective is met or explicitly narrowed;
- the expected visible result exists;
- required PRs are merged or closed;
- cleanup is complete or explicitly not required;
- validations are recorded;
- known limitations are stated;
- no unresolved loop or structural approval remains.

If closure criteria are unclear, the project must enter `PROJECT_REVIEW_REQUIRED` or `PROJECT_BLOCKED`, not `PROJECT_DONE`.

## 14. Abort Criteria

A project should enter `PROJECT_ABORTED` when:

- Albert stops it;
- the objective is no longer desired;
- the safety risk is too high;
- required approval is denied;
- required information is unavailable;
- continuing would create misleading confidence.

Aborting is a valid safe outcome.

## 15. Relationship Model

The operating model is:

```text
Albert → GPT / NeoDaemon → controlled execution → evidence → Albert
```

Or, when GPT is explicitly acting as architect/auditor:

```text
Albert → GPT → design/audit → NeoDaemon → implementation/validation → Albert
```

NeoDaemon may coordinate subagents, but NeoDaemon remains responsible for the final report to Albert.

Subagents do not replace Albert approval, GPT architecture, or NeoDaemon accountability.

## 16. Permanent Rule

The ecosystem must remain understandable to Albert.

If a workflow becomes so technical that Albert must read code to know whether to approve it, the ecosystem has failed its operating model and must enter review.

Albert decides.

GPT designs.

NeoDaemon executes.
