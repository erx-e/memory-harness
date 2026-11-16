# Design — cli_recent

> Decisiones técnicas para implementar el comando `recent`. Apoyado en
> `docs/example/architecture.md` y `docs/example/conventions.md`. Solo se
> documentan los puntos donde la feature roza la frontera de esas reglas.
> Cada archivo y firma cita los `R<n>` que lo motivan (regla
> anti-sobreingeniería de `docs/specs.md`).

## Alcance y archivos a tocar

| Archivo                  | Cambio                                                                 | Motivado por |
|--------------------------|------------------------------------------------------------------------|--------------|
| `src/cli.py`             | Añadir `cmd_recent` y registrar el subparser `recent` en `build_parser` | R1–R7        |
| `tests/test_cli.py`      | Añadir 5 tests nuevos (orden por defecto, límite custom, archivo vacío, límite 0 y límite negativo) y el helper `_add_with_created_at` | R1–R7 |

No se tocan `src/notes.py` ni `src/storage.py`. La feature es puramente
de presentación: lee notas con `storage.load()`, ordena y filtra en memoria,
imprime con el formato existente.

## Firma del nuevo subcomando

```python
def cmd_recent(args: argparse.Namespace) -> int:
    ...
```

Recibe el `Namespace` con un atributo `limit: int` (default `5`). Motivado
por R1–R7.

El helper de test `_add_with_created_at` escribe una nota con un
`created_at` controlado: sin él, R3 no se puede comprobar, porque las notas
creadas en el mismo segundo comparten marca de tiempo (ver «Ordenación»).

Subparser registrado en `build_parser()`:

```python
p_recent = sub.add_parser("recent", help="Listar las N notas más recientes.")
p_recent.add_argument("--limit", type=int, default=5)
p_recent.set_defaults(func=cmd_recent)
```

## Algoritmo

1. **Validación temprana del límite.** Si `args.limit <= 0`, lanzar
   `NoteError("--limit debe ser un entero positivo")`. Esto cubre R6 y R7
   (al levantarse antes de `storage.load()`, no se modifica nada — y
   `cmd_recent` nunca llama a `storage.save()`, así que R7 está garantizado
   estructuralmente).
2. Cargar notas con `storage.load()`.
3. Si la lista está vacía, retornar `0` sin imprimir (cubre R5).
4. Ordenar la lista en memoria por `created_at` descendente:
   `sorted(notes, key=lambda n: n["created_at"], reverse=True)`.
5. Hacer slice `[: args.limit]`.
6. Para cada nota del slice, imprimir `f"{n['id']}\t{n['created_at']}\t{n['title']}"`
   (idéntico al `cmd_list`).
7. Retornar `0`.

## Contratos de datos

Sin contratos de datos nuevos. `cmd_recent` lee el diccionario de nota que
ya guarda `storage` y no lo cambia:

| Campo        | Tipo  | Uso en esta feature                          |
|--------------|-------|----------------------------------------------|
| `id`         | `int` | Primer campo de cada línea de salida (R4)     |
| `title`      | `str` | Tercer campo de cada línea de salida (R4)     |
| `body`       | `str` | No se usa                                    |
| `created_at` | `str` | ISO 8601; clave de orden (R3) y segundo campo (R4) |

## Manejo de errores

- Reutilizar `NoteError` ya definido en `src/notes.py`. No se introducen
  nuevas excepciones.
- El handler global `main()` captura `NoteError`, imprime a `stderr` y sale
  con código `1`. Mismo patrón que `cmd_edit` cuando faltan flags.

## Formato de salida

Idéntico a `cmd_list`:

```
<id>\t<created_at>\t<title>
```

La cadena `f"{n['id']}\t{n['created_at']}\t{n['title']}"` se duplica
deliberadamente entre `cmd_list` y `cmd_recent` para evitar introducir un
helper compartido sin justificación (`docs/example/architecture.md` desaconseja
abstracciones prematuras). Si en el futuro un tercer comando necesita el
mismo formato, se extraerá un `_format_row(note: dict) -> str` privado.

## Ordenación: por qué `created_at` y no `id`

`created_at` está en ISO 8601 con `timespec="seconds"` (ver
`src/notes.py::Note.new`). El orden lexicográfico de ISO 8601 coincide con
el orden cronológico, así que `sorted(..., key=lambda n: n["created_at"])`
es correcto sin parseo.

`id` también es monótonamente creciente, pero el acceptance criterion
exige explícitamente "ordenado por `created_at`", así que se sigue al pie
de la letra. (Si dos notas comparten `created_at` por venir creadas en el
mismo segundo, el orden relativo queda definido por la estabilidad de
`sorted` de Python — suficiente para esta feature.)

## Alternativa descartada

**Alternativa A: usar `heapq.nlargest(limit, notes, key=...)`.**
Más eficiente en O(n log k) frente a O(n log n) del `sorted` completo. Se
descarta porque:

- El dataset esperado es pequeño (notas personales en un JSON local).
- `sorted(...)[:limit]` es más legible y mantiene paridad estilística con
  el resto de `cli.py`, que usa list comprehensions y `sorted` simples.
- `docs/example/architecture.md` prioriza claridad sobre optimización prematura.

## Riesgos / notas

- **Límite mayor que el total de notas.** Python permite slicing más allá
  del final de una lista sin error; devuelve todo. Comportamiento aceptado
  sin requirement explícito (no figura en el acceptance original).
- **`argparse` y enteros negativos.** `type=int` acepta valores negativos.
  La validación `<= 0` la hace `cmd_recent`, no `argparse`, para poder
  devolver un mensaje en español a través de `NoteError` (consistente con
  el resto del CLI, que evita los mensajes automáticos de argparse para
  errores de dominio).
