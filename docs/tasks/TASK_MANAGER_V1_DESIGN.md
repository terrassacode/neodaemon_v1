# TASK_MANAGER_V1_DESIGN

## Estado

Diseño documental.

No implementa dashboard real, scripts, automatización ni escritura operativa.

## Objetivo

Diseñar un sistema visual y estructurado de gestión de tareas para NeoDaemon.

El objetivo es saber:

- qué tareas existen;
- cuáles están abiertas;
- cuáles están bloqueadas;
- cuál es la prioridad actual;
- cuánto progreso real hay;
- cuál es la próxima acción segura.

## Modelo base

```text
PROYECTO -> EPICA -> TAREA
```

La fuente de verdad será JSON.

El dashboard será derivado del JSON, no la fuente principal.

## Estados permitidos

```text
BACKLOG
PLANNED
IN_PROGRESS
BLOCKED
REVIEW
DONE
CANCELLED
```

## Prioridades permitidas

```text
P0
P1
P2
P3
```

## Health

El estado indica fase.

La salud indica cómo va.

Valores permitidos:

```text
GREEN
YELLOW
RED
```

Regla:

```text
status = dónde está la tarea
health = cómo va la tarea
```

Ejemplo:

```json
{
  "status": "IN_PROGRESS",
  "health": "YELLOW"
}
```

## Weight

Cada tarea tendrá peso.

Campo:

```json
"weight": 1
```

Por defecto:

```text
weight = 1
```

Tareas grandes pueden tener:

```text
weight = 3
weight = 5
```

## Progreso

El progreso recomendado será ponderado:

```text
weighted DONE / weighted total no cancelado
```

Las tareas canceladas no cuentan.

Las tareas bloqueadas no cuentan como DONE.

Ejemplo:

```text
done_weight = suma de weight donde status == DONE

total_weight = suma de weight donde status != CANCELLED

progress = done_weight / total_weight
```
## Schema de proyecto

```json
{
  "id": "project.github-copilot",
  "title": "GitHub Copilot controlado",
  "status": "IN_PROGRESS",
  "health": "GREEN",
  "priority": "P1",
  "owner": "Neodaemon",
  "decision_owner": "Albert",
  "epics": [],
  "created_at": "YYYY-MM-DD",
  "updated_at": "YYYY-MM-DD"
}
```

## Schema de épica

```json
{
  "id": "epic.github-pr-flow",
  "project_id": "project.github-copilot",
  "title": "Flujo controlado PR",
  "status": "IN_PROGRESS",
  "health": "GREEN",
  "priority": "P1",
  "tasks": [],
  "blocked_reason": null,
  "created_at": "YYYY-MM-DD",
  "updated_at": "YYYY-MM-DD"
}
```
## Schema de tarea

```json
{
  "id": "task.github-doc-flow",
  "project_id": "project.github-copilot",
  "epic_id": "epic.github-pr-flow",
  "title": "Documentar flujo operativo",
  "status": "REVIEW",
  "health": "GREEN",
  "priority": "P1",
  "weight": 1,
  "blocked_reason": null,
  "next_action": "Esperar OK_GITHUB",
  "prs": [29, 30],
  "commits": ["71d25d0"],
  "branches": ["feature/github-publisher-token-push"],
  "created_at": "YYYY-MM-DD",
  "updated_at": "YYYY-MM-DD"
}
```

## Relación con GitHub

Cada tarea puede enlazar:

```json
{
  "prs": [28, 29, 30],
  "commits": ["71d25d0"],
  "branches": ["feature/example"]
}
```

Reglas:

- Los PRs aportan evidencia.
- Los commits aportan evidencia.
- Las ramas aportan trazabilidad.
- Neo puede proponer cambios de estado.
- Albert decide los cambios de estado.

## Detección de bloqueos

Una tarea está bloqueada cuando:

```text
status == BLOCKED
```

o cuando:

```json
"blocked_reason": "..."
```

Ejemplos:

```text
- Falta OK FEATURE
- Falta OK_GITHUB
- PR pendiente
- Credencial no disponible
- Evidencia host pendiente
```

## Next Action

Regla:

```text
next_action = siguiente paso mínimo, seguro y accionable
```

Ejemplos:

```text
Esperar OK FEATURE
Preparar FEATURE_PROPOSAL
Ejecutar validaciones
Esperar merge manual
Bloqueado: falta evidencia host
```

Neo propone.

Albert decide.

## Dashboard Propuesto

```text
TASK DASHBOARD

Prioridad actual:
[P1] GitHub Copilot controlado

Progreso global:
██████░░░░ 60%

Tareas abiertas:
- task.github-doc-flow [REVIEW] [GREEN] P1
- task.gmail-draft-design [BACKLOG] [GREEN] P2

Bloqueadas:
- task.gmail-real-draft [BLOCKED] [RED]
  motivo: Gmail draft capability no validada

Últimos PRs:
- #30 Token Publisher
- #29 GitHub PR Publisher
- #28 Controlled PR Assistant

Próxima acción recomendada:
Preparar FEATURE_PROPOSAL para TASK_MANAGER_V1 implementation
```

## Flujo Operativo

1. Neo propone creación de tarea.
2. Albert aprueba o corrige.
3. Neo propone cambios de estado.
4. Albert valida los cambios.
5. El JSON se actualiza.
6. El dashboard se regenera desde JSON.
7. Los cambios sensibles requieren aprobación explícita.

## Qué puede proponer Neo

- nueva tarea;
- nueva épica;
- nuevo proyecto;
- cambio de estado;
- cambio de health;
- prioridad sugerida;
- bloqueo;
- next_action;
- enlace PR;
- enlace commit;
- propuesta de cierre.

## Qué debe decidir Albert

- prioridades P0 y P1;
- mover a DONE;
- cancelar;
- desbloquear;
- autorizar ejecución;
- autorizar acciones remotas;
- cambios estratégicos del roadmap.

## Estado de Madurez Actual

```text
Preparación local: Operativo
Commit local: Operativo
Push con token host: Operativo
Creación de PR: Operativo
Detección PR existente: Operativo
Merge automático: No implementado
Borrado automático de ramas: No implementado
Modificación de código fuera de alcance documental: No autorizado
```

Principio fundamental:

```text
Neo es un copiloto controlado.

Albert mantiene la decisión final sobre cualquier acción remota.
```

## Riesgos

Riesgo estimado:

```text
BAJO
```

Riesgos:

- complejidad excesiva;
- estados inconsistentes;
- dashboard convertido en fuente de verdad;
- automatización excesiva.

Mitigaciones:

- JSON como fuente de verdad;
- dashboard derivado;
- Neo propone;
- Albert decide.

## Rollback

Antes de commit:

```bash
git checkout -- docs/tasks/TASK_MANAGER_V1_DESIGN.md
```

Después de commit:

```bash
git revert <commit>
```

## Qué NO tocará

- scripts;
- dashboard real;
- GitHub remoto;
- tokens;
- Gmail;
- OAuth;
- systemd;
- gateway;
- routing;
- core;
- automatización de estados.
