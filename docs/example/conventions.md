# Convenciones de código — Ejemplo: CLI de notas

> **Ejemplo.** Convenciones del proyecto de muestra (CLI de notas en Python). Rigen solo
> las features con `"example": true`; las del proyecto real se rigen por
> `docs/conventions.md`.

## Estilo Python

- **Versión:** Python 3.9+ (sintaxis `list[str]` permitida).
- **Formato automático:** `lint.sh`, bloque «Ejemplo»: una comprobación
  propia con la stdlib, porque el ejemplo no admite dependencias. Aplica la
  longitud de línea, cómo se parte una llamada o una colección que no cabe
  en una, el orden de los imports, las comillas y la forma de interpolar, y
  cada fallo dice qué hacer. Lo ejecuta `./init.sh`.
- **Formato a mano:** lo aplica la herramienta.
- **Reglas que la herramienta no detecta:** ninguna en esta sección.

## Nombres

| Tipo                    | Convención        | Ejemplo               |
|-------------------------|-------------------|-----------------------|
| Módulos                 | `snake_case`      | `notes.py`            |
| Clases                  | `PascalCase`      | `Note`                |
| Funciones / variables   | `snake_case`      | `load_notes`          |
| Constantes              | `UPPER_SNAKE`     | `DEFAULT_NOTES_PATH`  |
| Privadas                | prefijo `_`       | `_atomic_write`       |

`lint.sh` comprueba los nombres de funciones y clases. Los de constantes y
privadas se comprueban leyendo: saber qué es una constante o qué es privado
pide juicio.

## Estructura de archivo

Cada archivo en `src/` empieza así (lo comprueba `lint.sh`):

```python
"""Una línea describiendo el propósito del módulo."""
from __future__ import annotations

# imports stdlib
import json
import os

# imports locales
from src.notes import Note
```

## Tests

- Un archivo de test por módulo: `tests/test_<módulo>.py` (lo comprueba
  `lint.sh`).
- Una clase `Test<Cosa>(unittest.TestCase)` por unidad lógica.
- Cada test usa un `tempfile.TemporaryDirectory()` y limpia tras de sí.
  `lint.sh` rechaza los mocks del filesystem.
- Nombres de test descriptivos: `test_load_returns_empty_when_file_missing`.
- Cuántos: un test por regla y su borde, más el caso que motivó el cambio
  (`docs/verification.md`).

## Manejo de errores

Excepciones del dominio en `src/notes.py`:

```python
class NoteError(Exception):
    """Base para errores del dominio."""

class NoteNotFound(NoteError):
    """Se lanza cuando se busca una nota inexistente."""
```

El CLI captura excepciones del dominio, imprime mensaje a `stderr` y sale
con código 1. Nunca propaga stack traces al usuario.

## Comentarios

Por defecto **no** se escriben. Solo se permiten cuando explican un *por qué*
no obvio (p. ej. workaround documentado, invariante sutil). Los nombres deben
hacer el resto.
