# Spec — F-7 (cli_recent)

> Muestra del formato de un spec. Con los tamaños actuales, `cli_recent` (un
> comando nuevo) sería `medium`: un plan en `progress/current.md`, sin spec.
> Se conserva como ejemplo de cómo se escribe uno.

## Objetivo

Comando `recent` que lista las N notas más recientes (5 por defecto),
ordenadas por `created_at` de la más reciente a la más antigua.

## Requisitos

- R1 — `recent` sin `--limit` imprime como máximo 5 notas, de la más reciente a la más antigua → test: `test_recent_default_limit_orders_by_created_at_desc`
- R2 — `recent --limit N` (N > 0) imprime como máximo N notas, cada una como `<id>\t<created_at>\t<title>`, el formato de `list` → test: `test_recent_custom_limit`
- R3 — Sin notas, sale con código 0 y no imprime nada → test: `test_recent_empty_outputs_nothing`
- R4 — Con `--limit` ≤ 0, sale con código distinto de 0, escribe un mensaje en stderr y no toca el archivo de notas → tests: `test_recent_invalid_limit_zero`, `test_recent_invalid_limit_negative`

## Diseño

- Archivos: `src/cli.py` → `cmd_recent(args) -> int` y el subparser `recent`, con `--limit` (`type=int`, `default=5`) (R1-R4); `tests/test_cli.py` → los tests y el helper `_add_with_created_at`, que fija la fecha de cada nota (R1).
- `cmd_recent` valida `limit <= 0` antes de cargar nada y lanza `NoteError`, que `main()` traduce a stderr y código 1 (ADR-02). Ordena con `sorted(…, key=created_at, reverse=True)[:limit]`: ISO 8601 ordena bien como texto. Imprime con el mismo formato que `cmd_list` y nunca llama a `storage.save()`.
- Sin contratos de datos nuevos: lee los campos `id`, `title` y `created_at` que ya guarda `storage`.
- Alternativa descartada: `heapq.nlargest`, más eficiente (O(n log k)) pero menos legible, para un archivo de notas pequeño (ADR-01).

## Tareas

- [x] T1 — `cmd_recent` y su subparser en `src/cli.py` (R1-R4)
- [x] T2 — Los cinco tests y `_add_with_created_at` en `tests/test_cli.py` (R1-R4)
