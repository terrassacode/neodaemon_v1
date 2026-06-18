# Project Automerge Apply Design v1

## Status

Design only. Do not implement AUTO real from this document alone.

## Goal

Define how PROJECT_SCOPE automerge can move from validated dry-run to real apply safely.

## Source of truth

The only source of truth for PROJECT_SCOPE automerge eligibility must be:

```text
evaluate_project_scope_pr(..., evaluate_auto=true)
```

No other component should duplicate PROJECT_SCOPE interpretation.

## Shared decision rule

DRY_RUN and APPLY must use the same decision.

AUTO real is allowed only if the same PR would have produced:

```text
PROJECT_AUTOMERGE_ALLOWED_DRY_RUN
```

If dry-run would return any blocked status, AUTO real must not merge.

## Future executor action

Future controlled executor action:

```text
github_pr_automerge_apply
```

It should accept only:

```text
pr_number
```

It should construct the exact confirmation internally:

```text
MERGE PR #<pr_number>
```

It should call PR Guardian only through the controlled mode.

## Future PR Guardian mode

Future PR Guardian mode:

```text
auto
```

The auto mode must call:

```text
evaluate_project_scope_pr(..., evaluate_auto=true)
```

Before any mutation.

## Expected success output

Successful AUTO real should emit:

```text
PASS_MERGED_AND_CLEANED_AUTO
```

The output must distinguish real apply from dry-run.

## Hard conditions

AUTO real must require all of the following:

- PR open
- base main
- repo expected
- branch feature/*
- working tree clean
- checks SUCCESS
- mergeability CLEAN
- PROJECT_SCOPE_ALLOWED
- automerge_allowed=true
- runtime_required=false
- no tools/
- no scripts/
- no gateway/
- no runtime/
- no models/
- no deletes
- no renames
- no sensitive paths

## Mutation boundary

Dry-run must always report:

```text
mutation_performed=false
```

AUTO real may report mutation only after merge/cleanup/sync were attempted:

```text
mutation_performed=true
```

If the decision is not allowed, mutation must remain false.

## Blocked zones

AUTO real must never apply automatically for PRs touching:

- PR Guardian control files
- executor control files
- publisher control files
- gateway
- runtime
- models
- scripts
- tools
- generated or sensitive material

## Rollback

If AUTO real merges content that must be undone, rollback is:

```text
create controlled revert PR
```

Never use:

- reset main
- force push
- branch rewriting

## What this does not enable

This design does not enable:

- auto for PR Guardian
- auto for executor
- auto for publisher
- auto for runtime
- auto for gateway
- any real AUTO merge

## Implementation note

Implementation should be split into small PRs:

1. PR Guardian auto apply gate using evaluate_project_scope_pr(..., evaluate_auto=true)
2. executor route github_pr_automerge_apply
3. low-risk end-to-end test using PROJECT_AUTOMERGE_DRY_RUN_TEST
