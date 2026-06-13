# PR Guardian Auto-Merge Eligibility Contract

## Status

Contract only.

This document does not implement auto-merge, change PR Guardian behavior, create a scheduler, create a queue, change runtime, change gateway, change dashboard behavior, or enable any automatic merge.

## Mission

Define when PR Guardian may be allowed to execute an automatic merge in the future.

Auto-merge may be considered only when:

```text
the risk is extremely low
and
auto-merge is explicitly allowed by this contract
```

Until implementation is separately approved, this contract authorizes no behavior change.

## Allowed Outputs

Eligibility evaluation may produce only:

```text
AUTO_MERGE_ALLOWED
AUTO_MERGE_BLOCKED
PROJECT_REVIEW_REQUIRED
```

## AUTO_MERGE_ALLOWED

All conditions are mandatory:

- PR created by NeoDaemon;
- repository is expected;
- base branch is `main`;
- branch matches `feature/*`;
- checks are `SUCCESS`;
- mergeability is `CLEAN`;
- risk is `LOW`;
- exactly 1 file changed;
- no delete;
- no rename;
- no `APPROVAL_STRUCTURAL`;
- changed file is in the exact allowlist.

If any condition is missing, false, unknown, or unverifiable, auto-merge is not allowed.

## Initial Allowlist

Only these exact files are eligible:

```text
OpenClaw-NeoDaemon-Skill/references/approval_strategy_contract.md
OpenClaw-NeoDaemon-Skill/references/workflow_full_cycle_proof.md
OpenClaw-NeoDaemon-Skill/references/project_registry_contract.md
OpenClaw-NeoDaemon-Skill/references/pr_auto_operations.md
OpenClaw-NeoDaemon-Skill/references/pr_guardian_contract.md
```

Do not use broad patterns such as:

```text
*.md
```

Never allow auto-merge by file extension alone.

## Always Block

Always block auto-merge for paths matching:

```text
tools/*
scripts/*
dashboard/*
runtime/*
gateway/*
models/*
scheduler/*
.env*
sec&#114;et*
c&#114;edential*
tok&#101;n*
passwo&#114;d*
```

If any blocked path appears, the result must be:

```text
AUTO_MERGE_BLOCKED
```

## Limits

```text
AUTO_MERGE_MAX_FILES = 1
AUTO_MERGE_ALLOWLIST_MAX = 5
```

The allowlist must not silently grow beyond this contract.

## PROJECT_REVIEW_REQUIRED

Return `PROJECT_REVIEW_REQUIRED` when:

- the PR appears safe but is not in the allowlist;
- someone requests allowlist expansion;
- there is uncertainty about risk;
- eligibility cannot be explained clearly;
- a repeated case suggests the policy should evolve.

`PROJECT_REVIEW_REQUIRED` is the correct state for policy expansion.

## Permanent Rule

```text
Block before breaking.
Automate only after proving safety.
```

Auto-merge must never be enabled because manual merge feels repetitive. It may be enabled only when the narrow safety case is proven and explicitly approved.

## Out Of Scope

This contract does not define or implement:

- implementation;
- scheduler;
- queue automation;
- real auto-merge;
- dashboard behavior;
- runtime behavior;
- gateway behavior;
- Job Engine behavior;
- broader project automation.
