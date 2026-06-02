# Gmail Legacy Assessment

## Resumen ejecutivo

La capacidad Gmail legacy llegó a estar operativa en dos fases:

- Fase 1: lectura Gmail readonly funcionando.
- Fase 2: envío controlado funcionando.

No debe migrarse copiando código directamente. Debe rediseñarse para `neodaemon_v1` manteniendo separación por addon/plugin, confirmación humana y sin exponer tokens.

## Fuentes revisadas

| Documento | Clasificación | Resultado |
|---|---|---|
| 33_NEODAEMON_GMAIL_CONTROLLED_ACCESS_POLICY.md | diseño | política de acceso controlado |
| 34_NEODAEMON_GMAIL_PHASE0_STATUS.md | working | identidad y seguridad completadas |
| 35_NEODAEMON_GMAIL_PHASE1_READONLY_SETUP.md | diseño readonly | diseño de lectura Gmail |
| 37_NEODAEMON_GMAIL_PHASE1_READONLY_WORKING.md | working readonly | Gmail readonly funcionaba |
| 38_NEODAEMON_GMAIL_PHASE2_CONTROLLED_SEND_DESIGN.md | diseño controlled_send | diseño de envío controlado |
| 39_NEODAEMON_GMAIL_PHASE2_CONTROLLED_SEND_WORKING.md | working controlled_send | envío real controlado funcionaba |

## Assessment

| Capacidad | Funcionaba en legacy | Merece migrarse | Requiere rediseño | Motivo |
|---|---|---|---|---|
| Gmail readonly | sí | sí | sí | dependía de OAuth/addon aislado |
| Gmail controlled send | sí | sí | sí | envío real requiere confirmación explícita |
| Gmail como memoria operativa | no | no | sí | estaba prohibido |
| Borrado/modificación de correos | no | no | sí | estaba prohibido |

## Riesgos

- OAuth y tokens no deben copiarse ni imprimirse.
- Envío real requiere `CONFIRMACIÓN_ESPECIAL`.
- No se debe usar Gmail como memoria operativa.
- No se deben descargar adjuntos automáticamente.
- No se deben borrar, archivar ni modificar correos en la migración inicial.

## Decisión recomendada

Migrar primero Gmail readonly.

Después diseñar controlled send.

No activar envío real hasta tener:

- plugin/addon separado;
- scope mínimo;
- confirmación exacta obligatoria;
- prueba controlada;
- rollback documentado.

## Próximos pasos seguros

1. Crear diseño Gmail readonly para `neodaemon_v1`.
2. Revisar arquitectura de addon/plugin.
3. Definir scopes mínimos.
4. No tocar tokens en Git.
5. No activar envío en esta fase.


