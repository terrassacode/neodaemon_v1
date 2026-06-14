# CORECLAW Startup Context Loader Design v1

## Status

Design only. No runtime behavior is changed by this document.

## Finding

CORECLAW files exist, but current evidence does not prove they are loaded into NeoDaemon runtime/startup context.

Verified audit result:

- `core_files_exist=true`
- `runtime_loading_verified=false`
- `missing_runtime_bridge=true`
- `runtime_evidence=[]`

This means CORECLAW is currently verified as documentary/project material, not as an operational startup context bridge.

## Goal

Define a minimal safe design for connecting CORECLAW files to NeoDaemon operational context.

Core files:

- `AGENTS.md`
- `SOUL.md`
- `USER.md`
- `TOOLS.md`
- `MEMORY.md`

## 1. Component responsible for loading CORECLAW

Preferred component:

- OpenClaw agent startup context assembly layer.

Fallback component if the startup layer is not directly available:

- A project reference bridge that explicitly declares which CORECLAW files must be included for NeoDaemon MAIN sessions.

The loader should not live in PR Guardian, executor scripts, or project validation tools. Those components can validate files, but they should not define agent identity or memory-loading behavior.

## 2. When CORECLAW should load

Load CORECLAW during session startup, before the agent begins normal task execution.

Recommended points:

1. Resolve session type.
2. Resolve workspace/project root.
3. Resolve whether the context is private MAIN or shared/group.
4. Load approved CORECLAW files according to policy.
5. Attach a small provenance marker to startup context.

Do not load CORECLAW dynamically during arbitrary tool execution.

## 3. Files to include always

For NeoDaemon MAIN private sessions, always include:

- `AGENTS.md`
- `SOUL.md`
- `USER.md`
- `TOOLS.md`

These define operating rules, persona, user preferences, and environment notes.

## 4. Files to include only in main/private session

Include only in private MAIN sessions:

- `MEMORY.md`

Reason:

- long-term memory can contain personal/project context and must not leak into shared/group contexts.

## 5. Files to exclude in groups/shared context

In group/shared contexts, exclude:

- `MEMORY.md`
- any user-personal memory supplements
- private notes not explicitly approved for the group

Shared/group contexts may include a reduced public-safe subset:

- `AGENTS.md` if needed for behavior rules
- limited project instructions explicitly marked safe for shared context

Default should be deny-by-default for memory material.

## 6. Recommended loading order

Recommended order:

1. `AGENTS.md`
2. `SOUL.md`
3. `USER.md`
4. `TOOLS.md`
5. `MEMORY.md` only if private MAIN session

Rationale:

- operational rules first;
- persona second;
- user preferences third;
- environment/tool notes fourth;
- long-term memory last, because it is contextual and most sensitive.

## 7. Security limits

The loader must:

- load only exact approved filenames;
- read only from the resolved workspace root;
- reject symlinks unless explicitly approved;
- reject path traversal;
- never read private environment files or private config material;
- never include private access material;
- redact or block suspicious content if detected;
- avoid broad filesystem search;
- avoid runtime mutation;
- avoid gateway/runtime restarts;
- record provenance without exposing private content.

For shared contexts, the loader must use a stricter allowlist and exclude `MEMORY.md` by default.

## 8. Size limits / context budget

Recommended initial limits:

- `AGENTS.md`: max 20 KB
- `SOUL.md`: max 12 KB
- `USER.md`: max 12 KB
- `TOOLS.md`: max 16 KB
- `MEMORY.md`: max 32 KB in private MAIN only
- total CORECLAW startup budget: max 80 KB

If files exceed budget:

1. load priority files first;
2. include truncation metadata;
3. prefer curated summaries over raw expansion;
4. never silently drop security rules.

Priority if trimming is required:

1. `AGENTS.md`
2. `USER.md`
3. `TOOLS.md`
4. `SOUL.md`
5. `MEMORY.md`

## 9. Validation that CORECLAW really loaded

A runtime validation should prove loading without exposing private content.

Recommended validation output:

```json
{
  "status": "CORECLAW_CONTEXT_LOADED",
  "session_type": "main_private",
  "loaded_files": ["AGENTS.md", "SOUL.md", "USER.md", "TOOLS.md", "MEMORY.md"],
  "excluded_files": [],
  "memory_loaded": true,
  "content_hashes": {
    "AGENTS.md": "sha256:<redacted-length-safe-hash>",
    "SOUL.md": "sha256:<redacted-length-safe-hash>",
    "USER.md": "sha256:<redacted-length-safe-hash>",
    "TOOLS.md": "sha256:<redacted-length-safe-hash>",
    "MEMORY.md": "sha256:<redacted-length-safe-hash>"
  },
  "content_not_returned": true
}
```

Validation should check:

- exact file list loaded;
- session policy applied;
- memory included only when private MAIN;
- content hashes or byte counts match expected files;
- no blocked files were read;
- no private material was returned.

## 10. Rollback

Rollback should be simple:

- disable the loader or project bridge flag;
- fall back to current documented behavior;
- leave CORECLAW files unchanged;
- preserve audit tools for diagnosis.

No migration should be required.

## 11. Loader, project reference bridge, or both

Recommended path:

1. Project reference bridge first.
2. Runtime loader second.

### Project reference bridge

Purpose:

- explicitly declare CORECLAW startup files in project state or agent metadata;
- make expected context visible and auditable;
- avoid implicit assumptions.

Risk:

- low;
- still documentary unless runtime consumes it.

### Runtime loader

Purpose:

- actually load the approved files into startup context;
- enforce private/shared session policy;
- emit safe validation metadata.

Risk:

- medium;
- touches startup behavior and privacy boundaries.

### Final recommendation

Use both:

- project reference bridge as source of truth;
- runtime loader as enforcement mechanism.

Do not rely on documentation alone.

## Non-goals

This design does not:

- implement the loader;
- modify gateway;
- modify runtime;
- modify executor;
- change CORECLAW files;
- create automatic memory sharing;
- change group/shared context behavior.
