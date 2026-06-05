# Current AUTOPILOT Operating Model

## Estado actual

AUTOPILOT reduce intervención manual en features permitidas, sin ampliar zonas protegidas ni autonomía de merge.

Estado validado tras PR #47–#50:

- PR #47 DONE: `github_sync_main` permite volver a `main` y actualizar por fast-forward mediante acción controlada.
- PR #48 DONE: `prepare` usa Trust Zone en vez de limitarse a `docs/**/*.md`.
- PR #49 DONE: AUTOPILOT fue validado end-to-end sobre `scripts/*.py`.
- PR #50 DONE: `OPERATOR_CHATGPT_V1_PROTOCOL` quedó documentado.

## MAIN en modo consultivo

Neodaemon MAIN analiza, propone, prepara instrucciones y sintetiza resultados.

MAIN no usa exec approvals genérico como vía principal de operación mientras persista el problema approval → sin output.

La ejecución controlada mediante acciones allowlisted sí está validada y se utiliza para operaciones acotadas.

## Ejecución operativa

La ejecución operativa actual ocurre mediante scripts y acciones allowlisted existentes de NeoDaemon.

Acciones validadas relevantes:

- `github_sync_main` para volver a `main` y hacer `git pull --ff-only origin main` con working tree limpio.
- `prepare` con Trust Zone.
- AUTOPILOT end-to-end para documentación y scripts permitidos.
- Publicación controlada con push y PR sin merge automático ni borrado de ramas.

No se toca OpenClaw, gateway, routing, systemd ni servicios.

## Trust Zone validada

AUTOPILOT puede continuar solo si todos los archivos modificados están dentro de ALLOW y no caen en BLOCK.

Si cualquier archivo queda fuera, resultado: FEATURE_BLOCKED.

La Trust Zone ya se usa en `prepare` y en el flujo AUTOPILOT, incluyendo validación end-to-end sobre `scripts/*.py`.

## Decision Log V1 implementado

Las decisiones AUTOPILOT_CONTINUE / FEATURE_BLOCKED se registran en:

`/home/openclaw/.openclaw/neodaemon/autopilot_decision_log.jsonl`

El log está fuera del repo para no ensuciar `git status`.

## Flujo actual

Albert → propuesta → AUTOPILOT/acciones allowlisted → validaciones → commit/push/PR → Albert revisa → merge/reject.

`OPERATOR_CHATGPT_V1` puede usarse antes de la propuesta para reducir copy-paste, limitar bucles y mantener contexto actualizado.

## Validado

- PR #47: `github_sync_main`.
- PR #48: `prepare` usa Trust Zone.
- PR #49: AUTOPILOT end-to-end sobre `scripts/*.py`.
- PR #50: protocolo `OPERATOR_CHATGPT_V1`.
- Trust Zone mínima.
- Bloqueo de rutas no permitidas.
- Decision Log V1 fuera del repo.
- Ejecución controlada mediante acciones allowlisted.
- Merge sigue manual.

## Pendiente

- Exec approvals genérico sigue pendiente y no es la vía principal de operación.
- Usar `OPERATOR_CHATGPT_V1` para reducir copy-paste y mantener contexto actualizado.
- Medir 10 features con métricas de intervención humana.
- Confirmar reducción real de SSH/copy-paste.
- Mantener cero incidencias en zonas protegidas.

## Restricciones vigentes

No OpenClaw core, gateway, routing, modelos, secrets, tokens, systemd, exec approvals genérico como vía principal, servicios, merge automático ni borrado automático de ramas.
