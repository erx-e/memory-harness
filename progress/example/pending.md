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
- **Origen:** feature 7.

## Deuda y mejoras

### D1 · El formato de fila está copiado en tres comandos

- **Problema:** la misma línea de salida se repite en `list`, `search` y
  `recent`. El diseño de la feature 7 aplazó extraerla hasta que hubiera un
  tercer uso, y ya lo hay.
- **Dónde:** `src/cli.py:23`, `src/cli.py:55`, `src/cli.py:67`.
- **Arreglo propuesto:** extraer `_format_row(note: dict) -> str`.
- **Gravedad:** baja · **Esfuerzo:** muy bajo.
- **Origen:** feature 7 (`specs/example/cli_recent/design.md` › Formato de salida).
