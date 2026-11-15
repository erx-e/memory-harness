# ejemplo-harness — Notes CLI

Proyecto de ejemplo que demuestra los principios de **Harness Engineering**
aplicados a un CLI minimalista de notas en Python.

> El código de la aplicación es deliberadamente simple. Lo importante de
> este repo no es **qué** hace, sino **cómo** está estructurado para que un
> agente de IA pueda trabajar sobre él de forma autónoma y verificable.

## Cómo está organizado el arnés

| Pilar                                  | Manifestación en este repo                                                       |
|----------------------------------------|----------------------------------------------------------------------------------|
| **1. El repositorio ES el sistema**    | `AGENTS.md`, `init.sh`, `feature_list.json`, `specs/`, `progress/`, `docs/`      |
| **2. Orquestación multi-agente**       | `.claude/agents/leader.md`, `spec_author.md`, `implementer.md`, `reviewer.md`    |
| **3. Spec Driven Development**         | `docs/specs.md`, EARS notation, aprobación humana del spec y del cambio final    |
| **4. Supervisión y mejora**            | `CHECKPOINTS.md`, hooks en `.claude/settings.json`, `tests/`                     |
| **5. Contexto bajo demanda**           | Grafo del repo con graphify (`graphify-out/`, `docs/graphify.md`): los agentes preguntan dónde está cada cosa en vez de leer todo el código |

## Para empezar

```bash
./init.sh
```

Si todo está verde, abre `AGENTS.md` y sigue desde ahí.

`init.sh` también construye el grafo de contexto si tienes
[graphify](https://github.com/Graphify-Labs/graphify) instalado
(`uv tool install graphifyy`). Es opcional: sin él verás un aviso y el arnés
funciona igual, pero los agentes tendrán que leer más código para orientarse.

## Usar este repo como plantilla

Los `.md` del arnés que dependen del proyecto tienen dos partes: **«Ejemplo»**,
con el contenido real del CLI de notas, y **«Tu proyecto»**, con la misma
estructura vacía. El ejemplo enseña cómo se rellena; la estructura vacía es
por donde continúas.

| Archivo                 | Qué rellenas en «Tu proyecto»                              |
|-------------------------|------------------------------------------------------------|
| `docs/brief.md`         | Visión, usuarios, qué sí hace y qué no (te lo pregunta el leader) |
| `docs/architecture.md`  | Principios (el primero, la dirección de dependencias entre capas), stack y dependencias, estructura de carpetas, flujo de datos y qué no hacer |
| `docs/conventions.md`   | Estilo, nombres, estructura de archivo, tests y errores    |
| `docs/verification.md`  | Niveles de verificación, anti-patrones y trampas del entorno |
| `CHECKPOINTS.md`        | Los checks de C3 y C4 (C1, C2, C5 y C6 valen para todo proyecto) |
| `progress/history.md`   | Tu bitácora, con la estructura de entrada que trae         |
| `docs/lessons.md`       | Decisiones, bugs resueltos y callejones sin salida (lo escribe el leader) |
| `progress/pending.md`   | Decisiones que te esperan y deuda detectada (lo escribe el leader) |

Las reglas de «Ejemplo» valen solo para las features de ejemplo; las tuyas se
rigen solo por «Tu proyecto». Por eso, antes de tu primera feature, el leader
rellena contigo esa parte de `docs/architecture.md`, `docs/conventions.md`,
`docs/verification.md` y de C3 y C4 en `CHECKPOINTS.md`. Lo que aún no esté
decidido se escribe como «Sin decidir», no se deja el hueco `<...>`:
`./init.sh` falla si una feature tuya avanza con huecos. No borres el ejemplo
a mano.

**Retirada del ejemplo.** Las features del proyecto de muestra llevan
`"example": true` en `feature_list.json`. Cuando añades tus propias features,
el leader las trabaja antes que las de ejemplo. El leader te enseña la lista
de todo lo que pertenece al ejemplo y, si confirmas, lo retira de una vez:
features, specs, informes, código y tests, la sección «Ejemplo» de
`progress/history.md` y las de los docs cuya parte «Tu proyecto» ya esté
rellena. Cuándo lo hace:

- **Antes de tu primera feature**, si tu proyecto ya tiene código o no usa
  Python: ahí el ejemplo no puede convivir con él.
- **Al cerrar tu primera feature** (con tu aprobación final), si empiezas de
  cero en Python: hasta entonces sirve de referencia.

Los ejemplos de `docs/specs.md` los sustituye por fragmentos de tu primer
spec cuando lo cierras.

Los informes de `progress/` (`impl_cli_edit.md`, `review_cli_edit.md`,
`impl_cli_recent.md`, `review_cli_recent.md`, `explore_*.md`) son ejemplos
rellenos. Su estructura vacía está en `.claude/agents/implementer.md` y
`.claude/agents/reviewer.md`, que es donde la leen los agentes.
`progress/current.md` ya es una estructura vacía.

`specs/cli_recent/` es el spec de ejemplo, completo y ya implementado. La
estructura de un spec nuevo y sus reglas están en `docs/specs.md`.

Lo que no es `.md` sigue siendo el ejemplo y también hay que sustituirlo:
`src/`, `tests/`, las features de `feature_list.json` y los comandos de Python
de `init.sh` y `.claude/settings.json`.

El reviewer usa la skill `requesting-code-review` de
[obra/superpowers](https://github.com/obra/superpowers) (MIT), incluida en
`.claude/skills/requesting-code-review/` con su licencia, así que viaja con
el repo y no hay que instalarla aparte.

Plantilla derivada de
[betta-tech/ejemplo-harness-subagentes](https://github.com/betta-tech/ejemplo-harness-subagentes)
y, para el flujo SDD, de
[betta-tech/harness-sdd](https://github.com/betta-tech/harness-sdd).

## Para usar la app (humanos)

```bash
python3 -m src.cli add "comprar pan" --body "y leche"
python3 -m src.cli list
```

## Probarlo tú mismo con Claude Code

Si te descargas el repo y abres Claude Code en la raíz, ya estás dentro del
arnés: `.claude/settings.json` arranca la sesión como el agente `leader`
(orquesta, no edita código), `CLAUDE.md` refuerza ese rol y `docs/specs.md`
impone el flujo Spec Driven Development.

Receta rápida:

1. `./init.sh` — debe terminar verde.
2. Abre `feature_list.json` y deja al menos una feature con
   `status: "pending"` y `"sdd": true`. La #8 `cli_count` ya está así.
3. Lanza Claude Code en la raíz del repo: `claude`.
4. Pídele: **«implementa la siguiente feature pendiente»**.

Lo que ocurre, en dos fases:

**Fase 1 — Spec.** El `leader` lanza un `spec_author` que escribe
`specs/<feature>/{requirements.md, design.md, tasks.md}` y deja la feature
en `spec_ready`. Luego **para y te pide aprobación**.

Tú lees los tres archivos en tu editor:

- `requirements.md` — qué debe hacer la feature, en EARS estricto.
- `design.md` — decisiones técnicas antes de escribir código.
- `tasks.md` — checklist de pasos discretos a ejecutar.

Cuando estés conforme, dices al chat «aprobado» (o pides cambios).

**Fase 2 — Código.** El `leader` transiciona la feature a `in_progress` y
lanza `implementer` (sigue las tasks una a una marcándolas `[x]`) y
después `reviewer` (verifica trazabilidad `R<n>` ↔ test y todas las tasks
completas). Si el reviewer rechaza, el implementer corrige y se revisa de
nuevo, como máximo tres rondas; si no converge, el `leader` para y te explica
el bloqueo. Si el reviewer aprueba, el `leader` **para otra vez y te pide la
aprobación final**, con un resumen de los cambios sacado de los informes del
implementer y del reviewer: revisas el cambio y dices «aprobado» para cerrar la
feature (o pides cambios, que vuelven al implementer y al reviewer).

Dónde queda la traza de cada subagente:

| Archivo                                  | Quién lo escribe   | Qué contiene                                                  |
|------------------------------------------|--------------------|---------------------------------------------------------------|
| `specs/<feature>/requirements.md`        | spec_author        | EARS requirements numeradas `R1`, `R2`, ...                  |
| `specs/<feature>/design.md`              | spec_author        | Decisiones técnicas + alternativa descartada                  |
| `specs/<feature>/tasks.md`               | spec_author        | Checklist; el implementer la va marcando `[x]`                |
| `progress/current.md`                    | leader             | Plan vivo de la sesión                                        |
| `progress/impl_<feature>.md`             | implementer        | Archivos tocados + mapa `R<n> → test` + output de los tests   |
| `progress/review_<feature>.md`           | reviewer           | Checklist contra `docs/`, `specs/<feature>/` y `CHECKPOINTS.md` |
| `feature_list.json`                      | spec_author, leader | `pending` → `spec_ready` (spec_author) → `in_progress` → `done` (leader, tras tu aprobación) |
| `progress/history.md`                    | leader             | Resumen append-only al cerrar la sesión                       |

Abre `specs/` y `progress/` en tu editor mientras Claude trabaja: cada
informe aparece en cuanto el subagente termina. Esa es la regla
anti-teléfono-descompuesto en acción — el contenido no circula por chat,
vive en disco y queda versionado.

## Estructura

```
.
├── AGENTS.md              # Mapa para agentes (divulgación progresiva)
├── CHECKPOINTS.md         # Criterios de "estado final correcto"
├── feature_list.json      # Alcance: una feature a la vez
├── init.sh                # Verificación e inicialización
├── specs/<feature>/       # Spec por feature (Kiro-style)
│   ├── requirements.md    # EARS notation
│   ├── design.md          # Decisiones técnicas
│   └── tasks.md           # Checklist de implementación
├── progress/
│   ├── current.md         # Sesión activa (estado vivo)
│   ├── history.md         # Bitácora append-only
│   └── pending.md         # Decisiones pendientes del usuario y deuda
├── docs/
│   ├── architecture.md    # Qué significa "buen trabajo"
│   ├── conventions.md     # Estilo, nombres, errores
│   ├── specs.md           # Proceso SDD: EARS, 3 archivos, aprobación humana
│   ├── verification.md    # Cómo demostrar que funciona
│   ├── brief.md           # Para qué existe el proyecto y qué no debe hacer
│   ├── lessons.md         # Decisiones, bugs resueltos, callejones sin salida
│   └── graphify.md        # Cómo consultar el grafo de contexto
├── .claude/
│   ├── agents/            # leader, spec_author, implementer, reviewer
│   └── settings.json      # Hooks que automatizan la verificación
├── src/
│   ├── storage.py         # Persistencia atómica (JSON)
│   ├── notes.py           # Modelo de dominio
│   └── cli.py             # Interfaz argparse
└── tests/
    ├── test_storage.py
    ├── test_notes.py
    └── test_cli.py
```

## Aprendizajes que ilustra este proyecto

- **Divulgación progresiva** en `AGENTS.md`: el agente no recibe todas las
  reglas de golpe, recibe un mapa para buscarlas bajo demanda.
- **Una feature a la vez** validado por `init.sh` (rechaza más de un
  `in_progress` en `feature_list.json`).
- **Spec Driven Development** estilo Kiro: requirements (EARS) → design →
  tasks → code, con una puerta de aprobación humana antes de tocar código
  y otra antes de dar el cambio por terminado.
- **Estado en disco**, no en chat: `specs/`, `progress/current.md` y
  `history.md` sobreviven a reinicios y context windows reventadas.
- **Verificación ejecutable**: `init.sh` corre los tests reales y valida
  la presencia de specs para toda feature SDD.
- **Trazabilidad obligatoria**: cada `R<n>` se mapea a un test concreto;
  el reviewer rechaza si falta.
- **Patrón Leader-Spec-Implementer-Reviewer**: el leader no implementa,
  el spec_author no codifica, el implementer no se autoaprueba, el
  reviewer no edita código.
- **Anti teléfono-descompuesto**: los subagentes escriben sus resultados
  en archivos y solo devuelven una referencia ligera.
