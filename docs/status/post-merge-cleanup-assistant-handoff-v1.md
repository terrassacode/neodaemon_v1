# FEATURE_HANDOFF_POST_MERGE_CLEANUP_ASSISTANT_V1

## 1. Resumen ejecutivo

Este documento permite continuar en un nuevo chat sin perder contexto sobre el flujo de cierre post-merge.

El objetivo original fue reducir el trabajo manual de Albert al cerrar PRs ya mergeados, manteniendo control humano explícito antes de borrar ramas locales o remotas.

Estado actual: el `github_post_merge_cleanup_assistant` existe, fue probado en modo diagnóstico y devolvió `next_action=nothing_to_cleanup` porque no había candidatas.

## 2. De dónde venimos

Objetivo original:

- cierre automático/controlado post-merge;
- diagnóstico de ramas mergeadas;
- limpieza local/remota solo con autorización explícita;
- menos dependencia de ChatGPT para repetir comandos manuales.

Durante el proceso aparecieron problemas con `autopilot-commit` y approvals al publicar cambios en `tools/*.sh` desde MAIN. Varias fases tuvieron que pasar por SSH manual controlado.

## 3. Cronología resumida

- PR #66: diseño documental inicial de acción post-merge en tres fases: check read-only, `OK CLEANUP`, cleanup controlado.
- PR #72: implementación de `github_post_merge_close` con `mode=check` y `mode=cleanup`.
- PR #73: añadido `mode=list_candidates` para detectar ramas candidatas sin que Albert indique una rama concreta.
- PR #74: añadido `github_post_merge_cleanup_assistant` como acción de alto nivel.

## 4. Estado actual del sistema

- `main` actualizado.
- Ramas de #72, #73 y #74 eliminadas.
- `github_post_merge_cleanup_assistant` probado sin candidatas.
- Resultado actual del assistant:

```json
{"status":"OK","action":"github_post_merge_cleanup_assistant","current_branch":"main","working_tree_clean":true,"main_current":true,"main_updated":true,"cleanup_ready_count":0,"candidates":[],"safe":true,"logs_redacted":true,"next_action":"nothing_to_cleanup"}
```

## 5. Capacidades validadas

- Diagnóstico post-merge en modo check.
- Listado de candidatas post-merge.
- Assistant de alto nivel sin candidatas.
- Bloqueo sin `OK CLEANUP` exacto.
- Cleanup local/remoto validado en pruebas controladas.
- Salidas JSON claras.

## 6. Capacidades pendientes de validación

Pendiente E2E definitivo con NeoDaemon:

1. crear rama test documental;
2. mergearla;
3. dejar rama local/remota viva;
4. ejecutar `github_post_merge_cleanup_assistant`;
5. obtener texto exacto `OK CLEANUP PR #<número> branch <rama>`;
6. confirmar `OK CLEANUP`;
7. validar borrado local/remoto;
8. confirmar repo limpio.

`autopilot-commit` sigue no fiable en MAIN para cambios en `tools/*.sh`; usar SSH manual controlado si vuelve a pedir approval.

## 7. Riesgos conocidos

- Cleanup remoto implica operación destructiva: `git push origin --delete <branch>`.
- Squash/merge puede hacer que Git no marque una rama como mergeada aunque el contenido esté absorbido.
- `autopilot-commit` puede pedir approval en MAIN para `tools/*.sh`.
- Si hay dudas de rama, PR o estado de main, debe bloquearse.

## 8. Reglas de seguridad vigentes

- No cleanup sin `OK CLEANUP` exacto.
- No `git branch -D`.
- No force.
- No `reset`.
- No `stash`.
- No `merge` manual dentro de cleanup.
- No `rebase`.
- No tocar OpenClaw core, gateway, routing, systemd ni secrets.
- Si falla cualquier check, parar.

## 9. Próximo objetivo recomendado

`FEATURE_POST_MERGE_CLEANUP_ASSISTANT_E2E_TEST_V1`

Objetivo: validar el flujo completo con una rama test documental viva local/remota.

## 10. Instrucciones para el nuevo chat

1. Leer este documento primero.
2. No rediseñar el sistema desde cero.
3. No repetir investigación de approvals.
4. Continuar desde el E2E test.
5. Mantener separación estricta entre diagnóstico y cleanup.
6. Pedir confirmación explícita antes de cualquier borrado.

## 11. Qué NO volver a investigar

- No volver a investigar por defecto `exec-approvals.json`.
- No volver a añadir patrones allowlist a ciegas.
- No volver a discutir si cleanup remoto es sensible: ya está definido como operación destructiva remota.
- No volver a diseñar `github_post_merge_close` desde cero.
- No volver a diseñar `github_post_merge_cleanup_assistant` desde cero.

## 12. Checklist de arranque para continuidad

- Confirmar `main` limpio y actualizado.
- Confirmar que existen las acciones:
  - `github_post_merge_close`;
  - `github_post_merge_cleanup_assistant`.
- Ejecutar diagnóstico sin cleanup:

```bash
tools/neodaemon_local_executor_v1.sh '{"action":"github_post_merge_cleanup_assistant"}'
```

- Si no hay candidatas, preparar rama test documental para E2E.
- No ejecutar cleanup hasta recibir `OK CLEANUP PR #<número> branch <rama>` exacto.
