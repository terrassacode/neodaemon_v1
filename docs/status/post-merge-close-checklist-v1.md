# FEATURE_POST_MERGE_CLOSE_CHECKLIST_V1

Usar solo después de confirmar que el PR está mergeado.

## CHECK primero

```bash
git switch main
git pull --ff-only origin main
git status --short
```

Resultado esperado:

```text
branch: main
pull: fast-forward o already up to date
status: sin salida
```

Si `git status --short` muestra algo, parar y pedir revisión.

## BORRADO después

Sustituir `<branch>` por la rama del PR mergeado.

Borrar rama local:

```bash
git branch -d <branch>
```

Borrar rama remota:

```bash
git push origin --delete <branch>
```

Confirmar estado final:

```bash
git status --short
git branch --show-current
git branch --list <branch>
git branch -r --list origin/<branch>
```

Resultado esperado:

```text
status: sin salida
current branch: main
local branch: sin salida
remote branch: sin salida
```

## Warning: not yet merged to HEAD

Significa que Git no ve la rama como mergeada en el `HEAD` actual.

Puede pasar si no estás en `main`, si `main` no está actualizado o tras squash/merge.

Si aparece este warning, no usar `-D`. Parar y pedir revisión.

## Si la rama remota no existe

Si `git push origin --delete <branch>` dice que la rama remota no existe, comprobar con:

```bash
git branch -r --list origin/<branch>
```

Si no devuelve nada, tratarlo como ya limpia en remoto.

## Cuándo parar y pedir revisión

- PR no confirmado como mergeado.
- `git status --short` no está limpio.
- `git pull --ff-only` falla.
- Aparece `not yet merged to HEAD`.
- La rama esperada no coincide con la rama del PR.
- Hay dudas por squash/merge.

## Qué NO hacer

- No usar `git branch -D`.
- No usar `git push --force`.
- No usar `reset`, `stash`, `merge` ni `rebase`.
- No borrar ramas sin confirmar PR mergeado.
