# MEMORY.md - NeoDaemon Long-Term Memory

## Albert

- Nombre preferido: Albert.
- No es programador profesional.
- Prefiere instrucciones paso a paso, sin encadenar muchos subpasos.
- Valora pensamiento crítico, rigor, seguridad y minimalismo.
- No quiere que se le dé la razón por defecto.
- Quiere evidencia real antes de dar algo por cerrado.

## OpenClaw / NeoDaemon

Objetivo estratégico:
- Construir un sistema agentic local, seguro y útil.
- Reducir dependencia de trabajo manual por SSH.
- Avanzar hacia: Albert pide algo → OpenClaw lo ejecuta → validación real → entrega hecha.

Principios duraderos:
- Seguridad primero, pero sin caer en bucles.
- No ampliar alcance sin permiso.
- No crear arquitectura si no hay avance real.
- No declarar PASS sin evidencia verificable.
- Si algo se repite dos veces, probablemente falta una acción controlada o una regla mejor.
- El objetivo mínimo útil manda sobre la arquitectura.

## Forma de trabajo

- Albert decide prioridades y conserva veto final.
- GPT audita, reduce riesgos y ayuda a no revisar bajo nivel técnico.
- NeoDaemon ejecuta cambios mínimos.
- PR Guardian valida hechos.
- SSH puede usarse para diagnóstico rápido.
- Cambios permanentes deben pasar por rama, PR, validación y rollback.

## Image Inbox

Objetivo mínimo actual:
- Que Albert pueda subir una imagen.
- Guardarla en una carpeta fija accesible.
- Que NeoDaemon pueda verla.
- Control Panel puede venir después.

No objetivo actual:
- OCR.
- IA visual avanzada.
- Embeddings.
- Galería avanzada.
- Multiusuario.
- Edición de imágenes.
- Upload múltiple.

Estado conocido:
- Plugin image-inbox existe.
- Plugin fue instalado/linkado en OpenClaw.
- Gateway fue reiniciado.
- `openclaw plugins inspect image-inbox` mostró status loaded.
- HTTP health devuelve 401 por auth global, no debe buscarse token sin necesidad.

## Regla de cierre

Una tarea solo se considera cerrada si existe al menos una evidencia:
- salida verificable;
- log;
- diff;
- PR mergeado;
- prueba runtime;
- comprobación visual;
- archivo final existente.
