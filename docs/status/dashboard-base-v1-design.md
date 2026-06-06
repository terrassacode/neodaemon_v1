# FEATURE_DASHBOARD_BASE_V1_DESIGN

## Objetivo

Diseñar un dashboard base único para integrar, en fases posteriores, la visión operativa de tokens, métricas de autonomía y control GitHub.

V1 es solo diseño. No crea dashboard real.

## Problema que resuelve

Cuellos de botella actuales:

1. Albert sigue dependiendo demasiado de ChatGPT.
2. Cierre de ramas y vuelta a `main` sigue siendo manual.
3. Falta un dashboard base común para ver tokens, métricas y GitHub.

Un dashboard base permitiría tener una única entrada visual para el estado operativo, sin mezclar aún implementación ni automatización.

## Paneles iniciales

Paneles futuros previstos:

- Dashboard de tokens.
- Dashboard de métricas de autonomía.
- Dashboard de control GitHub.

V1 solo define el contenedor conceptual y el orden de integración.

## Fuentes de datos

Fuentes actuales conocidas:

- Estado operativo AUTOPILOT documentado en `docs/status/current-autopilot-operating-model.md`.
- Métricas JSONL fuera del repo en `/home/openclaw/.openclaw/neodaemon/autonomy_metrics_v1.jsonl`.
- Documentación de bloqueos y rutas pendientes en `docs/status/`.
- Datos de tokens existentes cuando estén disponibles en el entorno operativo.
- Estado GitHub disponible mediante flujos controlados existentes o revisión manual.

Estado operativo actual:

- `docs/*.md` → AUTOPILOT operativo.
- `scripts/*.py` → validado end-to-end.
- `tools/*.sh` → validable, pero publicación bloqueada si pide approval no allowlisted.
- métricas JSONL fuera del repo → funcionan manualmente, pero automatización requiere acción allowlisted específica.

## Qué NO hace V1

- No implementa dashboard real.
- No crea código.
- No crea scripts.
- No automatiza lecturas.
- No cambia servicios.
- No toca OpenClaw core, gateway, routing, systemd ni secrets.
- No mueve métricas JSONL dentro del repo.
- No sustituye decisiones manuales de Albert.

## Riesgos

- Diseñar demasiado antes de validar necesidades reales.
- Mezclar métricas de autonomía con métricas de actividad.
- Introducir dependencia de automatización antes de tener acciones allowlisted.
- Convertir el dashboard en otra superficie que mantener manualmente.

Mitigación: V1 debe ser solo diseño y mantener implementación por fases pequeñas.

## Orden de implementación recomendado

1. Mantener este documento como fuente mínima de diseño.
2. Definir el esquema visual base sin datos vivos.
3. Integrar primero métricas de autonomía en modo lectura/manual.
4. Integrar tokens usando fuentes ya existentes.
5. Integrar control GitHub solo cuando existan acciones allowlisted suficientes.
6. Evitar servicios o automatización hasta tener una necesidad concreta y segura.
