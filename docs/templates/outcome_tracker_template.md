# Outcome Tracker Template

## Propósito

Registrar qué ocurrió después de una decisión relevante para mejorar criterio operacional con evidencia real.

El objetivo no es demostrar que una decisión “tenía razón”, sino observar:

- qué ocurrió;
- qué impacto tuvo;
- qué aprendizaje deja;
- si el análisis previo fue razonable.

---

## Cuándo registrar

Registrar outcomes principalmente cuando exista:

- medium/high risk;
- impacto operacional;
- efectos inesperados;
- decisiones fallidas;
- bloqueos relevantes;
- validaciones excesivas;
- acciones repetitivas;
- aprendizaje útil.

---

## Cuándo NO registrar

No registrar outcomes triviales sin valor futuro.

Ejemplos:

- lecturas simples;
- validaciones rutinarias;
- acciones reversibles sin impacto;
- tareas mecánicas repetitivas;
- éxitos técnicos sin aprendizaje operacional.

---

## Campos obligatorios

- `outcome_id`
- `linked_decision_id`
- `fecha_observacion`
- `outcome`
- `decision_quality`
- `outcome_quality`
- `impacto_real`
- `validation_cost`
- `rollback_usado`
- `human_operational_value`
- `aprendizaje`
- `estado_final`

---

## Campos opcionales

- `efectos_secundarios`
- `riesgo_infravalorado`
- `riesgo_sobrevalorado`
- `acciones_futuras`
- `limitaciones`
- `notas`

---

## Outcomes recomendados

- `success`
- `partial_success`
- `failure`
- `avoided_risk`
- `unnecessary_action`
- `unknown`
- `not_observable`

---

## Calidad de decisión vs calidad de outcome

Una buena decisión puede terminar mal.

Una mala decisión puede terminar bien.

Por eso deben separarse:

- `decision_quality`
- `outcome_quality`

El sistema no debe aprender únicamente del resultado final.

---

## Outcome técnico ≠ outcome útil

```text
npm build OK
```

no implica:

```text
valor operacional alto
```

El outcome debe evaluar utilidad real, no solo éxito técnico.

---

## Plantilla mínima

````markdown


# Outcome — <outcome_id>

## Linked decision
<decision_id>

## Fecha observación
YYYY-MM-DD HH:MM Europe/Madrid

## Outcome
success | partial_success | failure | avoided_risk | unnecessary_action | unknown | not_observable

## Calidad de decisión
buena | aceptable | mala | incierta

## Calidad de outcome
bueno | parcial | malo | incierto

## Impacto real
none | low | medium | high

## Coste de validación
bajo | medio | alto

## Rollback usado
sí | no

## Valor operacional humano
alto | medio | bajo | negativo

## Aprendizaje
<qué se aprendió realmente>

## Estado final
closed | monitoring | pending

````
