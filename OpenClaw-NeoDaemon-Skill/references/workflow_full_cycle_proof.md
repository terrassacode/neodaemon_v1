# Workflow Full Cycle Proof

## Purpose

Prove the GPT ↔ NeoDaemon ↔ PR Guardian workflow with a small documentation-only PR that is eligible for controlled auto-merge.

The proof demonstrates that NeoDaemon can create a PR, PR Guardian can evaluate auto-merge eligibility, and `mode=auto` can merge and clean up only when the exact low-risk policy allows it.

## Actors

### Albert

Albert defines the objective and keeps final decision authority over the workflow rules.

### GPT

GPT proposes the feature, checks intent, and defines the next action.

### NeoDaemon

NeoDaemon implements the approved documentation change, creates the PR, validates evidence, and reports results.

### PR Guardian

PR Guardian protects `main`, checks PR state, evaluates auto-merge eligibility, merges only when allowed, cleans exact branches, and returns evidence.

## Full Cycle

```text
GPT proposes
↓
NeoDaemon creates PR
↓
PR Guardian check
↓
PASS_READY_TO_MERGE
↓
PR Guardian auto eligibility
↓
AUTO_MERGE_ALLOWED
↓
merge
↓
sync main
↓
cleanup local
↓
cleanup remote
↓
PASS_MERGED_AND_CLEANED
↓
GPT defines next action
```

If eligibility is not allowed, the workflow stops before merge and falls back to the explicit manual command path.

## Success Criteria

A full cycle succeeds when all criteria pass:

- one documentation PR is created;
- only this file changes;
- `CHECK PR #123` returns `PASS_READY_TO_MERGE`;
- auto eligibility returns `AUTO_MERGE_ALLOWED`;
- `mode=auto` merges only after eligibility passes;
- cleanup local passes;
- cleanup remote passes;
- `main` is clean and synchronized;
- next action is defined.

## Failure Cases

### AUTO_MERGE_BLOCKED

Auto-merge is not allowed.

Action:

```text
Do not auto-merge. Use MERGE PR #123 only if Albert explicitly approves.
```

### PROJECT_REVIEW_REQUIRED

The PR appears safe but policy is unclear or needs expansion.

Action:

```text
Do not auto-merge. Escalate for review.
```

### WAITING_FOR_CHECKS

Checks are still pending.

Action:

```text
Wait, then retry CHECK PR #123 or mode=auto later.
```

### BLOCKED_WITH_REASON

PR Guardian found a blocker.

Action:

```text
Fix the blocker or escalate.
```

### NO_VERIFICADO

The PR cannot be verified.

Action:

```text
Do not merge. Restore verifiability first.
```

### PARTIAL_MERGE_CLEANUP_FAILED

Merge happened but cleanup or final verification failed.

Action:

```text
Stop. Inspect evidence. Use legacy cleanup only with exact branch safety.
```

## Permanent Rule

```text
GPT designs.
NeoDaemon implements.
PR Guardian protects main.
Albert keeps final decision authority.
Block before breaking.
```
