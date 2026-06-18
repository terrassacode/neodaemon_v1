# Project Automerge Event Ledger Design V1

## Status

Design only. Do not implement from this document alone.

## Goal

Define a minimal event ledger for PROJECT_AUTOMERGE decisions before expanding AUTO scope or adding dashboards.

## Runtime ledger path

The ledger must live outside the repository runtime tree:

```text
/home/openclaw/.openclaw/neodaemon/automerge_ledger/events.jsonl
```

Reason:

- avoid dirtying the Git working tree
- avoid merge loops caused by runtime writes
- keep operational event history separate from source-controlled design files

## Format

The ledger format is JSON Lines:

```text
one JSON object per line
```

The ledger is append-only.

Existing events must not be rewritten automatically.

## Allowed events

Only these event names are allowed in V1:

- dry_run_allowed
- dry_run_blocked
- auto_apply_success
- auto_apply_blocked
- manual_merge

## Minimal fields

Each event must include:

- timestamp
- event
- pr
- project_id
- decision
- mutation_performed
- reason
- commit

Example:

```json
{"timestamp":"2026-06-18T12:35:00+02:00","event":"auto_apply_success","pr":222,"project_id":"PROJECT_AUTOMERGE_DRY_RUN_TEST","decision":"PASS_MERGED_AND_CLEANED_AUTO","mutation_performed":true,"reason":"","commit":"feeb738fe50a1351f589989bdb9640d719526dd6"}
```

## Single writer

The only writer should be PR Guardian.

Reason:

PR Guardian has the final verified decision context:

- PROJECT_SCOPE_ALLOWED
- dry-run decision
- auto apply decision
- merge result
- cleanup result
- mutation_performed

## Components that must not write

The ledger must not be written by:

- executor
- publisher
- dashboard
- runtime services
- gateway

Those components may read future summarized views only after a separate design and approval.

## Data that must not be stored

The ledger must not store private or sensitive operational material, including:

- access material such as to-kens
- au-th headers
- diffs
- PR body
- raw logs
- sec-ret material
- cred-ential material
- personal data
- stderr/stdout dumps

Reasons should be short, explicit, and sanitized.

## Dashboard policy

No dashboard in V1.

No UI in V1.

The ledger is operational evidence only.

## Failure policy

A ledger write failure must not silently fake success.

Recommended behavior for future implementation:

- if merge/apply has not happened yet, block before mutation if ledger cannot be prepared
- if merge/apply already happened, report ledger write failure explicitly as partial operational evidence failure
- never rewrite main
- never force push

## Rollback

Rollback for bad source changes remains:

```text
create controlled revert PR
```

Rollback must not use:

- reset main
- force push
- history rewrite

## Non-goals

This design does not implement:

- ledger writing
- dashboard
- UI
- AUTO expansion
- new PROJECT_SCOPE approvals
- runtime service changes
