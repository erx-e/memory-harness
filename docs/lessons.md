# Lecciones — Registro anti-amnesia

> Evita repetir trabajo y repetir errores. Antes de proponer un enfoque o de
> "arreglar" algo que parece raro, búscalo aquí: puede que ya se intentó y se
> descartó por una razón.

> **Cómo usar este archivo.** Lo escribe el leader al cerrar una feature,
> con lo que el spec, el informe del implementer y la revisión enseñaron y
> sirve más allá de esa feature. Cada entrada se añade al final de su
> sección, con el número siguiente; los números no se reutilizan ni se
> cambian, porque otros archivos los citan. Aquí no va estado (qué está hecho
> o pendiente): eso vive en `feature_list.json` y en `progress/`.
> «Ejemplo» son las lecciones del proyecto de muestra (CLI de notas). No lo
> borres a mano: lo retira el leader junto con el resto del ejemplo.

## Ejemplo: CLI de notas

### Decisiones

#### ADR-01 · `sorted()[:limit]` en vez de `heapq.nlargest`

- **Contexto:** `recent` necesita las N notas más nuevas.
- **Decisión:** ordenar la lista completa y cortar.
- **Coste aceptado:** O(n log n) en vez de O(n log k).
- **Descartado:** `heapq.nlargest`. El archivo de notas es pequeño y el resto
  de `cli.py` usa `sorted` y comprensiones simples; la claridad pesa más.
- **Origen:** feature 7 (`specs/cli_recent/design.md`).

#### ADR-02 · La validación de `--limit` la hace el comando, no `argparse`

- **Contexto:** `type=int` acepta negativos y los errores de `argparse` salen
  en inglés y con su propio formato.
- **Decisión:** validar `limit <= 0` en `cmd_recent` y lanzar `NoteError`.
- **Coste aceptado:** una comprobación manual por comando.
- **Descartado:** un `type` personalizado en `argparse`. Rompería la regla de
  que los errores de dominio pasan por el handler de `main()`.
- **Origen:** feature 7 (`specs/cli_recent/design.md`).

### Bugs resueltos

#### Bug-01 · Notas creadas seguidas comparten `created_at`

- **Síntoma:** un test que crea varias notas con `add` no puede comprobar el
  orden por fecha: todas salen con la misma marca de tiempo.
- **Causa:** `Note.new` guarda la fecha con `timespec="seconds"`
  (`src/notes.py:30`).
- **Solución:** el helper de test `_add_with_created_at`
  (`tests/test_cli.py:155`) escribe notas con una fecha controlada.
- **Lección:** cualquier test que dependa del orden temporal debe fijar las
  fechas, no confiar en el reloj.
- **Origen:** feature 7 (`progress/impl_cli_recent.md`).

### Callejones sin salida

**No vuelvas a intentar esto:**

- **Crear las notas con el comando `add` en tests de orden temporal.** Se
  crean en el mismo segundo y el orden queda indefinido (Bug-01). Usa
  `_add_with_created_at`.

## Tu proyecto

### Decisiones

_Ninguna todavía._

### Bugs resueltos

_Ninguno todavía._

### Callejones sin salida

_Ninguno todavía._

### Estructura de las entradas

Copia el bloque que corresponda al final de su sección y quita la línea
"Ninguna todavía" de esa sección.

```markdown
#### ADR-<n> · <La decisión, en una frase>

- **Contexto:** <qué situación obligó a decidir>
- **Decisión:** <qué se hace>
- **Coste aceptado:** <qué se pierde a cambio>
- **Descartado:** <la alternativa y por qué no>
- **Origen:** feature <id> (<archivo donde está el detalle>)

#### Bug-<n> · <El síntoma, en una frase>

- **Síntoma:** <qué se observaba>
- **Causa:** <la causa real, con archivo:línea>
- **Solución:** <qué se cambió>
- **Lección:** <qué hacer distinto la próxima vez>
- **Origen:** feature <id> (<archivo donde está el detalle>)

- **<Enfoque que no funciona.>** <Por qué falla y qué usar en su lugar.>
```
