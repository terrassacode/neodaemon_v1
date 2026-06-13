# PR Auto Operations

## Status

Operational reference for daily PR Auto usage.

This document does not create a scheduler, queue, dashboard, gateway change, runtime change, or automatic merge policy.

## Purpose

PR Auto is the daily operating flow for safe PR check, merge, and cleanup through PR Guardian.

PR Guardian is the primary path for PR finalization.

Legacy manual cleanup remains available only as fallback.

## Inputs

Allowed human inputs:

```text
CHECK PR #123
MERGE PR #123
```

Any malformed input must be blocked.

## When To Use CHECK PR #123

Use `CHECK PR #123` when you want to know whether a PR is safe to merge without changing anything.

Expected behavior:

- inspect exactly one PR;
- run the same safety rules as merge;
- do not merge;
- do not cleanup;
- return evidence.

## When To Use MERGE PR #123

Use `MERGE PR #123` when the human explicitly wants PR Guardian to finalize one PR.

Expected behavior:

1. run the same check gate first;
2. require `PASS_READY_TO_MERGE`;
3. merge exactly one PR;
4. synchronize local `main`;
5. cleanup only the exact PR branch locally and remotely;
6. verify final main state.

## Outputs And Actions

### PASS_READY_TO_MERGE

Meaning: the PR passed check mode and is safe to merge.

Action:

```text
Use MERGE PR #123 if Albert wants to finalize it.
```

### WAITING_FOR_CHECKS

Meaning: required checks are still pending.

Action:

```text
Wait and retry CHECK PR #123 later.
```

Do not merge.

### BLOCKED_WITH_REASON

Meaning: the PR is unsafe or policy-blocked.

Action:

```text
Read blockers. Fix the cause or escalate to PROJECT_REVIEW_REQUIRED.
```

Do not merge.

### NO_VERIFICADO

Meaning: PR Guardian could not verify PR safety.

Action:

```text
Do not merge. Retry only after the missing verification source is available.
```

If repeated, escalate to `PROJECT_REVIEW_REQUIRED`.

### PASS_MERGED_AND_CLEANED

Meaning: the PR was merged, main synchronized, and exact branch cleanup completed.

Action:

```text
Continue project flow or mark project done if closure criteria are met.
```

### PARTIAL_MERGE_CLEANUP_FAILED

Meaning: the merge completed, but cleanup or final verification did not fully complete.

Action:

```text
Stop automatic continuation. Inspect evidence. Use legacy cleanup fallback only if safe.
```

Escalate to `PROJECT_REVIEW_REQUIRED` if cleanup failure repeats or is unclear.

## PROJECT_REVIEW_REQUIRED Triggers

Escalate to `PROJECT_REVIEW_REQUIRED` when:

- blockers repeat;
- verification remains unknown;
- cleanup partially fails;
- checks repeatedly fail for the same reason;
- PR count exceeds planned PRs;
- manual fallback is needed repeatedly;
- approval or merge flow becomes structurally unclear.

## Legacy Cleanup Fallback

Legacy manual cleanup remains available only as fallback.

It should be used when:

- PR Guardian cannot complete cleanup;
- evidence proves the exact branch is safe to delete;
- Albert explicitly approves the fallback.

Legacy cleanup is not the primary path.

## Primary Rule

```text
PR Guardian is the primary PR finalization path.
Manual cleanup is legacy fallback.
```

No scheduler. No queue. No auto-merge without explicit human input.
