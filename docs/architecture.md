# Arquitectura — Qué significa "hacer un buen trabajo"

> Este documento define el estándar de calidad. Los agentes revisores
> evalúan código contra este archivo. Si no está aquí, no es un requisito.

> **Cómo usar este archivo.** Tiene dos partes con la misma estructura.
> «Ejemplo» es el contenido real del proyecto de muestra (CLI de notas en
> Python) y enseña cómo se rellena. «Tu proyecto» es esa estructura vacía.
> «Ejemplo» vale solo para las features de ejemplo (`"example": true`); para
> las tuyas rige solo «Tu proyecto», nunca las reglas del ejemplo. El leader
> lo rellena contigo antes de tu primera feature: `./init.sh` falla si una
> feature tuya avanza con huecos `<...>`, así que lo que aún no esté decidido
> se escribe como «Sin decidir». No borres «Ejemplo» a mano: lo retira el
> leader, y solo si «Tu proyecto» ya está relleno.

Cada parte tiene cinco secciones, siempre en este orden:

| Sección                 | Responde a                                             |
|-------------------------|--------------------------------------------------------|
| Principios              | ¿Qué reglas de diseño no se pueden romper?             |
| Stack y dependencias    | ¿Con qué está hecho y qué no puedo dar por supuesto?   |
| Estructura de carpetas  | ¿Dónde va cada cosa nueva?                             |
| Flujo de datos          | ¿Por dónde pasa una petición de principio a fin?       |
| Qué NO hacer            | ¿Qué debe rechazar un revisor sin dudar?               |

## Ejemplo: CLI de notas

### Principios

1. **Capas claras.** El proyecto tiene tres capas y solo tres:
   - `storage.py` — persistencia (JSON en disco).
   - `notes.py` — modelo de dominio (`Note`).
   - `cli.py` — interfaz de usuario (argparse).
   No introducir capas adicionales (servicios, repositorios, ORMs) hasta que
   haya una razón concreta documentada en `feature_list.json`.

2. **Sin dependencias externas.** Solo stdlib de Python. Si una feature
   requiere una dependencia, primero se discute (estado `blocked`).

3. **Errores explícitos.** Las funciones que pueden fallar (id no existe,
   archivo corrupto) lanzan excepciones nombradas, no devuelven `None`.

4. **Inmutabilidad por defecto.** `Note` es un `@dataclass(frozen=True)`.
   Modificar = crear una nueva instancia.

5. **Atomicidad en disco.** Toda escritura a `notes.json` se hace primero
   en un archivo temporal y luego `os.replace()`. Nunca dejar el archivo
   a medio escribir.

6. **Dependencias en una sola dirección.** `cli.py` es el único módulo que
   importa a los otros dos. `notes.py` y `storage.py` solo importan stdlib:
   no se conocen entre sí ni conocen al CLI.

   | Módulo       | Puede importar              | No puede importar  |
   |--------------|-----------------------------|--------------------|
   | `cli.py`     | `notes`, `storage`, stdlib  | —                  |
   | `notes.py`   | stdlib                      | `storage`, `cli`   |
   | `storage.py` | stdlib                      | `notes`, `cli`     |

   Se comprueba leyendo las líneas `import` de cada módulo de `src/`.

### Stack y dependencias

| Pieza                    | Qué se usa                                              | Dónde            |
|--------------------------|---------------------------------------------------------|------------------|
| Lenguaje                 | Python 3.9 o superior (lo comprueba `./init.sh`)        | todo el proyecto |
| Interfaz                 | `argparse`                                              | `src/cli.py`     |
| Modelo de dominio        | `dataclasses`, `datetime`                               | `src/notes.py`   |
| Persistencia             | `json`, `os`, `tempfile`                                | `src/storage.py` |
| Tests                    | `unittest`, `unittest.mock`                             | `tests/`         |
| Dependencias de terceros | Ninguna. No hay `requirements.txt` ni `pyproject.toml`  | —                |

Todo lo de la columna central es biblioteca estándar de Python.

**Restricciones del stack que importan:**

- **No se instala nada.** El proyecto no es un paquete: no hay `pip install`.
  Se ejecuta como módulo desde la raíz del repositorio
  (`python3 -m src.cli`).
- **`str | None` en las anotaciones funciona en Python 3.9 solo porque cada
  módulo empieza con `from __future__ import annotations`.** Un módulo nuevo
  sin esa línea falla al importarse en 3.9.
- **El archivo de datos es `.notes.json`, en la carpeta desde la que se
  ejecuta el comando,** salvo que la variable de entorno `NOTES_FILE` indique
  otra ruta. La variable se lee una sola vez, al importar `src/storage.py`
  (línea 8).

### Estructura de carpetas

```
src/
├── __init__.py
├── cli.py         # interfaz: una función cmd_<nombre> por comando + build_parser()
├── notes.py       # dominio: Note, NoteError, NoteNotFound
└── storage.py     # persistencia: load() y save()
tests/
├── __init__.py
├── test_cli.py    # un test por comportamiento de cada comando
├── test_notes.py
└── test_storage.py
```

**Dónde va cada cosa nueva:**

| Si vas a añadir               | Va en                                                                            | Su test va en                       |
|-------------------------------|----------------------------------------------------------------------------------|-------------------------------------|
| Un comando del CLI            | `src/cli.py`: función `cmd_<nombre>(args)` y su subparser en `build_parser()`    | `tests/test_cli.py`                 |
| Un campo o una regla de la nota | `src/notes.py`, en la clase `Note`                                             | `tests/test_notes.py`               |
| Un error de dominio           | `src/notes.py`, heredando de `NoteError`                                         | el test del comando que lo provoca  |
| Lectura o escritura en disco  | `src/storage.py`                                                                 | `tests/test_storage.py`             |
| Un módulo nuevo               | No se añade sin justificarlo antes (Principio 1)                                 | —                                   |

### Flujo de datos

```
usuario  ─→  cli.py (argparse)
              │
              ├─ construye Note con notes.Note.new(...)
              │
              └─→  storage.load() / storage.save()
                       │
                       └─→  .notes.json (en CWD)
```

### Qué NO hacer

- No usar `print()` para errores. Usa `sys.stderr` y exit code != 0.
- No mezclar IO con lógica de dominio dentro de `notes.py`.
- No importar `storage` ni `cli` desde `notes.py`, ni `notes` ni `cli` desde
  `storage.py` (Principio 6). Lo que necesite a los dos va en `cli.py`.
- No leer/escribir el archivo en cada operación dentro de un bucle.
  Carga al inicio, modifica en memoria, guarda al final.
- No añadir un sistema de configuración. La ruta del archivo se pasa
  explícitamente o usa la constante por defecto.

## Tu proyecto

### Principios

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

### Stack y dependencias

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

### Estructura de carpetas

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

### Flujo de datos

```
<origen>  ─→  <capa de entrada>
                │
                └─→  <capa de dominio>
                         │
                         └─→  <persistencia o servicio externo>
```

### Qué NO hacer

Lista corta y concreta de lo que un revisor rechaza sin discutir. Suele
incluir: lógica de negocio en controladores o en componentes de interfaz,
acceso a la base de datos fuera de la capa de datos, y saltarse una capa
«solo esta vez».

- <Violación de arquitectura que el revisor debe rechazar.> <Qué hacer en su
  lugar.>
