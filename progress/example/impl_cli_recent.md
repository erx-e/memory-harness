# Implementación — cli_recent

> **Ejemplo.** Informe del implementer de la feature F-7 del proyecto de
> muestra (CLI de notas), la primera hecha con SDD. Muestra cómo queda un
> informe relleno con la estructura de `.claude/agents/implementer.md`. Se
> retira con el resto del ejemplo (`docs/project-setup.md`).

> F-7. Resumen de la implementación y trazabilidad `R<n> → test`.

## Resumen de cambios

- `src/cli.py`
  - Nueva función `cmd_recent(args)`: valida `args.limit > 0` (levanta
    `NoteError` si no), carga las notas con `storage.load()`, las ordena
    por `created_at` descendente, aplica el slice `[: args.limit]` e
    imprime cada una con el formato `<id>\t<created_at>\t<title>`.
  - Nuevo subparser `recent` en `build_parser()` con
    `--limit` (`type=int`, `default=5`) y `set_defaults(func=cmd_recent)`.
- `tests/test_cli.py`
  - Nuevo helper `_add_with_created_at`, que escribe una nota directamente
    en el archivo de notas con un `created_at` controlado.
  - 5 tests nuevos (ver "Trazabilidad").

No se han tocado `src/notes.py` ni `src/storage.py`, conforme al
`design.md`.

## Trazabilidad

- R1 → `test_recent_default_limit_orders_by_created_at_desc` (crea 7 notas;
  `recent` sin flags imprime exactamente 5 líneas)
- R2 → `test_recent_custom_limit` (crea 6 notas; `--limit 3` imprime 3
  líneas)
- R3 → `test_recent_default_limit_orders_by_created_at_desc` (timestamps en
  orden descendente y títulos de las 5 más recientes)
- R4 → `test_recent_custom_limit` (3 campos separados por tabulador; el
  segundo, ISO 8601)
- R5 → `test_recent_empty_outputs_nothing` (`code == 0`, `out == ""`,
  `err == ""`)
- R6 → `test_recent_invalid_limit_zero`, `test_recent_invalid_limit_negative`
- R7 → `test_recent_invalid_limit_zero`, `test_recent_invalid_limit_negative`
  (comparan el archivo de notas antes y después, en bytes y como objeto
  cargado)

## Verificación

- `./init.sh` ejecutado al final: 27 tests OK (5 nuevos + 22 preexistentes).

## Tasks

T1..T8 marcadas `[x]` en `specs/example/cli_recent/tasks.md`. Ninguna queda
en `[ ]`.

## Lecciones

- **Notas creadas seguidas comparten `created_at`.** Síntoma: los tests de
  orden temporal que crean notas con `add` no pueden comprobar el orden.
  Causa: `Note.new` guarda la fecha con `timespec="seconds"`
  (`src/notes.py:30`). Solución: el helper `_add_with_created_at`
  (`tests/test_cli.py:155`) fija las fechas.

## Estado

Listo para review. La feature sigue en `in_progress`.
