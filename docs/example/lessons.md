# Lecciones — Ejemplo: CLI de notas

> **Ejemplo.** Lecciones del proyecto de muestra (CLI de notas en Python).
> Valen solo para las features con `"example": true`; las del proyecto real
> van en `docs/lessons.md`, que explica cómo se lee y se escribe este
> registro. Sus tags son los de `docs/example/tags.md`.

## Índice

| Id     | En una línea                                                                   | Tags                           | Afecta a                                         |
|--------|--------------------------------------------------------------------------------|--------------------------------|--------------------------------------------------|
| ADR-01 | `recent` ordena con `sorted()[:limit]`, no con `heapq.nlargest`                | `cli`, `fechas`                | `src/cli.py` › `cmd_recent`                      |
| ADR-02 | `--limit` lo valida el comando, no `argparse`                                  | `cli`, `validacion`, `errores` | `src/cli.py` › comandos con flags numéricos      |
| Bug-01 | Notas creadas seguidas comparten `created_at`: los tests de orden fijan fechas | `tests`, `fechas`              | `tests/test_cli.py`, `src/notes.py` › `Note.new` |
| CS-01  | Crear las notas con `add` en tests de orden temporal                           | `tests`, `fechas`              | `tests/test_cli.py`                              |

## Callejones sin salida

**No vuelvas a intentar esto:**

#### CS-01 · Crear las notas con el comando `add` en tests de orden temporal

- **Por qué falla:** se crean en el mismo segundo y el orden queda
  indefinido (Bug-01).
- **En su lugar:** usa `_add_with_created_at`.
- **Origen:** F-7 (`progress/example/impl_cli_recent.md`).

## Decisiones

#### ADR-01 · `sorted()[:limit]` en vez de `heapq.nlargest`

- **Contexto:** `recent` necesita las N notas más nuevas.
- **Decisión:** ordenar la lista completa y cortar.
- **Coste aceptado:** O(n log n) en vez de O(n log k).
- **Descartado:** `heapq.nlargest`. El archivo de notas es pequeño y el resto
  de `cli.py` usa `sorted` y comprensiones simples; la claridad pesa más.
- **Origen:** F-7 (`specs/example/cli_recent/design.md`).

#### ADR-02 · La validación de `--limit` la hace el comando, no `argparse`

- **Contexto:** `type=int` acepta negativos y los errores de `argparse` salen
  en inglés y con su propio formato.
- **Decisión:** validar `limit <= 0` en `cmd_recent` y lanzar `NoteError`.
- **Coste aceptado:** una comprobación manual por comando.
- **Descartado:** un `type` personalizado en `argparse`. Rompería la regla de
  que los errores de dominio pasan por el handler de `main()`.
- **Origen:** F-7 (`specs/example/cli_recent/design.md`).

## Bugs resueltos

#### Bug-01 · Notas creadas seguidas comparten `created_at`

- **Síntoma:** un test que crea varias notas con `add` no puede comprobar el
  orden por fecha: todas salen con la misma marca de tiempo.
- **Causa:** `Note.new` guarda la fecha con `timespec="seconds"`
  (`src/notes.py:30`).
- **Solución:** el helper de test `_add_with_created_at`
  (`tests/test_cli.py:155`) escribe notas con una fecha controlada.
- **Lección:** cualquier test que dependa del orden temporal debe fijar las
  fechas, no confiar en el reloj.
- **Origen:** F-7 (`progress/example/impl_cli_recent.md`).
