# Tags — Ejemplo: CLI de notas

> **Ejemplo.** Tags del proyecto de muestra (CLI de notas en Python). Valen
> solo para las features con `"example": true` y sus lecciones; los del
> proyecto real van en `docs/tags.md`, que explica sus reglas.

## Tags

| Tag | Qué cubre |
|-----|-----------|
| `persistencia` | Lectura y escritura del archivo de notas (`src/storage.py`): el JSON en disco y la escritura atómica |
| `modelo` | La entidad `Note` (`src/notes.py`): sus campos, su creación y su serialización |
| `cli` | Los comandos del CLI (`src/cli.py`): subcomandos, flags y formato de la salida |
| `busqueda` | Encontrar notas por su contenido |
| `fechas` | `created_at`: cómo se genera, su formato y el orden por fecha |
| `validacion` | Comprobar la entrada del usuario (ids, flags, límites, confirmaciones) antes de actuar |
| `errores` | Las excepciones del dominio y cómo llegan al usuario: mensaje en stderr y exit code |
| `exportacion` | Sacar las notas a otros formatos o archivos |
| `tests` | Cómo se escriben los tests: archivos temporales, datos de prueba y fechas controladas |
