# Project State

## Current Snapshot

NeoDaemon is in active transition from the Assistant-Controlled Model to the Project Executor Model.

Compact executive state lives in:

```text
task_manager/projects/neodaemon.json
```

The current behavioral source of truth is:

```text
OpenClaw-NeoDaemon-Skill/references/neodaemon_operating_model_v2.md
```

The current role source of truth is:

```text
OpenClaw-NeoDaemon-Skill/references/openclaw_role_model_v1.md
```

## Current Categories

- DONE: Skill baseline, Master Handoff, OK CLEANUP hash workflow, task_manager seed, documentation perimeter decision, Operating Model v2, Role Model v1, Skill Project Executor alignment.
- WATCH: Project Executor implementation, docs/** perimeter implementation, runtime state validation, dashboard executive observability.
- BLOCKED: current runtime/service/Gmail/dashboard state remains `NO_VERIFICADO` until inspected through a safe read-only route.

## Recent Evidence

Recent PRs supporting this state:

```text
PR #100 - OK CLEANUP runtime fix documentation
PR #101 - MASTER_HANDOFF
PR #102 - task_manager publish path support
PR #103 - task_manager seed
PR #104 - Project Executor documentation perimeter decision
PR #105 - NeoDaemon Operating Model v2
PR #106 - MASTER_HANDOFF Project Executor alignment
PR #107 - OpenClaw Role Model v1
PR #108 - Skill Project Executor documentation audit
```

## How To Update

Keep this file short. Update `task_manager/projects/neodaemon.json` for executive state and use detailed status documents only when they add durable evidence.

Do not treat runtime, service, dashboard, or Gmail state as verified unless inspected in the current task through a safe read-only route.

## Sources To Read

- `task_manager/projects/neodaemon.json`
- `OpenClaw-NeoDaemon-Skill/MASTER_HANDOFF.md`
- `OpenClaw-NeoDaemon-Skill/references/neodaemon_operating_model_v2.md`
- `OpenClaw-NeoDaemon-Skill/references/openclaw_role_model_v1.md`
- `OpenClaw-NeoDaemon-Skill/references/project_executor_documentation_perimeter.md`
