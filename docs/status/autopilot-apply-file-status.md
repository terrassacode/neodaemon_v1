# Autopilot Apply File Status

## Estado

Validación real de `neodaemon_autopilot_apply_file_v1.sh`.

## Objetivo

Comprobar que OpenClaw puede pasar de contenido temporal a PR sin edición manual directa dentro del repositorio.

## Resultado esperado

- Crear rama.
- Escribir un archivo permitido.
- Validar.
- Commit.
- Push.
- Crear PR.
- No tocar zonas protegidas.
- No usar approvals de MAIN.
