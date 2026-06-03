# GMAIL_READONLY_INTEGRATION_PLAN_V1

## Objetivo

Planificar la integración Gmail readonly en `neodaemon_v1` usando el addon legacy recuperado, pero con salida sanitizada.

## Contexto

`OAUTH_READONLY_RECOVERY_RESULT = working`.

El addon legacy funciona con scope `gmail.readonly`.

No debe integrarse tal cual porque la salida legacy mostró snippets y metadatos visibles.

## Regla central

Gmail readonly solo debe exponer metadata sanitizada por defecto.

Cualquier acceso a snippet, asunto completo, remitente completo o cuerpo requiere `CONFIRMACIÓN_ESPECIAL` separada.

## Alcance

Permitido:

- readonly únicamente;
- metadata-only por defecto;
- sin snippets por defecto;
- sin cuerpo por defecto;
- sin envío;
- sin drafts;
- sin modificación de buzón;
- sin OAuth nuevo;
- sin servicios;
- sin systemd.

## Campos permitidos por defecto

- número de mensajes encontrados;
- estado de conexión;
- scope usado;
- fecha aproximada si es necesaria;
- IDs parciales o hash local si es necesario.

## Campos prohibidos por defecto

- cuerpo completo;
- snippets;
- asunto completo;
- remitente completo;
- destinatario completo;
- emails privados completos;
- tokens;
- client secrets;
- refresh tokens;
- rutas completas a credenciales.

## Criterios de bloqueo

Bloquear si:

- aparece scope distinto de `gmail.readonly`;
- aparece `gmail.send`;
- aparece `gmail.modify`;
- aparece `gmail.compose`;
- se imprime token;
- se imprime client secret;
- se muestra snippet por defecto;
- se muestra cuerpo por defecto;
- se intenta modificar buzón;
- se intenta enviar;
- se intenta crear draft.

## Implementación futura

La futura implementación deberá crear una capa controlada entre `neodaemon_v1` y el addon Gmail readonly.

Esa capa deberá sanitizar la salida antes de entregarla a NeoDaemon.

No se debe usar directamente `gmail_readonly_check.py` como interfaz operativa final.

## Validaciones futuras

- confirmar scope `gmail.readonly`;
- confirmar que no hay scopes de escritura;
- confirmar salida sin snippets;
- confirmar salida sin cuerpo;
- confirmar salida sin tokens;
- confirmar que no se crea OAuth nuevo;
- confirmar que no se toca systemd;
- confirmar que no se toca servicios.

## Rollback conceptual

Si la integración futura expone datos privados:

- desactivar la capa readonly;
- revertir cambios;
- revisar logs;
- rotar credenciales si hubiera exposición;
- documentar incidente.

## Decisión recomendada

Integrar Gmail readonly primero.

No integrar Gmail send todavía.

No exponer snippets ni cuerpos por defecto.


