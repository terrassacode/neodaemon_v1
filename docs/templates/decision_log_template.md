# Decision Log Template

## Propósito

Registrar decisiones operativas relevantes para que Neodaemon pueda explicar qué se decidió, por qué, con qué riesgo, con qué confianza y qué resultado se esperaba.

Este registro no sustituye a `TASK_VALIDATOR`, ni a la confirmación humana cuando sea necesaria.

El objetivo es mejorar criterio futuro sin crear burocracia.

MVP manual.  
Sin automatización.  
Sin scripts.  
Sin JSON obligatorio.

---

## Cuándo registrar

Registrar una decisión solo cuando aporte valor futuro de auditoría o aprendizaje.

Registrar si ocurre alguno de estos casos:

- acción `medium/high risk`;
- cambio en rutas sensibles;
- decisión que crea o modifica un proyecto;
- decisión que falla o queda incompleta;
- decisión repetitiva que pueda revelar patrón;
- acción `low risk` con baja confianza;
- bloqueo relevante;
- solicitud de confirmación humana por riesgo o incertidumbre.

---

## Cuándo NO registrar

No registrar por defecto:

- lecturas simples;
- comandos de inspección;
- validaciones triviales;
- correcciones menores sin impacto;
- pasos reversibles dentro de un proyecto ya autorizado;
- acciones `low risk` con alta confianza y sin impacto externo.

### Regla anti-burocracia

> Si el coste de registrar supera el valor futuro de auditarlo, no se registra.

---

## Campos obligatorios

- `decision_id`
- `fecha`
- `origen`
- `resumen_peticion`
- `accion_propuesta`
- `decision`
- `riesgo`
- `confianza_0_100`
- `coste_reversion`
- `motivo`
- `resultado_esperado`
- `validacion_prevista`
- `rollback`
- `estado`

---

## Campos opcionales

- `rutas_afectadas`
- `proyecto_relacionado`
- `confirmacion_humana`
- `limitaciones`
- `enlace_outcome`
- `notas`
- `lecciones_aprendidas`

---

## Confianza 0–100

La confianza mide qué tan fiable es el análisis previo, no qué tan deseable es la acción.

### Guía rápida

- `0–39` → baja
- `40–69` → media
- `70–100` → alta

Si la confianza es baja, no ejecutar automáticamente aunque el riesgo sea bajo.

---

## Coste de reversión

El `coste_reversion` mide cuánto esfuerzo, riesgo o pérdida implica volver atrás.

### Valores recomendados

- `bajo`: revertir es simple, local y rápido;
- `medio`: revertir requiere varios pasos o validación posterior;
- `alto`: revertir puede afectar datos, servicios, terceros o estado externo.

---

## Plantilla mínima

````markdown
# Decision Log — <decision_id>

## Fecha
YYYY-MM-DD HH:MM Europe/Madrid

## Origen
Albert | Neodaemon | heartbeat | sistema | subagente

## Resumen de la petición
<qué se pidió>

## Acción propuesta
<qué se quiere hacer>

## Decisión
execute | ask_confirmation | block | defer | document_only

## Riesgo
low | medium | high

## Confianza 0–100
<número entre 0 y 100>

## Coste de reversión
bajo | medio | alto

## Motivo
<por qué se toma esta decisión con la información disponible antes de actuar>

## Resultado esperado
<qué debería pasar si la decisión es correcta>

## Validación prevista
<cómo se comprobará el resultado>

## Rollback
<cómo revertir si algo sale mal>

## Estado
pending | executed | blocked | failed | completed | cancelled
````

## Ejemplo realista

# Decision Log — 20260527-0915-visualitzador-bloque2

## Fecha
2026-05-27 09:15 Europe/Madrid

## Origen
Albert

## Resumen de la petición
Crear el Bloque 2 del MVP frontend Visualitzador Cívic CAT dentro del proyecto autorizado.

## Acción propuesta
Crear `src/App.jsx` y `src/styles.css` con interfaz local en catalán, sin backend y sin APIs externas. La instalación y build quedarían sujetas a validación posterior.

## Decisión
execute

## Riesgo
medium

## Confianza 0–100
72

## Coste de reversión
bajo

## Motivo
El dominio editorial/cívico es sensible, pero la acción técnica está aislada dentro de `/projects/visualitzador-civic-cat/` y no toca core ni servicios.

## Resultado esperado
El proyecto tendrá una UI local funcional con lenguaje prudente, separación entre datos detectados, interpretaciones, indicios, preguntas abiertas y datos no verificados.

## Validación prevista
Leer los archivos creados y comprobar presencia de:

- sección “Fets detectats en les dades aportades”;
- `try/catch` en copia al portapapeles;
- ausencia de fetch, scraping o APIs externas;
- CSS responsive e imprimible.

## Rollback
Eliminar o restaurar únicamente:

- `src/App.jsx`
- `src/styles.css`

## Estado
completed

## Rutas afectadas

- `/openclaw/workspace/main/projects/visualitzador-civic-cat/src/App.jsx`
- `/openclaw/workspace/main/projects/visualitzador-civic-cat/src/styles.css`

## Confirmación humana
Sí. Ejecución autorizada por Albert.

##Estado

completed

## Enlace outcome

Pendiente.
