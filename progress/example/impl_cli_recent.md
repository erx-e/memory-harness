# Implementación — F-7 (cli_recent)

> **Ejemplo.** Informe del implementer de una feature del proyecto de muestra,
> con el formato de `.claude/agents/implementer.md`.

- Cambios: `src/cli.py` → `cmd_recent` y el subparser `recent` con `--limit` (`type=int`, `default=5`); `tests/test_cli.py` → cinco tests y el helper `_add_with_created_at`
- Tests: `test_recent_default_limit_orders_by_created_at_desc`, `test_recent_custom_limit`, `test_recent_empty_outputs_nothing`, `test_recent_invalid_limit_zero`, `test_recent_invalid_limit_negative`
- Verificación: `./init.sh` en verde, 27 tests (5 nuevos)
- Notas: notas creadas seguidas comparten `created_at` (`timespec="seconds"` en `src/notes.py:30`); los tests de orden fijan la fecha con `_add_with_created_at`. Va a lecciones (Bug-01, CS-01)
