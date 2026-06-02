# Gmail Legacy Inventory

## Objetivo

Inventariar capacidad Gmail del repo legacy sin migrar código ni exponer secretos.

## Resultados relevantes

| archivo legacy | función | lee Gmail | crea borradores | envía correos reales | dependencias | secretos_detectados | riesgos | recomendación |
|---|---|---|---|---|---|---|---|---|
| `projects/fabric-for-welding-data/33_NEODAEMON_GMAIL_CONTROLLED_ACCESS_POLICY.md` | política de acceso controlado | por verificar | por verificar | por verificar | por verificar | por verificar | posible referencia a OAuth/Gmail | revisar manualmente |
| `projects/fabric-for-welding-data/34_NEODAEMON_GMAIL_PHASE0_STATUS.md` | estado fase 0 | por verificar | por verificar | por verificar | por verificar | por verificar | posible referencia a configuración | revisar manualmente |
| `projects/fabric-for-welding-data/35_NEODAEMON_GMAIL_PHASE1_READONLY_SETUP.md` | configuración lectura Gmail | por verificar | por verificar | no | por verificar | por verificar | posible referencia a OAuth | revisar manualmente |
| `projects/fabric-for-welding-data/37_NEODAEMON_GMAIL_PHASE1_READONLY_WORKING.md` | lectura Gmail funcionando | por verificar | por verificar | no | por verificar | por verificar | posible referencia a cuenta/configuración | revisar manualmente |
| `projects/fabric-for-welding-data/38_NEODAEMON_GMAIL_PHASE2_CONTROLLED_SEND_DESIGN.md` | diseño de envío controlado | por verificar | por verificar | diseño | por verificar | por verificar | envío real requiere aprobación humana | revisar manualmente |
| `projects/fabric-for-welding-data/39_NEODAEMON_GMAIL_PHASE2_CONTROLLED_SEND_WORKING.md` | envío controlado funcionando | por verificar | por verificar | por verificar | por verificar | por verificar | posible capacidad de envío real | revisar manualmente |

## Resultados descartados por ruido

- `.git/hooks/sendemail-validate.sample`
- `projects/visualitzador-civic-cat/node_modules/@reduxjs/toolkit/src/createDraftSafeSelector.ts`
- `rag_send_telegram.sh`
- `snapshots/openclaw_pre_oauth.json`
- `backups/2026-05-15-rag-clean/snapshots/openclaw_pre_oauth.json`

## Reglas

- No se copió código.
- No se imprimieron credenciales.
- No se enviaron correos.
- No se tocaron servicios ni systemd.
- Los secretos solo deben marcarse como sí/no.
- El envío real de Gmail requiere `CONFIRMACIÓN_ESPECIAL`.


