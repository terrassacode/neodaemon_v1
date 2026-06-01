# 00_PROJECT_STATE

## Purpose

This repository is a versioned external context system for ChatGPT work sessions.

ChatGPT should be used as a reasoning engine, not as the primary long-term memory.

## Repository

- GitHub account: `egaracode`
- Repository: `egaracode/chatgpt-context-system`
- Current purpose: store project state, decisions, and handoff prompts for clean session restarts.

## Core problem

Long ChatGPT conversations can degrade over time:

- context becomes too large;
- older decisions may be mixed with newer ones;
- precision may drift;
- hidden assumptions may accumulate;
- restarting work becomes difficult without a stable external source of truth.

## Working principle

The repository is the source of truth.

ChatGPT may read these files at the start of a new session and continue from the documented state.

## Active files

- `00_PROJECT_STATE.md`: current state of the system and operating rules.
- `02_DECISIONS.md`: explicit technical and architectural decisions.
- `99_HANDOFF_PROMPT.md`: restart prompt for a new ChatGPT session.

## Current status

- A previous repository under `terrassacode/chatgpt-context-system` allowed metadata reading but failed on content writes with `403 — Resource not accessible by integration`.
- A new repository under `egaracode/chatgpt-context-system` has been validated.
- Write access was tested with `write_test.md`.
- The file was written and then read back successfully.

## Operating rules

1. Do not store secrets, credentials, tokens, passwords, medical private data, or sensitive personal data.
2. Every important decision must be written to `02_DECISIONS.md`.
3. Every new session should start by reading `99_HANDOFF_PROMPT.md` and then the current state files.
4. Do not assume GitHub writes worked unless the file is read back successfully.
5. Treat apparent permissions such as `push: true` as insufficient until write + read is verified.
6. Keep files concise and operational.

## Next recommended steps

1. Use this repo as the stable handoff layer between ChatGPT sessions.
2. Update `00_PROJECT_STATE.md` after major milestones.
3. Update `02_DECISIONS.md` when architecture or workflow choices are made.
4. Use `99_HANDOFF_PROMPT.md` to restart work in a new chat without relying on long conversation memory.
