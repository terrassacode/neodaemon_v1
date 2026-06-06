# FEATURE_TOOLS_SH_AUTOPILOT_PUBLISH_DECISION_V1

## Objetivo

Documentar la decisión explícita sobre publicación AUTOPILOT de cambios en `tools/*.sh`.

## Decisión

`tools/*.sh` puede publicarse por AUTOPILOT solo si existe una ruta allowlisted para `autopilot-commit` sobre Trust Zone.

Esta decisión habilita publicación controlada, no ejecución de acciones destructivas.

## Publicación vs ejecución

Publicación significa:

- validar el cambio;
- crear commit;
- hacer push de la rama;
- abrir PR contra `main`.

Ejecución significa correr la acción publicada contra el repo o contra GitHub.

Esta decisión solo trata publicación. No autoriza ejecutar cleanup ni borrar ramas.

## Condiciones obligatorias

Para publicar cambios en `tools/*.sh` por AUTOPILOT deben cumplirse todas:

- archivo dentro de Trust Zone;
- ruta allowlisted explícita para `autopilot-commit` sobre Trust Zone;
- validación de sintaxis, por ejemplo `bash -n` si aplica;
- validación funcional segura cuando aplique;
- `git status --short` muestra solo el archivo autorizado;
- salida clara de commit/push/PR;
- sin cambios en OpenClaw core, gateway, routing, systemd ni secrets.

## Qué sigue prohibido

- Ejecutar cleanup como consecuencia de esta decisión.
- Borrar ramas locales o remotas.
- Usar `git branch -D`.
- Usar force.
- Usar `reset`, `stash`, `merge` o `rebase`.
- Tocar allowlist o approvals desde esta feature.
- Tocar `tools/*.sh` desde esta feature.
- Implementar cleanup desde esta feature.

## Regla de bloqueo

Si esta decisión se interpreta como permiso para ejecutar cleanup, resultado obligatorio:

```text
FEATURE_BLOCKED
```

También debe bloquearse si falta la ruta allowlisted para publicar `tools/*.sh` por AUTOPILOT.

## Alcance de esta feature

Esta feature no cambia allowlist ni approvals.

Esta feature no toca `tools/*.sh`.

Esta feature no implementa cleanup.
