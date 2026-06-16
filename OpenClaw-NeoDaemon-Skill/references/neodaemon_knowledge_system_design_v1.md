# NeoDaemon Knowledge System Design v1

## Status

Design only. No runtime behavior is changed by this document.

## Goal

Define a structured operational knowledge system for NeoDaemon.

The purpose is to replace scattered conversational memory with explicit, versioned and citable knowledge documents.

This system should help NeoDaemon answer questions such as:

- Why does Human Approval exist?
- Why do protected zones exist?
- What is the role of PR Guardian?
- What is Image Inbox?
- What is the difference between documentation memory and runtime context?

The system must be simple, auditable and compatible with future RAG or OKF-style catalogs.

## Difference from MEMORY.md

`MEMORY.md` is curated long-term memory.

It should contain:

- durable lessons;
- Albert preferences;
- strategic project direction;
- important current context;
- high-level summaries.

It should not become:

- a full architecture manual;
- a decision log archive;
- a project encyclopedia;
- a replacement for RAG;
- a dumping ground for every event.

The knowledge system is different.

It stores focused operational documents that can be searched, cited and maintained independently.

## Difference from Skill References

`OpenClaw-NeoDaemon-Skill/references/` contains operational guidance, contracts and protocols.

The knowledge system should not duplicate those documents.

Instead:

- Skill references define how NeoDaemon should operate.
- Knowledge documents explain why decisions exist and what they mean.
- If a rule is procedural, keep it in Skill references.
- If a topic is explanatory, historical or citable, store it in the knowledge system.

Example:

- `project_delivery_protocol.md` explains the delivery protocol.
- `knowledge/decisions/why_human_approval_exists.md` explains why Human Approval exists.

## Proposed Structure

Initial structure:

```text
knowledge/
├── architecture/
├── decisions/
├── protected_zones/
├── projects/
└── incidents/


## Single Source of Truth

Every concept must have one canonical document.

References may link to Knowledge.

Knowledge may link to References.

The same information must never be maintained twice.

If duplication appears:

1. Choose one canonical source.
2. Convert the other document into a pointer.
3. Remove duplicated explanations.

Examples:

GOOD

references/project_delivery_protocol.md
↓

knowledge/decisions/why_human_approval_exists.md

One explains HOW.
The other explains WHY.

BAD

references/security.md

knowledge/security.md

Both containing the same explanations.


## Glossary

The knowledge system should contain a glossary.

Purpose:

Provide short, canonical definitions for important concepts.

Examples:

knowledge/glossary/

- coreclaw.md
- human_approval.md
- pr_guardian.md
- project_executor.md
- image_inbox.md
- operational_control_plane.md

Rules:

- Maximum one page.
- Definition first.
- Links to architecture or decisions if needed.
- No implementation details.

## Document Lifecycle

Create a document when:

- a concept becomes important;
- a decision affects future architecture;
- the same question appears repeatedly;
- a failure teaches an important lesson.

Update a document when:

- the concept evolves;
- architecture changes;
- security rules change.

Delete a document when:

- it is obsolete;
- another document replaces it;
- it violates Single Source of Truth.

Avoid:

- temporary notes;
- chat transcripts;
- duplicated explanations;
- implementation dumps.

## Future Compatibility

The knowledge system should remain compatible with:

- RAG retrieval systems;
- Open Knowledge Format (OKF);
- startup context loaders;
- agent memory systems;
- future NeoDaemon runtimes.

The initial implementation should remain:

- markdown only;
- human readable;
- git versioned;
- searchable;
- optional for runtime.

Knowledge must help NeoDaemon think better.

It must not become another source of confusion.


## Current Status

Status:

DESIGN APPROVED

Implementation:

NOT STARTED

Runtime Integration:

NOT STARTED

RAG Integration:

NOT STARTED


