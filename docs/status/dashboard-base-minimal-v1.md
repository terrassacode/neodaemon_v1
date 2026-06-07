# FEATURE_DASHBOARD_BASE_MINIMAL_V1

## Propósito

Crear una fuente de verdad mínima, manual y legible para visualizar el estado operativo del proyecto sin añadir scripts, HTML ni automatización.

El dashboard base consiste en un único JSON versionado:

```text
docs/status/project-dashboard-state-v1.json
```

## Uso manual

Actualizar el JSON cuando cambie el estado de una capacidad relevante:

- feature completada;
- feature en revisión;
- bloqueo operativo;
- nueva prioridad;
- siguiente acción mínima.

No intenta reemplazar los documentos de estado. Solo resume el tablero actual.

## Campos permitidos

Cada item usa:

```text
id           identificador estable en MAYÚSCULAS/SNAKE_CASE
title        descripción humana breve
status       BACKLOG | PLANNED | IN_PROGRESS | BLOCKED | REVIEW | DONE | CANCELLED
priority     P0 | P1 | P2 | P3
health       OK | WATCH | RISK | BLOCKED
last_update  fecha YYYY-MM-DD
next_action  siguiente acción mínima, breve
```

## Reglas

- Mantener 5-15 items máximos hasta que haya dashboard real.
- No añadir scripts.
- No añadir HTML.
- No automatizar todavía.
- Si un item queda obsoleto, actualizarlo o marcarlo `DONE`/`CANCELLED`.

## Estado inicial

El estado inicial queda definido en `project-dashboard-state-v1.json` con capacidades ya validadas y pendientes relevantes.
