# NeoDaemon Current Capabilities V1

## Status

Current capability boundary.

This document is evidence-oriented and does not change runtime behavior.

## Purpose

Separate what NeoDaemon can currently claim as verified from what is partial or not verified.

NeoDaemon must not present future design goals as current runtime capability.

## VERIFIED

These capabilities are demonstrated with repo, PR, or controlled validation evidence.

### Controlled documentation changes

NeoDaemon can prepare controlled documentation changes through branch, PR, validation, merge confirmation, and cleanup.

Evidence includes repeated successful documentation PRs and PR Guardian checks.

### Documentation PRs

NeoDaemon can create small documentation PRs inside approved documentation perimeters.

Evidence includes DOCS-domain documentation PRs created and checked through controlled routes.

### Checks before merge

NeoDaemon can run CHECK PR validation before merge.

Evidence includes PR Guardian outputs such as:

```text
PASS_READY_TO_MERGE
```

### DOCS domain automerge

The DOCS domain automerge path has been validated end-to-end for LOW-risk documentation.

Evidence:

```text
PROJECT_AUTOMERGE_ALLOWED_DRY_RUN
PASS_MERGED_AND_CLEANED_AUTO
```

Validated boundary:

```text
OpenClaw-NeoDaemon-Skill/references/
docs/
.md
.json
```

### Evidence protocol

The evidence protocol exists as a documentary protocol for answering questions with structured sources.

Evidence:

```text
OpenClaw-NeoDaemon-Skill/references/evidence_protocol_v1.md
```

### CORECLAW project reference bridge

CORECLAW has a documentary project reference bridge.

Evidence:

```text
task_manager/projects/neodaemon.json
```

The bridge records expected startup files, but it is not runtime loading proof.

## PARTIAL

These capabilities exist, but are limited, incomplete, or dependent on controlled compatibility routes.

### Project Executor

The Project Executor model is documented and partially followed operationally.

It is not yet a complete dedicated runtime executor implementation.

### knowledge/

`knowledge/` exists as a minimal documental structure.

It is not a populated knowledge base, RAG index, or runtime source of truth.

### CORECLAW startup context

CORECLAW source files exist and are referenced.

Current status:

```text
runtime_loading_verified=false
missing_runtime_bridge=true
```

### Image Inbox

Image Inbox has static/plugin-related evidence and controlled proof attempts.

Runtime proof remains incomplete where plugin loaded and route registered evidence is missing.

### GitHub automation outside DOCS

GitHub automation exists through controlled routes and PR Guardian.

Outside DOCS, automation remains constrained by manual review, protected paths, and existing allowlists.

## NOT VERIFIED

These capabilities are designed, desired, or future-oriented, but must not be claimed as working runtime capability.

### CORECLAW runtime loader

A CORECLAW runtime loader is not verified.

### RAG over knowledge/

No RAG over `knowledge/` is verified.

### Complete autonomy

Full autonomous operation is not verified.

Albert remains the decision owner for scope exceptions, merge decisions, cleanup confirmations, and sensitive actions.

### Safe free shell

Safe unrestricted shell execution is not verified and is not part of the operating model.

### Gateway/runtime/model modification

NeoDaemon must not claim capability to safely modify gateway, runtime, routing, models, sandbox, or sensitive configuration without explicit approval and project review.

### Automatic startup memory loading

Automatic startup loading of memory or CORECLAW files is not verified as runtime behavior.

## RULE

NeoDaemon must not declare as `VERIFIED` anything that is only designed, documented, inferred, or desired.

If evidence is static only, use `PARTIAL`.

If runtime proof is missing, say so explicitly.

If sources conflict, apply the source hierarchy and report uncertainty.

Evidence beats aspiration.
