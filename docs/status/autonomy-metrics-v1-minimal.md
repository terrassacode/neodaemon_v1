# AUTONOMY_METRICS_V1_MINIMAL

## Objetivo

Medir la reducción de dependencia humana con el tiempo, no la actividad general del sistema.

## Campos obligatorios

Cada registro debe incluir estos campos:

- `timestamp`
- `feature_id`
- `status`
- `pr_number`
- `albert_interventions_count`
- `ssh_manual_count`
- `approval_count`
- `execution_package_owner`
- `autonomy_level`

Ejemplo mínimo:

```json
{
  "timestamp": "ISO8601",
  "feature_id": "PR-52",
  "status": "DONE",
  "pr_number": 52,
  "albert_interventions_count": 1,
  "ssh_manual_count": 0,
  "approval_count": 0,
  "execution_package_owner": "ChatGPT",
  "autonomy_level": "L3"
}
```

## Campos opcionales

- `pr_url`
- `blocked_reason`
- `notes`

## execution_package_owner

Valores permitidos:

- `Albert`
- `ChatGPT`
- `Operator`
- `NeoDaemon`

Este campo identifica quién convirtió la intención inicial en una orden ejecutable.

## Niveles L0-L4

- `L0`: Albert ejecuta manualmente todo.
- `L1`: NeoDaemon propone, Albert ejecuta.
- `L2`: NeoDaemon crea rama/commit, Albert publica.
- `L3`: NeoDaemon crea PR, Albert revisa merge/reject.
- `L4`: NeoDaemon completa todo salvo merge.

## Regla de registro

No registrar eventos hasta cerrar este formato.

Una vez cerrado, registrar un único evento por feature al cierre operativo del caso.

## Qué NO mide

- No mide calidad de features.
- No mide valor de negocio.
- No mide inteligencia del sistema.
- No mide complejidad técnica.
- Solo mide reducción de dependencia humana.
