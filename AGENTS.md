# AGENTS.md — Mapa y reglas comunes

> Lo carga `CLAUDE.md` en cada sesión y en cada subagente: no lo vuelvas a
> leer. Lo que solo afecta a un rol está en su definición
> (`.claude/agents/<rol>.md`).

## Mapa

| Archivo | Qué es | Quién lo lee |
|---|---|---|
| `feature_list.json` | La cola de features y las cerradas | El leader |
| `progress/current.md` | La feature en curso: decisiones, plan aprobado y estado | Leader e implementer |
| `progress/pending.md` | Decisiones que esperan al humano (`Q<n>`) y deuda (`D<n>`) | El leader, cuando hace falta |
| `specs/<name>/spec.md` | El spec de una feature `large` | Implementer y reviewer de esa feature |
| `progress/impl_<name>.md`, `progress/review_<name>.md` | Informes cortos del implementer y del reviewer | El leader |
| `docs/brief.md` | Para qué existe el proyecto y qué NO hace | Leader y spec_author |
| `docs/architecture.md`, `docs/conventions.md` | Las reglas del código | Implementer, reviewer y spec_author |
| `docs/verification.md` | Qué verificar según el tamaño del cambio, y las trampas del entorno | Implementer y reviewer |
| `docs/lessons.md` | Trampas, callejones sin salida y decisiones que no se reabren | Todos, antes de «arreglar» algo que parece raro |
| `docs/project-setup.md` | Preparar el proyecto y retirar el ejemplo | El leader, una vez por proyecto |
| `docs/graphify.md`, `docs/ui-review.md` | Guías puntuales: el grafo y el navegador | Solo si las necesitas |
| `init.sh`, `lint.sh` | `./init.sh`: verificación completa; `./init.sh --status`: rápida | Se ejecutan, no se leen |
| `src/`, `tests/` | El código de la aplicación y sus tests | Para implementar y verificar |
| `docs/example/`, `specs/example/`, `progress/example/` | El proyecto de muestra: sus docs, specs, informes y pendientes | Solo en features con `"example": true` |

## Reglas comunes

- **Una feature a la vez.** Solo el leader cambia su `status`, y solo el
  humano aprueba un plan, un spec o un cambio.
- **Solo el implementer escribe en `src/` y `tests/`.** El hook H1 lo impone
  para `Edit` y `Write`; con Bash está igual de prohibido.
- **Nada se da por terminado sin `./init.sh` en verde.**
- **Verificación proporcional** (`docs/verification.md`): un test por regla y
  su borde. Levantar la app, contenedores o un navegador, solo si el plan o el
  spec aprobado lo justifican.
- **Git:** nadie hace commit ni push si el humano no lo pide.
- **Repositorio limpio:** sin temporales ni salidas de debug, y cada TODO cita
  `F-<id>`, `D<n>` o `Q<n>` (lo comprueba `lint.sh`).
- **No esquives un hook.** Si un mensaje `[harness]` te frena, corrige la
  causa o para y repórtalo.
- **Cita las features como `F-<id>`** (`F-12`, o `F-12 (export_csv)`).
- **Features de ejemplo.** Si tu feature lleva `"example": true`, lo suyo vive
  en la subcarpeta `example/` de cada área: sus docs son los de
  `docs/example/`, su spec, `specs/example/<name>/spec.md`, y sus informes y
  pendientes, los de `progress/example/`. Solo `progress/current.md` es único.
  El ejemplo lo retira el leader de una vez, con la confirmación del humano
  (`docs/project-setup.md`).
- **Para orientarte**, grep y lectura directa. El grafo (`graphify query` o
  `graphify explain`) ayuda en preguntas amplias sobre el código
  (`docs/graphify.md`).

## Flujo

```
pending → [entrevista y tamaño] → plan (spec si es large) → ⏸ HUMANO → in_progress → [implementer (+ reviewer si es large)] → ⏸ HUMANO → done
```

Una feature trivial no lleva entrevista ni plan: implementer → ⏸ HUMANO. El
detalle lo lleva el leader (`.claude/agents/leader.md`).

## Hooks

- **H1:** `Edit` y `Write` en `src/` y `tests/`, solo el implementer.
- **Al iniciar la sesión:** `./init.sh --status` da el estado real del
  proyecto, que manda sobre lo escrito en `progress/`.
- **Al terminar cada turno:** `./init.sh --status`. Si falla, no se puede
  terminar hasta resolverlo, o explicárselo al humano.
