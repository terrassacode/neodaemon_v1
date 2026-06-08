# Changelog

## 2026-06-08 - OK CLEANUP runtime routing restored

- Restored `/main OK CLEANUP <hash>` routing through NeoDaemon MAIN / `ask_main`.
- Removed Telegram direct cleanup execution from runtime.
- Confirmed invalid hash `abc1234` returns a visible `BLOCKED` response.
- Confirmed `main` remains clean after blocked cleanup.
- This entry validates the documentation publishing and cleanup workflow:
  feature → publish_doc_folder → PR → manual merge → `OK CLEANUP <hash>`.
