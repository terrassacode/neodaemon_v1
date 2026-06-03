# GITHUB_TOKEN_SETUP_SAFE_V1

## Estado

Diseño documental.

Este documento define cómo configurar de forma segura un usuario/token de GitHub en el host para un futuro `GITHUB_CONTROLLED_PR_ASSISTANT_V1`.

No contiene tokens reales, credenciales, secretos ni valores privados.

## Objetivo

Reducir la dependencia manual de Albert en tareas GitHub controladas, sin exponer secretos y sin permitir acciones remotas sin autorización explícita.

El objetivo futuro es permitir que un asistente controlado pueda preparar cambios documentales simples, crear ramas, hacer commits y abrir PRs, siempre bajo reglas estrictas.

## Alcance

Esta fase es solo documentación.

No se crea token.

No se pide token.

No se imprime token.

No se usa GitHub remoto.

No se hace push.

No se abre PR real.

No se crea executor.

## Ubicación segura del token

Ubicación recomendada en el host:

```text
~/.openclaw/neodaemon/secrets/github.env
```

Directorio recomendado:

```text
~/.openclaw/neodaemon/secrets
```

Permisos recomendados:

```bash
chmod 700 ~/.openclaw/neodaemon/secrets
chmod 600 ~/.openclaw/neodaemon/secrets/github.env
```

Contenido esperado del archivo, sin valores reales:

```bash
GITHUB_USER=REDACTED_USER
GITHUB_TOKEN=REDACTED_DO_NOT_COMMIT
```

## Regla de oro

Nunca hacer esto:

```text
- pegar el token en ChatGPT;
- pegar el token en NeoDaemon;
- imprimir el token por pantalla;
- guardar el token dentro del repo;
- incluir el token en logs;
- incluir el token en snapshots;
- incluir el token en documentación Markdown;
- pasar el token como argumento visible en comandos;
- usar set -x cerca de secretos.
```

## Permisos mínimos recomendados

Usar preferentemente un token fine-grained.

Debe estar limitado al repositorio concreto:

```text
terrassacode/neodaemon_v1
```

Permisos mínimos para un futuro asistente de PR documental:

```text
Metadata: Read
Contents: Read and Write
Pull requests: Read and Write
```

No conceder:

```text
Admin
Secrets
Workflows
Packages
Organization write
Delete repository
Actions write
```

Cualquier permiso adicional requiere una decisión separada.

## Variables de entorno

El token no debe estar en comandos pegados en el chat.

En una fase futura, el asistente podrá cargarlo desde:

```bash
set -a
source ~/.openclaw/neodaemon/secrets/github.env
set +a
```

Condiciones:

```text
- no usar set -x;
- no imprimir env;
- no imprimir printenv;
- no imprimir el contenido del archivo;
- no guardar la salida en logs;
- no exponer headers HTTP.
```

## Prueba de autenticación sin mutaciones

Una futura prueba permitida, solo con autorización explícita, podría consultar el usuario autenticado sin modificar nada.

Ejemplo documental:

```bash
GITHUB_TOKEN="$(grep '^GITHUB_TOKEN=' ~/.openclaw/neodaemon/secrets/github.env | cut -d= -f2-)"
curl -sS \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/user
```

Advertencias:

```text
- no usar curl -v;
- no imprimir headers;
- no guardar salida si contiene datos sensibles;
- no hacer mutaciones;
- no ejecutar push;
- no abrir PR;
- no modificar ramas.
```

## Comandos prohibidos

Prohibidos siempre salvo diseño posterior explícito:

```bash
echo "$GITHUB_TOKEN"
env
printenv
set -x
gh auth token
git push --force
git push --mirror
git credential approve
```

Prohibidos sin `OK GITHUB`:

```bash
git push
gh pr create
curl -X POST
curl -X PATCH
curl -X PUT
curl -X DELETE
```

## Relación con OK FEATURE y OK GITHUB

### OK FEATURE

Autoriza solo trabajo local.

Puede autorizar:

```text
- crear rama local;
- crear o modificar un archivo Markdown aprobado;
- revisar diff;
- hacer commit local;
- preparar FEATURE_READY_FOR_GITHUB.
```

No autoriza:

```text
- usar token;
- hacer push;
- abrir PR;
- hacer merge;
- borrar ramas remotas;
- tocar GitHub remoto.
```

### OK GITHUB

Autoriza una acción remota concreta.

Puede autorizar:

```text
- push de una rama aprobada;
- apertura de un PR aprobado contra main.
```

No autoriza:

```text
- merge;
- force push;
- borrar ramas;
- tocar otros repositorios;
- modificar archivos no aprobados;
- reutilizar token para otra operación.
```

## Flujo futuro recomendado

Futuro flujo para `GITHUB_CONTROLLED_PR_ASSISTANT_V1`:

```text
1. FEATURE_PROPOSAL.
2. Albert responde OK FEATURE.
3. Trabajo local controlado.
4. Diff explícito.
5. Commit local.
6. FEATURE_READY_FOR_GITHUB.
7. Albert responde OK GITHUB.
8. Se carga token desde archivo protegido.
9. Push de rama aprobada.
10. Apertura de PR aprobado.
11. No merge.
12. No borrado de rama sin autorización separada.
```

## Prevención de fugas

El asistente debe bloquear:

```text
- impresión de variables de entorno;
- impresión de headers HTTP;
- logs con token;
- comandos con token como argumento;
- set -x;
- inclusión del archivo github.env en Git;
- copias del token en Markdown;
- snapshots que incluyan secretos.
```

## .gitignore recomendado

El repo debe ignorar cualquier archivo de secretos local.

Ejemplo documental:

```gitignore
.openclaw/
*.env
.env
secrets/
```

Nota: no añadir rutas reales de secretos al repo si no es necesario. La ubicación recomendada está fuera del repo.

## Rollback

Si hay sospecha de exposición:

```text
1. Revocar el token en GitHub.
2. Crear un token nuevo con permisos mínimos.
3. Revisar logs locales.
4. Revisar historial Git.
5. Confirmar que el token no fue pegado en chat.
```

Eliminar archivo local:

```bash
shred -u ~/.openclaw/neodaemon/secrets/github.env
```

Si `shred` no está disponible:

```bash
rm ~/.openclaw/neodaemon/secrets/github.env
```

Después:

```bash
chmod 700 ~/.openclaw/neodaemon/secrets
```

## Riesgo

Riesgo: MEDIO.

Motivo:

```text
Aunque esta fase es solo documentación, trata una futura capacidad remota sobre GitHub.
Un token mal protegido puede permitir cambios no deseados en el repositorio.
```

Mitigaciones:

```text
- no incluir token real;
- no pedir token en chat;
- no imprimir token;
- no usar remoto en esta fase;
- usar permisos mínimos;
- limitar a repo concreto;
- separar OK FEATURE de OK GITHUB;
- no permitir merge automático;
- no permitir force push;
- no permitir borrado de ramas automático.
```

## Qué NO toca esta fase

Esta fase no toca:

```text
- token real;
- GitHub remoto;
- push;
- PR real;
- merge;
- executor;
- OAuth;
- Gmail;
- systemd;
- gateway;
- routing;
- core;
- servicios;
- configuración sensible.
```

## Estado esperado

Después de esta documentación:

```text
- existe una guía segura para guardar token en host;
- no existe token en el repo;
- no existe token en logs;
- no se ha usado GitHub remoto;
- no se ha hecho push;
- no se ha abierto PR;
- no se ha creado executor.
```
