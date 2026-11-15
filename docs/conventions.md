# Convenciones de código

> Homogeneidad extrema. La IA predice mejor cuando el repositorio se parece
> a sí mismo en todas partes.

> **Cómo usar este archivo.** Tiene dos partes con la misma estructura.
> «Ejemplo» es el contenido real del proyecto de muestra (CLI de notas en
> Python) y enseña cómo se rellena. «Tu proyecto» es esa estructura vacía.
> «Ejemplo» vale solo para las features de ejemplo (`"example": true`); para
> las tuyas rige solo «Tu proyecto», nunca las reglas del ejemplo. El leader
> lo rellena contigo antes de tu primera feature: `./init.sh` falla si una
> feature tuya avanza con huecos `<...>`, así que lo que aún no esté decidido
> se escribe como «Sin decidir». No borres «Ejemplo» a mano: lo retira el
> leader, y solo si «Tu proyecto» ya está relleno.

## Ejemplo: CLI de notas

### Estilo Python

- **Versión:** Python 3.9+ (sintaxis `list[str]` permitida).
- **Formato:** PEP 8. Líneas máximo 100 caracteres.
- **Imports:** stdlib primero, luego locales. Una línea por módulo.
- **Strings:** comillas dobles `"..."` siempre. Comillas simples solo
  para escapar comillas dobles dentro.
- **f-strings** para interpolación. Nada de `.format()` ni `%`.

### Nombres

| Tipo                    | Convención        | Ejemplo               |
|-------------------------|-------------------|-----------------------|
| Módulos                 | `snake_case`      | `notes.py`            |
| Clases                  | `PascalCase`      | `Note`                |
| Funciones / variables   | `snake_case`      | `load_notes`          |
| Constantes              | `UPPER_SNAKE`     | `DEFAULT_NOTES_PATH`  |
| Privadas                | prefijo `_`       | `_atomic_write`       |

### Estructura de archivo

Cada archivo en `src/` empieza con:

```python
"""Una línea describiendo el propósito del módulo."""
from __future__ import annotations

# imports stdlib
import json
import os

# imports locales
from src.notes import Note
```

### Tests

- Un archivo de test por módulo: `tests/test_<módulo>.py`.
- Una clase `Test<Cosa>(unittest.TestCase)` por unidad lógica.
- Cada test usa un `tempfile.TemporaryDirectory()` y limpia tras de sí.
- Nombres de test descriptivos: `test_load_returns_empty_when_file_missing`.

### Manejo de errores

Excepciones del dominio en `src/notes.py`:

```python
class NoteError(Exception):
    """Base para errores del dominio."""

class NoteNotFound(NoteError):
    """Se lanza cuando se busca una nota inexistente."""
```

El CLI captura excepciones del dominio, imprime mensaje a `stderr` y sale
con código 1. Nunca propaga stack traces al usuario.

### Comentarios

Por defecto **no** se escriben. Solo se permiten cuando explican un *por qué*
no obvio (p. ej. workaround documentado, invariante sutil). Los nombres deben
hacer el resto.

## Tu proyecto

### Estilo <lenguaje>

- **Versión:** <versión mínima del lenguaje o del runtime>
- **Formato:** <formateador o guía de estilo; longitud máxima de línea>
- **Imports:** <orden y agrupación>
- **Strings:** <comillas e interpolación>

### Nombres

| Tipo                    | Convención        | Ejemplo               |
|-------------------------|-------------------|-----------------------|
| Módulos / archivos      | <...>             | <...>                 |
| Clases / tipos          | <...>             | <...>                 |
| Funciones / variables   | <...>             | <...>                 |
| Constantes              | <...>             | <...>                 |
| Privadas                | <...>             | <...>                 |

### Estructura de archivo

<Con qué empieza cada archivo de código y en qué orden van sus partes.
Acompáñalo de un bloque de código de muestra.>

### Tests

- <Dónde viven los tests y cómo se nombran sus archivos.>
- <Cómo se agrupan (clases, bloques, módulos).>
- <Qué recursos reales usan y cómo limpian tras de sí.>
- <Cómo se nombra cada test.>

### Manejo de errores

<Qué errores define el dominio y dónde. Cómo los presenta la interfaz al
usuario: mensaje, canal de salida y código de salida.>

### Comentarios

<Cuándo se permiten y cuándo no.>
