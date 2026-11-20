# Verificación

> El agente no dice «funciona»: lo demuestra con un comando. Y verifica en
> proporción al cambio, no al máximo posible.

> **Plantilla.** Los huecos `<...>` los rellena el leader contigo antes de tu
> primera feature (`docs/project-setup.md`); al rellenarla se quitan esta nota
> y el texto que solo explica cómo rellenar. Ejemplo relleno:
> `docs/example/verification.md`.

## Qué se verifica según el tamaño

Esta sección no se rellena: rige en todos los proyectos del harness. El
tamaño es el campo `"size"` de la feature: lo propone el leader y lo confirma
el humano. Un cambio `trivial` no es una feature: no entra en la cola
(`.claude/agents/leader.md` › Cambio trivial).

| Tamaño | Qué cambia | Verificación |
|---|---|---|
| `trivial` | Un texto, un estilo o un renombre, sin lógica | `./init.sh`; un test se actualiza solo si comprueba el texto que cambia |
| `small` | Una regla, un tope, una validación, un mensaje, un campo o una opción de algo que ya existe | Un test por regla y su borde, y `./init.sh`. La implementa el leader, sin subagente |
| `medium` | Una pieza nueva o cambiada con lógica propia (un caso de uso, una consulta, un comando, un endpoint, una pantalla), sin flujo que cruce varios componentes ni migración | Los tests de lo que cambia (abajo) y `./init.sh` |
| `large` | Un flujo nuevo que cruza componentes, una migración o un refactor | Lo mismo, con spec y reviewer |

- **Tests: uno por regla y su borde** (el valor justo, que pasa, y el
  siguiente, que falla), más el caso que motivó el cambio. Nada de barridos
  exhaustivos, oráculos ni tests de rendimiento, salvo que el plan o el spec
  lo pidan; aun así, un caso representativo.
- **Levantar la app o servicios (contenedores, base de datos, API) y el
  navegador: en ningún tamaño por defecto.** Solo si algo no se puede
  comprobar de otra forma (tests, compilación, lectura del código) y el plan
  o el spec aprobado lo justifica.
- **`./init.sh` completo, una vez por feature, al final** (y otra tras
  arreglar lo que falle). Mientras trabajas, solo los tests que tocas. Lo
  ejecuta quien implementa; en verde, anota qué código comprobó, y quien
  venga después (leader, reviewer, el cierre) mira `./init.sh --status`, que
  dice si sigue valiendo. Solo se repite si el código cambió.

**Ejemplo del fallo** (de un proyecto real con este harness): una regex y dos
topes de longitud, unas 40 líneas, se verificaron con la base de datos en
Docker, un navegador automatizado en cuatro pantallas y 57 tests de una sola
regex (todo Unicode y ~87 000 cadenas): ~510k tokens entre todos los agentes.
Bastaba un test por regla y borde, la compilación y `./init.sh`.

## Tests

### Nivel 1 — <tipo de test> (obligatorio)

<Qué tiene que estar cubierto y con qué casos como mínimo.>

```bash
<comando que ejecuta estos tests>
```

### Nivel 2 — <tipo de test> (<cuándo es obligatorio>)

<Qué se verifica y contra qué entorno. Acompáñalo de un ejemplo corto. Si el
proyecto no lo necesita, borra este nivel.>

## Recorrido manual (excepcional)

Solo si el plan o el spec aprobado lo justifica. <Cómo arrancar la app (el
comando, desde la raíz del repositorio), dónde abrirla y cómo pararla; o «No
aplica: sin interfaz».> Para el navegador, `docs/ui-review.md`.

## Anti-patrones (no hacer)

- ❌ <Práctica que no cuenta como verificación.> → <qué hacer en su lugar>

## Trampas del entorno

Lo que falla al ejecutar o verificar por una razón que no está en el código
que se está cambiando: desde dónde hay que lanzar los comandos, variables de
entorno, herramientas que se comportan distinto en esta máquina, secretos.
Una fila por trampa, con el error literal para que se reconozca al verlo.

| Si haces esto | Pasa esto | Haz esto |
|---|---|---|
| <comando o acción que parece correcta> | <error literal o efecto que produce> | <comando o acción correcta> |

Cuando descubras una trampa nueva, añádela aquí.

## Verificación final

`./init.sh` debe terminar con `[OK] Entorno listo`: ejecuta `lint.sh` y los
tests. Si está en rojo, nada se cierra.
