# Grafo de contexto (graphify)

> **Opcional.** Úsalo para preguntas amplias sobre el código (qué usa qué,
> qué se rompe al cambiar algo, cómo está organizado). Para un símbolo o un
> texto concreto, grep es más rápido.

## Qué es

`graphify-out/graph.json` es un grafo del repositorio: cada función, clase,
método, test y sección de los `.md` es un nodo, y las relaciones entre ellos
(quién llama a quién, qué test cubre qué, qué spec menciona qué función) son
aristas. Lo construye `graphify update .` analizando el código en local, sin
ningún modelo ni clave de API.

`./init.sh` no lo reconstruye: actualízalo antes de usarlo con
`graphify update .` (tarda alrededor de un segundo), que regenera también el
informe `GRAPH_REPORT.md`; el wiki de `graphify-out/wiki/`, con
`graphify export wiki`.

## Cómo consultarlo

Ejecuta los comandos desde la raíz del proyecto.

| Necesitas                                    | Comando                                  |
|----------------------------------------------|------------------------------------------|
| Dónde está un símbolo y con qué se relaciona | `graphify explain "<símbolo>"`           |
| Qué hay sobre un tema                        | `graphify query "<palabras clave>"`      |
| Qué se rompe si cambio esto                  | `graphify affected "<símbolo>"`          |
| Cómo se conectan dos piezas                  | `graphify path "<A>" "<B>"`              |
| Cuáles son las piezas centrales del proyecto | `graphify god-nodes`                     |

Ejemplo con el proyecto de muestra:

```
$ graphify explain "cmd_recent"
Node: cmd_recent()
  Source:    src/cli.py L59
Connections (13):
  --> load() [calls] src/cli.py:L62
  --> NoteError [calls] src/cli.py:L61
  <-- build_parser() [indirect_call] src/cli.py:L122
  <-- Algoritmo [references] specs/example/cli_recent/spec.md:L22
```

Con eso lees `src/cli.py` desde la línea 59, no el archivo entero.

## Vista general del proyecto

Para preguntas amplias ("cómo está organizado esto", "cuáles son las piezas
principales") hay dos documentos que se regeneran junto al grafo, sin
ningún modelo:

| Documento                       | Qué contiene                                                                 | Úsalo para |
|---------------------------------|------------------------------------------------------------------------------|------------|
| `graphify-out/GRAPH_REPORT.md`  | Piezas centrales ("God Nodes"), grupos de código, conexiones inesperadas y ciclos de imports | Una revisión de arquitectura de una sola lectura |
| `graphify-out/wiki/index.md`    | Índice de un wiki con un artículo por grupo de código y por pieza central     | Navegar el proyecto por temas: abre el índice y solo los artículos que necesites |

Orden recomendado, de menos a más contexto:

1. Pregunta concreta sobre un símbolo → `graphify explain` o `graphify query`.
2. Pregunta sobre una zona del proyecto → `graphify-out/wiki/index.md` y el
   artículo de esa zona.
3. Pregunta sobre el proyecto entero → `graphify-out/GRAPH_REPORT.md`.

Los grupos llevan el nombre de su elemento principal (`cli.py`, `save`)
porque se deducen en local. No describen el tema del grupo: mira su lista de
"Key Concepts" para saber de qué trata.

## Qué da y qué no da

- **Da**: archivo y línea de cada función, clase, método y test; a quién
  llama y quién lo llama; qué tests lo ejercitan; qué specs, docs e informes
  lo mencionan.
- **No da**: los parámetros, los tipos ni el cuerpo de una función. Para eso
  lee las líneas que indica el grafo (`Read` con `offset` y `limit`), no el
  archivo completo.

## Cómo preguntar bien

- La búsqueda es literal: compara tus palabras con los nombres del grafo, sin
  sinónimos ni traducción. Pregunta con los identificadores y términos que usa
  el código (`save`, `NoteError`, `limit`), no con una descripción libre.
- Si conoces el nombre exacto, usa `explain`; es más preciso que `query`.
- `query` corta la salida a unos 2000 tokens. Si avisa `TRUNCATED`, acota la
  pregunta o sube el límite con `--budget 4000`.
- "No matching nodes found" significa que esas palabras no existen en el
  grafo. Prueba con otro término del código antes de recurrir a `grep`.

## Mantenerlo al día

- A mano: `graphify update .` (grafo e informe) y `graphify export wiki`
  (wiki).
- Al terminar, `graphify update` imprime "For doc/paper/image changes run
  /graphify --update in your AI assistant". Es un texto fijo del programa:
  ignóralo. Los `.md` ya se actualizan en local y este arnés no usa la
  extracción con modelo.
- Si editas código y vas a consultar el grafo en la misma sesión, ejecuta
  antes `graphify update .` (tarda alrededor de un segundo).
- Si tras borrar código `graphify update .` se niega a reducir el grafo,
  repítelo con `--force`.

## Qué se indexa

Todo el repositorio menos lo que excluyen `.gitignore` y `.graphifyignore`
(las definiciones de agentes en `.claude/`). `graphify-out/` se regenera y
no se versiona.

## Si graphify no está instalado

El grafo es una ayuda, no un requisito. Sin él, orienta la lectura con `Grep` y lee solo lo necesario.
Para instalarlo: `uv tool install graphifyy` (o `pip install graphifyy`).

