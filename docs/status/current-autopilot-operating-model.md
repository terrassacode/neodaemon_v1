# Current AUTOPILOT Operating Model

## Estado actual

AUTOPILOT reduce intervención manual en features permitidas, sin ampliar zonas protegidas ni autonomía de merge.

## MAIN en modo consultivo

Neodaemon MAIN analiza, propone, prepara instrucciones y sintetiza resultados.

MAIN no usa exec approvals para operar features mientras persista el problema approval → sin output.

## Ejecución operativa desde host

La ejecución real ocurre desde host usando scripts existentes de NeoDaemon.

No se toca OpenClaw, gateway, routing, systemd ni servicios.

## Trust Zone validada

AUTOPILOT puede continuar solo si todos los archivos modificados están dentro de ALLOW y no caen en BLOCK.

Si cualquier archivo queda fuera, resultado: FEATURE_BLOCKED.

## Decision Log V1 implementado

Las decisiones AUTOPILOT_CONTINUE / FEATURE_BLOCKED se registran en:

`/home/openclaw/.openclaw/neodaemon/autopilot_decision_log.jsonl`

El log está fuera del repo para no ensuciar `git status`.

## Flujo actual

Albert → propuesta → AUTOPILOT → validaciones → commit/push/PR → Albert revisa → merge/reject.

## Validado

- Trust Zone mínima.
- Bloqueo de rutas no permitidas.
- Decision Log V1 fuera del repo.
- Merge sigue manual.

## Pendiente

- Resolver bug approval → sin output o mantener host como ejecución operativa.
- Medir 10 features con métricas de intervención humana.
- Confirmar reducción real de SSH/copy-paste.
- Mantener cero incidencias en zonas protegidas.

## Restricciones vigentes

No OpenClaw core, gateway, routing, modelos, secrets, tokens, systemd, exec approvals, servicios, merge automático ni borrado automático de ramas.
