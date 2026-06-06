# FEATURE_TOOLS_SH_ALLOWLIST_ROUTE_DESIGN_V1

## Objetivo

Documentar la ruta allowlisted mínima que falta para publicar cambios en `tools/*.sh` por AUTOPILOT.

## Ruta faltante

El comando o wrapper faltante es una ruta allowlisted para `autopilot-commit` sobre Trust Zone.

Esa ruta debe permitir únicamente:

- commit;
- push de rama;
- creación de PR.

No debe ejecutar acciones destructivas ni cleanup.

## Futuro archivo a tocar

El futuro archivo a tocar sería la configuración/allowlist de herramientas OpenClaw.

Eso solo debe hacerse en una feature explícita posterior.

Esta feature no modifica allowlist ni approvals.

## Publicación no equivale a ejecución

Publicar `tools/*.sh` significa llevar un cambio validado a PR.

Ejecutar `tools/*.sh` significa correr una acción operativa.

Esta ruta solo habilitaría publicación. No autoriza ejecución de cleanup, borrado de ramas ni operaciones remotas destructivas.

## Validaciones obligatorias

Antes de publicar `tools/*.sh` por AUTOPILOT deben cumplirse:

- Trust Zone;
- archivo único autorizado;
- `bash -n` si aplica;
- salida JSON/PR clara;
- `git status` limpio después de commit/push/PR;
- no cambios en OpenClaw core, gateway, routing, systemd ni secrets.

## Prohibiciones

La ruta allowlisted no debe permitir:

- cleanup;
- branch delete;
- `push --delete`;
- force;
- `reset`;
- `stash`;
- `merge`;
- `rebase`.

## Alcance de esta feature

- Solo documentación.
- No código.
- No scripts.
- No allowlist real.
- No approvals.
- No cleanup.
- No tocar `tools/*.sh`.
