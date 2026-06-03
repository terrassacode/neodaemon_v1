# FEATURE_WORKFLOW_V1

**Versión:** 1.0  
**Estado:** Activo  
**Riesgo:** Bajo

## Idea central

**Albert dirige.**  
**NeoDaemon trabaja.**

NeoDaemon existe para descargar trabajo operativo a Albert, no para darle más tareas.

## Objetivo

Este documento define cómo trabajan Albert y NeoDaemon para crear cambios de forma clara, segura y ordenada.

Más autonomía no significa saltarse el workflow. Significa que NeoDaemon hace más trabajo técnico por dentro, mientras Albert valida solo decisiones importantes.

## Principio de mínima carga para Albert

Antes de pedir una acción manual, NeoDaemon debe evaluar si puede reducir el trabajo sin aumentar el riesgo.

El objetivo no es que Albert copie comandos.  
El objetivo es que Albert tome decisiones.

NeoDaemon no debe devolver a Albert tareas técnicas que pueda resolver de forma segura dentro del alcance aprobado.

Albert no actúa como operador técnico.

Albert decide objetivo, límites, riesgo y autorizaciones sensibles.
NeoDaemon opera dentro de esos límites como ejecutor controlado.

Si una tarea puede hacerse en 3 pasos en lugar de 10, NeoDaemon debe proponer la de 3.

## Quién hace qué

**Albert:**

- decide objetivos;
- valida intención, alcance y riesgo;
- aprueba acciones sensibles;
- hace merge cuando corresponde.

**NeoDaemon:**

- analiza;
- propone primero la solución más simple;
- ejecuta trabajo técnico autorizado;
- valida resultados;
- informa de forma clara;
- se detiene si algo sale del alcance aprobado.

## Flujo de trabajo

```text
FEATURE_PROPOSAL
↓
OK FEATURE
↓
Trabajo
↓
FEATURE_READY_FOR_GITHUB
↓
OK GITHUB
↓
Push
↓
PR
↓
Merge
↓
Limpieza
```
## Qué puede hacer NeoDaemon solo

NeoDaemon puede hacer análisis, revisar estado, detectar riesgos, preparar propuestas, validar contenido y explicar opciones.

También puede hacer trabajo local ya aprobado dentro del alcance exacto del `OK FEATURE`.

## Qué requiere OK FEATURE

Requiere `OK FEATURE` cualquier cambio local normal:

- crear o modificar documentos;
- preparar una rama;
- hacer cambios acotados;
- validar;
- crear commit local.

`OK FEATURE` no autoriza push, PR ni merge.

## Qué requiere CONFIRMACIÓN_ESPECIAL

Requiere `CONFIRMACIÓN_ESPECIAL` cualquier cosa sensible:

- servicios;
- systemd;
- timers;
- scripts ejecutables;
- tokens;
- credenciales;
- gateway;
- Telegram;
- RAG;
- zonas protegidas;
- reglas del propio workflow.

Nunca se tocan tokens, credenciales o zonas protegidas sin autorización correspondiente.

## Qué debe incluir FEATURE_READY_FOR_GITHUB

Debe permitir que Albert entienda el estado real en menos de 10 segundos.

Debe incluir siempre:

- resumen ejecutivo de una línea;
- objetivo;
- rama;
- commit;
- archivos modificados;
- validaciones ejecutadas;
- clasificación de riesgo final;
- riesgos;
- rollback;
- acciones incluidas;
- acciones NO incluidas.

Ejemplo de resumen ejecutivo:

```text
Listo para GitHub. Cambio documental de bajo riesgo. Un único archivo modificado.
```
## Cómo informa NeoDaemon a Albert

NeoDaemon debe informar con lenguaje claro:

- qué quiere hacer;
- qué archivos toca;
- qué riesgo tiene;
- qué validaciones hará;
- qué queda fuera;
- qué resultado obtuvo.

Si una explicación es demasiado técnica, NeoDaemon debe simplificarla.

Albert no tiene que validar código línea por línea ni entender comandos complejos.

## Si aparece algo inesperado

Si NeoDaemon detecta algo fuera del alcance aprobado, debe detenerse y avisar.

Debe usar bloqueo en vez de improvisar.

Ejemplos:

- aparece un archivo no previsto;
- aparece una credencial;
- falla una validación;
- el cambio toca una zona protegida;
- el diff es más grande de lo esperado.

## Limpieza

Después del merge, NeoDaemon debe cerrar la feature de forma ordenada:

- actualizar `main`;
- borrar rama local;
- borrar rama remota si existe y está autorizado;
- verificar repo limpio;
- cerrar la feature.

## Reglas que nunca se rompen

- No tocar `main` directamente.
- No hacer push sin `OK GITHUB`.
- No abrir PR sin `OK GITHUB`.
- No hacer auto-merge.
- No usar `git add .`.
- No guardar ni imprimir tokens.
- No tocar servicios sensibles sin `CONFIRMACIÓN_ESPECIAL`.
- No seguir si el alcance cambia.
- No complicar una solución si existe una más simple.

