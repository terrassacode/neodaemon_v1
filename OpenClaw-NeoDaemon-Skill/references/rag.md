# RAG

## Role

RAG is a fallback for knowledge/document questions. It must not consume operational commands that have explicit routing.

## Operational Commands Before RAG

`OK CLEANUP <short_hash>` must route to the cleanup assistant before RAG.

If a message looks operational, verify routing before answering as documentation.

## Known Risk

A command can be misclassified as a RAG query and return irrelevant context. This happened with `OK CLEANUP f163328` before Telegram routing was patched.

## Sources To Read

- `docs/status/telegram-ok-cleanup-routing-v1.md`
- `docs/status/ssh-and-hash-cleanup-workflow-v1.md`
