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
