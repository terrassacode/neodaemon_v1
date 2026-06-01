# OpenClaw Knowledge Wiki

Shell aislado para construir una wiki operativa de conocimiento OpenClaw al estilo LLM Wiki / Obsidian / Claude Code, adaptada a Neodaemon.

## Objetivo

Convertir fuentes seleccionadas en notas navegables, resumidas y trazables dentro de `wiki/`, sin tocar core ni sistemas globales.

Este proyecto es documental y local.  
No ejecuta scripts.  
No usa APIs externas.  
No instala dependencias.

## Principios

- `raw/` es inmutable.
- `wiki/` es generado por Neodaemon.
- `wiki/index.md` es el catálogo maestro.
- `wiki/log.md` es append-only.
- Máximo 3 fuentes por ingest.
- No modificar `raw/`.
- No escribir fuera de este proyecto.
- No usar APIs externas.
- No instalar dependencias.
- No ejecutar scripts globales.

## Estructura

```text
/openclaw/workspace/main/projects/openclaw-knowledge-wiki/
├── README.md
├── .project_scope.md
├── NEODAEMON_WIKI.md
├── .gitignore
├── raw/
│   ├── articles/
│   ├── papers/
│   ├── notes/
│   ├── docs/
│   └── data/
├── wiki/
│   ├── index.md
│   ├── log.md
│   ├── concepts/
│   ├── entities/
│   ├── sources/
│   └── comparisons/
└── outputs/
    └── lint/
```

## Obsidian

Obsidian es opcional.
Puede usarse como visor/editor Markdown de la carpeta del proyecto.
No es dependencia obligatoria.
No razona, no ingiere fuentes y no valida contenido.
La generación y mantenimiento de la wiki corresponde a Neodaemon bajo autorización de Albert.

## Flujo manual

1. Albert autoriza fuentes.
2. Las fuentes se colocan manualmente en `raw/`.
3. Neodaemon lee máximo 3 fuentes por ingest.
4. Neodaemon propone notas dentro de `wiki/`.
5. Neodaemon actualiza `wiki/index.md`.
6. Neodaemon añade una entrada al final de `wiki/log.md`.
7. Si hay revisión lint/manual, el resultado puede documentarse en `outputs/lint/`.

## Validación manual antes de escribir

Antes de crear o modificar archivos, comprobar:

- todas las rutas quedan dentro de `/openclaw/workspace/main/projects/openclaw-knowledge-wiki/`;
- no se modifica nada dentro de `raw/`;
- no se toca core;
- no se tocan scripts globales;
- no se toca `dashboard-v2`;
- no se tocan logs globales;
- no se toca `memory`;
- no se toca RAG;
- no se toca Gmail;
- no se toca Telegram;
- no se toca systemd;
- no se toca gateway;
- no se ejecutan comandos;
- no se instalan dependencias;
- no se usan APIs externas.

## Estado

Propuesta inicial.  
Sin automatización activa.
