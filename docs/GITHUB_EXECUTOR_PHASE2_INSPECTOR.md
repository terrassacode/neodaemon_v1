# GITHUB_EXECUTOR_PHASE2_INSPECTOR

**Estado:** Diseño documental
**Riesgo:** Medio
**Autoridad principal:** `FEATURE_WORKFLOW_V1`
**Referencia secundaria:** `GITHUB_EXECUTOR_V1`

## Objetivo

Diseñar la Fase 2 del GitHub Executor: **Inspector**.

El objetivo principal es reducir trabajo operativo de Albert revisando propuestas antes de que lleguen a él.

El Inspector no crea un workflow nuevo.

Ayuda a cumplir mejor el workflow existente.

## Principio

```text
FEATURE_WORKFLOW_V1 manda.
GITHUB_EXECUTOR_V1 guía.
El Inspector revisa.
Albert decide.
NeoDaemon trabaja.
```

Si hay conflicto, gana `FEATURE_WORKFLOW_V1`.

## Qué revisa el Inspector

El Inspector revisa antes de pedir decisión a Albert:

- `FEATURE_PROPOSAL`;
- `FEATURE_READY_FOR_GITHUB`;
- propuestas con `OK FEATURE`;
- propuestas con `CONFIRMACIÓN_ESPECIAL`;
- propuestas relacionadas con Git/GitHub.

## Qué debe detectar

Debe buscar:

- alcance mal definido;
- archivos no previstos;
- riesgo mal clasificado;
- falta de rollback;
- falta de validaciones;
- lenguaje demasiado técnico;
- pasos manuales innecesarios;
- copia/pega evitable;
- desviaciones de `FEATURE_WORKFLOW_V1`;
- contradicciones con `GITHUB_EXECUTOR_V1`.

## Regla crítica

El Inspector trabaja con esta proporción:

```text
70% crítico
30% constructivo
```

Esto significa:

- busca problemas reales;
- no suaviza riesgos;
- no aprueba por inercia;
- pero tampoco bloquea por bloquear.

Si detecta un problema, debe explicar:

- cuál es el problema;
- cuál es el riesgo;
- cuál es la alternativa recomendada.

## Resultados posibles

El Inspector devuelve uno de estos estados:

```text
REVIEW_OK
REVIEW_WARNINGS
REVIEW_BLOCKED
```

### REVIEW_OK

La propuesta puede llegar a Albert.

No se han detectado problemas relevantes.

### REVIEW_WARNINGS

La propuesta puede llegar a Albert, pero con advertencias claras.

Debe explicar qué mejorar y por qué.

### REVIEW_BLOCKED

La propuesta no debe llegar todavía a Albert.

Debe corregirse antes.

Bloquear exige explicar:

- problema;
- riesgo;
- alternativa recomendada.

## Formato para Albert

Cada revisión debe resumirse así:

```text
RESUMEN:
<estado general en lenguaje simple>

PROBLEMA:
<qué se detectó o "sin problema relevante">

RECOMENDACIÓN:
<qué conviene hacer>

RIESGO:
<BAJO | MEDIO | ALTO>

DECISIÓN NECESARIA:
<qué debe decidir Albert o "ninguna todavía">
```

## Qué NO hace el Inspector

El Inspector no:

- decide por Albert;
- modifica archivos;
- crea ramas;
- hace commits;
- hace push;
- abre PR;
- hace merge;
- toca tokens;
- gestiona credenciales;
- toca servicios;
- toca systemd o timers;
- toca GitHub real;
- modifica repos externos.

## Ejemplos

### Ejemplo 1 — OK

Una propuesta documental toca un único archivo, tiene rollback claro, riesgo bajo y validaciones suficientes.

Resultado:

```text
REVIEW_OK
```

### Ejemplo 2 — Warning

Una propuesta es válida, pero pide a Albert copiar comandos innecesarios.

Resultado:

```text
REVIEW_WARNINGS
```

Recomendación: reducir pasos manuales.

### Ejemplo 3 — Blocked

Una propuesta dice "solo documentación", pero también toca un script.

Resultado:

```text
REVIEW_BLOCKED
```

Problema: alcance contradice archivos afectados.

Riesgo: se puede aprobar algo distinto de lo que Albert entiende.

Alternativa: rehacer la propuesta incluyendo el script y su validación.

## Beneficio esperado

Albert debería recibir propuestas más claras, más cortas y con menos errores.

El Inspector debe reducir:

- revisión manual repetitiva;
- copia/pega;
- dudas sobre riesgo;
- propuestas incompletas;
- bloqueos tardíos.

## Métrica simple de éxito

```text
Éxito =
menos trabajo operativo para Albert
más propuestas correctas a la primera
sin aumentar riesgo
sin romper FEATURE_WORKFLOW_V1
```

