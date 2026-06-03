# NEODAEMON_SAFE_EXECUTOR_DESIGN_V1

## Objetivo

Definir un executor mínimo y seguro para NeoDaemon.

El objetivo es permitir la ejecución de tareas de bajo riesgo previamente aprobadas por Albert.

Este documento no implementa ningún executor.

Este documento no concede permisos.

Este documento solo define reglas y límites para una implementación futura.

## Principios

1. Seguridad antes que autonomía.
2. Menor privilegio posible.
3. Todo cambio debe ser auditable.
4. Los secretos nunca deben imprimirse.
5. Las zonas protegidas permanecen protegidas.
6. El executor no debe disponer de shell libre.
7. El executor debe operar únicamente dentro de límites explícitos.

## Alcance

El executor seguro solo podrá utilizarse para tareas de bajo riesgo.

Ejemplos permitidos en fases iniciales:

- crear documentación;
- editar documentación existente;
- crear tests no destructivos;
- ejecutar validaciones de lectura;
- revisar estado Git;
- preparar commits documentales;
- preparar ramas de trabajo.

No podrá utilizarse para capacidades sensibles sin aprobación separada.

## Comandos permitidos

Ejemplos de comandos permitidos:

- `git status`
- `git diff`
- `git diff --stat`
- `git branch`
- `git checkout` (ramas autorizadas)
- `git add`
- `git commit`
- `mkdir`
- `touch`
- `cat`
- `sed`
- validaciones de lectura
- `python3 -m py_compile`

Todos los comandos deberán estar explícitamente permitidos.

No existe ejecución arbitraria.

## Comandos prohibidos

Quedan prohibidos por defecto:

- shell interactiva libre;
- ejecución arbitraria;
- `sudo`;
- modificación de permisos del sistema;
- instalación de paquetes;
- gestión de servicios;
- modificación de systemd;
- acceso a secretos;
- acceso a tokens;
- acceso a credenciales;
- comandos destructivos no autorizados;
- cualquier comando fuera de la lista permitida.

## Política de ejecución

Todo comando no incluido explícitamente

## Rutas permitidas

El executor solo podrá operar sobre rutas autorizadas.

Ejemplos iniciales:

- `docs/`
- `tests/`
- ramas de trabajo aprobadas

Las rutas permitidas deberán mantenerse en una lista explícita.

## Rutas prohibidas

Quedan prohibidas por defecto:

- zonas protegidas del core;
- directorios de credenciales;
- directorios de tokens;
- configuraciones sensibles;
- servicios;
- systemd;
- OAuth;
- Gmail operativo;
- cualquier ruta marcada como protegida por la política del proyecto.

## Aprobación humana

El executor no decide objetivos.

Albert decide.

NeoDaemon propone.

El executor ejecuta únicamente acciones previamente autorizadas.

Las acciones clasificadas como:

- medium risk;
- high risk;
- special confirmation;requieren aprobación humana explícita.

Sin aprobación válida:

`DENY`

## Validaciones

Antes de cualquier cambio deberán ejecutarse validaciones adecuadas al tipo de tarea.

Ejemplos:

- revisión de alcance;
- validación de rutas;
- validación de permisos;
- validación de secretos;
- validación de sintaxis;
- validación Git.

Toda validación fallida debe bloquear la ejecución.

## Política de secretos

Queda prohibido:

- imprimir tokens;
- imprimir credenciales;
- imprimir client secrets;
- imprimir refresh tokens;
- almacenar secretos en logs;
- almacenar secretos en documentación.

La detección de secretos debe bloquear la ejecución.

## Rollback

Toda acción ejecutable deberá disponer de rollback razonable.

Ejemplos:

- revertir commit;
- eliminar archivo creado;
- restaurar archivo modificado;
- cerrar PR no aprobado.

Si no existe rollback razonable, la acción deberá elevarse para revisión humana.

## Criterios de bloqueo

La ejecución debe bloquearse si:

- el alcance es ambiguo;
- la ruta no está autorizada;
- existe riesgo no evaluado;
- aparecen secretos;
- se intenta acceder a zonas protegidas;
- se solicita una capacidad no autorizada;
- falla una validación obligatoria.

## Fases futuras

Fase 0:
- documentación;
- revisión;
- validación.

Fase 1:
- cambios documentales de bajo riesgo;
- validaciones automáticas.

Fase 2:
- creación controlada de código;
- ejecución limitada de tests.

Fase 3:
- operaciones semiautónomas con aprobación humana.

Fase 4:
- capacidades ampliadas sujetas a nuevas políticas de seguridad.

Ninguna fase implica autorización automática para avanzar a la siguiente.

## Límites absolutos

Las siguientes capacidades quedan fuera del alcance del executor seguro salvo autorización específica independiente:

- Gmail operativo;
- envío de correos;
- OAuth;
- gestión de credenciales;
- gestión de secretos;
- systemd;
- servicios;
- acceso administrativo;
- ejecución remota;
- modificación del core;
- shell libre.

Estas restricciones prevalecen sobre cualquier otra regla del documento.

