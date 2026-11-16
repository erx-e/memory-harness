# Implementación — cli_edit

> **Ejemplo.** Informe del implementer de la feature #6 del proyecto de
> muestra (CLI de notas), anterior a SDD: no tiene spec, así que la
> trazabilidad y las tasks no aplican. Muestra cómo queda un informe sin
> spec con la estructura de `.claude/agents/implementer.md`. Se retira con
> el resto del ejemplo (`docs/project-setup.md`).

> Feature #6. Resumen de la implementación.

## Resumen de cambios

- `src/cli.py`
  - Nueva función `cmd_edit(args)`: carga las notas, busca la del `id` y la
    sustituye por una nueva instancia `Note(...)` con `id` y `created_at`
    preservados y solo los campos pasados cambiados; después
    `storage.save(notes)` e imprime `editada id=<id>`.
  - Sin `--title` ni `--body` lanza `NoteError("debes pasar --title y/o
    --body")`; con un id inexistente, `NoteNotFound`. Los dos llegan a
    `stderr` con código 1 por el handler de `main()`.
  - Nuevo subparser `edit` con `id` (entero posicional) y `--title` /
    `--body` opcionales con valor por defecto `None`, no `""`: la cadena
    vacía es un valor legítimo de `--body`.
- `tests/test_cli.py`
  - 5 tests nuevos: `test_edit_updates_only_title`,
    `test_edit_updates_only_body`, `test_edit_updates_both_fields`,
    `test_edit_missing_id_returns_error` y
    `test_edit_without_flags_returns_error`.

No se han tocado `src/notes.py` ni `src/storage.py`.

## Trazabilidad

No aplica: feature anterior a SDD, sin spec.

## Verificación

- `./init.sh` ejecutado al final: 22 tests OK (5 nuevos + 17 preexistentes).

## Tasks

No aplica: feature anterior a SDD, sin spec.

## Lecciones

Ninguna.

## Estado

Listo para review. La feature sigue en `in_progress`.
