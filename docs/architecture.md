# Arquitectura — Qué significa "hacer un buen trabajo"

> Este documento define el estándar de calidad. Los agentes revisores
> evalúan código contra este archivo. Si no está aquí, no es un requisito.

> **Plantilla.** Los huecos `<...>` los rellena el leader contigo antes de tu
> primera feature (`docs/project-setup.md`); al rellenarla se quitan esta nota
> y el texto que solo explica cómo rellenar. Ejemplo relleno:
> `docs/example/architecture.md`.

Cinco secciones, siempre en este orden:

| Sección                 | Responde a                                             |
|-------------------------|--------------------------------------------------------|
| Principios              | ¿Qué reglas de diseño no se pueden romper?             |
| Stack y dependencias    | ¿Con qué está hecho y qué no puedo dar por supuesto?   |
| Estructura de carpetas  | ¿Dónde va cada cosa nueva?                             |
| Flujo de datos          | ¿Por dónde pasa una petición de principio a fin?       |
| Qué NO hacer            | ¿Qué debe rechazar un revisor sin dudar?               |

## Principios

Cada principio es una regla que un revisor puede comprobar leyendo el código:
di qué está permitido y qué no. Con tres a seis suele bastar. Temas que
suelen necesitar uno:

- **Dependencias externas**: cuándo se puede añadir una y quién lo decide.
- **Manejo de errores**: excepciones o tipos de resultado, y qué no se
  devuelve nunca para señalar un fallo.
- **Mutabilidad y transacciones**: qué datos son inmutables, y qué escrituras
  (en disco, en base de datos o en servicios externos) se completan enteras o
  no se hacen.

Los tres primeros son fijos. Sin la dirección de dependencias escrita, un
revisor no puede rechazar un import en sentido contrario; sin las fronteras
escritas no puede distinguir una validación que falta de una que sobra, y sin
el principio YAGNI no puede rechazar lo que nadie pidió: lo que no está en
este archivo no es un requisito.

1. **Capas y dirección de dependencias.** <Qué capas o módulos existen y en
   qué único sentido se importan. Lo habitual: el dominio no conoce la
   interfaz ni la infraestructura.> Una fila por capa:

   | Capa o módulo     | Responsabilidad | Puede importar       | No puede importar            |
   |-------------------|-----------------|----------------------|------------------------------|
   | `<capa o módulo>` | <qué hace>      | <capas permitidas>   | <capas que no debe conocer>  |

   <Cómo se comprueba: una regla de `lint.sh` (un linter de imports o un
   chequeo propio, como el del ejemplo). Leyendo, o con `graphify path`
   entre las dos capas, solo si no se puede automatizar.> Si el proyecto
   tiene una sola capa, dilo aquí en una línea; no borres el principio.

2. **Fronteras y validación.** La validación, el estrechamiento de tipos
   (*type narrowing*) y el manejo de errores van en las fronteras del
   sistema. Se confía en el código interno sin condiciones. La lógica de
   negocio vive en funciones puras, y la capa externa (el *shell*: lo que
   recibe la entrada y llama al resto) es delgada y mecánica. Aplica al
   escribir validación, manejo de errores o adaptadores de un framework.

   <Las fronteras de este proyecto, una por línea: por dónde entran o salen
   datos de fuera (argumentos de la línea de comandos, archivos de
   configuración, APIs externas, protocolos de red, archivos o bases de
   datos), qué archivo o capa los valida y en qué tipo del dominio se
   convierten.>

   **Por qué:** la validación dispersa es ruidosa, redundante y da una falsa
   sensación de seguridad. Mantener la lógica fuera del cableado del
   framework permite probarla sin el framework.

   **El patrón:**

   - **En las fronteras** (argumentos de la línea de comandos, archivos de
     configuración, APIs externas, protocolos de red): se valida, se
     devuelven errores y se actúa a la defensiva.
   - **Dentro del sistema:** datos tipados, propagación de errores y ninguna
     revalidación. Se confía en los tipos. Cómo traduce los errores la capa
     externa lo fija `docs/conventions.md` › Manejo de errores.
   - **A través de la frontera:** se exponen conceptos del dominio, no la
     representación privada de la frontera. El mecanismo de propósito
     general va dentro y la política de propósito específico, en el borde.

   **Aplicaciones:**

   Validación y manejo de errores:

   - La configuración se valida al leerla (en la frontera), no dentro de la
     lógica de negocio.
   - Los datos crudos se convierten en tipos del dominio en la frontera.
   - La interfaz pública no reexporta tipos de transporte, de
     almacenamiento, del framework ni del formato de transmisión (*wire*).
   - Si la frontera ya validó, no hay comprobaciones de nulos redundantes en
     lo profundo de la cadena de llamadas.

   Organización del código:

   - La lógica de negocio va en funciones puras, sin dependencias del
     framework.
   - Las funciones de parseo son transformaciones puras de bytes crudos a
     estado tipado.
   - Construir un prompt (o cualquier texto generado): entra estado
     estructurado, sale un string.
   - Puntuar y evaluar (o cualquier cálculo de resultados): transformaciones
     puras del estado a los resultados.

   **Las dos preguntas para comprobarlo:**

   - «¿Este dato está cruzando una frontera del sistema ahora mismo?» Si no,
     validarlo es redundante.
   - «¿Esto puede ser una función pura a la que la capa externa solo llama?»
     Si puede, extráela.

   Este principio es la disciplina de fronteras, la política que recomienda
   la plantilla, y al rellenarla se conserva entero; el original, del que es
   traducción, está en `.claude/boundary-discipline/`. Si el humano elige otra
   política de validación, sustitúyelo por la suya, y si el proyecto no recibe
   datos de fuera, dilo aquí en una línea. No borres el principio.

3. **Solo lo que pide el spec (YAGNI).** Se construye lo que exige un `R<n>`
   del spec aprobado (o el `acceptance` de una feature trivial), y nada más.
   Aplica al escribir requisitos, al diseñar y al implementar.

   **Por qué:** cada línea que nadie pidió hay que leerla, probarla y
   mantenerla, y casi nunca acierta con la necesidad que imaginaba. Cuando la
   necesidad llega de verdad, llega con su requisito y se construye para ese
   uso.

   **El patrón:**

   - **Uso observado, no casos especulativos.** No se añaden parámetros,
     opciones, configuración, capas, puntos de extensión ni casos límite que
     ningún requisito pida, aunque «seguro que harán falta».
   - **Ninguna guarda de más.** Ni validadores, ni parseos, ni comprobaciones
     más allá de lo que pide el spec. Dónde va la validación que sí se pide
     lo fija el principio 2.
   - **El cambio más pequeño.** Se hace el diff mínimo que cumple las tareas:
     menos líneas ganan a un andamiaje «elegante». Un helper o una
     abstracción se extrae cuando ya hay varios usos reales, no para uno.
   - **Restar antes de sumar.** Si el código que la feature modifica tiene
     algo muerto o redundante, se quita en vez de construir encima. Lo que
     esté fuera de lo que modifica se anota como `D<n>`, no se toca.
   - **Lo futuro se anota, no se construye.** Una necesidad que se intuye va
     a «Fuera de alcance» en la entrevista, o a una `D<n>` en
     `progress/pending.md`.

   **Las dos preguntas para comprobarlo:**

   - «¿Qué `R<n>` falla si borro esto?» Si ninguno, sobra.
   - «¿Lo pide el uso real o lo estoy imaginando?» Si lo imaginas, no se
     construye.

   Este principio es la política que trae la plantilla, y al rellenarla se
   conserva entero; los originales, de los que es traducción adaptada, están
   en `.claude/yagni/`. No borres el principio.

4. **<Nombre del principio>.** <Regla concreta y qué hacer ante la excepción.>

## Stack y dependencias

Una fila por pieza del sistema. Pon la versión cuando un cambio de versión
pueda romper algo.

| Pieza                    | Qué se usa                                              | Dónde            |
|--------------------------|---------------------------------------------------------|------------------|
| Lenguaje o plataforma    | <nombre y versión mínima; quién la comprueba>           | <dónde aplica>   |
| Framework                | <nombre y versión mínima, o "ninguno">                  | <carpeta>        |
| Datos                    | <base de datos y ORM o cliente, con versión; o "ninguno"> | <carpeta>      |
| <Interfaz, auth, colas…> | <librería o servicio, con versión>                      | <carpeta>        |
| Tests                    | <framework de tests, con versión mínima>                | <carpeta>        |
| Dependencias de terceros | <lista, o "ninguna"; en qué archivo se declaran>        | —                |

**Restricciones del stack que importan:**

- **<Lo que un agente no puede dar por supuesto.>** <Qué pasa si lo ignora y
  qué hacer en su lugar. Ejemplos: el modo estricto del compilador o una de
  sus opciones desactivada, una librería prohibida y cuál se usa en su lugar,
  una librería que solo se importa en parte, una licencia con condiciones, un
  valor que se lee una sola vez al arrancar.>

## Estructura de carpetas

```
<carpeta de código>/
├── <archivo o subcarpeta>    # <qué contiene>
└── <archivo o subcarpeta>    # <qué contiene>
<carpeta de tests>/
└── <archivo o subcarpeta>    # <qué prueba>
```

**Dónde va cada cosa nueva:**

Es la tabla que más usa el implementer. Una fila por tipo de cambio habitual,
con la ruta exacta; quita las filas que no apliquen a tu proyecto.

| Si vas a añadir                                    | Va en                                            | Su test va en                |
|----------------------------------------------------|--------------------------------------------------|------------------------------|
| Un punto de entrada (endpoint, pantalla o comando) | <archivo o carpeta, y con qué forma o nombre>    | <archivo o carpeta de tests> |
| Una regla de dominio                               | <archivo o carpeta, y con qué forma o nombre>    | <archivo o carpeta de tests> |
| Una consulta o un acceso a datos                   | <archivo o carpeta, y con qué forma o nombre>    | <archivo o carpeta de tests> |
| <otro tipo de cambio habitual>                     | <archivo o carpeta, y con qué forma o nombre>    | <archivo o carpeta de tests> |
| Un módulo o capa nueva                             | <dónde, o "no se añade sin justificarlo antes">  | —                            |

## Flujo de datos

```
<origen>  ─→  <capa de entrada>
                │
                └─→  <capa de dominio>
                         │
                         └─→  <persistencia o servicio externo>
```

## Qué NO hacer

Lista corta y concreta de lo que un revisor rechaza sin discutir. Suele
incluir: lógica de negocio en controladores o en componentes de interfaz,
acceso a la base de datos fuera de la capa de datos, y saltarse una capa
«solo esta vez».

- <Violación de arquitectura que el revisor debe rechazar.> <Qué hacer en su
  lugar.>
