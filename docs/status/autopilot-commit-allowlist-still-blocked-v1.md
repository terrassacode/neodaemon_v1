# FEATURE_AUTOPILOT_COMMIT_ALLOWLIST_STILL_BLOCKED_V1

## Objetivo

Documentar el bloqueo persistente de `autopilot-commit` aunque existan entradas allowlist en:

```text
/home/openclaw/.openclaw/exec-approvals.json
```

## Hechos verificados

- `exec-approvals.json` fue localizado en `/home/openclaw/.openclaw/exec-approvals.json`.
- La allowlist está en `agents.<id>.allowlist`.
- Se añadieron entradas para `main` y `gateway`.
- Se probó patrón con wildcard para:

```text
OK_GITHUB=1 tools/github_controlled_pr_assistant.sh autopilot-commit *
```

- Se añadió ruta absoluta del ejecutable para `gateway`:

```text
/openclaw/workspace/git_clean/neodaemon_v1/tools/github_controlled_pr_assistant.sh
```

- `openclaw approvals get` muestra las entradas.
- Se reinició `openclaw-gateway.service`.
- La prueba sigue pidiendo approval.
- No se creó PR.
- El repo quedó limpio.

## Conclusión

La allowlist existe, pero no es efectiva para este flujo.

No seguir añadiendo patrones sin entender antes:

- target real;
- matcher usado;
- comando interno evaluado;
- resolved path aplicado por gateway.

## Regla

No añadir más patrones de allowlist para `autopilot-commit` hasta entender target/matcher/comando interno.

## Restricciones vigentes

- No código.
- No scripts.
- No más cambios de allowlist.
- No approvals.
- No cleanup.
- No branch delete.
- No `push --delete`.
- No force.
- No OpenClaw core, gateway, routing, systemd ni secrets.
