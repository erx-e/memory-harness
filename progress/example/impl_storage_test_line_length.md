# Implementación — F-12 (storage_test_line_length)

> **Ejemplo.** Informe del implementer de una feature `trivial` del proyecto
> de muestra: sin plan ni spec, y sin reviewer.

- Cambios: `tests/test_storage.py` → en `test_save_then_load_roundtrip`, el dict de la línea 24 (104 caracteres) pasa a una clave por línea, como `existing.append({…})` en `tests/test_cli.py:158`
- Tests: ninguno nuevo; el cambio es de formato
- Verificación: `./init.sh` en verde; ninguna línea de `tests/test_storage.py` pasa de 100 caracteres
- Notas: ninguna
