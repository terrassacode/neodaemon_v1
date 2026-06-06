# FEATURE_AUTOPILOT_TOOLS_PUBLISH_BLOCKED_V1

## Objetivo

Documentar el bloqueo operativo detectado al intentar publicar cambios en `tools/*.sh` mediante AUTOPILOT.

## Hechos observados

Durante `FEATURE_POST_MERGE_CLEANUP_CHECK_IMPL_V1`:

- La validación local de `tools/neodaemon_local_executor_v1.sh` funcionó.
- `bash -n tools/neodaemon_local_executor_v1.sh` fue OK.
- La salida JSON de la nueva acción fue OK.
- El bloqueo ocurrió en commit/publicación.
- `commit` sigue siendo docs-only.
- `autopilot-commit` / executor pidió approval no allowlisted.
- El working tree quedó limpio tras rollback.

## Conclusión

`tools/*.sh` está dentro de Trust Zone, pero publicar cambios en `tools/*.sh` por AUTOPILOT aún no está operativo sin resolver allowlist/approval.

Este bloqueo es operativo. No fue un fallo de sintaxis ni de salida JSON.

## Restricciones vigentes

Este documento no propone cambios de código, scripts, allowlist, approvals, OpenClaw core, gateway, routing, systemd ni secrets.
