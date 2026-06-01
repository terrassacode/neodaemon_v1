# Protected Zones Blacklist v0.1

## Estado

Documento de gobernanza operativa para Neodaemon v2.

Define zonas protegidas que Neodaemon no debe tocar mediante features ordinarias. Esta blacklist se aplica antes que cualquier workflow, proposal, executor o automatización futura.

## Objetivo

Evitar que errores, automatizaciones o features normales modifiquen zonas críticas del sistema OpenClaw, datos sensibles, políticas de seguridad o reglas de autorización.

## Precedencia obligatoria

```text
BLACKLIST > WORKFLOW > FEATURE
```

Esto significa:

1. La blacklist prevalece sobre cualquier `FEATURE_PROPOSAL`.
2. La blacklist prevalece sobre permisos generales del workspace.
3. La blacklist prevalece sobre futuros executors o automatizaciones.
4. Si hay conflicto, se bloquea o se exige confirmación especial según esta blacklist.
5. Ningún workflow puede relajar esta blacklist por sí mismo.

## Clasificaciones

### BLOCK

Prohibido por defecto.

Neodaemon debe detener la acción y devolver `FEATURE_BLOCKED`.

No se permite continuar dentro de un feature normal.

### SPECIAL_CONFIRMATION

Requiere confirmación especial explícita fuera del flujo ordinario.

No basta con `OK FEATURE`.
No basta con `OK GITHUB`.

Debe incluir:

- motivo;
- riesgo;
- alcance;
- rollback;
- validación posterior;
- confirmación humana explícita.

### ALLOWED_ONLY_IF_EXPLICIT

Permitido solo si aparece explícitamente en `FEATURE_PROPOSAL`.

Si aparece sin estar previsto, se bloquea.

---

## 1. Core OpenClaw — BLOCK

Estas zonas quedan bloqueadas por defecto.

Motivo: un error aquí puede dejar OpenClaw inutilizable, degradado o inseguro.

### Rutas / componentes

```text
~/.openclaw/openclaw.json
gateway
routing
model providers
sandbox global
```

### Regla

Cualquier intento de modificar estas zonas mediante feature normal debe producir:

```text
FEATURE_BLOCKED
```

No se permite degradar esta regla dentro de un workflow ordinario.

---

## 2. Secrets / Credentials — BLOCK

Motivo: riesgo crítico de filtración o persistencia accidental.

### Rutas / patrones

```text
.env
*.env
**/.env
**/*token*
**/*secret*
**/*password*
**/*credential*
**/*apikey*
**/*api_key*
**/*auth*
```

### Regla

Bloquear:

- lectura innecesaria;
- escritura;
- diff;
- grep/sed/test;
- staging;
- commit;
- logging;
- impresión en prompt.

Neodaemon no debe imprimir, guardar ni transformar secretos.

---

## 3. Logs / Backups / Snapshots / Sessions — BLOCK

Motivo: pueden contener contexto sensible, prompts, respuestas, tokens o datos históricos.

### Rutas / patrones

```text
logs/**
backups/**
snapshots/**
sessions/**
**/sessions/**
*.log
*.jsonl
*.jsonl.*
```

### Regla

Bloqueado por defecto para features normales.

Excepción limitada solo para auditoría explícita:

- metadata no sensible;
- conteos;
- tamaños;
- fechas;
- clasificación;
- sin leer contenido sensible.

---

## 4. Generated Data — BLOCK manual write / ALLOWED_ONLY_IF_EXPLICIT generators

Motivo: los artefactos generados no deben editarse ni versionarse manualmente.

### Rutas

```text
dashboard-v2/data/**
outputs/**
```

### Clasificación

```text
BLOCK para escritura manual directa
ALLOWED_ONLY_IF_EXPLICIT para generadores autorizados
```

### Regla

- Edición manual directa: `BLOCK`.
- Staging/commit de outputs generados: `BLOCK`, salvo excepción documentada.
- Escritura por generador: solo si el generador está explícitamente autorizado en el `FEATURE_PROPOSAL`.
- El generador autorizado debe declarar ruta de output, campos escritos y política de no secretos.

Ejemplo:

```text
scripts/generate_token_dashboard_v0_1.py -> dashboard-v2/data/token_dashboard_v0_1.json
```

solo sería admisible si aparece explícitamente autorizado para ese feature.

---

## 5. Protected Projects

Algunos proyectos tienen reglas internas propias que prevalecen sobre el workflow general.

### OpenClaw Knowledge Wiki raw

```text
projects/openclaw-knowledge-wiki/raw/**
```

Clasificación:

```text
BLOCK
```

Motivo: `raw/` es fuente inmutable y no debe modificarse mediante features normales.

### Otros proyectos protegidos futuros

```text
projects/<protected-project>/**
```

Clasificación futura:

```text
BLOCK | SPECIAL_CONFIRMATION
```

según clasificación explícita.

### Regla

Si un proyecto se declara protegido, sus reglas locales prevalecen sobre el workflow general.

---

## 6. Protected Repositories

Repositorios o worktrees marcados como protegidos no deben modificarse mediante features ordinarias.

### Clasificación

```text
BLOCK | SPECIAL_CONFIRMATION
```

según clasificación explícita del repositorio.

### Regla

Ningún executor, workflow o feature puede modificar un repositorio protegido salvo que exista autorización específica para ese repositorio y esa operación.

Si la clasificación no está clara:

```text
FEATURE_BLOCKED
```

### Motivo

Un repositorio protegido puede contener código, configuración, credenciales, historial sensible o reglas propias de gobierno.

---

## 7. Human Approval Documents — SPECIAL_CONFIRMATION

Motivo: modificar estas reglas equivale a modificar el gobierno operativo de Neodaemon.

### Rutas

```text
docs/human-approval-*
docs/protected-zones-*
```

Clasificación:

```text
SPECIAL_CONFIRMATION
```

### Regla

No basta con `OK FEATURE`.

Debe indicarse explícitamente:

- qué regla cambia;
- si endurece o relaja restricciones;
- riesgo de gobernanza;
- rollback;
- validación posterior.

---

## 8. Meta-Workflow / Self-Governance — SPECIAL_CONFIRMATION mínimo

Motivo: Neodaemon no debe poder debilitar sus propias restricciones mediante una feature ordinaria.

### Categorías

```text
github executor
workflow engine
task validator
approval policies
security policies
```

### Clasificación base

```text
SPECIAL_CONFIRMATION
```

### Evaluación recomendada

| categoría | clasificación mínima | escalar a BLOCK si... |
|---|---|---|
| github executor | SPECIAL_CONFIRMATION | amplía permisos, añade push/PR/auth o reduce bloqueos |
| workflow engine | SPECIAL_CONFIRMATION | altera autorizaciones o permite bypass |
| task validator | SPECIAL_CONFIRMATION | reduce scoring, elimina checks o rebaja riesgo |
| approval policies | SPECIAL_CONFIRMATION | reduce intervención humana o relaja confirmaciones |
| security policies | SPECIAL_CONFIRMATION | reduce protección de secretos, rutas o comandos |

### Regla

Si el cambio reduce restricciones, elimina bloqueos o amplía permisos sensibles:

```text
BLOCK
```

salvo confirmación especial explícita fuera del flujo ordinario.

---

## 9. Rule Relaxation Protection

Motivo: una feature ordinaria no debe poder debilitar las reglas que la controlan.

### Regla

Cualquier cambio que haga una de estas acciones debe escalar:

- convertir `BLOCK` en `SPECIAL_CONFIRMATION`;
- convertir `SPECIAL_CONFIRMATION` en permitido ordinario;
- ampliar rutas permitidas;
- añadir comandos permitidos;
- eliminar validaciones;
- eliminar checks de secretos;
- permitir push/PR/auth donde antes no existía;
- permitir modificación de servicios o configuración crítica;
- reducir intervención humana en acciones sensibles.

Clasificación:

```text
SPECIAL_CONFIRMATION mínimo
BLOCK si afecta Core OpenClaw, secretos, executor scope, servicios o bypass de aprobación
```

### Regla de seguridad

Si no está claro si un cambio endurece o relaja reglas:

```text
FEATURE_BLOCKED
```

---

## 10. Executor Scope Lock

Motivo: ningún executor debe ampliar su propio alcance o permisos mediante una feature ordinaria.

### Regla

Cambios a cualquiera de estos elementos requieren `SPECIAL_CONFIRMATION` mínimo:

- allowlist de comandos;
- denylist de comandos;
- rutas permitidas;
- rutas prohibidas;
- validaciones obligatorias;
- manejo de secretos;
- acciones Git permitidas;
- acciones GitHub permitidas;
- política de autenticación;
- política de logs;
- reglas de bloqueo.

### BLOCK obligatorio si el cambio introduce

```text
push
PR creation
gh
token handling
GitHub auth
force push
auto-merge
service modification
systemd/cron/timers
```

sin una aprobación especial previa.

### Regla v0.1 esperada

El executor v0.1, si se implementa en el futuro, debe ser `LOCAL ONLY` por defecto:

- status;
- diff;
- create branch;
- validate;
- stage explicit files;
- commit.

Sin:

- push;
- PR;
- `gh`;
- token;
- GitHub auth.

---

## 11. Services / System Automation — BLOCK

Motivo: impacto operativo persistente.

### Rutas / componentes

```text
systemd/**
**/*.service
**/*.timer
cron/**
crontab
services/**
```

### Regla

Bloqueado por defecto.

No se permite modificar servicios, timers, cron ni automatización persistente en features normales.

---

## 12. Docker / Runtime Environment — SPECIAL_CONFIRMATION or BLOCK

Motivo: puede cambiar aislamiento, runtime o superficie de ejecución.

### Rutas

```text
Dockerfile
docker-compose.yml
docker-compose.*.yml
.dockerignore
```

Clasificación:

```text
SPECIAL_CONFIRMATION
```

Si afecta sandbox, red, volúmenes sensibles o permisos elevados:

```text
BLOCK
```

---

## 13. Package Locks / Dependency Surface — SPECIAL_CONFIRMATION

Motivo: cambios de dependencias pueden introducir supply-chain risk.

### Rutas

```text
package-lock.json
pnpm-lock.yaml
yarn.lock
requirements.txt
pyproject.toml
poetry.lock
```

Clasificación:

```text
SPECIAL_CONFIRMATION
```

---

## 14. Scripts / Executable Code — ALLOWED_ONLY_IF_EXPLICIT

Motivo: scripts pueden ejecutar acciones reales.

### Rutas

```text
scripts/*.py
scripts/*.sh
**/*.py
**/*.sh
```

Clasificación:

```text
ALLOWED_ONLY_IF_EXPLICIT
```

Riesgo mínimo:

```text
MEDIO
```

### Regla

- No son rutas permitidas por defecto.
- Solo permitidos si aparecen explícitamente en `FEATURE_PROPOSAL`.
- Requieren validación por tipo.
- Si tocan zonas protegidas, prevalece la blacklist.
- Si amplían permisos o automatización, escalan a `SPECIAL_CONFIRMATION` o `BLOCK`.

---

## 15. Read-only shell safety

Las lecturas shell seguras no requieren aprobación y no cuentan como interacción humana, pero solo si se aplican sobre archivos previstos o rutas no sensibles.

### Permitidos con restricciones

```text
git status --short
git branch --show-current
git log --oneline
git diff --stat
git diff --name-only
git diff
grep
sed
test
```

### Prohibido aplicar grep/sed/test sobre

```text
.env
logs/**
backups/**
snapshots/**
sessions/**
**/sessions/**
**/*token*
**/*secret*
**/*password*
**/*credential*
**/*auth*
```

Si hay duda:

```text
FEATURE_BLOCKED
```

---

## 16. Commands always forbidden

```text
git add .
git add -A
git commit -am
git push origin main
git push --force
git push --force-with-lease
git merge
git rebase
git reset --hard
git clean -fd
gh pr merge
sudo
curl | sh
wget | sh
docker
systemctl
crontab
```

`git branch -D` solo puede considerarse con confirmación especial post-merge/squash y tras verificar:

- PR merged confirmado;
- main actualizado;
- cambio existe en main;
- working tree limpio.

---

## 17. External integrations — BLOCK by default

Motivo: pueden exponer datos o modificar sistemas externos.

### Bloqueado por defecto

```text
GitHub API write
gh auth
gmail send
telegram send
webhooks
external HTTP writes
cloud APIs
package publish
deployment
```

Lecturas externas también requieren evaluación específica si pueden filtrar contexto o credenciales.

---

## 18. Secret handling policy

Neodaemon debe:

- no imprimir tokens;
- no guardar tokens;
- no escribir credenciales en repo;
- no escribir credenciales en logs;
- no incluir secretos en prompts;
- no incluir secretos en commits;
- no incluir secretos en PR descriptions;
- no usar tokens hardcodeados;
- no modificar remotes para incluir tokens.

Si aparece un posible secreto:

```text
FEATURE_BLOCKED
```

---

## 19. Required blocked response

Cuando la blacklist bloquee una acción, responder:

```text
FEATURE_BLOCKED

Objetivo:
<objetivo>

Fase:
<fase>

Motivo del bloqueo:
<explicación breve>

Regla activada:
<BLACKLIST rule>

Evidencia:
- <ruta/comando/categoría>

Qué he detenido:
<acción>

Siguiente paso seguro:
<alternativa>
```

---

## 20. Implementation plan

### PR #1

```text
docs/protected-zones-blacklist-v0-1.md
```

Solo documentación.

### PR #2

```text
docs/human-approval-github-executor-v0-1.md
```

No avanzar hasta que PR #1 esté merged.

Debe depender conceptualmente de esta blacklist.

### PR #3

```text
scripts/github_workflow_executor.py
```

No avanzar hasta que PR #1 y PR #2 estén merged.

Debe requerir `SPECIAL_CONFIRMATION`, porque implementa código ejecutable que opera Git.

Wrapper v0.1 debe ser `LOCAL ONLY`:

- status;
- diff;
- create branch;
- validate;
- stage explicit files;
- commit.

Sin:

- push;
- PR;
- `gh`;
- token;
- GitHub auth.
