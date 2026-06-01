# Human Approval GitHub Executor v0.1

## Estado

Documento de diseño de meta-workflow.

Clasificación según `docs/protected-zones-blacklist-v0-1.md`:

```text
SPECIAL_CONFIRMATION
```

Este documento diseña un executor seguro para asistir el Human Approval GitHub Workflow.

No implementa código.

## Objetivo

Definir un executor local, restringido y de solo lectura para inspeccionar estado Git sin shell libre y sin capacidad de modificar repositorios.

Executor v0.1 queda limitado a:

```text
inspector local read-only
```

No prepara ramas.  
No escribe archivos.  
No valida código.  
No stagea archivos.  
No crea commits.  
No publica en GitHub.

## Documentos normativos

El executor debe obedecer siempre:

- `docs/protected-zones-blacklist-v0-1.md`
- `docs/human-approval-github-workflow-v0-1.md`

Precedencia obligatoria:

```text
BLACKLIST > WORKFLOW > FEATURE > EXECUTOR
```

Si hay conflicto, gana la blacklist.

---

## Principio principal

```text
Albert valida decisiones; Neodaemon valida técnica; el executor limita ejecución.
```

El executor no decide por sí mismo.

El executor solo ejecuta acciones read-only permitidas, parametrizadas y validadas.

---

## Alcance v0.1 — Inspector local read-only

Executor v0.1 es estrictamente local y de solo lectura.

Permitido v0.1 únicamente:

```text
status
current-branch
diff-stat
diff-name-only
file-exists
```

Equivalencias permitidas:

```text
git status --short
git branch --show-current
git diff --stat
git diff --name-only
test -f <archivo_previsto_o_no_sensible>
```

Todo lo que no aparece en esta lista queda prohibido en v0.1.

---

## Prohibido en v0.1

Quedan prohibidas explícitamente las siguientes capacidades:

```text
diff completo
log-oneline
show-file-range
grep
sed
create-branch
write-planned-file
validate-files
stage-explicit-files
commit-feature
git checkout main
git checkout -b
git pull origin main
```

También queda prohibido:

```text
push
PR
gh
auth
tokens
red
APIs externas
curl
wget
shell libre
shell=True
comandos compuestos
pipes arbitrarios
redirecciones arbitrarias
backticks
$()
```

Cualquier intento de ejecutar o añadir estas capacidades al v0.1 debe producir:

```text
FEATURE_BLOCKED
```

---

## LOCAL ONLY

En v0.1, `LOCAL ONLY` significa:

- sin red;
- sin GitHub;
- sin `gh`;
- sin auth;
- sin tokens;
- sin APIs externas;
- sin `curl`;
- sin `wget`;
- sin `git pull`;
- sin `git fetch`;
- sin `git push`.

`main actualizado` no lo verifica ni lo ejecuta el executor v0.1.

`main actualizado` pasa a ser una precondición externa verificada por host/humano antes de usar workflows posteriores.

---

## Fases previstas

### v0.1 — Inspector local read-only

Permitido:

- `status`;
- `current-branch`;
- `diff-stat`;
- `diff-name-only`;
- `file-exists`.

No modifica nada.

### v0.2 — Branch/stage/commit local

Diseño futuro.

Podría estudiar, con aprobación especial separada:

- create branch;
- write planned file;
- validate files;
- stage explicit files;
- commit local.

No forma parte de v0.1.

### v0.3 — GitHub / push / PR

Diseño futuro.

Podría estudiar, con aprobación especial separada:

- push branch;
- create PR.

No forma parte de v0.1 ni v0.2.

---

## Metadata read vs content read

### Metadata read permitido en v0.1

V0.1 solo permite metadata Git o existencia de archivo:

```text
git status --short
git branch --show-current
git diff --stat
git diff --name-only
test -f <archivo_previsto_o_no_sensible>
```

### Content read bloqueado en v0.1

V0.1 no permite leer contenido de archivos.

Prohibido:

```text
git diff
sed
grep
cat
head
tail
show-file-range
```

Motivo: la lectura de contenido puede exponer secretos, prompts, respuestas, logs o datos sensibles.

Si una tarea requiere leer contenido, queda fuera del executor v0.1 y debe pasar por revisión humana o mecanismo futuro separado.

---

## Repo Root Lock

El executor debe operar solo

dentro de repositorios incluidos explícitamente en allowlist.

### Allowed repositories

Repositorios permitidos v0.1:

```text
/openclaw/workspace/git_clean/neodaemon_repo
```

Ningún otro repositorio, worktree o ruta Git queda permitido por defecto.

Si se solicita operar sobre un repositorio no incluido en la allowlist:

```text
FEATURE_BLOCKED
```

Motivo:

```text
repository_not_allowed
```

### Reglas de bloqueo de rutas

Antes de cualquier acción, el executor debe:

1. Resolver `realpath` del repo root.
2. Verificar identidad del repo root mediante comparación estable de path real e inode cuando esté disponible.
3. Resolver `realpath` de cada ruta objetivo.
4. Bloquear cualquier ruta que escape del repo root.
5. Bloquear symlinks que apunten fuera del repo root.
6. Bloquear rutas absolutas fuera del repo permitido.
7. Bloquear `..` si produce escape del repo.
8. Bloquear operaciones si el repo root no coincide exactamente con la allowlist.
9. Fallar cerrado ante duda.

Ante escape o duda:

```text
FEATURE_BLOCKED
```

Motivo:

```text
repo_root_lock_violation
```

---

## Protected Zones / Denylist

El executor debe aplicar `docs/protected-zones-blacklist-v0-1.md` antes de cualquier acción.

La blacklist prevalece siempre.

### BLOCK por defecto

- Core OpenClaw;
- secrets/credentials;
- logs/backups/snapshots/sessions;
- escritura manual en generated data;
- protected project raw zones;
- services/system automation;
- integraciones externas;
- comandos prohibidos.

### SPECIAL_CONFIRMATION mínimo

- Human Approval documents;
- protected-zones documents;
- meta-workflow;
- github executor;
- workflow engine;
- task validator;
- approval policies;
- security policies;
- package locks / dependency surface;
- Docker/runtime environment.

### ALLOWED_ONLY_IF_EXPLICIT

- scripts `.py` / `.sh`;
- generadores autorizados;
- rutas de riesgo medio explícitamente previstas.

Si una ruta coincide con varias reglas, se aplica la más restrictiva.

---

## Output Size Guard

El executor debe evitar generar o mostrar salidas excesivas.

Aunque v0.1 solo expone metadata, todo output debe tener límites.

Límites v0.1:

```text
max_stdout_bytes: 12000
max_stderr_bytes: 4000
max_json_bytes: 16000
max_files_listed: 100
max_command_duration_seconds: 10
```

Reglas:

- si la salida excede límite, truncar y marcar `truncated: true`;
- si `diff-name-only` lista más de `max_files_listed`, bloquear;
- si `diff-stat` excede límite, bloquear;
- no imprimir contenido sensible aunque esté dentro del límite;
- no devolver stdout/stderr crudo sin resumen estructurado.

Bloqueo:

```text
FEATURE_BLOCKED
```

Motivo:

```text
output_size_guard_exceeded
```

---

## Secret Pattern Guard

Si aparece un patrón de secreto en cualquier output, el executor debe bloquear.

Patrones conceptuales:

```text
token
secret
password
credential
api_key
apikey
authorization
bearer
private_key
```

Regla:

```text
secret_pattern_in_output -> FEATURE_BLOCKED
```

El executor no debe intentar “arreglar” o guardar el secreto.

Debe devolver solo metadata mínima del bloqueo, sin imprimir el valor.

---

## No Auto-Discovery

El executor no debe descubrir automáticamente nuevos archivos para modificar, stagear o validar.

En v0.1 no existe modificación, staging ni validación de archivos, pero la regla aplica igualmente:

1. Los archivos consultados con `file-exists` deben venir de `FEATURE_PROPOSAL` o ser rutas no sensibles explícitamente permitidas.
2. El executor no puede convertir archivos detectados por `git status` en permitidos automáticamente.
3. Si aparece un archivo inesperado en metadata Git, debe reportarlo como metadata, no actuar sobre él.
4. Si aparece un archivo generado o sensible en metadata Git, debe bloquear.

Prohibido:

```text
git add .
git add -A
git add *
git add docs/
git add <directorio>
```

Permitido en v0.1:

```text
ningún git add
```

Bloqueo:

```text
FEATURE_BLOCKED
```

Motivo:

```text
unexpected_file_or_auto_discovery
```

---

## Executor Scope Lock

El executor no puede modificar su propio alcance o permisos mediante feature ordinaria.

Requieren `SPECIAL_CONFIRMATION` mínimo:

- diseño del executor;
- implementación del executor;
- allowlists;
- denylists;
- rutas permitidas;
- rutas prohibidas;
- comandos permitidos;
- comandos prohibidos;
- validaciones obligatorias;
- política de logs;
- política de secretos;
- reglas de bloqueo.

Debe bloquear si se intenta introducir sin aprobación especial:

```text
push
PR creation
gh
auth
token handling
network access
GitHub API
force push
auto-merge
systemd/cron/timers
service modification
branch creation
file writing
staging
commit
content read
```

Motivo:

```text
executor_scope_lock_violation
```

---

## Comandos prohibidos siempre

```text
git add .
git add -A
git add *
git add <directorio>
git commit
git commit -am
git checkout main
git checkout -b
git pull
git fetch
git push
git push origin main
git push --force
git push --force-with-lease
git merge
git rebase
git reset --hard
git clean -fd
gh
gh pr merge
sudo
curl
wget
docker
systemctl
crontab
cat
head
tail
sed
grep
```

También prohibido:

- shell libre;
- `shell=True`;
- comandos compuestos;
- pipes arbitrarios;
- redirecciones arbitrarias;
- backticks;
- `$()`;
- ejecución de scripts;
- lectura de rutas sensibles;
- lectura de contenido de archivos.

---

## Salida JSON estructurada obligatoria

Toda respuesta del executor debe ser JSON estructurada.

No se permite devolver stdout/stderr crudo directamente al usuario.

Campos mínimos:

```json
{
  "ok": true,
  "action": "status",
  "repo": "/openclaw/workspace/git_clean/neodaemon_repo",
  "blocked": false,
  "reason": null,
  "stdout_summary": "",
  "stderr_summary": "",
  "truncated": false,
  "metadata": {}
}
```

En bloqueo:

```json
{
  "ok": false,
  "action": "diff-name-only",
  "repo": "/openclaw/workspace/git_clean/neodaemon_repo",
  "blocked": true,
  "reason": "secret_pattern_in_output",
  "stdout_summary": "",
  "stderr_summary": "",
  "truncated": false,
  "metadata": {
    "next": "FEATURE_BLOCKED"
  }
}
```

Reglas:

- `stdout_summary` debe ser resumen, no dump completo;
- `stderr_summary` debe ser resumen, no dump completo;
- `metadata` no debe contener secretos;
- si hay duda, bloquear;
- si la salida supera límites, truncar o bloquear según severidad.

---

## Auditoría sin secretos

El executor puede registrar metadata mínima para auditoría local futura, pero v0.1 no debe escribir logs persistentes salvo diseño separado.

Metadata permitida conceptualmente:

```text
timestamp
action
repo
allowed/blocked
reason
duration_ms
files_count
truncated
```

Prohibido registrar:

```text
tokens
prompts
responses
file contents
full diffs
credentials
stdout crudo
stderr crudo
```

Si una auditoría persistente se diseña en el futuro, requiere aprobación separada.

---

## Diseño técnico esperado futuro

Cuando se implemente en una fase futura, el executor debe:

- usar listas de argumentos, nunca strings shell;
- usar `subprocess.run(..., shell=False)`;
- tener allowlist cerrada de acciones;
- validar repo root antes de cada acción;
- validar rutas antes de cada acción;
- aplicar denylist antes de allowlist;
- aplicar output size guard;
- aplicar secret pattern guard;
- no guardar prompts/respuestas;
- no guardar tokens;
- no devolver stdout/stderr crudo;
- devolver JSON estructurado siempre;
- fallar cerrado.

---

## Flujo v0.1

### 1. Precheck interno

- confirmar repo root en allowlist;
- confirmar acción en allowlist v0.1;
- confirmar que no hay rutas sensibles;
- confirmar que no se requiere red;
- confirmar que no se requiere lectura de contenido;
- confirmar límites de output.

### 2. Ejecución read-only

Ejecutar solo una de:

```text
status
current-branch
diff-stat
diff-name-only
file-exists

```

### 3. Resultado estructurado

Devolver JSON estructurado.

Si hay bloqueo, elevar a:

```text
FEATURE_BLOCKED
```
---

## Acciones fuera de alcance v0.1

Quedan fuera de v0.1:

```text
diff completo
log-oneline
show-file-range
grep
sed
create-branch
write-planned-file
validate-files
stage-explicit-files
commit-feature
git checkout main
git checkout -b
git pull origin main
push-branch
create-pr
```

Estas acciones no pertenecen al executor v0.1.

Fases futuras requerirán nuevo diseño y aprobación especial.

---

## Manejo de tokens

Executor v0.1 no maneja tokens.

Prohibido:

- leer tokens;
- imprimir tokens;
- guardar tokens;
- aceptar token como argumento;
- aceptar token por env;
- escribir token en remoto Git;
- usar `gh auth`;
- usar GitHub API;
- usar red.

Si aparece una necesidad de autenticación:

```text
FEATURE_BLOCKED
```

Motivo:

```text
auth_not_allowed_in_v0_1
```

---

## Riesgos

1. Convertir el wrapper en shell indirecta.
2. Permitir rutas amplias que evadan la blacklist.
3. Imprimir metadata que contenga patrones de secreto.
4. Convertir `diff-name-only` en auto-discovery.
5. Ampliar capacidades locales antes de tiempo.
6. Modificar el propio workflow sin confirmación especial.

Mitigaciones:

- inspector read-only;
- allowlist de 5 acciones;
- repo root lock;
- output size guard;
- secret pattern guard;
- no auto-discovery;
- executor scope lock;
- blacklist primero;
- JSON estructurado;
- fail closed.

---

## Criterios mínimos antes de implementar PR futuro

Antes de crear cualquier código executor debe existir:

1. PR de blacklist merged.
2. PR de este diseño hardened merged.
3. Confirmación especial para código ejecutable.
4. Tests diseñados para:
   - repo allowlist;
   - path escape;
   - symlink escape;
   - output limits;
   - secret pattern guard;
   - no content read;
   - no network;
   - no shell=True;
   - no commands outside allowlist.
5. SELF_CHECK_PYTHON obligatorio si el futuro executor se implementa en Python.

---

## Estado final v0.1

Este documento solo diseña el executor.

No autoriza:

- implementación;
- escritura de archivos;
- validación de código;
- branch creation;
- staging;
- commit;
- push;
- PR;
- GitHub auth;
- red;
- APIs externas;
- tokens;
- servicios;
- automatización persistente.

Executor v0.1 queda limitado a:

```text
status
current-branch
diff-stat
diff-name-only
file-exists
```
