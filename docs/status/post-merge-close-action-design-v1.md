# FEATURE_POST_MERGE_CLOSE_ACTION_DESIGN_V1

## Objetivo

Diseñar una acción futura de cierre post-merge para reducir el trabajo manual después de mergear un PR.

Esta V1 no implementa ni ejecuta nada. Solo define el diseño y las barreras de seguridad.

## Fases obligatorias

### 1. Check read-only

La acción futura debe empezar con una fase de inspección sin modificar estado.

Debe comprobar como mínimo:

- repo en `main`;
- `git status` limpio;
- PR confirmado como mergeado;
- rama local identificada;
- rama remota identificada;
- ausencia de dudas por squash/merge.

Si cualquier check falla, parar.

### 2. Aprobación explícita de Albert

No se debe borrar nada sin aprobación explícita:

```text
OK CLEANUP
```

La aprobación debe referirse a una rama concreta y a un PR concreto.

### 3. Cleanup controlado

Solo después de `OK CLEANUP`, la acción futura podría limpiar ramas de forma controlada.

Debe seguir estas reglas:

- no usar `git branch -D`;
- no usar force;
- no borrar si `git status` no está limpio;
- no borrar si el PR no está confirmado como mergeado;
- no borrar si hay duda por squash/merge;
- no continuar si la rama esperada no coincide con la rama del PR.

## Paradas obligatorias

Parar y pedir revisión si:

- `git status` no está limpio;
- el PR no está confirmado como mergeado;
- hay duda por squash/merge;
- aparece warning de rama no mergeada;
- la rama local o remota no coincide con la esperada;
- falta `OK CLEANUP` explícito.

## Riesgo

Riesgo: MEDIO.

Motivo: una fase futura podría borrar ramas locales o remotas. Aunque el borrado sea posterior y controlado, el diseño debe tratarlo como operación sensible.

Mitigación: separar check, aprobación y cleanup; prohibir `-D` y force; parar ante cualquier duda.

## Qué NO hace esta V1

- No implementa código.
- No ejecuta comandos.
- No borra ramas.
- No automatiza cleanup.
- No cambia allowlist.
- No toca approvals.
- No toca OpenClaw core, gateway, routing, systemd ni secrets.
