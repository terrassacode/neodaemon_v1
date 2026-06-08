# Architecture

## Core Flow

```text
Albert → NeoDaemon MAIN → subagents/tools → NeoDaemon MAIN → Albert
```

NeoDaemon coordinates and executes approved project work inside the approved perimeter. Subagents/tools support execution. Albert decides objectives, Protected Zone exceptions, PR merge, and cleanup.

## Main Components

- MAIN session: objective handling, project execution coordination, validation, synthesis.
- Bridge/local executor: controlled JSON operational actions.
- GitHub helpers: branch, commit, PR, cleanup workflows.
- Telegram/RAG layer: conversational entrypoint; operational commands must route before RAG.
- dashboard-v2: visual observability entrypoint.

## Sources To Read

- `OpenClaw-NeoDaemon-Skill/references/neodaemon_operating_model_v2.md`
- `OpenClaw-NeoDaemon-Skill/references/openclaw_role_model_v1.md`
- `docs/OPERATOR_CHATGPT_V1.md`
- `docs/status/current-autopilot-operating-model.md`
- `docs/status/telegram-ok-cleanup-routing-v1.md`
