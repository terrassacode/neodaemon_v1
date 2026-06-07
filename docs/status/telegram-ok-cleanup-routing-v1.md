# FEATURE_TELEGRAM_OK_CLEANUP_ROUTING_DOCUMENTATION_V1

## Estado

VALIDADO.

## Problema

El comando operativo:

```text
OK CLEANUP <short_hash>
```

era enviado a RAG y podía recibir una respuesta documental irrelevante.

Ejemplo real:

```text
OK CLEANUP f163328
```

Respuesta observada: contenido relacionado con `SpotWeldEvents`, sin ejecutar el flujo operativo esperado.

## Causa raíz

El bot de Telegram enviaba todo el contenido recibido por `/main` a:

```text
ask_main(question)
```

sin detectar antes comandos operativos específicos.

Archivo implicado:

```text
/openclaw/bots/telegram_rag_bot.py
```

## Solución aplicada

Se añadió una detección previa a `ask_main(question)`:

```text
^OK CLEANUP [A-Fa-f0-9]{7,40}$
```

Si el mensaje coincide exactamente:

1. llama al bridge;
2. ejecuta `github_post_merge_cleanup_assistant`;
3. devuelve el resultado operativo;
4. no pasa por RAG.

El flujo operativo objetivo es:

```text
tools/neodaemon_executor_bridge.sh '{"action":"github_post_merge_cleanup_assistant","confirmation":"OK CLEANUP <short_hash>"}'
```

## Validación real

Comando real:

```text
/main OK CLEANUP f163328
```

Resultado:

- cleanup ejecutado;
- branch local eliminada;
- branch remota eliminada;
- `main` limpio.

PR afectado:

```text
#78
```

Branch:

```text
docs/ssh-and-hash-cleanup-workflow-v1
```

Resultado operativo observado:

```json
{
  "status": "OK",
  "branch": "docs/ssh-and-hash-cleanup-workflow-v1",
  "pr_number": 78,
  "final_local_branch_exists": false,
  "final_remote_branch_exists": false
}
```

## Riesgo identificado

El parche vive actualmente en:

```text
/openclaw/bots/telegram_rag_bot.py
```

y no en `neodaemon_v1`.

Debe revisarse si ese archivo pertenece a un repositorio Git gestionado para evitar pérdida futura en despliegues, reinstalaciones o actualizaciones.

## Restricciones mantenidas

- No se modificó `tools/` en esta documentación.
- No se modificó bridge.
- No se modificó executor.
- No se modificó OpenClaw desde este cambio documental.
- No se añadió ninguna nueva feature en este PR documental.

## Decisión operativa

`OK CLEANUP <short_hash>` debe tratarse como comando operativo antes de RAG en superficies conversacionales donde Albert lo emita como instrucción directa.
