# MAIN_RAG_DECOUPLING_V1

## Estado

Completado y validado.

Fecha: 2026-06-08

## Problema detectado

Se asumía que el flujo `/main` utilizaba exclusivamente NeoDaemon MAIN.

La inspección de `main_handler.py` demostró que:

```text
ask_main()
├─ ask_rag()
└─ openclaw agent main
```

Por tanto, las consultas recibidas por `/main` podían ser respondidas por RAG antes de llegar a NeoDaemon.

Esto provocó respuestas incorrectas y comportamiento no determinista para operaciones y consultas relacionadas con NeoDaemon.

## Root Cause

La causa raíz no fue un fallo de RAG.

La causa raíz fue asumir incorrectamente que:

```text
ask_main() → NeoDaemon MAIN
```

cuando en realidad:

```text
ask_main()
├─ ask_rag()
└─ openclaw agent main
```

La modificación se realizó sobre una hipótesis no verificada.

La inspección posterior del código permitió identificar el flujo real y aplicar la corrección adecuada.

## Decisión

Separar responsabilidades:

```text
/main → NeoDaemon MAIN → GPT
/rag  → RAG Microsoft Fabric
```

RAG deja de formar parte del flujo `/main`.

## Cambios realizados

`main_handler.py`:

- se eliminó la llamada inicial a `ask_rag(question)`;
- el flujo queda: `ask_main(question) → openclaw agent main`.

`telegram_rag_bot.py`:

- se restauró el uso de:

```python
answer = ask_main(question)
send_message(chat_id, answer)
```

para que `/main` vuelva a comunicarse con NeoDaemon MAIN.

## Validación

Prueba realizada:

```text
/main qué es NeoDaemon
```

Resultado:

- NeoDaemon respondió correctamente describiendo su función como coordinador MAIN de OpenClaw;
- no apareció ninguna respuesta procedente de RAG.

## Arquitectura resultante

Flujo operativo:

```text
Albert
↓
Telegram
↓
NeoDaemon MAIN
↓
GPT
↓
Respuesta
```

Consultas documentales:

```text
/rag
↓
RAG Fabric
↓
Respuesta documental
```

## Lección aprendida

No asumir que un componente es exclusivamente GPT o exclusivamente RAG.

Verificar siempre el flujo real antes de modificar el routing.

La inspección directa del código identificó que `ask_main()` mezclaba ambas responsabilidades.

## Resultado

NeoDaemon vuelve a operar conforme al diseño original del proyecto.

RAG queda desacoplado del flujo operativo principal.
