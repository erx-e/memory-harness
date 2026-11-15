# Bitácora histórica (append-only)

> Cada vez que se cierra una sesión, su resumen se añade aquí.
> No edites entradas anteriores. Solo añades al final.

> **Cómo usar este archivo.** «Ejemplo» es la bitácora real del proyecto de
> muestra (CLI de notas) y enseña cómo queda una entrada rellena. «Tu
> proyecto» trae la estructura vacía de una entrada. Añade tus entradas al
> final del archivo. No borres «Ejemplo» a mano: lo retira el leader junto
> con el resto del ejemplo.

---

## Ejemplo: CLI de notas

### 2026-04-20 — Bootstrap del proyecto
- **Agente:** humano (Martín)
- **Cambios:** estructura inicial del arnés (AGENTS.md, init.sh, feature_list.json, docs/).
- **Resultado:** entorno listo. `./init.sh` verde.

### 2026-04-22 — Feature 1: storage_layer
- **Agente:** implementador #1
- **Plan:** crear `src/storage.py` con `load()` / `save()` atómicos y tests.
- **Cambios:** `src/storage.py`, `tests/test_storage.py`.
- **Verificación:** `./init.sh` verde, 3 tests pasan.
- **Cierre:** feature 1 marcada `done`.

### 2026-04-23 — Feature 2: note_model
- **Agente:** implementador #2
- **Plan:** dataclass `Note` con `Note.new(title, body)` y serialización dict.
- **Cambios:** `src/notes.py`, `tests/test_notes.py`.
- **Verificación:** `./init.sh` verde.
- **Cierre:** feature 2 marcada `done`.

### 2026-04-25 — Feature 3: cli_add_list
- **Agente:** implementador #3, revisado por reviewer-agent.
- **Plan:** `src/cli.py` con argparse, comandos `add` y `list`.
- **Cambios:** `src/cli.py`, `tests/test_cli.py`.
- **Verificación:** `./init.sh` verde, 7 tests pasan.
- **Cierre:** feature 3 marcada `done`. Próximo: feature 4 (show/delete).

### 2026-04-27 — Feature 4: cli_show_delete
- **Agente:** Claude Opus 4.7
- **Plan:** añadir `cmd_show` y `cmd_delete` en `src/cli.py` con manejo de `NoteNotFound` (stderr + exit 1).
- **Cambios:** `src/cli.py` (subcomandos `show`/`delete` y captura de `NoteError` en `main`), `tests/test_cli.py` (4 tests nuevos: éxito y fallo de cada comando, captura de stderr).
- **Verificación:** `./init.sh` verde, 14 tests pasan.
- **Cierre:** feature 4 marcada `done`. Próximo: feature 5 (search).

### 2026-04-27 — Feature 5: cli_search
- **Agente:** Claude Opus 4.6
- **Plan:** añadir `cmd_search` en `src/cli.py` con búsqueda case-insensitive en título y body. Sin coincidencias → NoteNotFound (stderr + exit 1).
- **Cambios:** `src/cli.py` (subcomando `search` con `cmd_search`), `tests/test_cli.py` (3 tests nuevos: coincidencia, no-coincidencia, case-insensitivity).
- **Verificación:** `./init.sh` verde, 17 tests pasan.
- **Cierre:** feature 5 marcada `done`. Todas las features completadas.

### 2026-04-29 — Feature 6: cli_edit
- **Agente:** Claude Opus 4.7 (leader) → implementer → reviewer.
- **Plan:** añadir `cmd_edit` en `src/cli.py` con `--title` y `--body` opcionales; sin flags → `NoteError`; id inexistente → `NoteNotFound`.
- **Cambios:** `src/cli.py` (subcomando `edit` y `cmd_edit` que construye una nueva instancia `Note` preservando `id`/`created_at`), `tests/test_cli.py` (5 tests: cada flag, ambos juntos, id inexistente, ausencia de flags).
- **Verificación:** `./init.sh` verde, 22 tests pasan. Reviewer APPROVED (`progress/review_cli_edit.md`).
- **Cierre:** feature 6 marcada `done`. Todas las features del proyecto completadas.

### 2026-05-13 — Feature 7: cli_recent
- **Agente:** Claude Opus 4.7 (leader) → spec_author → implementer → reviewer.
- **Plan:** ejecutar las 8 tasks de `specs/cli_recent/tasks.md`: añadir `cmd_recent` y subparser `recent` en `src/cli.py`, cubrir R1–R7 con tests, validar trazabilidad y `./init.sh`.
- **Cambios:** `src/cli.py` (`cmd_recent` + subparser con `--limit`), `tests/test_cli.py` (5 tests nuevos: orden por defecto, límite custom, archivo vacío, límite 0, límite negativo; helper `_add_with_created_at`).
- **Verificación:** `./init.sh` verde, 27 tests pasan. Reviewer APPROVED (`progress/review_cli_recent.md`); trazabilidad en `progress/impl_cli_recent.md`.
- **Cierre:** feature 7 marcada `done`. Próximo: feature 8 (cli_count).

---

## Tu proyecto

Estructura de una entrada. Copia el bloque al final del archivo por cada
sesión cerrada y rellénalo:

```markdown
### AAAA-MM-DD — Feature <id>: <name>
- **Agente:** <quién trabajó, p. ej. leader → implementer → reviewer>
- **Plan:** <qué se quería conseguir, en una frase>
- **Cambios:** <archivos tocados y qué cambió en cada uno>
- **Verificación:** <resultado de `./init.sh` y veredicto, con la ruta del informe de revisión>
- **Aprobación del usuario:** <sí, AAAA-MM-DD; y los cambios que pidió antes de aprobar, si los hubo>
- **Cierre:** <estado final de la feature y próximo paso>
```
