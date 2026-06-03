# GMAIL_CONTROLLED_SEND_IMPLEMENTATION_PLAN_V1

## Objetivo

Implementar la Fase 1 de Gmail controlled send en `neodaemon_v1`.

Esta fase permite preparar y validar un email en modo `dry-run`.

No se permite envío real.

No se permite Gmail API real.

No se permite OAuth.

No se permiten tokens.

## Alcance aprobado

Permitido:

- documento de implementación;
- herramienta `dry-run`;
- tests;
- bloqueo sin aprobación;
- aprobación válida simulada;
- logs sanitizados.

No autorizado:

- envío real;
- Gmail API real;
- OAuth;
- tokens;
- drafts;
- core;
- gateway;
- routing;
- systemd;
- servicios.

## Arquitectura propuesta

La Fase 1 debe funcionar completamente desconectada de Gmail.

El flujo previsto es:

1. NeoDaemon prepara destinatario, asunto y cuerpo.
2. La herramienta valida formato mínimo.
3. La herramienta ejecuta un `dry-run`.
4. Se registra el resultado sanitizado.
5. No se realiza ningún envío.

## Principio de bloqueo

El comportamiento por defecto debe ser:

`DENY`

Sin aprobación válida, la operación queda bloqueada.

La aprobación utilizada en esta fase es simulada y solo sirve para validar la lógica de control.

No autoriza ningún envío real.

## Reglas obligatorias

- no envío directo;
- no envío sin aprobación humana;
- no imprimir tokens;
- no imprimir credenciales;
- no guardar cuerpos como memoria;
- no modificar buzón;
- no crear drafts;
- logs sanitizados;
- `dry-run` antes de cualquier fase futura de envío real;
- `gmail_send_check.py` no puede usarse como interfaz operativa directa.

## Reglas de privacidad

La salida por defecto no debe exponer contenido sensible.

Los logs deben evitar:

- tokens;
- credenciales;
- refresh tokens;
- client secrets;
- rutas reales de credenciales;
- cuerpo completo del email;
- destinatarios completos si no son necesarios para validar.

## Validaciones requeridas

La Fase 1 deberá demostrar:

- bloqueo sin aprobación;
- aprobación válida simulada;
- ejecución en modo `dry-run`;
- ausencia de Gmail API real;
- ausencia de envío real;
- ausencia de OAuth;
- ausencia de tokens;
- logs sanitizados;
- validación mínima de destinatario;
- validación mínima de asunto;
- validación mínima de cuerpo.

## Comandos de validación esperados

```bash
python3 -m py_compile scripts/gmail_controlled_send_dry_run.py
python3 -m py_compile tests/test_gmail_controlled_send_dry_run.py
python3 tests/test_gmail_controlled_send_dry_run.py
git diff --stat
git status --short
```
## Archivos previstos

```text
docs/gmail/GMAIL_CONTROLLED_SEND_IMPLEMENTATION_PLAN_V1.md
scripts/gmail_controlled_send_dry_run.py
tests/test_gmail_controlled_send_dry_run.py
```
## Criterios de aceptación

La fase se considera válida solo si:

- el script compila;
- los tests compilan;
- los tests pasan;
- el bloqueo sin aprobación funciona;
- la aprobación simulada funciona;
- no existe llamada real a Gmail API;
- no existe envío real;
- no se imprimen secretos;
- no se toca el core;
- no se toca `gateway`;
- no se toca `routing`;
- no se toca `systemd`;
- no se tocan servicios.

## Rollback

Si la Fase 1 falla:

- revertir el commit;
- eliminar documento, script y tests;
- no revocar credenciales porque no se usan credenciales;
- no revertir OAuth porque no se toca OAuth;
- no desactivar servicios porque no se tocan servicios;
- documentar el fallo si afecta al diseño.

## Decisión

La Fase 1 queda limitada a `dry-run`.

No se permite envío real.

El envío real solo podrá plantearse en una fase futura separada, con nueva `CONFIRMACIÓN_ESPECIAL`.


