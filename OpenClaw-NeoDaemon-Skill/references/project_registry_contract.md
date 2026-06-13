# Project Registry Contract

## Status

Contract only.

This document defines the minimum project registry record for the Albert ↔ GPT ↔ NeoDaemon ↔ PR Guardian ecosystem.

It does not implement code, create a real JSON file, create persistence, create a dashboard, create a scheduler, modify runtime, modify gateway, modify PR Guardian, or modify the NeoDaemon executor.

## Purpose

The project registry exists to answer, with minimum state:

- what project is active;
- how many PRs were planned;
- how many PRs actually exist;
- whether approvals are appearing;
- whether the project is blocked;
- what the next action is.

The registry is a coordination contract, not an implementation.

## Minimal Project Record

Each project record must contain only these fields:

| Field | Meaning |
| --- | --- |
| `project_id` | Stable project identifier. |
| `title` | Short human-readable project title. |
| `objective` | Final objective of the project. |
| `status` | Current project lifecycle state. |
| `planned_prs` | Number of PRs expected at project start or last review. |
| `actual_prs` | Number of PRs created so far. |
| `approvals` | Approval counters only. |
| `risk_level` | Current project risk level. |
| `risk_reason` | Short reason for the current risk level. |
| `next_action` | Required next action. |

No additional fields are part of the minimum contract.

## Allowed Status Values

Only these project states are allowed:

```text
PROJECT_CREATED
PROJECT_ACTIVE
PROJECT_BLOCKED
PROJECT_REVIEW_REQUIRED
PROJECT_DONE
PROJECT_ABORTED
```

No extra lifecycle states should be introduced by the registry.

## Approvals

The `approvals` field stores counters only:

| Counter | Meaning |
| --- | --- |
| `correct` | Count of approvals classified as `APPROVAL_CORRECT`. |
| `incorrect` | Count of approvals classified as `APPROVAL_INCORRECT`. |
| `structural` | Count of approvals classified as `APPROVAL_STRUCTURAL`. |

The registry must not store:

- long commands;
- complete approval logs;
- shell scripts;
- sensitive values;
- private access material;
- raw provider output.

## Risk

Allowed `risk_level` values:

```text
LOW
MEDIUM
HIGH
```

`risk_reason` is mandatory.

The reason should be short and operational, for example:

- `documentation only`;
- `merge automation touched`;
- `approval repetition detected`;
- `blocked by checks`;
- `project exceeded planned PRs`.

## Next Action

`next_action` is mandatory.

It must answer:

```text
What do we do now?
```

Examples:

```text
MERGE PR #167
FEATURE_PR_GUARDIAN_CONTRACT
PROJECT_REVIEW_REQUIRED
PROJECT_DONE
```

If the next action is not known, the project should not pretend to be active. It should move to `PROJECT_BLOCKED` or `PROJECT_REVIEW_REQUIRED`.

## Out Of Scope

This contract does not define or create:

- real `registry.json`;
- database storage;
- persistence layer;
- dashboard;
- automation;
- scheduler;
- runtime behavior;
- gateway behavior;
- Job Engine behavior;
- advanced historical metrics.

## Future Use

This contract is intended to support future work in:

- Project Workflow;
- Approval Strategy;
- PR Guardian;
- Job Engine;
- Dashboard.

Future implementations must preserve the minimum record before adding derived views or historical metrics.
