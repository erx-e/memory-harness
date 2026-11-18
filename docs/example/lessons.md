# Lecciones — Ejemplo: CLI de notas

> **Ejemplo.** Lecciones del proyecto de muestra (CLI de notas en Python).
> Valen solo para las features con `"example": true`; las del proyecto real
> van en `docs/lessons.md`.

## Callejones sin salida

- **CS-01** · No crees con `add` las notas de un test de orden temporal: se
  crean en el mismo segundo y el orden queda indefinido (Bug-01). Usa
  `_add_with_created_at` (F-7).

## Trampas

- **Bug-01** · `Note.new` guarda la fecha con `timespec="seconds"`
  (`src/notes.py:30`), así que notas creadas seguidas comparten `created_at`.
  Todo test que dependa del orden temporal fija las fechas con
  `_add_with_created_at` (`tests/test_cli.py:155`) (F-7).

## Decisiones que no se reabren sin motivo

- **ADR-01** · `recent` ordena con `sorted()[:limit]`, no con
  `heapq.nlargest`: el archivo de notas es pequeño y la claridad pesa más que
  O(n log k) (F-7).
- **ADR-02** · `--limit` lo valida el comando (`limit <= 0` → `NoteError`),
  no un `type=` propio de `argparse`: los errores de dominio pasan por el
  handler de `main()`. `lint.sh` rechaza un `type=` propio en `src/cli.py`
  (F-7).
