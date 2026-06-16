# CORECLAW Source Hierarchy v1

## Status

Design only. No runtime behavior is changed by this document.

## Goal

Define which CORECLAW source has priority when two sources disagree.

This avoids contradictions between:

- AGENTS.md
- SOUL.md
- USER.md
- TOOLS.md
- MEMORY.md
- knowledge/
- RAG
- runtime loader

## Source Priority

Recommended priority order:

1. AGENTS.md
2. SOUL.md
3. USER.md
4. TOOLS.md
5. MEMORY.md
6. knowledge/
7. RAG retrieval results
8. runtime loader

## Rules

AGENTS.md defines hard operating rules.

SOUL.md defines behavior and personality.

USER.md defines Albert-specific preferences.

TOOLS.md defines environment-specific operational notes.

MEMORY.md contains curated long-term memory and strategic summaries.

knowledge/ contains citable operational knowledge and explanations.

RAG retrieves relevant documents, but does not override canonical sources.

The runtime loader is only the mechanism that loads sources. It does not decide truth.

## Conflict Resolution

If sources disagree:

1. Prefer the highest-priority source.
2. Prefer explicit rules over summaries.
3. Prefer current project state over old memory.
4. Prefer verified evidence over assumptions.
5. Report uncertainty if conflict remains.

## Examples

If MEMORY.md says a feature is complete but project_state says it is blocked:

project_state wins.

If RAG retrieves an old decision but AGENTS.md contains a newer rule:

AGENTS.md wins.

If TOOLS.md lists a port and runtime inspection proves another port is active:

runtime evidence wins for current operational facts.

If USER.md says Albert prefers step-by-step work:

that preference applies unless safety requires stopping.

## Safety Rule

No source may override:

- secrets protection;
- no destructive commands without approval;
- protected zones;
- explicit Albert refusal;
- evidence-before-PASS rule.

## Current Status

This hierarchy is documentary.

It becomes operational only when a startup context loader or project reference bridge consumes it.


