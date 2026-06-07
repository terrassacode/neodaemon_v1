# Project Delivery Protocol

## Purpose

Define a lightweight documentation protocol for medium or large projects. It preserves context across phases and reduces dependence on conversation history. This protocol does not grant new permissions.

## When To Use

Use it when work has multiple phases, multiple PRs, external review, high ambiguity, or a real risk of losing context.

## Roles

- **Albert:** decides priorities, approvals, merges, and stops.
- **GPT Operator:** structures requests, criticizes scope, and asks NeoDaemon for proposals.
- **NeoDaemon:** proposes, executes approved minimal changes, validates, and reports.
- **GPT Reviewer:** reviews outputs, risks, contradictions, and next actions.

## Phases

1. Project Brief
2. Work Breakdown
3. Phase Proposal
4. Critical Review
5. Human Approval
6. Execution
7. Validation
8. State Update
9. Next Phase or Stop

## Recommended Artifact

```text
docs/status/project-delivery-<slug>.md
```

Create this artifact only when a real project needs it.

## Minimal Artifact Template

```text
Project:
Goal:
Non-goals:
Current phase:
Done:
Blocked:
Next action:
Open PRs:
Risks:
```

## Stop Rules

Stop and ask when there is ambiguity, scope creep, sensitive risk, dirty `main`, failed validation, or more than one executable PR competing for attention.

## Limits

- No more than one executable PR in flight per project phase.
- No new permissions.
- No execution without `OK FEATURE` or equivalent explicit approval.
