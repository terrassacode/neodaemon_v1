# SAFE_EXECUTOR_IMPLEMENTATION_PLAN_V1

## Objetivo

Definir cómo pasar del diseño conceptual del Safe Executor a una implementación futura controlada.

Este documento depende de:

`docs/executor/NEODAEMON_SAFE_EXECUTOR_DESIGN_V1.md`

Este documento no implementa ningún executor.

Este documento no concede permisos.

Este documento solo define fases y criterios para una implementación futura.

## Principios

- seguridad antes que velocidad;
- menor privilegio posible;
- validación antes de ejecución;
- auditoría obligatoria;
- rollback obligatorio;
- sin shell libre;
- sin acceso a secretos;
- sin capacidades implícitas.

## Fase 0: revisión documental

Objetivo:

Validar que el diseño base es suficiente antes de escribir código.

Entrada:

- `docs/executor/NEODAEMON_SAFE_EXECUTOR_DESIGN_V1.md`

Acciones permitidas:

- revisar documentación;
- detectar contradicciones;
- detectar permisos demasiado amplios;
- detectar rutas ambiguas;
- proponer ajustes documentales.

No permitido:

- implementar executor;
- crear scripts;
- ejecutar comandos reales;
- tocar tokens;
- tocar OAuth;
- tocar Gmail;
- tocar systemd;
- tocar servicios;
- tocar core.

Criterio de salida:

La Fase 0 solo se considera cerrada si el diseño base no contiene permisos amplios, shell libre ni zonas críticas autorizadas.

## Fase 1: inspector read-only mínimo

Objetivo:

Permitir inspección controlada sin modificar nada.

Capacidades previstas:

- leer documentación;
- leer archivos autorizados;
- consultar estado Git;
- consultar diferencias Git;
- ejecutar validaciones de solo lectura.

Comandos previstos:

- `git status`
- `git diff`
- `git diff --stat`
- `cat`
- `sed`

Restricciones:

- sin escritura;
- sin commits;
- sin push;
- sin shell libre;
- sin acceso a secretos.

Criterio de salida:

Demostrar que todas las operaciones son de lectura y auditables.

## Fase 2: escritura documental controlada

Objetivo:

Permitir cambios documentales de bajo riesgo.

Capacidades previstas:

- crear documentación;
- editar documentación;
- actualizar archivos Markdown autorizados.

Rutas iniciales previstas:

- `docs/`

Restricciones:

- sin código ejecutable;
- sin scripts;
- sin secretos;
- sin zonas protegidas;
- sin shell libre.

Validaciones obligatorias:

- validación de ruta;
- validación de alcance;
- revisión Git;
- revisión de secretos.

Criterio de salida:

Demostrar que la escritura queda limitada a documentación autorizada.

## Fase 3: Git local controlado

Objetivo:

Permitir operaciones Git locales de bajo riesgo.

Capacidades previstas:

- crear ramas de trabajo;
- añadir archivos autorizados;
- crear commits locales;
- revisar diferencias antes del commit.

Comandos previstos:

- `git checkout`
- `git branch`
- `git add`
- `git commit`
- `git status`
- `git diff`
- `git diff --stat`

Restricciones:

- sin `push` automático;
- sin merge automático;
- sin borrado automático de ramas;
- sin force push;
- sin cambios fuera de rutas autorizadas.

Criterio de salida:

Demostrar que el executor puede preparar cambios locales sin publicar nada automáticamente.

## Fuera de alcance

Las siguientes capacidades no forman parte de Safe Executor V1:

- Gmail operativo;
- envío de correos;
- drafts;
- OAuth;
- gestión de tokens;
- gestión de credenciales;
- systemd;
- servicios;
- acceso administrativo;
- ejecución remota;
- modificación del core;
- shell libre.

Estas capacidades requerirán diseños y aprobaciones independientes.

## Validaciones obligatorias

Antes de cualquier ejecución deberán verificarse:

- alcance autorizado;
- ruta autorizada;
- permisos autorizados;
- ausencia de secretos;
- cumplimiento de la fase correspondiente;
- coherencia con el diseño base.

Toda validación fallida implica:

`DENY`

## Control de secretos

Debe bloquearse cualquier intento de:

- mostrar tokens;
- mostrar credenciales;
- mostrar client secrets;
- mostrar refresh tokens;
- registrar secretos en logs;
- almacenar secretos en documentación.

## Rollback

Toda fase debe tener rollback definido antes de implementarse.

Ejemplos:

- eliminar archivo creado;
- revertir commit local;
- restaurar documento modificado;
- cerrar PR no aprobado.

Si no existe rollback claro, la acción no debe ejecutarse.

## Requisitos antes de escribir código

Antes de crear cualquier script del Safe Executor deberán cumplirse:

- diseño base integrado en `main`;
- plan de implementación integrado en `main`;
- rutas permitidas definidas;
- comandos permitidos definidos;
- criterios de bloqueo definidos;
- política de secretos definida;
- aprobación humana explícita.

## Criterios para pasar de diseño a código

Solo se podrá pasar a código si:

- `NEODAEMON_SAFE_EXECUTOR_DESIGN_V1.md` está integrado en `main`;
- `SAFE_EXECUTOR_IMPLEMENTATION_PLAN_V1.md` está integrado en `main`;
- existe aprobación humana explícita;
- el alcance inicial es read-only o documental;
- no se concede shell libre;
- no se concede acceso a secretos;
- no se autoriza acceso a Gmail, OAuth, systemd, servicios ni core;
- existen validaciones claras;
- existe rollback claro.

## Decisión

Safe Executor V1 debe avanzar por fases.

La primera implementación real deberá ser mínima, auditable y reversible.

No se permite autonomía amplia en V1.

## Modo seguro

Ante cualquier duda, el executor debe bloquear la acción.

Situaciones que activan modo seguro:

- alcance ambiguo;
- ruta no reconocida;
- comando no autorizado;
- validación incompleta;
- riesgo no clasificado;
- posible exposición de secretos;
- conflicto con políticas existentes.

Comportamiento obligatorio:

`DENY`

El executor debe solicitar revisión humana antes de continuar.

## Principio final

La ausencia de autorización no implica autorización.

Todo permiso debe estar explícitamente definido.

Toda capacidad no autorizada explícitamente se considera prohibida.

