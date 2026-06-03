# GITHUB_REVIEWER_LOCAL_OPERATIONS_V0_8

## Estado

Activo localmente.

Este documento describe la operación local del reviewer Git/GitHub de NeoDaemon hasta V0.8.

No contiene logs, snapshots, borradores reales, tokens, credenciales ni datos sensibles.

## Objetivo

Mantener una revisión automática local del estado Git del repositorio `neodaemon_v1`, generar un resumen humano fácil de leer y preparar un borrador local de correo.

El sistema está pensado para descargar trabajo operativo de Albert sin darle tareas técnicas innecesarias.

## Versionado en GitHub

Estos archivos sí están versionados en GitHub:

```text
scripts/github_reviewer_readonly_v0_1.py
scripts/github_reviewer_readonly_v0_2.py
docs/github/GITHUB_REVIEWER_LOCAL_OPERATIONS_V0_6.md
```

## Solo local

Estas piezas existen solo en el host local y no deben subirse a GitHub:

```text
~/.openclaw/neodaemon/bin/github_reviewer_v0_2_run.sh
~/.openclaw/neodaemon/bin/github_reviewer_human_summary_v0_5.py
~/.openclaw/neodaemon/bin/github_reviewer_email_draft_v0_7.py
~/.openclaw/neodaemon/logs/github_reviewer_v0_2.log
~/.openclaw/neodaemon/reports/github_reviewer_last_summary.txt
~/.openclaw/neodaemon/reports/github_reviewer_last_email_draft.txt
~/.openclaw/neodaemon/github_reviewer_state_v0_2.json
~/.config/systemd/user/neodaemon-github-reviewer-v0-2.service
~/.config/systemd/user/neodaemon-github-reviewer-v0-2.timer
```

## Frecuencia

El timer local ejecuta el reviewer dos veces al día:

```text
08:00
20:00
```

## Qué hace cada ejecución

Cada ejecución realiza esta cadena:

```text
1. Ejecuta el reviewer técnico V0.2.
2. Revisa el estado Git local del repo.
3. Actualiza el snapshot fuera del repo.
4. Escribe el log técnico fuera del repo.
5. Genera el resumen humano.
6. Genera el borrador local de email.
```

## Qué comprueba

El reviewer técnico comprueba:

```text
- rama actual;
- git status --short;
- último commit;
- ramas locales;
- ramas remotas ya conocidas localmente;
- ramas no mergeadas;
- si hubo cambios desde el último barrido;
- si sigue funcionando en modo read-only.
```

## Qué NO hace

El sistema no hace:

```text
- no envía email real;
- no Gmail;
- no SMTP;
- no Telegram;
- no gh CLI;
- no fetch;
- no pull;
- no push;
- no merge;
- no borra ramas;
- no abre PRs;
- no modifica el repo;
- no toca tokens;
- no toca OAuth;
- no toca core;
- no toca gateway;
- no toca routing;
- no hace secret scanning;
- no copia diffs.
```

## Borrador local de email

El sistema genera un borrador local de correo en:

```text
~/.openclaw/neodaemon/reports/github_reviewer_last_email_draft.txt
```

Este borrador sirve para revisar manualmente qué se enviaría en un futuro.

Advertencia:

```text
El borrador no se envía automáticamente.
No hay destinatario configurado.
No se usa Gmail.
No se usa SMTP.
No se usa OAuth.
No se usan tokens.
No se envía ningún correo real.
```

## Cómo comprobar estado

```bash
systemctl --user status neodaemon-github-reviewer-v0-2.timer --no-pager
systemctl --user list-timers --all | grep neodaemon-github-reviewer-v0-2
systemctl --user status neodaemon-github-reviewer-v0-2.service --no-pager
```

## Cómo leer el log técnico

```bash
tail -n 80 ~/.openclaw/neodaemon/logs/github_reviewer_v0_2.log
```

## Cómo leer el resumen humano

```bash
cat ~/.openclaw/neodaemon/reports/github_reviewer_last_summary.txt
```

## Cómo leer el borrador local de email

```bash
cat ~/.openclaw/neodaemon/reports/github_reviewer_last_email_draft.txt
```

## Cómo ejecutar manualmente

```bash
~/.openclaw/neodaemon/bin/github_reviewer_v0_2_run.sh
```

## Cómo comprobar que no modifica el repo

```bash
cd /openclaw/workspace/git_clean/neodaemon_v1

before="$(git status --short)"
~/.openclaw/neodaemon/bin/github_reviewer_v0_2_run.sh
after="$(git status --short)"

test "$before" = "$after" && echo "OK: repo status unchanged" || echo "BLOCK: repo status changed"
```

## Cómo desactivar el timer

```bash
systemctl --user disable --now neodaemon-github-reviewer-v0-2.timer
```

## Rollback completo

```bash
systemctl --user disable --now neodaemon-github-reviewer-v0-2.timer
systemctl --user stop neodaemon-github-reviewer-v0-2.service

rm ~/.config/systemd/user/neodaemon-github-reviewer-v0-2.service
rm ~/.config/systemd/user/neodaemon-github-reviewer-v0-2.timer

systemctl --user daemon-reload
systemctl --user reset-failed neodaemon-github-reviewer-v0-2.service
systemctl --user reset-failed neodaemon-github-reviewer-v0-2.timer
```

No borrar automáticamente logs, snapshots, resúmenes ni borradores salvo decisión explícita.

## Advertencia importante

No subir logs, snapshots, borradores reales ni secretos.

No versionar:

```text
~/.openclaw/neodaemon/logs/
~/.openclaw/neodaemon/reports/
~/.openclaw/neodaemon/github_reviewer_state_v0_2.json
```

## Estado sano esperado

```text
repo limpio
rama main
sin ramas pendientes
changed_since_last_run=false
read_only=true
snapshot_outside_repo=true
no_fetch=true
no_gh=true
timer active waiting
próxima ejecución visible
resumen humano actualizado
borrador local de email actualizado
```

