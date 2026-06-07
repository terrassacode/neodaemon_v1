# OpenClaw NeoDaemon Skill

OpenClaw NeoDaemon Skill is a minimal operating guide for agents and humans working with NeoDaemon inside OpenClaw.

NeoDaemon is the MAIN coordinator for Albert: it prepares bounded proposals, executes safe approved work, validates results, and reports back clearly.

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

## Safety Limits

This skill is read-first documentation. It does not replace approval rules or `docs/status` project records.

Do not use it as permission to modify OpenClaw core, gateway/routing, models, systemd, secrets, bridge, executor, or runtime dashboards without explicit confirmation.
