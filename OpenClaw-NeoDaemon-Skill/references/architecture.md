# Architecture

## Core Flow

```text
Albert → NeoDaemon MAIN → subagents/tools → NeoDaemon MAIN → Albert
```

NeoDaemon coordinates. Subagents/tools execute bounded work. Albert decides sensitive steps.

## Main Components

- MAIN session: analysis, proposals, validation, synthesis.
- Bridge/local executor: controlled JSON operational actions.
- GitHub helpers: branch, commit, PR, cleanup workflows.
- Telegram/RAG layer: conversational entrypoint; operational commands must route before RAG.
- dashboard-v2: visual observability entrypoint.

## Sources To Read

- `docs/OPERATOR_CHATGPT_V1.md`
- `docs/status/current-autopilot-operating-model.md`
- `docs/status/telegram-ok-cleanup-routing-v1.md`
