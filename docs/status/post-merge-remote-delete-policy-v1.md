# FEATURE_POST_MERGE_REMOTE_DELETE_POLICY_V1

## Objetivo

Definir la política explícita para borrado remoto de ramas en una futura acción de cierre post-merge.

`git push origin --delete <branch>` es una operación destructiva remota.

Esta feature no implementa código ni ejecuta borrado.

## Política

Una futura acción post-merge solo podrá borrar una rama remota bajo condiciones estrictas.

Condiciones obligatorias:

- PR confirmado como mergeado.
- Rama concreta indicada.
- La rama coincide con el PR.
- Repo limpio.
- `main` actualizado.
- Ausencia de duda por squash/merge.
- Aprobación explícita de Albert con formato exacto:

```text
OK CLEANUP PR #<número> branch <rama>
```

## Prohibiciones

- Prohibido `git branch -D`.
- Prohibido force.
- Prohibido `reset`.
- Prohibido `stash`.
- Prohibido `merge`.
- Prohibido `rebase`.
- Prohibido borrar ramas sin aprobación explícita.

## Regla de bloqueo

Si falla cualquier check, resultado obligatorio:

```text
FEATURE_BLOCKED
```

No debe intentarse cleanup parcial.

## Qué NO hace esta feature

- No implementa código.
- No ejecuta comandos.
- No borra ramas.
- No ejecuta `push`.
- No cambia allowlist.
- No toca approvals.
- No automatiza cleanup.
- No toca OpenClaw core, gateway, routing, systemd ni secrets.
