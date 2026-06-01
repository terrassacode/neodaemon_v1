# 02_DECISIONS

## Decision 001 — Use GitHub as external versioned context

Status: accepted

ChatGPT will not be treated as the primary long-term memory.

GitHub will store the stable project state, key decisions, and restart prompts.

Rationale:

- Long chats can degrade precision.
- Versioned Markdown files are auditable.
- A repository creates a stable source of truth outside the chat.
- New ChatGPT sessions can restart from documented context instead of relying on hidden conversation memory.

## Decision 002 — Verify every write with read-back

Status: accepted

No GitHub write is considered successful until the written file is fetched and read back.

Rationale:

- Apparent permissions may be misleading.
- Previous tests showed metadata access and apparent push capability, but content writes failed with `403 — Resource not accessible by integration`.
- Read-back verification prevents false positives.

## Decision 003 — Do not store sensitive information

Status: accepted

The repository must not contain:

- API tokens;
- passwords;
- private keys;
- production secrets;
- sensitive personal data;
- confidential company data;
- medical private data.

Rationale:

The repository is a context and governance layer, not a secrets vault.

## Decision 004 — Prefer concise operational files

Status: accepted

The context files should remain concise, structured, and directly useful for restarting work.

Rationale:

The objective is to reduce context drift, not to create another overloaded memory system.

## Decision 005 — Use `egaracode/chatgpt-context-system` as the working repository

Status: accepted

The previous repository `terrassacode/chatgpt-context-system` is not used for ChatGPT write workflows because content writes failed with `403`.

The repository `egaracode/chatgpt-context-system` is used because write access was validated with `write_test.md` and confirmed by read-back.
