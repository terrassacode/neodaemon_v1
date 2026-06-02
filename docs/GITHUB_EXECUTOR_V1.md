# GITHUB_EXECUTOR_V1

**Estado:** Diseño documental  
**Riesgo:** Medio  
**Referencia principal:** `FEATURE_WORKFLOW_V1`

## Objetivo

El objetivo principal no es automatizar GitHub.

El objetivo principal es reducir trabajo operativo de Albert sin aumentar riesgo y sin romper el workflow aprobado.

GitHub es el primer caso de uso, no el objetivo final.

El Executor debe ayudar a NeoDaemon a trabajar mejor dentro del flujo existente:

```text
Albert dirige.
NeoDaemon trabaja.
```
## Alcance

El Executor actúa como una capa de ayuda sobre `FEATURE_WORKFLOW_V1`.

Nunca está por encima del workflow.

Si existe conflicto:

```text
FEATURE_WORKFLOW_V1 tiene prioridad.
```

El Executor puede ayudar a:

- preparar ramas;
- validar cambios;
- revisar diff;
- preparar commits;
- preparar `FEATURE_READY_FOR_GITHUB`;
- preparar PRs;
- detectar desviaciones del workflow;
- reducir copia/pega innecesario.

## Qué problemas resuelve

El Executor debe detectar:

- pasos repetitivos;
- copia/pega innecesario;
- validaciones olvidadas;
- desviaciones del workflow;
- acciones fuera del alcance aprobado;
- diferencias entre lo prometido y lo hecho.

Debe proponer:

- menos pasos;
- menos riesgo;
- más consistencia;
- explicaciones más simples para Albert.

Si una tarea puede hacerse en 3 pasos en lugar de 10, debe proponer la de 3.

## Auto-revisión crítica

La auto-revisión crítica es una capacidad explícita del Executor.

Debe aplicarse antes de presentar `FEATURE_READY_FOR_GITHUB`.

También debe aplicarse a:

- `FEATURE_PROPOSAL`;
- `FEATURE_READY_FOR_GITHUB`;
- propuestas de automatización;
- cambios de workflow.

El objetivo no es bloquear trabajo.

El objetivo es mejorar la calidad de las decisiones.

Principio operativo:

```text
70% crítico
30% constructivo
```

El Executor debe intentar encontrar:

- contradicciones;
- puntos ciegos;
- pasos innecesarios;
- riesgos ocultos;
- alternativas más simples;
- desviaciones del workflow.

Si detecta un problema, no debe limitarse a decir "no".

Debe explicar:

- cuál es el problema;
- cuál es el riesgo;
- cuál es una alternativa mejor.

`FEATURE_WORKFLOW_V1` sigue siendo la autoridad principal.

## Qué puede hacer solo

Puede hacer trabajo de ayuda y comprobación:

- revisar estado;
- ordenar información;
- preparar resúmenes;
- detectar riesgos;
- preparar propuestas;
- preparar mensajes para Albert;
- verificar que el flujo se está siguiendo.

No decide por Albert.

No salta aprobaciones.

## Qué sigue requiriendo aprobación

Requiere `OK FEATURE`:

- empezar trabajo local;
- crear/modificar archivos;
- preparar commit local.

Requiere `OK GITHUB`:

- push;
- abrir PR.

Requiere `CONFIRMACIÓN_ESPECIAL`:

- servicios;
- systemd;
- timers;
- scripts ejecutables;
- tokens;
- credenciales;
- zonas protegidas;
- cambios en el propio workflow;
- cualquier ampliación sensible del Executor.

## Qué NO intenta resolver

El Executor no intenta:

- sustituir a Albert;
- tomar decisiones de negocio;
- hacer merge automático;
- eliminar la revisión humana;
- gestionar credenciales;
- tocar tokens;
- modificar repos externos;
- crear workflows paralelos;
- saltarse `OK FEATURE`;
- saltarse `OK GITHUB`;
- saltarse `CONFIRMACIÓN_ESPECIAL`.

## Riesgos

Riesgos principales:

- que el Executor se convierta en un workflow paralelo;
- que pida demasiadas cosas a Albert;
- que oculte decisiones importantes;
- que automatice más de lo aprobado;
- que reduzca fricción a costa de seguridad.

Regla de seguridad:

Si hay duda, el Executor debe detenerse y avisar.

## Fases de implementación

### Fase 1 — Diseño

Documento claro, sin código.

### Fase 2 — Inspector

Ayuda a revisar estado y detectar desviaciones.

Solo lectura.

### Posible Fase 2.5 — Document Validator

Mejora futura identificada durante la revisión.

Objetivo: validar automáticamente documentos antes de presentarlos a Albert.

No se desarrolla todavía.

### Fase 3 — Asistente local

Ayuda a preparar ramas, validaciones y commits dentro de `OK FEATURE`.

### Fase 4 — Asistente GitHub

Ayuda a preparar push y PR dentro de `OK GITHUB`.

No hace merge automático.

## Cómo encaja con FEATURE_WORKFLOW_V1

El Executor no cambia el flujo.

Solo ayuda a cumplirlo mejor:

```text
FEATURE_PROPOSAL
↓
OK FEATURE
↓
Trabajo
↓
FEATURE_READY_FOR_GITHUB
↓
OK GITHUB
↓
Push
↓
PR
↓
Merge
↓
Limpieza
```

Su tarea es reducir trabajo operativo sin cambiar quién decide.

Albert decide.
NeoDaemon trabaja.
Github Executor ayuda.

## Ejemplos reales de uso

Ejemplo 1:

Albert aprueba un cambio documental.

El Executor ayuda a comprobar que solo se modificó un archivo, que el diff es pequeño y que el mensaje `FEATURE_READY_FOR_GITHUB` está completo.

Ejemplo 2:

NeoDaemon prepara un cambio de script.

El Executor recuerda que requiere validación Bash y riesgo medio.

Ejemplo 3:

Aparece un archivo no previsto.

El Executor bloquea y avisa en lugar de seguir.

## Beneficio esperado para Albert

Albert debería invertir menos tiempo en:

- copiar comandos;
- revisar pasos repetitivos;
- recordar validaciones;
- comprobar si el workflow se siguió.

Albert debería centrarse en:

- decidir objetivo;
- aprobar alcance;
- aceptar o bloquear riesgos;
- hacer merge cuando corresponda.

## Métrica simple de éxito

```text
Éxito =
menos tiempo invertido por Albert
sin aumentar riesgo
y sin romper el workflow.
```

