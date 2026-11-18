# Verificación — Ejemplo: CLI de notas

> **Ejemplo.** Reglas de verificación del proyecto de muestra (CLI de notas en
> Python). Rigen solo las features con `"example": true`; las del proyecto
> real se rigen por `docs/verification.md`.

## Qué se verifica según el tamaño

Rige la tabla de `docs/verification.md`. En el CLI de notas, una feature
`small` (un mensaje, la validación de un argumento) se verifica con su test
unitario y su borde; una `medium` (un comando nuevo, como `cli_recent`) añade
el test de integración del CLI; el recorrido manual, solo si el plan o el
spec lo justifica.

## Tests

### Nivel 1 — Tests unitarios (obligatorio)

Toda función pública en `src/` tiene al menos un test en `tests/` que cubre
el camino feliz y, si la función puede fallar, un camino de error.

```bash
python3 -m unittest discover -s tests
```

### Nivel 2 — Test de integración del CLI (obligatorio en comandos nuevos o cambiados)

El comando se verifica ejecutando el CLI real contra un archivo temporal:

```python
import subprocess, tempfile, os
with tempfile.TemporaryDirectory() as d:
    env = {**os.environ, "NOTES_FILE": os.path.join(d, "notes.json")}
    out = subprocess.check_output(
        ["python3", "-m", "src.cli", "add", "hola", "--body", "mundo"],
        env=env, text=True,
    )
    assert "id=" in out
```

## Recorrido manual (excepcional)

Solo si el plan o el spec lo justifica. Un flujo con un archivo temporal:

```bash
NOTES_FILE=/tmp/notes_demo.json python3 -m src.cli add "test" --body "x"
NOTES_FILE=/tmp/notes_demo.json python3 -m src.cli list
rm /tmp/notes_demo.json
```

No hay interfaz web: el reviewer no abre el navegador en estas features.

## Anti-patrones (no hacer)

- ❌ "He añadido el comando, debería funcionar." → falta test ejecutable.
- ❌ Test que solo verifica que la función no lanza excepción. → tiene que
  comprobar el resultado concreto.
- ❌ `mock` del filesystem. → usa `tempfile.TemporaryDirectory()` real (lo
  comprueba `lint.sh`).
- ❌ Marcar la feature como `done` sin pasar `./init.sh`.

## Trampas del entorno

Lo que falla al ejecutar o verificar por una razón que no está en el código
que estás cambiando. Léelo antes de lanzar el primer comando.

| Si haces esto                                             | Pasa esto                                                                       | Haz esto                                                                 |
|-----------------------------------------------------------|---------------------------------------------------------------------------------|--------------------------------------------------------------------------|
| `python3 src/cli.py list`                                 | `ModuleNotFoundError: No module named 'src'`                                    | `python3 -m src.cli list`, desde la raíz del repositorio                 |
| Ejecutar el CLI o los tests desde otra carpeta            | El mismo error; en los tests, `ImportError: Failed to import test module`       | Sitúate en la raíz del repositorio antes de ejecutar                     |
| Ejecutar el CLI sin definir `NOTES_FILE`                  | Crea o modifica `.notes.json` en la carpeta actual                              | `NOTES_FILE=/tmp/<archivo>.json python3 -m src.cli …`, y bórralo después |
| Cambiar `NOTES_FILE` dentro de un proceso ya arrancado    | No tiene efecto: la ruta se leyó al importar `src/storage.py` (línea 8)         | En tests, `patch.object(storage, "DEFAULT_NOTES_PATH", ruta)` (`tests/test_cli.py:19`). Desde fuera, define la variable antes de lanzar el proceso |
| Guardar `init.sh` con finales de línea de Windows (CRLF)  | `$'\r': command not found` y el script no se ejecuta                            | No toques `.gitattributes`, que fuerza LF en los `.sh`                   |
