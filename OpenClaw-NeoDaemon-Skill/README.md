# OpenClaw NeoDaemon Skill

OpenClaw NeoDaemon Skill is a minimal operating guide for agents and humans working with NeoDaemon inside OpenClaw.

NeoDaemon is the MAIN coordinator for Albert: it prepares bounded proposals, executes safe approved work, validates results, and reports back clearly.

## Agent Entry Point

For NeoDaemon/OpenClaw operational work, start with:

- [`SKILL.md`](SKILL.md)

For operator behavior, read:

- [`references/gpt_operator_behavior.md`](references/gpt_operator_behavior.md)

For medium/large projects, read:

- [`references/project_delivery_protocol.md`](references/project_delivery_protocol.md)

This skill summarizes and links operational guidance; it does not replace `docs/status`.

## When To Use It

Use this skill when you need to:

- understand NeoDaemon's role;
- operate GitHub/documentation workflows safely;
- check project status or dashboard guidance;
- route a problem to the right reference document;
- avoid touching protected OpenClaw areas by mistake.

## Structure

- [`SKILL.md`](SKILL.md): primary operational entrypoint for agents.
- [`references/`](references/): short domain notes for architecture, operations, security, GitHub, dashboard, RAG, and project state.

## Publishing

Use the controlled `publish_doc_folder` route for NeoDaemon Skill Markdown updates.

## Cleanup Validation

This README includes a small documentation change used to validate the `OK CLEANUP <hash>` workflow.

## Safety Limits

This skill is read-first documentation. It does not replace approval rules or `docs/status` project records.

Do not use it as permission to modify OpenClaw core, gateway/routing, models, systemd, secrets, bridge, executor, or runtime dashboards without explicit confirmation.
