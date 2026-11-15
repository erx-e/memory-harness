# Verificación — Cómo demostrar que el trabajo funciona

> Regla de oro: **el agente no dice "funciona", lo demuestra**.
> Toda feature termina con evidencia ejecutable, no con afirmaciones.

> **Cómo usar este archivo.** Tiene dos partes con la misma estructura.
> «Ejemplo» es el contenido real del proyecto de muestra (CLI de notas en
> Python) y enseña cómo se rellena. «Tu proyecto» es esa estructura vacía.
> «Ejemplo» vale solo para las features de ejemplo (`"example": true`); para
> las tuyas rige solo «Tu proyecto», nunca las reglas del ejemplo. El leader
> lo rellena contigo antes de tu primera feature: `./init.sh` falla si una
> feature tuya avanza con huecos `<...>`, así que lo que aún no esté decidido
> se escribe como «Sin decidir». No borres «Ejemplo» a mano: lo retira el
> leader, y solo si «Tu proyecto» ya está relleno.
> La última sección, «Verificación final antes de cerrar», vale para
> cualquier proyecto y no se borra.

## Ejemplo: CLI de notas

### Niveles de verificación

#### Nivel 1 — Tests unitarios (obligatorio)

Toda función pública en `src/` tiene al menos un test en `tests/` que:

1. Cubre el camino feliz.
2. Cubre al menos un camino de error si la función puede fallar.

Comando:
```bash
python3 -m unittest discover -s tests -v
```

#### Nivel 2 — Test de integración del CLI (obligatorio para features de UI)

Las features que añaden comandos al CLI se verifican ejecutando el CLI real
contra un archivo temporal:

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

#### Nivel 3 — Smoke test manual (opcional pero recomendado)

Antes de cerrar la sesión, ejecuta un flujo end-to-end con un archivo
temporal en `/tmp`:

```bash
NOTES_FILE=/tmp/notes_demo.json python3 -m src.cli add "test" --body "x"
NOTES_FILE=/tmp/notes_demo.json python3 -m src.cli list
rm /tmp/notes_demo.json
```

#### Nivel 4 — Trazabilidad de requirements (obligatorio para features con `"sdd": true`)

Cada `R<n>` de `specs/<name>/requirements.md` debe poder mapearse a al
menos un test concreto en `tests/`. El reviewer rechaza si falta cobertura.

El implementer documenta el mapa en `progress/impl_<name>.md`:

```markdown
## Trazabilidad
- R1 → `test_recent_default_limit`
- R2 → `test_recent_invalid_limit`
- R3 → `test_recent_custom_limit`
```

### Anti-patrones (no hacer)

- ❌ "He añadido el comando, debería funcionar." → falta test ejecutable.
- ❌ Test que solo verifica que la función no lanza excepción. → tiene que
  comprobar el resultado concreto.
- ❌ `mock` del filesystem. → usa `tempfile.TemporaryDirectory()` real.
- ❌ Marcar la feature como `done` sin pasar `./init.sh`.

### Trampas del entorno

Lo que falla al ejecutar o verificar por una razón que no está en el código
que estás cambiando. Léelo antes de lanzar el primer comando.

| Si haces esto                                             | Pasa esto                                                                       | Haz esto                                                                 |
|-----------------------------------------------------------|---------------------------------------------------------------------------------|--------------------------------------------------------------------------|
| `python3 src/cli.py list`                                 | `ModuleNotFoundError: No module named 'src'`                                    | `python3 -m src.cli list`, desde la raíz del repositorio                 |
| Ejecutar el CLI o los tests desde otra carpeta            | El mismo error; en los tests, `ImportError: Failed to import test module`       | Sitúate en la raíz del repositorio antes de ejecutar                     |
| Ejecutar el CLI sin definir `NOTES_FILE`                  | Crea o modifica `.notes.json` en la carpeta actual                              | `NOTES_FILE=/tmp/<archivo>.json python3 -m src.cli …`, y bórralo después |
| Cambiar `NOTES_FILE` dentro de un proceso ya arrancado    | No tiene efecto: la ruta se leyó al importar `src/storage.py` (línea 8)         | En tests, `patch.object(storage, "DEFAULT_NOTES_PATH", ruta)` (`tests/test_cli.py:19`). Desde fuera, define la variable antes de lanzar el proceso |
| Guardar `init.sh` con finales de línea de Windows (CRLF)  | `$'\r': command not found` y el script no se ejecuta                            | No toques `.gitattributes`, que fuerza LF en los `.sh`                   |

## Tu proyecto

### Niveles de verificación

#### Nivel 1 — <tipo de test> (obligatorio)

<Qué tiene que estar cubierto y con qué casos como mínimo.>

Comando:
```bash
<comando que ejecuta estos tests>
```

#### Nivel 2 — <tipo de test> (<cuándo es obligatorio>)

<Qué se verifica y contra qué entorno. Acompáñalo de un ejemplo corto.>

#### Nivel 3 — <comprobación manual> (opcional)

<Flujo de extremo a extremo que se ejecuta antes de cerrar la sesión.>

```bash
<comandos del flujo>
```

#### Nivel 4 — Trazabilidad de requirements (obligatorio para features con `"sdd": true`)

Cada `R<n>` de `specs/<name>/requirements.md` debe poder mapearse a al
menos un test concreto en `<carpeta de tests>`. El reviewer rechaza si falta
cobertura.

El implementer documenta el mapa en `progress/impl_<name>.md`:

```markdown
## Trazabilidad
- R1 → `<nombre_del_test>`
```

### Anti-patrones (no hacer)

- ❌ <Práctica que no cuenta como verificación.> → <qué hacer en su lugar>

### Trampas del entorno

Lo que falla al ejecutar o verificar por una razón que no está en el código
que se está cambiando: desde dónde hay que lanzar los comandos, variables de
entorno, herramientas que se comportan distinto en esta máquina, secretos.
Una fila por trampa, con el error literal para que se reconozca al verlo.

| Si haces esto                          | Pasa esto                                  | Haz esto                                   |
|----------------------------------------|--------------------------------------------|--------------------------------------------|
| <comando o acción que parece correcta> | <error literal o efecto que produce>       | <comando o acción correcta>                |

Cuando descubras una trampa nueva, añádela aquí. Si además costó rastrearla,
el leader la registra también en `docs/lessons.md`.

## Verificación final antes de cerrar

```bash
./init.sh           # debe terminar con [OK] Entorno listo
```

Si `./init.sh` está rojo, **no** marques nada como `done`. Anota el bloqueo
en `progress/current.md` con estado `blocked` en `feature_list.json`.
