# PR Guardian Contract

## 1. Status

Contract only.

This document defines the minimum responsibility boundary for PR Guardian.

PR Guardian has a dedicated controlled entrypoint:

```text
tools/pr_guardian.sh
```

NeoDaemon invokes PR Guardian through its existing controlled executor action. This contract does not create an agent, scheduler, queue, or automatic merge policy.

## 2. Mission

PR Guardian has one mission:

```text
Protect main and execute safe PR check, merge, and cleanup.
```

PR Guardian exists to make PR finalization mechanical, safe, auditable, and separated from feature creation.

## 3. Scope

PR Guardian is responsible only for PR safety and finalization.

Its scope begins when a PR exists and a human provides an allowed input.

Its scope ends when it returns evidence for one PR.

## 4. Allowed Responsibilities

PR Guardian may:

- check a PR;
- determine whether a PR is safe to merge;
- merge one PR if safe;
- cleanup the exact local branch for that PR;
- cleanup the exact remote branch for that PR;
- return evidence.

Evidence should include:

- PR number;
- branch;
- commit or merge commit;
- files touched;
- validations;
- blockers;
- cleanup result;
- final main state;
- rollback recommendation.

## 5. Prohibited Responsibilities

PR Guardian must not:

- create features;
- write code;
- decide priorities;
- modify runtime;
- modify gateway;
- modify model routing;
- execute jobs;
- create or run a scheduler;
- auto-merge a queue;
- run free shell commands;
- accept arbitrary user commands;
- merge multiple PRs in one execution;
- delete unrelated branches;
- touch unknown external PRs.

## 6. Allowed Inputs

PR Guardian accepts only these human inputs:

```text
CHECK PR #123
MERGE PR #123
```

Inputs must identify exactly one PR.

Any malformed input must be rejected.

## 7. Allowed Outputs

PR Guardian may return only these final statuses:

```text
PASS_READY_TO_MERGE
WAITING_FOR_CHECKS
BLOCKED_WITH_REASON
NO_VERIFICADO
PASS_MERGED_AND_CLEANED
PARTIAL_MERGE_CLEANUP_FAILED
```

Meaning:

- `PASS_READY_TO_MERGE`: PR is safe to merge, but no merge was performed.
- `WAITING_FOR_CHECKS`: required checks are still pending.
- `BLOCKED_WITH_REASON`: PR is unsafe or policy-blocked.
- `NO_VERIFICADO`: PR safety cannot be verified.
- `PASS_MERGED_AND_CLEANED`: PR was merged and exact branch cleanup succeeded.
- `PARTIAL_MERGE_CLEANUP_FAILED`: merge succeeded but cleanup or final verification did not fully complete.

## 8. Safety Rules

PR Guardian must enforce:

- deny-by-default;
- one PR per execution;
- PR base must be `main`;
- repository must be expected;
- no external forks;
- no protected zones;
- no sensitive paths;
- no force push;
- no reset;
- no stash;
- no rebase;
- cleanup only the exact PR branch;
- checks pending are never pass;
- unknown verification is never pass;
- failing checks block;
- mergeability conflicts block.

## 9. Relationship With NeoDaemon

NeoDaemon creates PRs.

PR Guardian checks, merges, and cleans PRs.

NeoDaemon must not decide to bypass PR Guardian when PR Guardian is the designated merge authority.

NeoDaemon may still propose features, implement changes, validate work, and report evidence. PR Guardian owns only the final PR gate.

NeoDaemon acts as invoker for PR Guardian. It must preserve PR Guardian inputs, outputs, and safety rules when routing requests.

The intended separation is:

```text
NeoDaemon creates and validates work.
PR Guardian protects main and finalizes PRs.
Albert remains the decision authority.
```

## 10. Success Criteria

PR Guardian succeeds when a future dedicated component reproduces the current PR Autopilot behavior while isolated behind this contract.

Success means:

- same safety behavior;
- same allowed inputs;
- same allowed outputs;
- same deny-by-default posture;
- same exact-branch cleanup policy;
- clearer responsibility separation.

## 11. Out Of Scope

This contract does not define:

- implementation language;
- scheduler behavior;
- queue processing;
- autonomous merge policy;
- dashboard UI;
- notification routing;
- runtime permissions;
- gateway configuration;
- model selection.

## 12. Future Isolation Path

A future implementation may extract PR Guardian from NeoDaemon only if it preserves this contract.

The extraction path should be:

1. keep current behavior stable;
2. define tests against this contract;
3. move PR check/merge/cleanup behind a dedicated controlled entrypoint;
4. verify outputs match existing PR Autopilot behavior;
5. keep NeoDaemon responsible for feature creation and evidence reporting.

No future extraction may weaken the safety rules in this contract.
