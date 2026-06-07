# FEATURE_SSH_AND_HASH_CLEANUP_WORKFLOW_V1

## Estado

VALIDADO.

## Problema original

El flujo de cierre post-merge tenía dos fricciones principales:

1. La confirmación manual de cleanup era demasiado larga:

```text
OK CLEANUP PR #<número> branch <rama>
```

2. El borrado remoto podía depender de HTTPS y credenciales interactivas, provocando fallos al ejecutar:

```text
git push origin --delete <branch>
```

## Solución implementada

La solución operativa quedó implementada en PR #77.

Capacidad principal:

```text
OK CLEANUP <short_hash>
```

El hash corto debe venir de una candidata previamente validada por el cleanup assistant.

## Validaciones de seguridad

El flujo mantiene la confirmación larga como fallback y solo acepta la confirmación corta si puede demostrar que:

- el hash resuelve a una única candidata;
- la candidata tiene PR explícito;
- la candidata tiene branch explícita;
- la candidata está `cleanup_ready=true`;
- el PR existe;
- el PR está mergeado;
- la branch coincide con el PR;
- la branch no es `main` ni `master`;
- no hay ambigüedad entre ramas.

Si hay duda, el flujo bloquea.

El cleanup efectivo sigue delegando en `github_post_merge_close`; no se relajaron sus checks.

## Migración GitHub SSH en bunker-ia

Se completó la migración operativa de GitHub en `bunker-ia`:

- origen GitHub de HTTPS a SSH;
- clave SSH dedicada para `bunker-ia`;
- validación con `ssh -T`;
- borrado remoto sin usuario/contraseña interactivos.

Remote objetivo validado:

```text
git@github.com:terrassacode/neodaemon_v1.git
```

## Decisiones operativas

- Usar **Merge commit** por defecto para features operativas.
- No usar **Squash and merge** hasta implementar cleanup squash-aware.
- Preferir:

```text
OK CLEANUP <short_hash>
```

- Mantener como fallback:

```text
OK CLEANUP PR #<número> branch <rama>
```

## Resultado

El flujo queda validado como hito operativo:

- confirmación corta disponible;
- seguridad conservada;
- cleanup sigue protegido por checks;
- GitHub SSH elimina dependencia de credenciales HTTPS interactivas;
- las ramas reales solo se limpian con confirmación explícita.
