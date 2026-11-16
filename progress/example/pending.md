# Pendientes — Ejemplo: CLI de notas

> **Ejemplo.** Decisiones pendientes y deuda del proyecto de muestra (CLI de
> notas en Python). Aquí va lo que dejan abierto las features con
> `"example": true`; lo del proyecto real va en `progress/pending.md`, que
> explica cómo se usa este registro.

## Decisiones pendientes del usuario

### Q1 · ¿`recent --limit` mayor que el total de notas debe avisar?

- **Contexto:** hoy devuelve todas las notas sin decir nada. Ningún
  requirement lo cubre (`specs/example/cli_recent/design.md` › Riesgos).
- **Opciones:** dejarlo así · avisar por stderr.
- **Bloquea:** nada.
- **Origen:** F-7.

## Deuda y mejoras

### D1 · El formato de fila está copiado en tres comandos

- **Problema:** la misma línea de salida se repite en `list`, `search` y
  `recent`. El diseño de F-7 aplazó extraerla hasta que hubiera un
  tercer uso, y ya lo hay.
- **Dónde:** `src/cli.py:23`, `src/cli.py:55`, `src/cli.py:67`.
- **Arreglo propuesto:** extraer `_format_row(note: dict) -> str`.
- **Gravedad:** baja · **Esfuerzo:** muy bajo.
- **Origen:** F-7 (`specs/example/cli_recent/design.md` › Formato de salida).

### D2 · Los datos de `.notes.json` entran sin validar

- **Problema:** `storage.load()` devuelve los registros tal cual
  (`list[dict]`), sin validarlos ni convertirlos en `Note`, y esos dicts
  llegan a todos los comandos y a `Note.new()`. Un archivo corrupto acaba en
  una traza de `JSONDecodeError`, porque `main()` solo captura `NoteError`,
  y un registro incompleto, en un `KeyError` dentro del comando. Incumple
  «Fronteras y validación» (Principio 7 de `docs/example/architecture.md`) y
  la convención de no mostrar trazas al usuario.
- **Dónde:** `src/storage.py:11`, `src/notes.py:24`, `src/cli.py:132`.
- **Arreglo propuesto:** validar el archivo y convertir cada registro en
  `Note` en un solo punto, justo después de leerlo, y traducir sus errores en
  `main()`. La conversión no puede ir dentro de `storage.load()`:
  `storage.py` no puede importar `notes` (Principio 6).
- **Gravedad:** media · **Esfuerzo:** medio.
- **Origen:** revisión de la disciplina de fronteras con el usuario
  (2026-11-16), sin feature.
