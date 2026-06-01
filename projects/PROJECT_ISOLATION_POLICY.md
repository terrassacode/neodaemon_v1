# Política de aislamiento de proyectos OpenClaw

Estado: activo  
Responsable operativo: Neodaemon MAIN  
Ámbito: /openclaw/workspace/main/projects/

## 1. Objetivo

Todo proyecto nuevo debe estar aislado del core operativo de Neodaemon/OpenClaw.

Objetivos:

- evitar contaminación del core;
- evitar cambios accidentales en servicios, scripts globales, memoria, RAG o dashboard operativo;
- facilitar rollback;
- facilitar auditoría;
- permitir desarrollo seguro de apps;
- separar experimentos, prototipos y aplicaciones del entorno principal.

## 2. Ubicación obligatoria

Todo proyecto nuevo debe crearse dentro de:

    /openclaw/workspace/main/projects/<nombre-proyecto>/

Ningún proyecto nuevo debe iniciarse fuera de esa ruta salvo autorización explícita de Albert.

## 3. Rutas prohibidas

Cada ruta prohibida debe mantenerse en línea independiente:

- /openclaw/core
- /openclaw/workspace/main/scripts
- /openclaw/workspace/main/systemd
- /openclaw/workspace/main/rag_store
- /openclaw/workspace/main/memory
- /openclaw/workspace/main/.openclaw
- /openclaw/workspace/main/context_repo
- /openclaw/workspace/main/dashboard-v2
- /openclaw/workspace/main/logs
- /openclaw/workspace/main/backups
- /openclaw/workspace/main/briefings
- /openclaw/workspace/git_clean
- /openclaw/.env
- /home/openclaw/.openclaw

## 4. Excepción

Solo se permite tocar rutas prohibidas con autorización explícita de Albert.

La autorización debe indicar:

- ruta exacta;
- motivo;
- alcance;
- archivos afectados;
- rollback previsto.

Sin esos datos, la acción debe considerarse no autorizada.

## 5. Estructura obligatoria de proyecto

Todo proyecto nuevo debe usar esta estructura mínima:

    /openclaw/workspace/main/projects/<nombre-proyecto>/
    ├── README.md
    ├── .project_scope.md
    ├── .gitignore
    ├── src/
    ├── data_samples/
    └── exports/

## 6. Regla de escritura

Un proyecto aislado no puede escribir fuera de:

    /openclaw/workspace/main/projects/<nombre-proyecto>/

Esto aplica aunque el sistema, permisos o herramientas permitan escribir fuera.

## 7. Regla de ejecución estricta

Un proyecto aislado no puede:

- ejecutar scripts fuera de su carpeta;
- invocar scripts de /openclaw/workspace/main/scripts;
- invocar ru_event.sh, ru_interaction.sh u otros wrappers globales;
- invocar herramientas del core.

Salvo autorización explícita de Albert.

## 8. Git

Queda prohibido ejecutar:

    git add .

desde:

    /openclaw/workspace/main

Cualquier git push requiere autorización explícita de Albert.

## 9. Datos permitidos

Un proyecto puede contener dentro de su carpeta:

- código fuente propio;
- datos de ejemplo no sensibles;
- documentación propia;
- exports generados por el propio proyecto;
- assets locales;
- configuración local no secreta.

## 10. Datos prohibidos

Un proyecto no puede contener ni copiar:

- tokens;
- claves API;
- secretos;
- .env reales;
- credenciales;
- datos privados de Albert;
- logs globales;
- memoria operativa;
- datos RAG internos;
- dumps de Gmail, Telegram o servicios externos.

## 11. Reglas de ejecución

Un proyecto aislado:

- solo puede ejecutar scripts dentro de su propia carpeta;
- no puede modificar servicios;
- no puede tocar systemd;
- no puede tocar gateway;
- no puede modificar RAG;
- no puede escribir en dashboards globales;
- no puede enviar datos a APIs externas sin autorización explícita.

## 12. Rollback

Cada proyecto debe poder revertirse eliminando o archivando únicamente:

    /openclaw/workspace/main/projects/<nombre-proyecto>/

No debe requerir revertir cambios en core, scripts, servicios, logs globales o dashboards.

## 13. Validación previa

Antes de crear o modificar un proyecto, validar:

- ruta dentro de projects/;
- ausencia de escritura fuera del proyecto;
- ausencia de secretos;
- ausencia de scripts globales invocados;
- ausencia de git add . desde /openclaw/workspace/main;
- ausencia de exposición externa no autorizada.

## 14. Plantilla obligatoria .project_scope.md

Cada proyecto debe incluir:

# Project Scope

## Nombre

<nombre-proyecto>

## Ruta raíz autorizada

    /openclaw/workspace/main/projects/<nombre-proyecto>/

## Objetivo

<objetivo breve>

## Rutas permitidas

    /openclaw/workspace/main/projects/<nombre-proyecto>/

## Rutas prohibidas

- /openclaw/core
- /openclaw/workspace/main/scripts
- /openclaw/workspace/main/systemd
- /openclaw/workspace/main/rag_store
- /openclaw/workspace/main/memory
- /openclaw/workspace/main/.openclaw
- /openclaw/workspace/main/context_repo
- /openclaw/workspace/main/dashboard-v2
- /openclaw/workspace/main/logs
- /openclaw/workspace/main/backups
- /openclaw/workspace/main/briefings
- /openclaw/workspace/git_clean
- /openclaw/.env
- /home/openclaw/.openclaw

## Datos permitidos

- código del proyecto;
- documentación del proyecto;
- datos de ejemplo no sensibles;
- exports locales.

## Datos prohibidos

- secretos;
- tokens;
- credenciales;
- logs globales;
- memoria operativa;
- datos privados;
- datos RAG internos.

## Reglas de ejecución

- no ejecutar scripts globales;
- no invocar ru_event.sh;
- no invocar ru_interaction.sh;
- no modificar servicios;
- no tocar gateway;
- no tocar systemd;
- no tocar RAG.

## Rollback

Eliminar o archivar solo esta carpeta de proyecto.

## Validación previa

Validar aislamiento antes de escribir, ejecutar o publicar.

## 15. Regla final

Si hay duda sobre si una acción pertenece al proyecto o al core, se debe tratar como acción sensible y pedir confirmación explícita a Albert antes de continuar.
