# Preparar el proyecto y retirar el ejemplo

> Dos procedimientos del `leader` que se hacen una sola vez por proyecto.
> Léelo solo cuando vayas a empezar la primera feature real o a retirar el
> ejemplo.

## Preparar el proyecto (antes de la primera feature real)

Lo del proyecto de muestra vive aparte, en la subcarpeta `example/` de cada
área (`docs/example/`, `specs/example/`, `progress/example/`). Una feature
real se planifica, se implementa y se revisa contra `docs/`, así que esos
archivos tienen que estar rellenos antes. `./init.sh` avisa si hay features
reales con huecos y **falla** si una pasa de `pending` con ellos. La marca
`SIN_CONFIGURAR` de `lint.sh` cuenta como un hueco más (paso 3).

1. **`docs/brief.md`**: se rellena preguntando, no deduciendo. El porqué y
   los límites no están en el código. Pregunta al humano lo mínimo: qué es
   el proyecto y qué problema resuelve, quién lo usa y qué necesita, qué no
   debe hacer todavía, y cómo sabrá que funciona. Escribe sus respuestas sin
   adornarlas. Si prefiere no responder ahora, sigue adelante y anótalo como
   `Q<n>` en `progress/pending.md`.
2. **`docs/architecture.md`, `docs/conventions.md` y `docs/verification.md`**:
   déjalos sin huecos `<...>`. Como muestra de cómo queda cada uno relleno
   tienes su gemelo en `docs/example/`.
   - Si el proyecto ya tiene código, redáctalos tú a partir de él,
     describiendo lo que hay y no lo que debería haber, y enséñaselos al
     humano para que los corrija.
   - Si empieza de cero, pregunta al humano qué está decidido y escribe solo
     eso.
   - Lo que no esté decidido se escribe como «Sin decidir todavía (`Q<n>`)»
     y se anota como `Q<n>` en `progress/pending.md`. Nunca dejes el hueco:
     el agente que lo lea rellenará el vacío con lo que tenga más cerca.
   - En `docs/architecture.md` › Principios, los tres primeros no se omiten.
     En el de capas, di qué capa puede importar a cuál, o que el proyecto
     tiene una sola. En el de fronteras, por dónde entran los datos de fuera
     y dónde se validan, o que no entran. El tercero se conserva tal cual.
     Lo que el código existente no cumpla se anota como excepción conocida
     con su `D<n>`, como en `docs/example/architecture.md`.
   - Lo que una regla de estos docs permita comprobar sin juicio (la
     dirección de imports, el formato, los restos de debug) va a `lint.sh`
     (paso 3), y en el doc queda «(lo comprueba `lint.sh`)» en lugar de la
     instrucción. Como muestra, `docs/example/` y el bloque «Ejemplo» de
     `lint.sh`.
   - Las partes marcadas «no se rellena» (los tamaños de
     `docs/verification.md`, la línea «Cuántos» de las convenciones, el
     tercer principio) se dejan como están: rigen en todos los proyectos.
   - Al rellenar un archivo, quita su nota «Plantilla» y el texto que solo
     explica cómo rellenarlo. Los agentes leen estos archivos en cada
     feature: lo que no es una regla del proyecto solo gasta contexto.
3. **Comandos del stack**: si el proyecto no usa Python, acuerda con el
   humano su comando de tests y cámbialo en `init.sh` (sección 4) y en
   `.claude/settings.json`: los permisos `Bash(python3 …)` y, si su código no
   vive en `src/` y `tests/`, las carpetas que vigila el hook H1. Hazlo antes
   de retirar el ejemplo: sin sus tests, el comando de Python no tiene nada
   que ejecutar.

   Acuerda también con el humano el análisis estático (linter, comprobación
   de tipos, reglas de imports) y escríbelo en el bloque «Proyecto» de
   `lint.sh`: el linter estándar del stack configurado con las reglas de
   `docs/conventions.md`, y chequeos propios solo para lo que ninguna
   herramienta cubra. Comprueba que pasa sobre el código que ya existe; lo
   que no cumpla se arregla o se anota como excepción conocida con su
   `D<n>`. Después borra la línea `SIN_CONFIGURAR`. Si el humano decide no
   tener análisis estático, borra igualmente la línea y anota su decisión en
   ese bloque.
4. **Ejemplo**: si el proyecto ya tiene código propio o su stack no es
   Python, retíralo ahora (sección siguiente). Si empieza de cero y usa
   Python, se queda hasta el cierre de la primera feature real.

## Retirar el ejemplo

El repositorio trae un proyecto de muestra (CLI de notas en Python). Sus
features llevan `"example": true`. Se retira entero y de una vez, siempre
con la confirmación del humano. Cuándo depende del proyecto real:

| Proyecto real                                    | Cuándo retiras el ejemplo                                                                 |
|--------------------------------------------------|-------------------------------------------------------------------------------------------|
| Ya tiene código propio, o su stack no es Python  | **Por adelantado**: al preparar el proyecto, antes del `spec_author` de la primera feature real |
| Empieza de cero y usa Python                     | Al cerrar la primera feature real; hasta entonces es la referencia de cómo se rellena cada archivo |

Se adelanta en esos dos casos porque ahí el ejemplo no puede convivir con el
proyecto: su código y sus tests son de otro stack, o se mezclan con código
que ya existe.

1. **Prepara la lista** de lo que se borra:
   - Las features con `"example": true` de `feature_list.json`.
   - `specs/example/` y `progress/example/`, enteras: el spec, los informes
     y los pendientes del ejemplo.
   - Código y tests del ejemplo: `src/storage.py`, `src/notes.py`,
     `src/cli.py`, `tests/test_storage.py`, `tests/test_notes.py`,
     `tests/test_cli.py`. Excluye cualquiera que haya modificado una feature
     real (míralo en «Cambios» de su `progress/impl_<name>.md`)
     y pregunta al humano por él. `src/__init__.py` y `tests/__init__.py`,
     solo si su carpeta se queda sin otro código.
   - De `docs/example/`: `lessons.md` siempre, y cada uno de los demás
     **solo si su gemelo ya está relleno** (sin huecos `<...>`): `brief.md`,
     `architecture.md`, `conventions.md` y `verification.md`. Los que sigan
     sin rellenar conservan su ejemplo y se lo dices al humano.
   - De `lint.sh`, el bloque «Ejemplo» y su llamada.
2. **Pide confirmación al humano** con esa lista. Si el proyecto no está en
   git, el borrado no se puede deshacer. Sin un «sí», no borres nada.
3. **Con el «sí»**:
   a. Lanza un `implementer` con la lista exacta de archivos de `src/` y
      `tests/` que hay que borrar; tú no puedes tocar esas carpetas.
   b. Borra tú el resto: las features de ejemplo, `specs/example/`,
      `progress/example/`, los archivos de `docs/example/` de la lista y el
      bloque «Ejemplo» de `lint.sh`.
   c. Quita lo que apuntaba al ejemplo: en `AGENTS.md`, la regla «Features
      de ejemplo» y la fila de las carpetas `example/` del mapa; en
      `.claude/agents/spec_author.md`, la línea de la muestra; y las líneas
      «Muestra rellena» de `docs/lessons.md` y «Entradas rellenas de
      muestra» de `progress/pending.md`. Si en `docs/example/` queda algún
      archivo porque su gemelo sigue sin rellenar, se conserva solo como
      muestra: ya no hay features que se rijan por él.
   d. Ejecuta `./init.sh`. Tiene que seguir verde.
4. **Informa al humano** de lo que se borró, lo que se conservó y por qué, y
   lo que sigue siendo del ejemplo y le toca a él: `README.md`, `project` y
   `description` de `feature_list.json`, y los comandos de `init.sh` y
   `.claude/settings.json` si su proyecto no usa Python.
