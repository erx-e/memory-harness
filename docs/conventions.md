# Convenciones de código

> Homogeneidad extrema. La IA predice mejor cuando el repositorio se parece
> a sí mismo en todas partes.

> **Plantilla.** Los huecos `<...>` los rellena el leader contigo antes de tu
> primera feature (`docs/project-setup.md`); al rellenarla se quitan esta nota
> y el texto que solo explica cómo rellenar. Ejemplo relleno:
> `docs/example/conventions.md`.

## Estilo <lenguaje>

Si un formateador o un linter ya aplica el formato, él es la norma: nombra la
herramienta y no repitas aquí lo que impone (longitud de línea, comillas,
orden de imports). Esta sección es para lo que solo se comprueba leyendo.

- **Versión:** <versión mínima del lenguaje o del runtime>
- **Formato automático:** <formateador o linter, comando que lo ejecuta y
  archivo donde se configura; o "ninguno">
- **Formato a mano:** <solo si no hay herramienta: longitud máxima de línea,
  comillas, orden y agrupación de imports. Si la hay, escribe "lo aplica la
  herramienta".>
- **Reglas que la herramienta no detecta:** <reglas semánticas que el revisor
  comprueba leyendo el código: tipos prohibidos, inmutabilidad exigida, forma
  de interpolar cadenas.>

## Nombres

| Tipo                    | Convención        | Ejemplo               |
|-------------------------|-------------------|-----------------------|
| Módulos / archivos      | <...>             | <...>                 |
| Clases / tipos          | <...>             | <...>                 |
| Funciones / variables   | <...>             | <...>                 |
| Constantes              | <...>             | <...>                 |
| Privadas                | <...>             | <...>                 |

## Estructura de archivo

<Con qué empieza cada archivo de código y cómo se agrupan sus imports.
Acompáñalo de un bloque de código de muestra.>

<Orden de los miembros dentro de una clase o de un módulo. Por ejemplo:
constantes, propiedades, constructor, métodos públicos y, al final, helpers
privados.>

## Tests

- <Dónde viven los tests y cómo se nombran sus archivos.>
- <Cómo se agrupan (clases, bloques, módulos).>
- <Qué recursos reales usan y cómo limpian tras de sí.>
- <Cómo se nombra cada test: el patrón y un ejemplo.>

El nombre de un test es lo que se cita en el mapa `R<n>` → test de
`progress/impl_<name>.md`, y con él lo busca el reviewer. Por eso la
convención debe dar nombres que describan el comportamiento verificado y que
no se repitan en toda la suite. No pongas el número del requirement en el
nombre: `R1` existe en el spec de cada feature.

## Manejo de errores

El mecanismo (excepciones o tipos de resultado) lo fija
`docs/architecture.md` › Principios. Aquí va dónde se definen los errores y
cómo llegan al usuario.

<Qué errores define el dominio y en qué archivo o carpeta.>

<Cómo los traduce la capa externa, según el tipo de aplicación. En una
herramienta de consola: mensaje, canal de salida y código de salida. En una
API: código HTTP y cuerpo del error. En una app con pantallas: el estado de
error que ve el usuario.>

<Qué no llega nunca al usuario: trazas, mensajes internos, datos sensibles.>

## Comentarios

<Cuándo se permiten y cuándo no.>
