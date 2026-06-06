# FEATURE_AUTONOMY_METRICS_WRITE_BLOCKED_V1

## Objetivo

Documentar el bloqueo operativo detectado al intentar registrar `AUTONOMY_METRICS_V1` fuera del repo.

## Hechos observados

- El registro manual de PR #62 funcionó.
- El archivo destino fue:

```text
/home/openclaw/.openclaw/neodaemon/autonomy_metrics_v1.jsonl
```

- NeoDaemon quedó bloqueado al intentar escribir fuera del sandbox/repo.
- El bloqueo fue por falta de aprobación o ruta allowlisted.
- El repo no cambió.
- El registro no debe vivir dentro del repo para no ensuciar Git.

## Conclusión

`AUTONOMY_METRICS_V1` puede registrarse manualmente, pero para automatizarlo hace falta una acción allowlisted específica.

## Restricciones vigentes

- No mover el JSONL al repo.
- No crear dashboard.
- No automatizar desde esta feature.
- No cambiar código, scripts, allowlist ni approvals.
- No tocar OpenClaw core, gateway, routing, systemd ni secrets.
