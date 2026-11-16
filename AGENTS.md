# AGENTS.md — Mapa de navegación para agentes de IA

> Punto de entrada para cualquier agente de este repositorio: un **mapa** y
> las reglas comunes a todos. Lo que solo afecta a un rol está en su
> definición (`.claude/agents/<rol>.md`), no aquí.

---

## 1. Antes de empezar

- **Este archivo ya está en tu contexto**: lo importa `CLAUDE.md` en cada
  sesión y en cada subagente. No lo vuelvas a leer.
- **Sigue el protocolo de tu definición.** Dice qué leer, en qué momento y
  cuándo ejecutar `./init.sh`. No leas por adelantado lo que no te pide
  (divulgación progresiva).
- **Lee secciones, no archivos.** Cuando tu protocolo nombra una sección,
  localízala (`Grep` de `^#{2,3} ` con números de línea, o
  `graphify explain "<título>"`) y lee solo ese tramo con `Read` y
  `offset`/`limit`.
- **Tu feature llega en el prompt.** El leader copia en él la entrada de tu
  feature. No abras `feature_list.json` ni `feature_archive.json`; si te
  falta la entrada, búscala con `Grep` (`"name": "<name>"` con contexto), sin
  leer el archivo entero.

## 2. Mapa del repositorio

La columna «Memoria» clasifica cada archivo. **Inmediata**: los agentes la
leen en el flujo normal de una feature. **Largo plazo**: nadie la lee por
defecto; es **histórica** si guarda lo ya hecho y **de consulta** si es un
procedimiento o una guía de uso puntual. El spec y los informes de una
feature son memoria inmediata mientras está abierta y pasan al largo plazo
al cerrarla, sin moverse de su carpeta.

| Archivo / carpeta            | Qué contiene                                                                | Quién lo lee y cuándo | Memoria |
|------------------------------|-----------------------------------------------------------------------------|-----------------------|---------|
| `feature_list.json`          | La cola sin cerrar y hasta 20 features cerradas recientes | El leader, al empezar | Inmediata |
| `feature_archive.json`       | Las features cerradas más antiguas                                          | Nadie por defecto; lo valida `./init.sh` | Largo plazo, histórica |
| `progress/current.md`        | Feature en curso: plan, decisiones de la entrevista, bitácora               | Leader e implementer, al empezar | Inmediata |
| `progress/history.md`        | Bitácora append-only de features cerradas                                   | Solo si necesitas contexto histórico | Largo plazo, histórica |
| `progress/pending.md`        | Decisiones que esperan al usuario (`Q<n>`) y deuda o mejoras (`D<n>`)       | El leader | Inmediata |
| `specs/<feature>/`           | `requirements.md` + `design.md` + `tasks.md` (Kiro-style)                   | Implementer y reviewer de esa feature | Inmediata con la feature abierta; histórica al cerrarla |
| `progress/impl_<feature>.md`, `progress/review_<feature>.md` | Informes del implementer y del reviewer de esa feature | El leader y el reviewer; el implementer, si lo relanzan | Inmediata con la feature abierta; histórica al cerrarla |
| `docs/brief.md`              | Para qué existe el proyecto, para quién y qué NO debe hacer                 | Leader y spec_author, antes de un spec | Inmediata |
| `docs/architecture.md`       | Qué significa "hacer un buen trabajo" en este proyecto                      | Antes de diseñar, implementar o revisar | Inmediata |
| `docs/conventions.md`        | Reglas de estilo, nombres, estructura                                       | Antes de escribir o revisar código | Inmediata |
| `docs/verification.md`       | Cómo verificar que el trabajo funciona y trampas del entorno                | Antes de ejecutar el primer comando | Inmediata |
| `docs/lessons.md`            | Hasta 20 lecciones activas (decisiones, bugs y callejones sin salida), con tags | Su índice, antes de proponer un enfoque o de "arreglar" algo raro | Inmediata |
| `docs/lessons-archive.md`    | Las lecciones menos usadas, archivadas                                      | Nadie por defecto | Largo plazo, histórica |
| `docs/tags.md`               | Vocabulario cerrado de tags de features y lecciones                         | El leader, al poner tags | Inmediata |
| `CHECKPOINTS.md`             | Criterios objetivos de "estado final correcto"                              | El reviewer; el leader, C5 al cerrar | Inmediata |
| `docs/specs.md`              | Proceso SDD: EARS, los 3 archivos, trazabilidad, cuándo no aplica           | Las secciones que cite tu protocolo | Inmediata |
| `docs/graphify.md`           | Cómo consultar el grafo de contexto: comandos, qué da y qué no              | Si no te bastan los comandos de §3 | Largo plazo, de consulta |
| `docs/hooks.md`              | Qué hooks se disparan, qué bloquean y cómo reaccionar                       | Solo cuando te frene un mensaje `[harness]`: tu definición ya resume los tuyos | Largo plazo, de consulta |
| `docs/project-setup.md`      | Preparar el proyecto y retirar el ejemplo                                   | El leader, una vez por proyecto | Largo plazo, de consulta |
| `docs/ui-review.md`          | Cómo revisar una interfaz web                                               | El reviewer, solo si la feature toca UI | Largo plazo, de consulta |
| `graphify-out/`              | Grafo, wiki (`wiki/index.md`) e informe (`GRAPH_REPORT.md`) del repositorio | Nunca directamente: se consulta con `graphify` | — (herramienta de búsqueda) |
| `memory.sh`                  | Consulta la memoria por tags e ids: qué entradas conectan y dónde leerlas    | En los pasos que marca cada protocolo | — (herramienta de búsqueda) |
| `lint.sh`                    | Análisis estático del código: las reglas de los docs que se comprueban sin juicio | Nadie lo lee: lo ejecuta `./init.sh`, y cada fallo dice dónde, qué hacer y qué doc fija la regla | — (herramienta de verificación) |
| `.claude/agents/`            | Definiciones de `leader`, `spec_author`, `implementer` y `reviewer`         | Cada agente recibe la suya; no leas las demás | Inmediata (cada agente, la suya) |
| `src/`, `tests/`             | Código de la aplicación y tests automáticos                                 | Para implementar y verificar | — (el proyecto en sí) |
| `docs/example/`, `specs/example/`, `progress/example/` | Lo del proyecto de muestra: sus docs, specs, informes, bitácora y pendientes | Solo en features con `"example": true` | Largo plazo, de consulta (inmediata en una feature de ejemplo) |

## 3. Reglas comunes (no negociables)

- **Una sola feature a la vez.** No mezcles cambios de varias tareas.
- **Nada se da por terminado sin `./init.sh` en verde.**
- **Solo el leader cambia el `status` de una feature y solo el humano
  aprueba** un spec o un cambio. Un subagente no escribe en
  `feature_list.json` ni lanza a otro agente.
- **Docs del proyecto.** Las reglas del proyecto son `docs/brief.md`,
  `docs/architecture.md`, `docs/conventions.md`, `docs/verification.md`,
  `docs/lessons.md`, `docs/tags.md` y C3-C4 de `CHECKPOINTS.md`.
- **Cómo se cita una feature.** Como `F-<id>`, con el número de su campo
  `id` (`F-12`); añade su `name` si ayuda: `F-12 (export_csv)`. Así la
  citan las lecciones («Origen»), el historial, los informes y los
  mensajes, y una sola búsqueda la encuentra en todos.
- **Features de ejemplo.** Si tu feature lleva `"example": true`, todo lo
  suyo vive en la subcarpeta `example/` de cada área y no lees ni escribes
  lo del proyecto: sus docs son los gemelos de `docs/example/` (C3-C4 en
  `docs/example/checkpoints.md`), su spec está en `specs/example/<name>/` y
  sus informes, bitácora y pendientes en `progress/example/`. Donde tu
  definición nombra un doc del proyecto, `specs/<name>/` o un archivo de
  `progress/`, usa esa subcarpeta. Solo `progress/current.md` es único.
- **El ejemplo no se borra a mano.** El proyecto de muestra (features con
  `"example": true` y lo que cuelga de ellas) lo retira el leader de una
  vez, con la confirmación del humano (`docs/project-setup.md`).
- **Documenta lo que haces** en `progress/current.md` mientras trabajas, no
  al final.
- **No escribas estado que `./init.sh` ya sabe.** Tests en verde, features
  cerradas o cambios sin commitear se desfasan en cuanto alguien actúa fuera
  de la sesión. El estado real lo imprime `./init.sh` ("Estado del trabajo")
  y manda sobre lo escrito. En los `.md` va lo que los archivos no dicen
  solos: foco, decisiones, bloqueos y sus porqués.
- **Lo que se aprende no se queda en la feature.** Decisiones, bugs difíciles
  y enfoques descartados van a `docs/lessons.md`; la deuda y las decisiones
  pendientes, a `progress/pending.md`. Los escribe el leader al cerrar; el
  implementer aporta su sección "Lecciones" y el reviewer sus hallazgos.
- **No esquives un hook.** Si un mensaje `[harness]` te bloquea o te avisa,
  corrige la causa, o para y repórtalo. No busques otra vía para hacer lo
  mismo (por ejemplo, escribir en `src/` con Bash cuando el hook te impide
  hacerlo con `Edit`).
- **Deja el repositorio limpio**: sin archivos temporales, sin `print()` de
  debug y sin TODOs sin contexto (un TODO cita la feature, la deuda o la
  decisión que lo resuelve: `F-<id>`, `D<n>` o `Q<n>`). En el código que
  cubre, lo comprueba `lint.sh`.
- **Si no sabes algo, busca en `docs/`** antes de inventarlo.
- **Consulta el grafo antes de leer código.** Para saber dónde está algo, qué
  lo usa o qué se rompe al cambiarlo, empieza por `graphify explain "<símbolo>"`
  o `graphify query "<palabras clave>"` y lee solo las líneas que indique. No
  recorras archivos enteros para orientarte. Si graphify no está instalado,
  esta regla no aplica.
- **Consulta la memoria con `./memory.sh`.** La memoria de largo plazo no se
  lee entera. `./memory.sh F-<id>` da lo conectado con una feature por sus
  tags y sus ids; también acepta tags (`./memory.sh <tag>...`), una lección
  (`./memory.sh ADR-<n>`) o `tags`, para ver la lista. Devuelve dónde leer
  cada entrada: abre solo lo que te sirva y cita por su id lo que uses.
  Cuándo usarlo lo dice tu definición.

## 4. Flujo de trabajo (SDD)

```
pending → [entrevista] → [spec_author] → spec_ready → ⏸ HUMANO → in_progress → [implementer → reviewer] → ⏸ HUMANO → done
```

El leader conduce el flujo y para en las dos puertas (⏸). Tu parte está en tu
definición; el proceso completo, en `docs/specs.md`.

## 5. Si te bloqueas

- Relee la sección relevante de `docs/`.
- Si la herramienta no hace lo que esperas, **no inventes un workaround**:
  documenta el bloqueo donde indique tu definición y para.
