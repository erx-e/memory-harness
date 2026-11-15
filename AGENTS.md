# AGENTS.md — Mapa de navegación para agentes de IA

> Este archivo es el **punto de entrada** para cualquier agente que trabaje en este
> repositorio. NO es una biblia de reglas: es un **mapa**. Lee solo lo que
> necesites cuando lo necesites (divulgación progresiva).

---

## 1. Antes de empezar (obligatorio)

1. Ejecuta `./init.sh` y verifica que termina sin errores. Si falla, **para**
   y resuelve el entorno antes de tocar código.
2. Lee `progress/current.md` para entender en qué estado quedó la última sesión.
3. Lee `feature_list.json`. Toda feature nueva (`"sdd": true`) pasa por
   **Spec Driven Development** — ver `docs/specs.md` y §4 de este archivo.
4. Lee `docs/specs.md` antes de tocar cualquier spec o feature `sdd: true`.

## 2. Mapa del repositorio

| Archivo / carpeta            | Qué contiene                                                                | Cuándo leerlo |
|------------------------------|-----------------------------------------------------------------------------|---------------|
| `feature_list.json`          | Lista de tareas con estado (`pending` / `spec_ready` / `in_progress` / `done` / `blocked`) | Siempre, al empezar |
| `progress/current.md`        | Estado de la sesión actual                                                  | Siempre, al empezar |
| `progress/history.md`        | Bitácora append-only de sesiones anteriores                                 | Si necesitas contexto histórico |
| `progress/pending.md`        | Decisiones que esperan al usuario (`Q<n>`) y deuda o mejoras (`D<n>`)       | Para saber qué falta además de las features |
| `docs/brief.md`              | Para qué existe el proyecto, para quién y qué NO debe hacer                 | Antes de redactar un spec |
| `docs/lessons.md`            | Decisiones, bugs difíciles resueltos y callejones sin salida                | Antes de proponer un enfoque o de "arreglar" algo raro |
| `specs/<feature>/`           | `requirements.md` + `design.md` + `tasks.md` (Kiro-style)                   | Antes de implementar cualquier feature con `"sdd": true` |
| `docs/architecture.md`       | Qué significa "hacer un buen trabajo" en este proyecto                      | Antes de implementar |
| `docs/conventions.md`        | Reglas de estilo, nombres, estructura                                       | Antes de escribir código |
| `docs/specs.md`              | Proceso SDD: EARS notation, los 3 archivos, puerta de aprobación humana     | Antes de redactar o leer un spec |
| `docs/verification.md`       | Cómo verificar que tu trabajo funciona (incluye trazabilidad requirements)  | Antes de declarar una tarea como `done` |
| `docs/graphify.md`           | Cómo consultar el grafo de contexto: comandos, qué da y qué no              | Antes de leer o buscar código |
| `graphify-out/`              | Grafo del repositorio (lo regenera `./init.sh`; no se edita a mano)         | Nunca directamente: se consulta con `graphify` |
| `graphify-out/wiki/index.md` | Wiki del proyecto: un artículo por grupo de código                          | Para entender una zona del proyecto sin leer su código |
| `graphify-out/GRAPH_REPORT.md` | Informe de arquitectura: piezas centrales, grupos, ciclos de imports      | Para una visión del proyecto entero |
| `CHECKPOINTS.md`             | Criterios objetivos de "estado final correcto"                              | Para auto-evaluarte |
| `.claude/agents/`            | Definiciones de subagentes (`leader`, `spec_author`, `implementer`, `reviewer`) | Si orquestas trabajo |
| `src/`                       | Código de la aplicación                                                     | Para implementar |
| `tests/`                     | Tests automáticos                                                           | Para verificar |

## 3. Reglas duras (no negociables)

- **Una sola feature a la vez.** No mezcles cambios de varias tareas en la misma sesión.
- **No declares una tarea `done` sin pruebas verdes.** Ejecuta `./init.sh` y
  asegúrate de que el bloque de tests pasa al 100%.
- **Ninguna feature se cierra sin revisión.** `./init.sh` falla si una
  feature `done` (con SDD, o que no sea del ejemplo) no tiene
  `progress/review_<name>.md` con `**Veredicto:** APPROVED`.
- **Ninguna feature real se cierra sin la aprobación del humano.**
  `./init.sh` falla si una feature `done` que no es del ejemplo no tiene,
  en su entrada de `progress/history.md`, la línea
  `- **Aprobación del usuario:** sí`. Solo el humano da esa aprobación.
- **No saltes la fase de spec.** Toda feature con `"sdd": true` debe pasar
  por `spec_author` y obtener aprobación humana antes de tocar código.
- **No saltes las puertas de aprobación humana.** El leader detiene el flujo
  en `spec_ready` y espera. Y tras el `APPROVED` del reviewer vuelve a parar:
  solo el humano da la aprobación final que permite marcar `done`.
- **Ninguna feature real empieza con los docs vacíos.** Las reglas de
  «Ejemplo» valen solo para las features de ejemplo; una feature real se rige
  solo por «Tu proyecto». Antes del primer spec, el leader deja sin huecos
  `<...>` esa parte de `docs/architecture.md`, `docs/conventions.md`,
  `docs/verification.md` y C3 y C4 de `CHECKPOINTS.md`; lo que no esté
  decidido se escribe como «Sin decidir», no se deja el hueco. `./init.sh`
  falla si una feature real pasa de `pending` con huecos.
- **No borres el ejemplo a mano.** El proyecto de muestra (features con
  `"example": true` y todo lo que cuelga de ellas) lo retira el leader de una
  vez, con tu confirmación: antes de la primera feature real si tu proyecto
  ya tiene código o no usa Python, y al cerrarla si empieza de cero en
  Python. La parte «Ejemplo» de un doc solo se borra si su parte «Tu
  proyecto» ya está rellena.
- **Documenta lo que haces** en `progress/current.md` mientras trabajas, no al final.
- **No escribas estado que `./init.sh` ya sabe.** Tests en verde, features
  cerradas o cambios sin commitear se desfasan en cuanto alguien actúa fuera
  de la sesión. El estado real lo imprime `./init.sh` ("Estado del trabajo"),
  y un hook lo muestra al iniciar cada sesión; ese estado manda sobre lo
  escrito. En los `.md` va lo que los archivos no dicen solos: foco,
  decisiones, bloqueos y sus porqués.
- **Lo que se aprende no se queda en la feature.** Decisiones, bugs difíciles
  y enfoques descartados van a `docs/lessons.md`; la deuda y las decisiones
  pendientes, a `progress/pending.md`. Los escribe el leader al cerrar; el
  implementer aporta su sección "Lecciones" y el reviewer sus hallazgos.
- **Deja el repositorio limpio** antes de cerrar la sesión (ver §5).
- **Si no sabes algo, busca en `docs/`** antes de inventarlo.
- **Consulta el grafo antes de leer código.** Para saber dónde está algo, qué
  lo usa o qué se rompe al cambiarlo, empieza por `graphify explain "<símbolo>"`
  o `graphify query "<palabras clave>"` y lee solo las líneas que indique. No
  recorras archivos enteros para orientarte. Detalle en `docs/graphify.md`.
  Si graphify no está instalado, esta regla no aplica.

## 4. Flujo de trabajo (SDD)

```
pending → [spec_author] → spec_ready → ⏸ HUMANO → in_progress → [implementer → reviewer] → ⏸ HUMANO → done
```

1. El leader detecta la primera feature `pending` con `"sdd": true`.
2. El leader lanza `spec_author`, que crea
   `specs/<name>/{requirements,design,tasks}.md` y marca el status como
   `spec_ready`.
3. **Pausa.** El humano lee el spec en `specs/<name>/` y aprueba (o pide cambios).
4. Una vez aprobado, el leader cambia el status a `in_progress` y lanza `implementer`.
5. El implementer ejecuta `tasks.md` una a una, marcándolas `[x]`.
6. El reviewer verifica trazabilidad `R<n>` ↔ test y tasks completas;
   aprueba o rechaza. Si rechaza, el implementer corrige y otro reviewer
   vuelve a revisar, como máximo tres rondas; si la tercera no aprueba, el
   leader para y plantea el bloqueo al humano. Un hook impide la cuarta
   ronda hasta que el humano responde.
7. Si aprueba, el leader **para** y pide al humano la aprobación final del
   cambio.
8. Con la aprobación del humano, el leader marca `done` y mueve el resumen a
   `progress/history.md`. Si el humano pide cambios, vuelven al implementer
   y al reviewer, y el leader pide de nuevo la aprobación.

## 5. Cierre de sesión (lifecycle)

Antes de terminar (el cierre lo hace el leader, nunca un subagente):

1. Ejecuta `./init.sh` — todo verde.
2. Si el reviewer emitió `APPROVED` en `progress/review_<feature>.md` **y**
   el humano dio su aprobación final: marca `status: "done"` en
   `feature_list.json`. Sin las dos la feature sigue en `in_progress`.
3. Mueve el resumen de `progress/current.md` al final de `progress/history.md`.
4. Vacía `progress/current.md` dejando solo la plantilla.
5. No dejes archivos temporales, ni `print()` de debug, ni TODOs sin contexto.

## 6. Si te bloqueas

- Relee la sección relevante de `docs/`.
- Si la herramienta no hace lo que esperas, **no inventes un workaround**:
  documenta el bloqueo en `progress/current.md` y para la sesión.
