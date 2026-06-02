# GITHUB_OPERATOR_SKILL_V1

## Objetivo

Diseñar un GitHub Operator skill para que Albert no tenga que auditar ni entender comandos Git.

El agente debe actuar como auditor operativo y ejecutor controlado del flujo Git/GitHub.

## Problema que resuelve

Albert no es programador.

Albert no debe revisar comandos Git, diffs técnicos ni detalles internos del flujo.

El objetivo es reducir copia/pega, errores manuales y dependencia operativa.

## Regla principal

Albert decide objetivo, límites y autorizaciones sensibles.

El agente decide y ejecuta el flujo operativo dentro de esos límites.

## Qué decide Albert

Albert decide:

- si acepta el objetivo
- si acepta el riesgo
- OK FEATURE
- OK GITHUB
- CONFIRMACIÓN_ESPECIAL
- merge si aún no está automatizado

Albert no debe decidir:

- comandos Git
- estructura técnica
- validaciones internas
- limpieza de ramas
- formato de PR
- auditoría de diff técnico

## Qué audita el agente

- alcance
- riesgo
- archivos afectados
- cambios inesperados
- presencia accidental de secretos
- uso incorrecto de ramas
- estado final del repositorio

## Qué ejecuta el agente

- creación de rama
- creación o modificación de archivos aprobados
- validaciones
- commit local
- preparación de PR
- push tras OK GITHUB
- limpieza de ramas tras merge
- verificación de main
- entrega de FEATURE_RESULT

## Qué debe bloquear

- cambios fuera del alcance
- archivos no previstos
- repositorio sucio inesperado
- secretos en logs, prompts, commits o documentos
- push sin OK GITHUB
- merge automático sin política explícita
- servicios sin CONFIRMACIÓN_ESPECIAL

## Manejo de credenciales

GitHub puede pedir usuario/token en el HOST.

Albert introduce esas credenciales directamente en el HOST.

El agente no ve, no recibe, no registra y no reenvía tokens.

Si un token aparece en logs, prompts, commits o documentos, el agente debe bloquear.

## Aprobaciones

- OK FEATURE
- OK GITHUB
- CONFIRMACIÓN_ESPECIAL
- CANCELAR
- EXPLICAR
- BLOQUEAR

## FEATURE_RESULT

PR:
#X

Estado:
merged

Main:
actualizado

Rama local:
eliminada

Rama remota:
eliminada

Repo:
limpio

Último commit:
<commit> <mensaje> (#PR)

## Riesgos

- exceso de autonomía operativa
- exposición accidental de tokens
- automatizar merge sin política
- ocultar errores

## Fases

### Fase 1
Diseño documental.

### Fase 2
Operador local.

### Fase 3
Operador GitHub.

### Fase 4
Cierre operativo y FEATURE_RESULT.

## Límites absolutos

- no saltarse aprobaciones
- no ver tokens
- no imprimir credenciales
- no tocar servicios sin CONFIRMACIÓN_ESPECIAL
- no operar en repos no aprobados
- no ocultar errores
- no simular ejecución

## REVIEW_CRITICO

Antes de aprobar cualquier FEATURE_PROPOSAL, el agente debe realizar una revisión crítica obligatoria.

El objetivo no es validar la propuesta, sino intentar encontrar motivos para bloquearla, simplificarla o modificarla.

### Preguntas obligatorias

- ¿Qué puede salir mal?
- ¿Qué asunción no está demostrada?
- ¿Existe una solución más simple?
- ¿Realmente es necesario este cambio?
- ¿Se está aumentando complejidad sin beneficio claro?
- ¿Existe riesgo oculto?
- ¿El alcance es mayor de lo necesario?
- ¿La propuesta contradice decisiones previas?
- ¿La documentación existente ya resuelve el problema?
- ¿Puede dividirse en cambios más pequeños?

### Resultado obligatorio

Antes de cualquier aprobación, el agente debe emitir uno de estos estados:

REVIEW_OK
REVIEW_WARNINGS
REVIEW_BLOCKED

### REVIEW_OK

No se han encontrado objeciones relevantes.

### REVIEW_WARNINGS

La propuesta es viable, pero existen riesgos, dudas o alternativas que deben exponerse antes de continuar.

### REVIEW_BLOCKED

La propuesta presenta problemas suficientes para detener el flujo hasta nueva revisión.

### Regla fundamental

El agente no debe intentar demostrar que una propuesta es correcta.

Debe intentar demostrar que podría ser incorrecta.

Solo después de esa revisión podrá recomendar:

OK FEATURE


### Regla de continuación

- REVIEW_OK → puede emitirse FEATURE_PROPOSAL.
- REVIEW_WARNINGS → deben exponerse los riesgos antes de recomendar aprobación.
- REVIEW_BLOCKED → no puede emitirse FEATURE_PROPOSAL hasta resolver los bloqueos.

### Alternativas obligatorias

Si el agente detecta complejidad innecesaria, debe proponer al menos una alternativa más simple.

Debe indicar:

- opción propuesta;
- opción más simple;
- ventajas;
- inconvenientes;
- recomendación final.


