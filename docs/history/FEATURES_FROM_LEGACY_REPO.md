# Features from Legacy Repo

## Estado del inventario

Este documento es un inventario progresivo.

La ausencia de una feature no implica que no existiera en el repositorio legacy.

Toda entrada debe indicar su evidencia.


No se debe asumir migración, eliminación o existencia sin evidencia verificable.

La trazabilidad histórica tiene prioridad sobre cualquier reclasificación posterior.

## Reglas documentales

La columna `ID` es el identificador principal del inventario.

No se deben renumerar features.

No se deben inventar IDs.

No se deben inventar features.

Una feature no puede marcarse como `migrada` sin evidencia verificable en `neodaemon_v1`.

La evidencia justifica el estado.

Una entrada no puede tener un estado más fuerte que su evidencia.

`confirmado_codigo` puede marcarse como `confirmado`.

`confirmado_documentacion` puede marcarse como `confirmado`.

`confirmado_memoria` debe usarse preferentemente como `por verificar` hasta encontrar evidencia adicional.

`por_verificar` obliga a usar estado `por verificar`.

La columna `Tipo` es informativa y no sustituye al `ID` histórico.

## Valores permitidos

### Evidencia

- `confirmado_codigo`
- `confirmado_documentacion`
- `confirmado_memoria`
- `por_verificar`
- `descartado`

### Prioridad

- `alta`
- `media`
- `baja`

### Tipo

- `funcional`
- `arquitectónica`
- `experimental`

### Estados

- `confirmado`
- `migrado`
- `pendiente`
- `por verificar`
- `descartado`

## Inventario

| ID | Feature | Tipo | Evidencia | Estado legacy | Estado neodaemon_v1 | Prioridad | Siguiente paso | Notas |
|---|---|---|---|---|---|---|---|---|
| por_verificar | por_verificar | por_verificar | por_verificar | por verificar | por verificar | media | revisar evidencia antes de asignar ID | fila ejemplo; no representa una feature confirmada |



