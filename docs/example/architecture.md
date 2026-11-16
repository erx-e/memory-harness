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
  sin esa línea falla al importarse en 3.9.
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
- No importar `storage` ni `cli` desde `notes.py`, ni `notes` ni `cli` desde
  `storage.py` (Principio 6). Lo que necesite a los dos va en `cli.py`.
- No leer/escribir el archivo en cada operación dentro de un bucle.
  Carga al inicio, modifica en memoria, guarda al final.
- No añadir un sistema de configuración. La ruta del archivo se pasa
  explícitamente o usa la constante por defecto.
