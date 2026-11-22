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
orden de imports). Esta sección es para lo que solo se comprueba leyendo. La
herramienta se conecta en `lint.sh`, que ejecuta `./init.sh`: si no, nadie
la ejecuta y su norma vuelve a ser una instrucción en texto.

- **Versión:** <versión mínima del lenguaje o del runtime>
- **Formato automático:** <formateador o linter, el comando con que lo
  ejecuta `lint.sh` y el archivo donde se configura; o "ninguno">
- **Formato a mano:** <solo si no hay herramienta: longitud máxima de línea,
  comillas, orden y agrupación de imports. Si la hay, escribe "lo aplica la
  herramienta".>
- **Reglas que la herramienta no detecta:** <reglas que el revisor juzga
  leyendo el código, como la inmutabilidad exigida. Si una se puede
  comprobar sin juicio (un tipo o una API prohibidos, la forma de interpolar
  cadenas), va a `lint.sh` en lugar de aquí.>

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
- <Propiedades: con qué librería se escribe un test con entradas generadas,
  cómo se nombra y un ejemplo; cómo se suben sus iteraciones y cómo se
  repite un fallo, con comandos comprobados. Si todavía no hay librería,
  dilo y apúntalo como deuda en `progress/pending.md`.>
- Una propiedad genera entradas nuevas en cada ejecución, y su resultado
  esperado sale de la regla, no del código que se prueba: dos campos que
  deben cuadrar, una ida y vuelta de escribir y leer, o un cálculo
  independiente y más simple. Cuando falla, su entrada mínima se fija como
  un test normal, que queda de regresión, y se arregla la causa; si la
  feature no tocó ese código, el fallo es real igualmente: se reporta, no
  se repite la ejecución hasta que pase. Esta línea no se rellena.
- Cuántos: un test por regla y su borde, más el caso que motivó el cambio
  (`docs/verification.md`). Esta línea no se rellena: rige en todos los
  proyectos.


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
