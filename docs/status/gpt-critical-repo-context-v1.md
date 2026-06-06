# FEATURE_GPT_CRITICAL_REPO_CONTEXT_V1

## Objetivo

Definir cómo GPT crítico obtiene contexto actualizado del repositorio antes de revisar propuestas de NeoDaemon/OpenClaw.

El objetivo es evitar revisiones genéricas, propuestas ya completadas o conclusiones basadas en contexto obsoleto.

## Fuentes mínimas a leer

Antes de revisar una propuesta, GPT crítico debe consultar solo el contexto útil mínimo:

- `docs/OPERATOR_CHATGPT_V1.md`
- `docs/status/current-autopilot-operating-model.md`
- `docs/status/autonomy-metrics-v1-minimal.md`
- `docs/status/post-merge-cleanup-check-design-v1.md`
- últimos PRs relevantes, si están disponibles en el contexto de trabajo

No debe leer todo el repo por defecto.

## Cómo comprobar estado actual

GPT crítico debe verificar si la propuesta toca una capacidad ya documentada o completada.

Comprobación mínima:

1. Revisar las fuentes mínimas listadas arriba.
2. Identificar PRs o features marcadas como DONE si aparecen en esas fuentes.
3. Contrastar la propuesta con el estado operativo actual documentado.
4. Separar hechos verificados de inferencias.

## Qué hacer si no puede verificar

Si GPT crítico no puede verificar el estado en el repo, debe responder exactamente:

```text
NO_VERIFICADO
```

No debe rellenar huecos con suposiciones ni proponer una feature como nueva si no puede comprobar que no existe ya.

## Formato de respuesta

La respuesta de GPT crítico debe ser breve y estructurada:

```text
estado: VERIFICADO / NO_VERIFICADO
fuentes_revisadas: <lista breve>
conclusión: <OK / riesgo / duplicado / falta contexto>
evidencia_mínima: <1-3 puntos>
recomendación: <siguiente acción mínima>
```

Si responde `NO_VERIFICADO`, no debe añadir recomendaciones operativas salvo pedir contexto verificable.

## Límite de contexto útil

GPT crítico debe usar contexto suficiente para revisar la propuesta, no contexto máximo.

Reglas:

- leer primero las fuentes mínimas;
- no expandir a todo el repo por defecto;
- pedir contexto adicional solo si bloquea la revisión;
- evitar convertir la revisión crítica en investigación extensa;
- priorizar estado actual, restricciones vigentes y PRs relevantes.
