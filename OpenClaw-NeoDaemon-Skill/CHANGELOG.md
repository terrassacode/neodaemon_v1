# Changelog

## 2026-06-08 - Project Executor documentation model aligned

- Added and aligned NeoDaemon Operating Model v2, OpenClaw Role Model v1, and Master Handoff Project Executor guidance.
- Updated Skill references to reduce Assistant-Controlled Model language.
- Confirmed task_manager is useful as a compact executive state index and should remain small.
- Current runtime/service/dashboard/Gmail state remains `NO_VERIFICADO` until inspected through a safe read-only route.

## 2026-06-08 - OK CLEANUP runtime routing restored

- Restored `/main OK CLEANUP <hash>` routing through NeoDaemon MAIN / `ask_main`.
- Removed Telegram direct cleanup execution from runtime.
- Confirmed invalid hash `abc1234` returns a visible `BLOCKED` response.
- Confirmed `main` remains clean after blocked cleanup.
- This entry validates the documentation publishing and cleanup workflow:
  feature → publish_doc_folder → PR → manual merge → `OK CLEANUP <hash>`.
