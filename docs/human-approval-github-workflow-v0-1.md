# Human Approval GitHub Workflow v0.1

## Estado

Diseño aceptado por Albert. Pendiente de validación mediante PR documental.

## Objetivo

Definir un workflow GitHub seguro para que Neodaemon pueda preparar ramas, commits y PRs de forma controlada, mientras Albert valida decisiones operativas en lenguaje humano.

Albert no necesita saber programar, revisar comandos complejos ni validar código línea por línea.

Regla principal:

1 feature = máximo 2 interacciones humanas.

Las dos interacciones son:

1. OK FEATURE — autoriza trabajo local.
2. OK GITHUB — autoriza push de rama y apertura de PR.

OK GITHUB no autoriza merge automático.

---

## Principios

- Neodaemon traduce cambios técnicos a lenguaje humano.
- Albert valida intención, alcance, riesgo y acciones sensibles.
- Albert responde solo con opciones simples.
- Neodaemon ejecuta checks técnicos.
- Neodaemon bloquea automáticamente ante señales de riesgo.
- No se toca main directamente.
- No se hace auto-merge.
- No se manejan tokens dentro del repo, prompts, commits ni logs.

---

## Respuestas válidas de Albert

Para fase local:

- OK FEATURE
- CANCELAR
- EXPLICAR
- BLOQUEAR

Para fase GitHub:

- OK GITHUB
- CANCELAR
- EXPLICAR
- BLOQUEAR

---

## Fase 0 — Precheck interno

Antes de pedir OK FEATURE, Neodaemon verifica:

- repositorio correcto;
- rama actual;
- main limpio;
- main actualizado;
- working tree limpio;
- objetivo acotado;
- rama propuesta;
- archivos previstos;
- tipo de cambios;
- riesgo estimado;
- validaciones necesarias;
- rutas sensibles;
- presencia potencial de secretos;
- que no se toquen servicios ni automatización del sistema.

Definición obligatoria:

main actualizado = git pull origin main ejecutado sin conflictos.

Además:

main local debe coincidir con origin/main tras git pull origin main.

Si el precheck detecta bloqueo, Neodaemon no pide aprobación y devuelve FEATURE_BLOCKED.

---

## Límite de tamaño de feature

Una feature debe ser pequeña y acotada.

Si el cambio supera 5 archivos, mezcla tipos no relacionados, combina documentación/scripts/servicios/UI en el mismo cambio, o el diff es demasiado grande para revisión operativa, Neodaemon debe bloquear y proponer dividirlo en features más pequeñas.

---

## Interacción 1 — OK FEATURE

Antes de empezar, Neodaemon presenta FEATURE_PROPOSAL.

Si Albert responde OK FEATURE, Neodaemon queda autorizado a completar el trabajo local de esa feature sin más preguntas, salvo bloqueo automático.

Acciones incluidas en OK FEATURE:

- crear rama local desde main limpio y actualizado;
- modificar solo archivos previstos;
- ejecutar validaciones definidas;
- revisar git status;
- revisar git diff --stat;
- revisar git diff;
- usar solo git add <archivo_concreto>;
- crear commit local claro.

Acciones NO incluidas en OK FEATURE:

- push;
- abrir PR;
- merge;
- borrar rama remota;
- tocar credenciales/tokens;
- tocar servicios;
- tocar systemd;
- tocar cron;
- tocar timers;
- modificar gateway;
- modificar routing;
- modificar modelos;
- modificar sandbox global.

---

## Formato — FEATURE_PROPOSAL

FEATURE_PROPOSAL debe incluir:

- Objetivo.
- Rama propuesta.
- Archivos previstos.
- Tipo de cambios.
- Riesgo estimado.
- Qué NO tocará.
- Validaciones que ejecutará.
- Rollback local.
- Acciones incluidas si Albert aprueba.
- Acciones NO incluidas.
- Respuesta válida: OK FEATURE / CANCELAR / EXPLICAR / BLOQUEAR.

---

## Trabajo local autorizado

Durante el trabajo local, Neodaemon debe:

- mantenerse en la rama de feature;
- tocar solo archivos previstos;
- ejecutar validaciones obligatorias;
- no usar git add .;
- no usar git add -A;
- no añadir archivos generados;
- no añadir logs/backups/snapshots;
- no tocar secretos;
- no tocar servicios;
- detenerse si aparece bloqueo.

---

## Interacción 2 — OK GITHUB

Cuando el trabajo local esté terminado y el commit local creado, Neodaemon presenta FEATURE_READY_FOR_GITHUB.

Si Albert responde OK GITHUB, Neodaemon queda autorizado a:

- hacer push de la rama;
- abrir PR.

OK GITHUB no autoriza merge automático.

El merge lo realiza Albert manualmente en GitHub o requerirá una aprobación especial futura.

Acciones incluidas en OK GITHUB:

- push de rama;
- apertura de PR.

Acciones NO incluidas en OK GITHUB:

- merge automático;
- borrado de rama remota;
- acciones destructivas;
- manejo de tokens;
- guardar credenciales;
- tocar servicios;
- tocar systemd/cron/timers.

---

## Autenticación

Si GitHub solicita usuario/token:

- Albert lo introduce manualmente;
- Neodaemon no debe ver el token;
- Neodaemon no debe imprimir el token;
- Neodaemon no debe guardar el token;
- Neodaemon no debe escribir credenciales en archivos, commits ni logs.

---

## Formato — FEATURE_READY_FOR_GITHUB

FEATURE_READY_FOR_GITHUB debe incluir:

- Objetivo.
- Rama.
- Commit creado.
- Archivos realmente cambiados.
- Validaciones ejecutadas.
- Resultado de git status.
- Confirmación de que no hay secretos.
- Confirmación de que no hay JSON/logs/backups/snapshots versionados.
- Riesgo final.
- Acciones propuestas: push de rama y abrir PR.
- Acciones NO incluidas: merge automático, borrado remoto, tokens, servicios.
- Nota: el merge lo realiza Albert manualmente.
- Respuesta válida: OK GITHUB / CANCELAR / EXPLICAR / BLOQUEAR.

---

## Post-merge

Después de que Albert confirme que el PR fue merged, Neodaemon puede ejecutar limpieza local solo si el protocolo vigente lo permite.

Acciones permitidas tras merge confirmado:

- git checkout main;
- git pull origin main;
- verificar git status;
- limpiar rama local con git branch -d <rama>.

El borrado de rama remota no queda incluido por defecto en OK GITHUB.

Borrar rama remota requiere confirmación separada o acción manual de Albert.

No usar git branch -D <rama> salvo confirmación especial explícita.

---

## Bloqueo automático

Aunque exista OK FEATURE, Neodaemon debe parar y bloquear si aparece cualquiera de estas condiciones:

- archivo no previsto;
- .env;
- token;
- password;
- secret;
- API key;
- credencial;
- intento de imprimir token;
- intento de guardar token;
- git add .;
- git add -A;
- JSON generado añadido a Git;
- logs añadidos a Git;
- backups añadidos a Git;
- snapshots añadidos a Git;
- systemd;
- cron;
- timers;
- servicios;
- gateway;
- modelos;
- routing;
- sandbox global;
- diff demasiado grande;
- diff fuera del objetivo;
- validación fallida;
- conflicto Git;
- main sucio;
- git pull origin main con conflictos;
- acción destructiva;
- push sin OK GITHUB;
- apertura de PR sin OK GITHUB;
- merge automático;
- borrado de rama sin PR merged confirmado;
- borrado de rama remota sin confirmación separada;
- uso de git branch -D sin confirmación especial.

---

## Formato — FEATURE_BLOCKED

FEATURE_BLOCKED debe incluir:

- Objetivo original.
- Fase.
- Motivo del bloqueo.
- Regla activada.
- Evidencia.
- Qué ha detenido.
- Qué NO ha hecho.
- Siguiente paso seguro.
- Respuesta válida: EXPLICAR / BLOQUEAR.

---

## Validaciones obligatorias por tipo

Python:

- python3 -m py_compile <archivo.py>

Bash:

- bash -n <archivo.sh>

HTML:

- revisar rutas fetch;
- labels visibles;
- enlaces;
- estados vacíos;
- estados de error;
- no cargar rutas sensibles;
- no introducir métricas fuera de alcance.

JSON generado:

- no versionar;
- no staged;
- ignorar si aplica;
- no guardar prompts;
- no guardar respuestas;
- no guardar tool args;
- no guardar secretos.

Documentación:

- alcance claro;
- sin afirmar ejecución no realizada;
- sin instrucciones peligrosas;
- sin credenciales;
- sin rutas sensibles innecesarias.

---

## Restricciones absolutas

Neodaemon no debe:

- tocar main directamente;
- usar git add .;
- usar git add -A;
- imprimir tokens;
- guardar tokens;
- escribir credenciales en logs;
- escribir credenciales en commits;
- hacer auto-merge;
- hacer push sin OK GITHUB;
- abrir PR sin OK GITHUB;
- borrar ramas sin PR merged confirmado;
- borrar rama remota sin confirmación separada;
- usar git branch -D salvo confirmación especial;
- tocar systemd/cron/timers;
- tocar servicios;
- modificar gateway/routing/modelos/sandbox global;
- ejecutar acciones destructivas sin autorización explícita.

---

## Resultado final

Al terminar una feature, Neodaemon debe responder FEATURE_RESULT con:

- Objetivo.
- Rama.
- Estado: local_committed, pushed, pr_opened, blocked o cancelled.
- Commit.
- PR.
- Validaciones.
- Git status.
- Pendiente de Albert.
- Resultado: OK, PARCIAL, BLOQUEADO o CANCELADO.

---

## Ejemplo práctico — cambio documental de bajo riesgo

Este ejemplo muestra cómo aplicar el flujo a una modificación simple de documentación.

### Situación

Albert pide añadir una pequeña aclaración a un documento existente.

Archivo previsto:

- docs/human-approval-github-workflow-v0-1.md

Tipo de cambio:

- documentación

Riesgo estimado:

- bajo

### Flujo esperado

Neodaemon presenta FEATURE_PROPOSAL indicando:

- objetivo del cambio;
- rama propuesta;
- único archivo afectado;
- validaciones documentales;
- acciones incluidas en OK FEATURE;
- acciones excluidas, como push, PR y merge.

Si Albert responde OK FEATURE, Neodaemon puede:

- crear rama local;
- modificar solo el archivo previsto;
- revisar el diff;
- comprobar que no hay secretos;
- usar git add solo sobre el archivo concreto;
- crear commit local.

Cuando el commit local está listo, Neodaemon presenta FEATURE_READY_FOR_GITHUB.

Si Albert responde OK GITHUB, Neodaemon puede:

- hacer push de la rama;
- abrir el PR.

El merge no queda autorizado por OK GITHUB. Albert lo realiza manualmente en GitHub o mediante aprobación especial futura.

### Resultado esperado

El cambio queda preparado con un máximo de dos interacciones humanas:

1. OK FEATURE.
2. OK GITHUB.

Albert valida la decisión operativa. Neodaemon valida la parte técnica.
