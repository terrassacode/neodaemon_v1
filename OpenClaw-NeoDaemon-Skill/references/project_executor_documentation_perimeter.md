# Project Executor Documentation Perimeter

## Decision

For the first Project Executor documentation perimeter, `docs/**` is treated as the single documentation space for project Markdown.

Allowed documentation path:

```text
docs/**/*.md
```

Not included in this first version:

```text
docs/**/*.json
```

Reason: documentation and data/configuration must remain clearly separated until there is evidence that JSON under `docs/**` is required.

## Principle

Do not create new documentation allowlists for each new subfolder.

`docs/**` is the project documentation perimeter. New documentation folders such as `docs/adr/`, `docs/status/`, `docs/examples/`, or `docs/metrics/` should be covered by the same documented perimeter instead of new folder-specific rules.

## Scope Covered

This perimeter covers Markdown documentation under:

```text
docs/*.md
docs/**/*.md
```

Examples:

```text
docs/adr/*.md
docs/status/*.md
docs/examples/*.md
docs/metrics/*.md
```

## Explicit Non-Scope

This perimeter does not authorize:

```text
docs/**/*.json
scripts
tools
bridge
executor
runtime
OpenClaw core
gateway
routing
models
systemd
private or sensitive material
```

It also does not authorize shell over the host, service restarts, external actions, automatic merge, or automatic cleanup.

## Required Safety Controls

The documentation perimeter must keep:

- sensitive diff scanner;
- PR required;
- manual merge;
- manual cleanup with exact hash;
- blocking of sensitive paths or content;
- Protected Zones outside documentation;
- clear report of files touched and validations run.

## Required Validations

A future implementation of this perimeter should validate:

- only `docs/**/*.md` is accepted;
- Markdown file exists and is non-empty;
- no sensitive path is accepted;
- no sensitive content appears in the staged diff;
- no generated data or runtime/core path is included;
- PR is created from a non-main branch;
- no merge is performed;
- no cleanup is performed automatically.

## Impact

This removes the need for future folder-specific documentation allowlists while staying aligned with the Project Executor model.

The unit of control becomes the documentation perimeter, not the individual documentation subfolder.

## Status

Documentation decision only.

No runtime, core, bridge, executor, permissions, approvals, or operational behavior is changed by this document.
