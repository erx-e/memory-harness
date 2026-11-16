# Lecciones — Registro anti-amnesia

> Evita repetir trabajo y repetir errores. Antes de proponer un enfoque o de
> "arreglar" algo que parece raro, búscalo aquí: puede que ya se intentó y se
> descartó por una razón.

> **Memoria inmediata.** Aquí viven como mucho 20 lecciones activas:
> decisiones (`ADR`), bugs resueltos (`Bug`) y callejones sin salida (`CS`).
> Las demás están en `docs/lessons-archive.md`, la memoria de largo plazo,
> que nadie lee por defecto.
>
> **Cómo se lee.** Lee solo «Índice» y «Callejones sin salida». Abre una
> entrada ADR o Bug únicamente si su fila del índice comparte tags con tu
> feature o toca lo que vas a cambiar.
>
> **Cómo se escribe.** Solo el leader, al cerrar una feature, con lo que
> sirve más allá de ella: la entrada al final de su sección y su fila en el
> índice, con sus tags de `docs/tags.md`, en el mismo cambio. Los ids no se
> reutilizan ni se cambian, porque otros archivos los citan. Aquí no va
> estado (qué está hecho o pendiente).
>
> **Antes, ¿se puede codificar?** Lo que un chequeo cubre entero no se
> escribe aquí, y cada entrada dice en `**Mecanismo:**` qué la hace cumplir
> (`.claude/agents/leader.md` › «Codificar las lecciones en estructura»).
> `./init.sh` falla si falta, o si cita una `D<n>` que ya no está en
> `progress/pending.md`.
>
> **Tope: 20 lecciones.** Si al cerrar una feature hay más, el leader mueve a
> `docs/lessons-archive.md` las menos usadas, con su fila del índice, sin
> pedir permiso: archivar no es borrar. El último uso de una lección es la
> feature más reciente (la de id más alto) que la cita en su spec o en sus
> informes, o la de su «Origen». `./init.sh` lo calcula y falla, diciendo
> cuáles mover, mientras sobre alguna.

## Índice

| Id | En una línea | Tags | Afecta a |
|----|--------------|------|----------|

_Sin entradas todavía._

## Callejones sin salida

**No vuelvas a intentar esto:**

_Ninguno todavía._

## Decisiones

_Ninguna todavía._

## Bugs resueltos

_Ninguno todavía._

## Estructura de las entradas

Copia el bloque que corresponda al final de su sección, quita la línea
"todavía" de esa sección y añade la fila al índice, con entre 1 y 4 tags de
`docs/tags.md`. En `**Mecanismo:**` va una de estas tres cosas: qué parte
comprueba qué chequeo (`lint.sh`, `init.sh`, un hook o un helper) y qué
sigue pidiendo juicio; la `D<n>` que creará el chequeo; o «requiere juicio»
y por qué.

```markdown
| ADR-<n> | <la decisión, en una frase> | `<tag>`, `<tag>` | <archivos, símbolos o tema a los que afecta> |

#### ADR-<n> · <La decisión, en una frase>

- **Contexto:** <qué situación obligó a decidir>
- **Decisión:** <qué se hace>
- **Coste aceptado:** <qué se pierde a cambio>
- **Descartado:** <la alternativa y por qué no>
- **Mecanismo:** <qué la hace cumplir>
- **Origen:** F-<id> (<archivo donde está el detalle>)

#### Bug-<n> · <El síntoma, en una frase>

- **Síntoma:** <qué se observaba>
- **Causa:** <la causa real, con archivo:línea>
- **Solución:** <qué se cambió>
- **Lección:** <qué hacer distinto la próxima vez>
- **Mecanismo:** <qué la hace cumplir>
- **Origen:** F-<id> (<archivo donde está el detalle>)

#### CS-<n> · <El enfoque que no funciona, en una frase>

- **Por qué falla:** <qué pasa si se intenta>
- **En su lugar:** <qué hacer>
- **Mecanismo:** <qué la hace cumplir>
- **Origen:** F-<id> (<archivo donde está el detalle>)
```
