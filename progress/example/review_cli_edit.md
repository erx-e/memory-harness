# Review — F-6

> **Ejemplo.** Revisión de la feature F-6 del proyecto de muestra (CLI de
> notas), anterior a SDD: sin spec, se revisa contra la `description` y el
> `acceptance` de la feature. Muestra cómo queda un veredicto sin spec con
> la estructura de `.claude/agents/reviewer.md`. Se retira con el resto del
> ejemplo (`docs/project-setup.md`).

**Veredicto:** APPROVED

## Trazabilidad requirements ↔ tests
No aplica: feature anterior a SDD, sin spec.

## Tasks completas
No aplica: feature anterior a SDD, sin spec.

## Checkpoints
- C1: [x]
- C2: [x]
- C3: [x]
- C4: [x]
- C6: [x]

## Fortalezas
- Cada criterio del `acceptance` tiene su test:
  - solo `--title` → `test_edit_updates_only_title` (`tests/test_cli.py:111`;
    comprueba que `body` se conserva)
  - solo `--body` → `test_edit_updates_only_body` (`tests/test_cli.py:120`)
  - los dos flags → `test_edit_updates_both_fields` (`tests/test_cli.py:129`)
  - id inexistente → `test_edit_missing_id_returns_error`
    (`tests/test_cli.py:138`; `code != 0`, `out == ""`, `"99" in err`)
  - sin flags → `test_edit_without_flags_returns_error`
    (`tests/test_cli.py:145`; además comprueba que la nota no cambió en
    disco)
- `src/cli.py:77` — la nota editada es una instancia nueva de `Note` con
  `id` y `created_at` preservados: respeta la inmutabilidad de `Note`.
- `src/cli.py:132` — los dos errores (`NoteError` y su subclase
  `NoteNotFound`) los traduce el handler de `main()` a `stderr` y código 1.
- El cambio no toca `src/notes.py` ni `src/storage.py` ni añade
  dependencias; los tests usan `tempfile.TemporaryDirectory()` y solo
  parchean la constante `DEFAULT_NOTES_PATH`.

## Hallazgos

### Críticos (bloquean)
- Ninguno.

### Importantes (bloquean)
- Ninguno.

### Menores (no bloquean)
- Ninguno.

## Descartado por estar fuera del spec
(vacío)

## Recomendaciones
- Ninguna.

## Cambios requeridos (si aplica)
- Ninguno.
