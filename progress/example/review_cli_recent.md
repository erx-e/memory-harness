# Review — feature 7

> **Ejemplo.** Revisión de la feature #7 del proyecto de muestra (CLI de
> notas), la primera hecha con SDD. Muestra cómo queda un veredicto relleno
> con la estructura de `.claude/agents/reviewer.md`. Lo descartado y las
> recomendaciones son los que el leader registró después como `Q1` y `D1`
> en `progress/example/pending.md`. Se retira con el resto del ejemplo
> (`docs/project-setup.md`).

**Veredicto:** APPROVED

## Trazabilidad requirements ↔ tests
- R1: [x] cubierto por `test_recent_default_limit_orders_by_created_at_desc`
  (`tests/test_cli.py:166`; crea 7 notas, espera exactamente 5 líneas)
- R2: [x] cubierto por `test_recent_custom_limit` (`tests/test_cli.py:180`;
  crea 6 notas, `--limit 3`, espera 3 líneas)
- R3: [x] cubierto por `test_recent_default_limit_orders_by_created_at_desc`
  (valida `timestamps == sorted(reverse=True)` y el orden de títulos
  `nota-6..nota-2`)
- R4: [x] cubierto por `test_recent_custom_limit` (3 campos separados por
  tab, primero numérico, segundo ISO 8601)
- R5: [x] cubierto por `test_recent_empty_outputs_nothing`
  (`tests/test_cli.py:195`; `code == 0`, `out == ""`, `err == ""`)
- R6: [x] cubierto por `test_recent_invalid_limit_zero`
  (`tests/test_cli.py:201`) y `test_recent_invalid_limit_negative`
  (`tests/test_cli.py:215`)
- R7: [x] cubierto por los mismos dos tests (comparan `before/after` con
  `storage.load` y los bytes exactos del archivo)

## Tasks completas
- T1: [x]
- T2: [x]
- T3: [x]
- T4: [x]
- T5: [x]
- T6: [x]
- T7: [x]
- T8: [x]

## Checkpoints
- C1: [x]
- C2: [x]
- C3: [x]
- C4: [x]
- C6: [x]

## Fortalezas
- `src/cli.py:59` — `cmd_recent` vive en la capa de interfaz, solo usa
  `storage.load()` y no toca `src/notes.py` ni `src/storage.py`, como fija
  `design.md`.
- `src/cli.py:132` — el error de `--limit` es un `NoteError` que llega a
  `stderr` con código 1 por el handler de `main()` ya existente; no hay
  `print()` de errores ni `None` como señal de fallo.
- `tests/test_cli.py:201` y `:215` — R7 se comprueba con los bytes del
  archivo, no solo con el objeto cargado.
- `tests/test_cli.py:155` — `_add_with_created_at` fija las fechas en vez de
  confiar en el reloj, lo que hace determinista el test de orden.
- Tests sobre `tempfile.TemporaryDirectory()` (`tests/test_cli.py:16`), sin
  mocks de filesystem, y con nombres que describen el comportamiento.

## Hallazgos

### Críticos (bloquean)
- Ninguno.

### Importantes (bloquean)
- Ninguno.

### Menores (no bloquean)
- Ninguno.

## Descartado por estar fuera del spec
- `recent --limit` mayor que el total de notas devuelve todas sin avisar —
  ningún requirement lo cubre y `design.md` › Riesgos lo acepta; si debe
  avisar lo decide el humano.

## Recomendaciones
- `src/cli.py:23`, `:55` y `:67` — la línea de salida
  `<id>\t<created_at>\t<title>` se repite ya en `list`, `search` y
  `recent`. `design.md` › Formato de salida aplazó extraer
  `_format_row(note: dict) -> str` hasta el tercer uso, y este es el tercero.

## Cambios requeridos (si aplica)
- Ninguno.
