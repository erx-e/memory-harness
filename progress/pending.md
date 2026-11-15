# Pendientes — Decisiones del usuario y deuda

> Lo que está pendiente y **no es una feature**: decisiones que esperan al
> usuario, y deuda o mejoras detectadas fuera del alcance de una feature. Las
> features viven en `feature_list.json`; no se copian aquí.

> **Cómo usar este archivo.** Lo escribe el leader. Cada entrada lleva un id
> estable (`Q<n>` para decisiones, `D<n>` para deuda) que no se reutiliza:
> otros archivos citan el id, no copian el detalle. **Hecho es fuera:** cuando
> una decisión se toma, o una deuda se convierte en feature o se descarta, su
> entrada se borra de aquí; el rastro queda en `progress/history.md` o en
> `docs/lessons.md`. No anotes aquí estado que `./init.sh` ya sabe (tests en
> verde, features cerradas).
> «Ejemplo» son los pendientes del proyecto de muestra (CLI de notas). No lo
> borres a mano: lo retira el leader junto con el resto del ejemplo.

## Ejemplo: CLI de notas

### Decisiones pendientes del usuario

#### Q1 · ¿`recent --limit` mayor que el total de notas debe avisar?

- **Contexto:** hoy devuelve todas las notas sin decir nada. Ningún
  requirement lo cubre (`specs/cli_recent/design.md` › Riesgos).
- **Opciones:** dejarlo así · avisar por stderr.
- **Bloquea:** nada.
- **Origen:** feature 7.

### Deuda y mejoras

#### D1 · El formato de fila está copiado en tres comandos

- **Problema:** la misma línea de salida se repite en `list`, `search` y
  `recent`. El diseño de la feature 7 aplazó extraerla hasta que hubiera un
  tercer uso, y ya lo hay.
- **Dónde:** `src/cli.py:23`, `src/cli.py:55`, `src/cli.py:67`.
- **Arreglo propuesto:** extraer `_format_row(note: dict) -> str`.
- **Gravedad:** baja · **Esfuerzo:** muy bajo.
- **Origen:** feature 7 (`specs/cli_recent/design.md` › Formato de salida).

## Tu proyecto

### Decisiones pendientes del usuario

_Ninguna._

### Deuda y mejoras

_Ninguna._

### Estructura de las entradas

Copia el bloque que corresponda en su sección y quita la línea "Ninguna".

```markdown
#### Q<n> · <La pregunta, tal como hay que respondérsela al usuario>

- **Contexto:** <por qué hace falta decidir>
- **Opciones:** <opción A> · <opción B>
- **Bloquea:** <qué feature o trabajo espera esta decisión, o "nada">
- **Origen:** <feature, revisión o conversación de donde salió>

#### D<n> · <El problema, en una frase>

- **Problema:** <qué está mal o qué se podría mejorar>
- **Dónde:** <archivo:línea>
- **Arreglo propuesto:** <qué habría que hacer>
- **Gravedad:** <alta | media | baja> · **Esfuerzo:** <alto | medio | bajo>
- **Origen:** feature <id> (<informe o spec donde está el detalle>)
```
