# EXECUTOR_BRIDGE_V1_DESIGN

## Estado

Diseño documental.

- No implementa wrapper.
- No activa exec approvals.
- No cambia configuración OpenClaw.
- No toca systemd, Gmail, OAuth, gateway, routing, core ni tokens.

---

## Objetivo

Diseñar un puente seguro entre NeoDaemon MAIN y el executor local usando OpenClaw exec approvals.

Decisión conceptual:

```text
exec approvals no sustituye al executor

exec approvals es el puente controlado

tools/neodaemon_local_executor_v1.sh
es el filtro allowlist interno
```

## Problema actual

NeoDaemon MAIN puede diseñar, revisar y proponer, pero no puede invocar directamente:

```text
/openclaw/workspace/git_clean/neodaemon_v1/tools/neodaemon_local_executor_v1.sh
```

Motivo:

```text
MAIN no tiene shell/exec operativo sobre neodaemon_v1

neodaemon_v1 está fuera de su sandbox operativo actual

no existe puente
tool -> executor -> Git/Shell
```

El executor local ya existe y funciona cuando lo invoca el host.

El problema es el puente.

## Arquitectura propuesta

```text
Albert
  ↓ aprobación
NeoDaemon MAIN
  ↓ request estructurado
OpenClaw exec approval
  ↓ comando fijo aprobado
bridge/wrapper fijo
  ↓
tools/neodaemon_local_executor_v1.sh
  ↓
allowlist interna
scripts GitHub permitidos
  ↓
resultado estructurado
NeoDaemon MAIN
  ↓
síntesis
Albert
```

Ruta fija del repositorio:

```text
/openclaw/workspace/git_clean/neodaemon_v1
```

## Principio de seguridad

MAIN coordina.

El executor ejecuta.

Albert aprueba lo sensible.

```text
Albert decide

NeoDaemon propone

Executor ejecuta acciones limitadas
```

## Por qué no usar exec genérico

`exec` genérico queda bloqueado porque:

```text
- abre shell real;
- permite comandos arbitrarios;
- puede tocar fuera del repo;
- puede imprimir secretos;
- puede modificar configuración crítica;
- rompe el principio de mínimo privilegio;
- dificulta auditoría.
```

Exec approvals debe aprobar solo un comando o wrapper fijo.

No debe aprobar shell libre.

## Por qué no dar shell libre a MAIN

NeoDaemon MAIN no debe ser operador shell general.

Motivos:

```text
- MAIN gestiona contexto y decisiones;
- MAIN no debe ejecutar comandos arbitrarios;
- MAIN no debe tocar sistema operativo;
- MAIN no debe tener acceso amplio al host;
- MAIN no debe saltarse el executor local.
```

Regla:

```text
MAIN
-> request estructurado
-> exec approval
-> puente controlado
-> executor local
-> allowlist
```

## Wrapper recomendado

Crear en fase futura:

```text
/openclaw/workspace/git_clean/neodaemon_v1/tools/neodaemon_executor_bridge.sh
```

Función:

```text
- aceptar JSON request;
- validar formato básico;
- cambiar a repo fijo;
- invocar solo tools/neodaemon_local_executor_v1.sh;
- devolver resultado estructurado;
- bloquear cualquier comando libre.
```

Ejemplo conceptual:

```bash
tools/neodaemon_executor_bridge.sh '{"action":"github_status"}'
```

El wrapper no debe aceptar comandos arbitrarios.

## Executor local

El executor local seguirá siendo:

```text
tools/neodaemon_local_executor_v1.sh
```

Responsabilidad:

```text
- validar acciones permitidas;
- bloquear acciones desconocidas;
- invocar solo scripts permitidos;
- devolver resultados estructurados;
- no imprimir tokens;
- no permitir shell libre.
```

## Acciones permitidas iniciales

Delegadas al executor local:

```text
github_status
github_publish_token
github_create_pr
```

### github_status

Acción read-only.

Debe devolver:

```text
branch actual
working tree
estado seguro
```

No debe modificar el repo.

### github_publish_token

Publica rama usando token host mediante script ya existente.

Requiere:

```text
OK_GITHUB=1
```

No autoriza:

```text
merge
borrado de ramas
force push
```

### github_create_pr

Crea PR contra main usando API.

Requiere:

```text
OK_GITHUB=1
```

No autoriza:

```text
merge
borrado de ramas
force push
```

## Acciones prohibidas

Queda prohibido:

```text
- shell libre;
- comandos arbitrarios;
- eval;
- bash -c;
- sh -c;
- set -x;
- gh;
- gh auth token;
- imprimir tokens;
- imprimir headers Authorization;
- leer o mostrar .env;
- systemd;
- Gmail;
- OAuth;
- gateway;
- routing;
- core;
- merge;
- borrado de ramas;
- force push;
- git config global;
- edición fuera de scripts permitidos;
- acceso a logs o snapshots sensibles sin aprobación separada.
```

## Política de aprobación humana

Antes de activar cualquier configuración OpenClaw:

```text
CONFIRMACIÓN_ESPECIAL obligatoria
```

Acciones read-only:

```text
pueden requerir aprobación inicialmente para calibrar seguridad
```

Acciones remotas:

```text
siempre requieren OK_GITHUB=1
```

No existe autorización permanente para operaciones remotas.

## Bloqueo por defecto

Cualquier caso no reconocido debe devolver:

```text
BLOCKED
```

Casos bloqueados:

```text
- action desconocida;
- JSON inválido;
- repo distinto;
- ruta distinta;
- ausencia de OK_GITHUB=1 para remoto;
- intento de comando arbitrario;
- intento de shell libre;
- intento de tocar zonas protegidas.
```

## Logs seguros

Los logs no deben contener:

```text
- tokens;
- headers Authorization;
- .env;
- payloads sensibles;
- set -x;
- secretos;
- rutas de credenciales.
```

Los logs pueden contener:

```text
- timestamp;
- action;
- status;
- branch;
- PR URL;
- PR number;
- errores sanitizados.
```

## Validaciones futuras

Cuando se implemente el bridge:

```text
acción desconocida -> BLOCKED
github_status no modifica repo
publish sin OK_GITHUB=1 -> BLOCKED
create_pr sin OK_GITHUB=1 -> BLOCKED
no shell libre
no comandos arbitrarios
no token en salida
repo fijo correcto
wrapper solo invoca executor local
exec approval no permite otros comandos
logs redaccionados
```

Validación conceptual:

```bash
tools/neodaemon_executor_bridge.sh '{"action":"unknown"}'
tools/neodaemon_executor_bridge.sh '{"action":"github_status"}'
tools/neodaemon_executor_bridge.sh '{"action":"github_publish_token","branch":"test/example"}'
```

Resultado esperado:

```text
unknown -> BLOCKED
github_status -> OK read-only
publish sin OK_GITHUB=1 -> BLOCKED
```

## Riesgo

Riesgo:

```text
MEDIO-ALTO
```

Motivo:

Aunque esta fase es documentación, el diseño habilita futura ejecución real mediante host.

Riesgos principales:

```text
- configurar exec demasiado amplio;
- permitir shell libre accidentalmente;
- exponer secretos en logs;
- permitir acciones remotas sin aprobación;
- saltarse el executor local;
- tocar rutas fuera de neodaemon_v1.
```

Mitigaciones:

```text
- documentación only ahora;
- CONFIRMACIÓN_ESPECIAL antes de tocar configuración;
- wrapper fijo;
- ruta fija;
- allowlist doble;
- bloqueo por defecto;
- sin shell libre;
- sin comandos arbitrarios;
- logs redaccionados.
```

## Rollback

Para esta fase documental:

```bash
git checkout -- docs/executor/EXECUTOR_BRIDGE_V1_DESIGN.md
```

Para fase futura si se activa configuración:

```text
- desactivar allowlist exec approval;
- eliminar wrapper;
- conservar logs para auditoría;
- reiniciar/reload solo si OpenClaw lo requiere y con confirmación;
- revertir commit si aplica.
```

## Qué NO toca esta feature

Esta feature no toca:

```text
- wrapper real;
- exec approvals;
- configuración OpenClaw;
- systemd;
- Gmail;
- OAuth;
- gateway;
- routing;
- core;
- tokens;
- GitHub remoto;
- merge;
- borrado de ramas;
- shell libre;
- comandos arbitrarios.
```

## Estado esperado tras esta documentación

Después de mergear este documento:

```text
- queda documentado el papel de exec approvals;
- queda documentado que exec approvals no sustituye al executor;
- queda prohibido exec genérico;
- queda definido el wrapper recomendado;
- queda claro que activar configuración requiere CONFIRMACIÓN_ESPECIAL;
- queda preparada la base para una futura implementación segura.
```

Después de guardar, valida:

```bash
git diff -- docs/executor/EXECUTOR_BRIDGE_V1_DESIGN.md
git status --short
```
