# Exploración: cli_surface

> **Ejemplo.** Informe de exploración del proyecto de muestra (CLI de notas).
> Se conserva para ver qué deja en disco un subagente de exploración: una
> pregunta acotada y sus hallazgos, no una respuesta en el chat.
>
> Se retira junto con el resto del ejemplo cuando el leader cierra tu
> primera feature real; no lo borres antes.

**Pregunta:** Qué comandos expone el CLI
**Archivo analizado:** `src/cli.py`
**Generado:** 2026-04-27T14:00:56+00:00

## Métricas
- Líneas de código: 49
- Funciones públicas: 4
- Clases: 0
- Imports: 5

## Funciones
- `cmd_add`
- `cmd_list`
- `build_parser`
- `main`

## Clases
- (ninguna)

## Dependencias
- `from __future__ import annotations`
- `import argparse`
- `import sys`
- `from src import storage`
- `from src.notes import Note`
