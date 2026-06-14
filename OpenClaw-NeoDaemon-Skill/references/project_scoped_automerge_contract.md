# Project Scoped Automerge Contract

## 1. Purpose

Allow useful auto-merge inside an approved `PROJECT_SCOPE`.

This contract connects project-scoped perimeters, GPT audit, PR Guardian validation, and auto-merge so low-risk project work can move without repeated manual merge commands.

## 2. Main Rule

If a PR is inside the approved project perimeter, and PR Guardian validates safety, it may be auto-merged.

Auto-merge is not granted by trust alone. It is granted only by approved scope plus fresh PR validation.

## 3. Mandatory Conditions

All conditions are required:

- `project_scope` approved;
- GPT audited the scope;
- PR is inside `allowed_paths`;
- PR is outside `blocked_paths`;
- checks are `SUCCESS`;
- mergeability is `CLEAN`;
- repository is expected;
- base branch is `main`;
- head branch is expected;
- no sensitive routes or materials are touched;
- no structural approvals are present;
- no changes outside the project.

If any condition is not proven, auto-merge must not happen.

## 4. Blockers

Auto-merge is blocked when any of these are true:

- PR is outside the approved scope;
- PR touches `blocked_paths`;
- PR touches runtime, gateway, or model surfaces;
- dangerous delete is detected;
- suspicious rename is detected;
- checks are pending;
- checks failed;
- mergeability is not clean;
- `PROJECT_REVIEW_REQUIRED` is raised.

A blocked auto-merge must return a reason instead of attempting a merge.

## 5. Roles

### NeoDaemon

NeoDaemon:

- creates PRs inside the approved scope;
- avoids scope expansion by accident;
- returns `PROJECT_REVIEW_REQUIRED` when work needs to leave the scope.

### GPT

GPT:

- audits the project scope;
- audits project risks;
- identifies when the scope is too broad or unsafe.

### PR Guardian

PR Guardian:

- validates the PR against the approved scope;
- validates repository, branch, checks, mergeability, paths, and blockers;
- auto-merges only when every required condition passes;
- returns a blocked result when proof is incomplete.

### Albert

Albert:

- does not interpret technical routes directly;
- keeps veto authority when GPT marks risk;
- decides whether a project continues when review is required.

## 6. Outputs

PR Guardian may return:

```text
PROJECT_AUTOMERGE_ALLOWED
PROJECT_AUTOMERGE_BLOCKED
PROJECT_REVIEW_REQUIRED
PASS_MERGED_AND_CLEANED
```

Output meanings:

- `PROJECT_AUTOMERGE_ALLOWED`: scope and PR validation allow auto-merge.
- `PROJECT_AUTOMERGE_BLOCKED`: auto-merge was denied with reason.
- `PROJECT_REVIEW_REQUIRED`: scope, risk, or project state requires human decision.
- `PASS_MERGED_AND_CLEANED`: merge and exact branch cleanup completed successfully.

## 7. Permanent Rule

Auto-merge must never be based on blind trust.

Auto-merge is allowed only when both are true:

```text
approved project scope
+
PR Guardian validation
```

If either side is missing, stale, or uncertain, the result must be `PROJECT_AUTOMERGE_BLOCKED` or `PROJECT_REVIEW_REQUIRED`.
