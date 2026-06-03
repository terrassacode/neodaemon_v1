# GMAIL_CONTROLLED_SEND_RECOVERY_DESIGN_V1

## Objetivo

Diseñar la recuperación de Gmail controlled send para `neodaemon_v1`.

Esta fase es exclusivamente documental.

No se migra código. 
No se migran plugins.
No se activa Gmail.
No se realizan envíos.

## Contexto legacy

En legacy existía una capacidad denominada:

`gmail_send_controlled`

Permitía enviar correos reales mediante Gmail API.

La capacidad estaba separada del core principal y utilizaba aprobación humana antes del envío.

## Regla central

NeoDaemon puede preparar. 
Albert debe aprobar. 
Nada se envía sin `CONFIRMACIÓN_ESPECIAL` explícita.

La implementación futura deberá mantener un mecanismo equivalente a:

`requireApproval: true`

## Qué funcionaba en legacy

Según el assessment histórico:

- Gmail readonly funcionaba.
- Gmail controlled send funcionaba.
- Existía una herramienta llamada `gmail_send_controlled`.
- El envío se realizaba mediante Gmail API.

## Qué no se considera migrable automáticamente

No se asume migrable:

- OAuth legacy.
- Tokens legacy.
- Configuración legacy.
- Rutas legacy.
- Plugins legacy.
- Validaciones legacy.

Todo debe volver a validarse.

## Reglas de seguridad

Queda prohibido:

- enviar sin aprobación humana;
- imprimir tokens;
- imprimir credenciales;
- usar Gmail como memoria operativa;
- modificar correos;
- borrar correos;
- archivar correos;
- modificar labels.

## Regla específica

`gmail_send_check.py` no debe utilizarse como interfaz operativa.

Solo podrá utilizarse detrás de una herramienta controlada con aprobación humana.

## Flujo propuesto

1. NeoDaemon prepara el correo.
2. NeoDaemon muestra destinatario, asunto y cuerpo.
3. Albert revisa.
4. Albert autoriza explícitamente.
5. La herramienta valida la autorización.
6. Solo entonces se permite el envío.

## Criterio para futura implementación

No basta con declarar:

`requireApproval: true`

Debe demostrarse mediante validación explícita que la aprobación humana bloquea el envío hasta recibir autorización real.

Si no se puede demostrar la aprobación humana funcionando, no se habilita envío.

## Pruebas permitidas en fases futuras

- validación de aprobación humana;
- validación de bloqueo sin aprobación;
- validación de sanitización de logs;
- validación de scopes mínimos;
- pruebas dry-run sin envío real.

## Pruebas prohibidas en esta fase

- envío real;
- creación de borradores;
- modificación de correos;
- lectura de tokens;
- activación de OAuth;
- activación de plugins;
- cambios en gateway;
- cambios en routing.

## Criterios para pasar a implementación

- diseño aprobado;
- riesgo aceptado;
- `CONFIRMACIÓN_ESPECIAL`;
- mecanismo de aprobación humana definido;
- validación de bloqueo sin aprobación;
- secretos fuera de Git;
- rollback documentado.

## Rollback conceptual

Si una futura implementación falla:

- desactivar la capacidad de envío;
- retirar acceso operativo;
- revocar credenciales si fuera necesario;
- revertir cambios;
- documentar el incidente.

## Decisión recomendada

Recuperar Gmail controlled send únicamente como capacidad controlada.

No recuperar envío directo.

No utilizar `gmail_send_check.py` como interfaz operativa.

La primera implementación futura deberá demostrar que la aprobación humana funciona antes de permitir cualquier envío real.


