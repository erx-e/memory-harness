# Lecciones — Registro anti-amnesia

> Evita repetir trabajo y repetir errores. Antes de proponer un enfoque o de
> "arreglar" algo que parece raro, búscalo aquí: puede que ya se intentó y se
> descartó por una razón.

> **Cómo se lee.** Lee solo «Índice» y «Callejones sin salida». Abre una
> entrada ADR o Bug únicamente si su fila del índice toca lo que vas a
> cambiar.
>
> **Cómo se escribe.** Solo el leader, al cerrar una feature, con lo que
> sirve más allá de ella: la entrada al final de su sección y su fila en el
> índice, en el mismo cambio. Los ids no se reutilizan ni se cambian, porque
> otros archivos los citan. Aquí no va estado (qué está hecho o pendiente).
>
> **Tope: 30 entradas ADR + Bug.** Al superarlo, `./init.sh` avisa y el
> leader propone al humano cuáles pasar a `docs/lessons-archive.md` (las que
> el código ya no sustenta). La entrada archivada sale del índice y ningún
> agente lee el archivo de archivadas por defecto.

## Índice

| Id | En una línea | Afecta a |
|----|--------------|----------|

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
"todavía" de esa sección y añade la fila al índice.

```markdown
| ADR-<n> | <la decisión, en una frase> | <archivos, símbolos o tema a los que afecta> |

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
