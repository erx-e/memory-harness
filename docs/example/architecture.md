# Arquitectura — Ejemplo: CLI de notas

> **Ejemplo.** Reglas de arquitectura del proyecto de muestra (CLI de notas en Python). Rigen solo
> las features con `"example": true`; las del proyecto real se rigen por
> `docs/architecture.md`.

## Principios

1. **Capas claras.** El proyecto tiene tres capas y solo tres:
   - `storage.py` — persistencia (JSON en disco).
   - `notes.py` — modelo de dominio (`Note`).
   - `cli.py` — interfaz de usuario (argparse).
   No introducir capas adicionales (servicios, repositorios, ORMs) hasta que
   haya una razón concreta documentada en `feature_list.json`. Un módulo
   nuevo en `src/` lo detecta `lint.sh`.

2. **Sin dependencias externas.** Solo stdlib de Python. Si una feature
   requiere una dependencia, primero se discute (estado `blocked`). Un
   import de fuera de la stdlib, un `requirements.txt` con contenido o un
   `pyproject.toml` los detecta `lint.sh`.

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

   Lo comprueba `lint.sh`.

7. **Fronteras y validación.** La validación, el estrechamiento de tipos
   (*type narrowing*) y el manejo de errores van en las fronteras del
   sistema. Se confía en el código interno sin condiciones. La lógica de
   negocio vive en funciones puras, y la capa externa (el *shell*: lo que
   recibe la entrada y llama al resto) es delgada y mecánica. Aplica al
   escribir validación, manejo de errores o adaptadores de un framework.

   Las fronteras de este proyecto:

   - **Argumentos de la línea de comandos**, en `src/cli.py`. `argparse`
     comprueba el subcomando, los argumentos obligatorios y los tipos
     (`type=int`). Lo que no puede comprobar (que `--limit` sea positivo,
     que `edit` reciba `--title` o `--body`) lo valida el `cmd_<nombre>` que
     lo recibe, lanzando `NoteError` (ADR-02).
   - **La variable de entorno `NOTES_FILE`**, que se lee una sola vez, al
     importar `src/storage.py`.
   - **El archivo `.notes.json`**, que leen y escriben `storage.load()` y
     `storage.save()`. Excepción conocida (D2): `storage.load()` devuelve los
     registros como `list[dict]`, sin validarlos ni convertirlos en `Note`, y
     esos dicts llegan a los comandos y a `Note.new()`. El arreglo va en un
     solo punto, junto a la lectura del archivo y sin romper el Principio 6;
     no se reparte por los comandos.
   - **La salida al usuario**: `main()`, en `src/cli.py`, traduce cada
     `NoteError` a un mensaje en `stderr` y código de salida 1.

   **Por qué:** la validación dispersa es ruidosa, redundante y da una falsa
   sensación de seguridad. Mantener la lógica fuera del cableado del
   framework permite probarla sin el framework.

   **El patrón:**

   - **En las fronteras** (argumentos de la línea de comandos, archivos de
     configuración, APIs externas, protocolos de red): se valida, se
     devuelven errores y se actúa a la defensiva.
   - **Dentro del sistema:** datos tipados, propagación de errores y ninguna
     revalidación. Se confía en los tipos. Cómo traduce los errores la capa
     externa lo fija `docs/example/conventions.md` › Manejo de errores.
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

## Stack y dependencias

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
  sin esa línea falla al importarse en 3.9; `lint.sh` lo detecta.
- **El archivo de datos es `.notes.json`, en la carpeta desde la que se
  ejecuta el comando,** salvo que la variable de entorno `NOTES_FILE` indique
  otra ruta. La variable se lee una sola vez, al importar `src/storage.py`
  (línea 8).

## Estructura de carpetas

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

## Flujo de datos

```
usuario  ─→  cli.py (argparse)
              │
              ├─ construye Note con notes.Note.new(...)
              │
              └─→  storage.load() / storage.save()
                       │
                       └─→  .notes.json (en CWD)
```

## Qué NO hacer

- No usar `print()` para errores. Usa `sys.stderr` y exit code != 0.
- No mezclar IO con lógica de dominio dentro de `notes.py`.
- No leer/escribir el archivo en cada operación dentro de un bucle.
  Carga al inicio, modifica en memoria, guarda al final.
- No añadir un sistema de configuración. La ruta del archivo se pasa
  explícitamente o usa la constante por defecto.
