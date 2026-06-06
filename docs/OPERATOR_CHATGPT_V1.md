# OPERATOR_CHATGPT_V1

## Objetivo

Definir un operador intermedio ligero para convertir intenciones de Albert en interacciones acotadas con NeoDaemon.

## Problema que resuelve para Albert

Reduce copy-paste, bucles largos, reformulación manual y carga cognitiva durante la preparación de features o decisiones operativas.

No aumenta permisos, no ejecuta acciones y no sustituye a NeoDaemon.

## Flujo máximo de 3 intercambios

1. Operator formula a NeoDaemon el objetivo, alcance, restricciones y resultado esperado.
2. NeoDaemon responde con propuesta, bloqueo o necesidad de aclaración. Operator puede hacer una única aclaración si falta información crítica.
3. NeoDaemon confirma la decisión final. Operator devuelve a Albert una salida permitida.

## Topología de conversación

Flujo normal:

```text
Albert → NeoDaemon → Albert
```

Flujo con revisión crítica opcional:

```text
Albert → NeoDaemon → GPT crítico → NeoDaemon → Albert
```

NeoDaemon sigue siendo el interlocutor principal de Albert.

GPT no es el router principal y no es un paso obligatorio. Cuando participa, actúa como revisor opcional para detectar:

- puntos ciegos;
- supuestos débiles;
- mejoras;
- riesgos.

Albert no debe actuar como puente manual entre NeoDaemon y GPT. Si se usa revisión crítica, NeoDaemon debe integrar el resultado y devolver a Albert una respuesta final clara.

## Entradas mínimas

- objetivo;
- alcance;
- archivos o rutas afectadas si se conocen;
- qué NO tocar;
- si se permite implementación o solo propuesta;
- resultado esperado;
- límite de autonomía.

## Salidas permitidas

- `OK_FEATURE`
- `FEATURE_BLOCKED`
- `CONCLUSIÓN`
- `NECESITA_ALBERT`

Cada salida debe incluir un motivo breve y la siguiente acción mínima.

## Regla de cierre

Si tras 3 intercambios no hay decisión clara, devolver:

```text
NECESITA_ALBERT
```

## Protocolos de comunicación obligatorios

### GPT → NeoDaemon: PROTOCOLO_OPERATIVO_V1

Toda comunicación de GPT hacia NeoDaemon debe ser estricta y estructurada.

Debe incluir:

- objetivo;
- alcance;
- restricciones;
- validaciones esperadas;
- formato de salida requerido.

La comunicación debe evitar ambigüedad, no mezclar objetivos y respetar el límite máximo de 3 intercambios.

### NeoDaemon → Albert: VALIDATION_OUTPUT_V1

Toda comunicación de NeoDaemon hacia Albert debe ser clara para no programadores.

Debe incluir:

- resumen humano;
- evidencia técnica mínima;
- resultado claro;
- siguiente acción mínima.

Debe evitar jerga innecesaria y separar claramente hechos confirmados, riesgos y bloqueos.

## Qué NO debe hacer

- No ejecutar comandos.
- No tocar archivos.
- No aprobar acciones sensibles.
- No sustituir a NeoDaemon.
- No decidir por Albert.
- No tocar approvals.
- No tocar OpenClaw core, gateway, routing, systemd ni secrets.
- No crear workflows, dashboards ni RAG.

## Ejemplo breve de uso

Albert pide una feature.

Operator resume:

```text
Objetivo: crear documentación operativa.
Alcance: docs/example.md.
Restricciones: no scripts, no configuración, no servicios.
Resultado esperado: FEATURE_PROPOSAL.
```

NeoDaemon responde con propuesta o bloqueo.

Operator devuelve una de las salidas permitidas, por ejemplo:

```text
OK_FEATURE
```
