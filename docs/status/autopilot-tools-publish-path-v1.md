# FEATURE_AUTOPILOT_TOOLS_PUBLISH_PATH_V1

## Objetivo

Definir una vía segura y minimalista para publicar cambios en `tools/*.sh` mediante AUTOPILOT sin saltarse controles.

## Estado V1

En V1, `tools/*.sh` puede prepararse y validarse localmente si está dentro de Trust Zone.

Sin embargo, no debe publicarse por AUTOPILOT si `autopilot-commit` pide approval no allowlisted.

Esto significa:

- la preparación puede ser válida;
- la validación técnica puede ser OK;
- el cambio debe bloquearse si la ruta de commit/publicación no está allowlisted;
- el working tree debe quedar limpio tras rollback si no puede publicarse.

## Ruta V2 futura

Una V2 futura podrá habilitar publicación solo cuando exista una ruta allowlisted explícita para `autopilot-commit` sobre Trust Zone.

Esa ruta debe ser aprobada como decisión separada y verificable.

## Restricciones

- No ampliar permisos desde esta feature.
- No tocar approvals desde esta feature.
- No saltarse AUTOPILOT.
- No usar git manual como vía normal para publicar `tools/*.sh`.
- No modificar código, scripts, allowlist ni configuración.
- No tocar OpenClaw core, gateway, routing, systemd ni secrets.

## Decisión pendiente

La implementación queda para una decisión explícita posterior.

Hasta entonces, cualquier cambio en `tools/*.sh` que no pueda publicarse por una ruta allowlisted debe terminar en `FEATURE_BLOCKED`.
