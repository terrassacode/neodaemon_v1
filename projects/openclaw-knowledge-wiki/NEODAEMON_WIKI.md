# Neodaemon Wiki Protocol

## Propósito

Definir cómo Neodaemon debe mantener esta wiki sin romper aislamiento ni convertirla en automatización no autorizada.

## Modelo

```text
raw/  →  wiki/  →  outputs/
```

- `raw/`: fuentes originales, inmutables.
- `wiki/`: notas generadas, reorganizadas y resumidas por Neodaemon.
- `outputs/`: resultados derivados de revisión manual, como lint documental.

## Reglas críticas

1. No modificar `raw/`.
2. No escribir fuera de este proyecto.
3. No procesar más de 3 fuentes por ingest.
4. No usar APIs externas.
5. No instalar dependencias.
6. No ejecutar scripts globales.
7. No tocar core, scripts globales, RAG, gateway, systemd, Gmail, Telegram, logs, memory ni dashboard-v2.
8. Mantener trazabilidad entre nota y fuente.
9. Separar datos confirmados, inferencias y dudas.
10. Registrar todo ingest en `wiki/log.md`.

## Workflow: ingest

Protocolo documental para convertir fuentes en notas.

### Entrada

- máximo 3 fuentes;
- todas dentro de `raw/`;
- fuentes autorizadas por Albert;
- sin secretos ni credenciales.

### Proceso manual

1. Identificar fuentes.
2. Confirmar que están dentro de `raw/`.
3. Leer fuentes sin modificarlas.
4. Crear o actualizar notas dentro de `wiki/`.
5. Actualizar `wiki/index.md`.
6. Añadir entrada al final de `wiki/log.md`.

### Salida

- notas en `wiki/concepts/`, `wiki/entities/`, `wiki/sources/` o `wiki/comparisons/`;
- índice actualizado;
- log append-only actualizado.

## Workflow: query

Protocolo documental para responder preguntas usando la wiki.

### Entrada

- pregunta de Albert;
- notas existentes en `wiki/`.

### Proceso manual

1. Revisar `wiki/index.md`.
2. Leer solo las notas necesarias.
3. Responder separando:
   - datos confirmados;
   - inferencias;
   - dudas;
   - límites.
4. Citar rutas internas cuando sea útil.

### Salida

- respuesta breve;
- enlaces internos sugeridos;
- dudas o huecos detectados.

## Workflow: lint

Protocolo documental para revisar calidad de la wiki.

No ejecuta linters ni scripts.

### Entrada

- nota o conjunto pequeño de notas en `wiki/`.

### Revisión manual

Comprobar:

- tiene fuente;
- tiene resumen;
- distingue hechos, inferencias y dudas;
- no contiene secretos;
- no inventa datos;
- enlaza con `wiki/index.md` cuando corresponde;
- no modifica `raw/`.

### Salida

Puede documentarse en:

```text
outputs/lint/
```

Solo como resultado manual.

## Formato sugerido de nota

```markdown
# <Título de nota>

## Fuente

- `<ruta dentro de raw/>`

## Resumen

<resumen breve>

## Datos confirmados

- ...

## Inferencias

- ...

## Dudas o límites

- ...

## Conceptos relacionados

- ...

## Enlaces internos

- ...
```

## Log append-only

Cada ingest añade una entrada al final de `wiki/log.md`.

No reescribir entradas anteriores salvo corrección explícita autorizada.
