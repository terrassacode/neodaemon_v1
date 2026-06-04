# EXECUTOR_BRIDGE_V1_STATUS

## Estado

Parcialmente operativo y validado.

**Fecha:** 2026-06-04

## Objetivo

Permitir que NeoDaemon MAIN ejecute acciones controladas sobre el host mediante:

```text
MAIN → exec → exec approvals → bridge → local executor
```

sin exponer shell libre.

## Componentes

**Bridge:**

```text
tools/neodaemon_executor_bridge.sh
```

**Executor:**

```text
tools/neodaemon_local_executor_v1.sh
```

## Configuración validada

**Agent MAIN:**

```text
tools.allow incluye:
- read
- write
- memory_get
- web_search
- gmail_send_controlled
- exec
```

**Exec policy:**

```text
security: allowlist
ask: on-miss
```

**Exec approvals:**

```text
Allowlist activa:

/openclaw/workspace/git_clean/neodaemon_v1/tools/neodaemon_executor_bridge.sh
```

## Validaciones realizadas

### Bridge

**Sintaxis:**

```text
OK
```

### Acción github_status

**Resultado:**

```json
{
  "status": "OK",
  "action": "github_status",
  "branch": "main",
  "working_tree": "",
  "safe": true,
  "logs_redacted": true
}
```

**Estado:**

```text
VALIDADO
```

### Acción desconocida

**Resultado:**

```json
{
  "status": "BLOCKED",
  "summary": "unknown action",
  "safe": true,
  "logs_redacted": true
}
```

**Estado:**

```text
VALIDADO
```

## Acciones disponibles actualmente

```text
github_status
github_publish_token
github_create_pr
```

**Fuente:**

```text
tools/neodaemon_local_executor_v1.sh
```

## Seguridad validada

**Default deny:**

```text
Sí
```

**Acciones desconocidas:**

```text
BLOCKED
```

**Shell libre:**

```text
No expuesto
```

**Read fuera de sandbox:**

```text
Bloqueado
```

## Limitaciones actuales

**github_publish_token:**

```text
No validado desde MAIN
```

**github_create_pr:**

```text
No validado desde MAIN
```

Se observó comportamiento anómalo en approvals:

```text
Rotación continua de approval IDs para determinadas acciones sensibles.
```

Pendiente investigación.

## Conclusión

El puente ha sido validado para operaciones de lectura controladas.

La arquitectura:

```text
MAIN → exec → approvals → bridge → executor
```

ha demostrado funcionar correctamente para `github_status`.

Las acciones sensibles requieren validación adicional antes de considerarse operativas.

