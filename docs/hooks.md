# Hooks — Qué se dispara solo mientras trabajas

> Un hook es un comando que Claude Code ejecuta por su cuenta cuando pasa
> algo: antes o después de que uses una herramienta, al empezar la sesión,
> al terminar un turno. Nadie lo llama, pero puede bloquearte o añadir un
> mensaje a lo que ves. Los de este repositorio están en
> `.claude/settings.json`. Este archivo dice cuáles hay, a quién afectan, qué
> verás y qué tienes que hacer.
>
> No hace falta leerlo al empezar: la sección "Hooks que te afectan" de tu
> definición resume los tuyos. Ábrelo cuando un mensaje `[harness]` te frene
> y ese resumen no baste, y lee solo la sección de ese hook.
>
> Si cambias un hook en `.claude/settings.json`, actualiza este archivo en el
> mismo cambio.

## Cómo reconocerlos

- Un mensaje que empieza por `[harness]` viene de un hook de este
  repositorio. Puede bloquearte.
- Un mensaje que empieza por `graphify:` viene de un hook de graphify. Solo
  avisa, nunca bloquea.
- Si un hook bloquea **antes** de una herramienta, la acción no ocurrió.
- Si un hook avisa **después** de una herramienta, la acción ya ocurrió: el
  aviso no la deshace.

## Qué agente ve cada hook

| Hook                                        | leader  | spec_author | implementer         | reviewer  |
|---------------------------------------------|---------|-------------|---------------------|-----------|
| H1 — Escritura protegida                    | bloquea | bloquea     | solo `.claude/state/` | bloquea |
| H2 — Tests tras cada edición                | —       | —           | sí                  | —         |
| H3 — Límite de rondas de revisión           | sí      | —           | —                   | indirecto |
| H4 — Reinicio del contador de rondas        | sí      | —           | —                   | —         |
| H5 — Estado real al iniciar la sesión       | sí      | —           | —                   | —         |
| H6 — `./init.sh` al terminar el turno       | sí      | —           | —                   | —         |
| H7 — Avisos de graphify                     | sí      | sí          | sí                  | sí        |

El leader es la sesión principal: es el único que recibe los hooks de
sesión (H4, H5, H6). Los hooks de herramienta (H1, H2, H3, H7) saltan
también cuando la usa un subagente.

## H1 — Escritura protegida

- **Cuándo:** antes de cada `Edit` o `Write` (PreToolUse).
- **Qué hace:** bloquea cualquier escritura en `.claude/state/`, que solo
  escriben los hooks. Y bloquea la escritura en `src/` y `tests/` a todo
  agente que no sea el `implementer`.
- **Qué verás:** `[harness] Bloqueado: solo el subagente implementer escribe
  en src/ y tests/ (agente actual: …)` o `[harness] Bloqueado: .claude/state/
  lo escriben solo los hooks del harness.`
- **Qué haces:** si eres el leader, delega el cambio en un `implementer`. Si
  eres el `spec_author` o el `reviewer`, ese cambio no te toca: tu única
  salida es tu archivo.
- **Lo que no vigila:** solo mira `Edit` y `Write`. Escribir en esas
  carpetas con Bash (`>`, `sed -i`, `rm`) no dispara el hook, pero está
  igual de prohibido.

## H2 — Tests tras cada edición

- **Cuándo:** después de cada `Edit` o `Write` sobre un archivo de `src/` o
  `tests/` (PostToolUse). En la práctica, solo le salta al `implementer`.
- **Qué hace:** ejecuta `python3 -m unittest discover -s tests -q`. Si los
  tests pasan, no dice nada.
- **Qué verás si fallan:** `[harness] Tests en rojo tras editar <archivo>:`
  y las últimas 15 líneas de la salida.
- **Qué haces:** la edición ya está guardada; el hook te avisa de que la
  suite ha quedado en rojo. No es un fallo de la herramienta, es
  información para ti:
  - Si es el rojo intermedio que esperabas (cambiaste una firma y aún no
    has actualizado su test, o escribiste el test antes que el código),
    sigue con la task y comprueba que queda en verde al terminarla.
  - Si no lo esperabas, arréglalo antes de pasar a la siguiente task.
  - No deshagas el cambio ni retoques un test solo para callar el aviso.
- **Si el proyecto no usa Python:** el comando es el del ejemplo. El leader
  lo cambia al preparar el proyecto (ver `docs/project-setup.md`).

## H3 — Límite de rondas de revisión

- **Cuándo:** cada vez que el leader lanza un subagente `reviewer`
  (PreToolUse sobre `Agent`).
- **Qué hace:** si hay exactamente una feature `in_progress`, cuenta los
  `reviewer` lanzados para ella en `.claude/state/review_rounds.json`. Deja
  pasar los tres primeros y bloquea el cuarto.
- **Qué verás:** `[harness] Límite de 3 rondas de revisión alcanzado para
  la feature <name>. …`
- **Qué haces (leader):** paras y explicas al humano qué hallazgos siguen
  abiertos, por qué no convergen y qué opciones ves (ver `leader.md` ›
  "Cierre de una feature"). No lo intentes otra vez ni cambies el estado
  de la feature para esquivarlo.
- **Ten en cuenta:** cuenta lanzamientos, no veredictos, y se pone a cero
  cada vez que el humano escribe (H4). Así que en realidad impide lanzar
  cuatro `reviewer` seguidos sin que el humano intervenga. La regla de tres
  rondas por ciclo la llevas tú en `progress/current.md`
  (`Ronda de revisión: N/3`).
- **Para el reviewer:** no lo ves, pero cada vez que te lanzan cuenta como
  una ronda.

## H4 — Reinicio del contador de rondas

- **Cuándo:** cada vez que el humano envía un mensaje (UserPromptSubmit).
- **Qué hace:** borra `.claude/state/review_rounds.json`. No muestra nada.
- **Para el leader:** cuando H3 te bloquea, la respuesta del humano lo
  desbloquea.

## H5 — Estado real al iniciar la sesión

- **Cuándo:** al iniciar, reanudar, limpiar o compactar la sesión
  (SessionStart).
- **Qué hace:** ejecuta `./init.sh --status` y te añade el bloque «Estado
  real del proyecto»: los `[FAIL]` y `[WARN]` de las validaciones rápidas y
  la sección «Estado del trabajo». No incluye el análisis estático, los
  tests ni el grafo.
- **Qué haces (leader):** ese estado manda sobre lo escrito en `progress/`.
  Para el análisis estático, los tests y el grafo, ejecuta `./init.sh`.

## H6 — `./init.sh` al terminar el turno

- **Cuándo:** cada vez que la sesión principal termina un turno, antes de
  devolver el control al humano (Stop). No salta al terminar un subagente.
- **Qué hace:** ejecuta `./init.sh` completo, con análisis estático, tests
  y grafo. Si pasa, no dice nada.
- **Qué verás si falla:** `[harness] init.sh FALLÓ. Resuélvelo antes de
  cerrar la sesión:` y las últimas 20 líneas. No puedes terminar el turno:
  vuelves a tener el control.
- **Qué haces (leader):** resuelve la causa si está a tu alcance. Si está en
  `src/` o `tests/`, delega en un `implementer`; si no, explícasela al
  humano. Si al intentar terminar otra vez sigue fallando, el hook te deja
  terminar y le muestra al humano el aviso `[harness] init.sh sigue en
  rojo: la sesión termina sin verificación verde`. Tú no lo verás, así que
  explícale en tu respuesta qué falla.

## H7 — Avisos de graphify

- **Cuándo:** antes de cada `Bash`, `Grep`, `Read` o `Glob`, y después de
  compactar la conversación. Solo si graphify está instalado.
- **Qué hace:** te añade un recordatorio `graphify: …` de consultar el grafo
  y, si vas a leer código, lo que el grafo ya sabe de ese archivo. Nunca
  bloquea.
- **Qué haces:** si aún no lo has hecho, consulta el grafo antes de leer el
  archivo entero (ver `docs/graphify.md`).

## No son hooks, pero también te frenan: permisos

`.claude/settings.json` › `permissions` dice qué comandos se ejecutan sin
pedir permiso (`allow`) y cuáles necesitan que el humano los confirme
(`ask`). Ahora piden confirmación las capturas, las grabaciones y el
guardado en disco de `playwright-cli` y `chrome-devtools` (ver
`docs/ui-review.md`). Si un comando tuyo queda esperando la
confirmación del humano, o él lo rechaza, no lo reformules para esquivar la
regla.
