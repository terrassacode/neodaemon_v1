# FEATURE_POST_MERGE_CLEANUP_CHECK_DESIGN_V1

## Objetivo

Diseñar un chequeo read-only para saber si una rama puede limpiarse manualmente después de mergear un PR.

El chequeo no borra ramas. Solo informa a Albert si la rama local y la rama remota parecen seguras para limpiar.

## Alcance V1

V1 es minimalista y local-first.

No usa GitHub API. Si el nombre esperado de la rama del PR está disponible por contexto externo, se compara con el nombre recibido. Si no está disponible, esa comprobación queda como no aplicable.

## Checks mínimos

1. Working tree limpio.
2. Estamos en `main`.
3. Rama local existe.
4. Rama local aparece como mergeada en `main`.
5. Rama remota existe.
6. Nombre de rama recibido coincide con la rama esperada del PR, si ese dato está disponible.

## Salida esperada para Albert

```text
safe_delete_local: sí/no
safe_delete_remote: sí/no
failed_check: <check/null>
recommended_next_action: <texto breve>
```

Reglas de interpretación:

- `safe_delete_local: sí` solo si working tree está limpio, estamos en `main`, la rama local existe y aparece mergeada en `main`.
- `safe_delete_remote: sí` solo si la rama remota existe y el nombre de rama recibido coincide con la rama esperada del PR cuando ese dato está disponible.
- Si falla cualquier check obligatorio, `failed_check` debe indicar el primer check fallido.
- La acción recomendada nunca debe ejecutar limpieza automática.

## Comandos permitidos read-only

```bash
git status --short
git branch --show-current
git branch --list <branch>
git branch --merged main --list <branch>
git branch -r --list origin/<branch>
```

Todos los comandos deben ser de inspección. No se permite ningún comando que modifique estado.

## Condiciones de fallo

- Working tree no está limpio.
- La rama actual no es `main`.
- La rama local no existe.
- La rama local no aparece mergeada en `main`.
- La rama remota no existe.
- El nombre de rama recibido no coincide con la rama esperada del PR, si ese dato está disponible.
- Cualquier necesidad de GitHub API en V1.
- Cualquier necesidad de comando destructivo o de modificación de estado.

## Qué NO hace

- No borra ramas locales.
- No borra ramas remotas.
- No ejecuta `push`.
- No ejecuta `reset`.
- No ejecuta `stash`.
- No ejecuta `merge`.
- No ejecuta `rebase`.
- No ejecuta operaciones `force`.
- No usa GitHub API.
- No toca OpenClaw core, gateway, routing, systemd ni secrets.
