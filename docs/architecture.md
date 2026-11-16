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

El primero es fijo. Sin la dirección de dependencias escrita, un revisor no
puede rechazar un import en sentido contrario: lo que no está en este archivo
no es un requisito.

1. **Capas y dirección de dependencias.** <Qué capas o módulos existen y en
   qué único sentido se importan. Lo habitual: el dominio no conoce la
   interfaz ni la infraestructura.> Una fila por capa:

   | Capa o módulo     | Responsabilidad | Puede importar       | No puede importar            |
   |-------------------|-----------------|----------------------|------------------------------|
   | `<capa o módulo>` | <qué hace>      | <capas permitidas>   | <capas que no debe conocer>  |

   <Cómo se comprueba: un linter de imports, un test, o `graphify path` entre
   las dos capas.> Si el proyecto tiene una sola capa, dilo aquí en una
   línea; no borres el principio.

2. **<Nombre del principio>.** <Regla concreta y qué hacer ante la excepción.>

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
