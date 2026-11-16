# Spec Driven Development (SDD)

> Este proyecto sigue un flujo Kiro-style: requirements → design → tasks → code.
> El código no se escribe hasta que el spec está aprobado por un humano.

## Estructura

Cada feature nueva (`"sdd": true` en `feature_list.json`) tiene una carpeta
dedicada en cuanto deja `pending`:

```
specs/<feature-name>/
├── requirements.md   # QUÉ se necesita (EARS notation)
├── design.md         # CÓMO se construirá (decisiones técnicas)
└── tasks.md          # PASOS concretos a implementar
```

El `feature-name` coincide con el campo `name` de `feature_list.json`. El
spec de una feature de ejemplo (`"example": true`) va en
`specs/example/<feature-name>/`.

## Estados de una feature

| Estado         | Significado                                                    |
|----------------|----------------------------------------------------------------|
| `pending`      | Sin spec. El leader entrevista al humano y después actúa el `spec_author`. |
| `spec_ready`   | Spec drafted. Esperando aprobación humana. NO se toca código.  |
| `in_progress`  | Spec aprobado. `implementer` trabajando, o cambio revisado esperando la aprobación final humana. |
| `done`         | Código verde, `reviewer` aprobó, humano aprobó. La entrada pasa de `feature_list.json` a `feature_archive.json`. |
| `blocked`      | Atascado. Razón en `progress/current.md`.                      |

Solo el `leader` cambia el `status` de una feature. Los subagentes reciben
su entrada en el prompt y no escriben en `feature_list.json`.

## Las puertas de aprobación humana

El flujo automático se detiene **dos veces**.

Antes de la primera hay una entrevista: el `leader` pregunta al humano por
rondas sobre los detalles de la feature (skill `grilling`) y, cuando él
confirma lo acordado, lo deja en `progress/current.md`, sección "Decisiones
de la entrevista". El `spec_author` redacta a partir de esa sección, así que
el spec recoge decisiones del humano y no suposiciones. Si la feature ya
está bien definida, la entrevista se reduce a un resumen que el humano
confirma.

**1. Aprobación del spec.** Cuando el `spec_author` termina sus tres
archivos, el `leader` marca la feature como `spec_ready` y para. El humano lee
`specs/<feature>/` y dice "aprobado" (o pide cambios). Solo entonces el
`leader` transiciona `spec_ready → in_progress` y lanza el `implementer`.

**2. Aprobación del cambio.** Cuando el `reviewer` emite `APPROVED`, el
`leader` para y pide al humano la aprobación final. El humano revisa el
cambio y dice "aprobado" (o pide cambios). Solo entonces el `leader` marca
la feature como `done`. El `APPROVED` del reviewer es necesario pero no
suficiente: quien aprueba el cambio final es el humano.

```
pending → [entrevista] → [spec_author] → spec_ready → ⏸ HUMANO → in_progress → [implementer → reviewer] → ⏸ HUMANO → done
```

> **Ejemplos de este archivo.** Los ejemplos de requirements, tasks y
> trazabilidad son del proyecto de muestra (comando `recent` del CLI de
> notas). Al cerrar tu primera feature real, el leader los sustituye por
> fragmentos de su spec.

## requirements.md — EARS estricto

Las requirements se redactan en **EARS** (Easy Approach to Requirements
Syntax). Cada requirement es un párrafo numerado con uno de estos seis
patrones:

| Patrón          | Plantilla                                                      |
|-----------------|----------------------------------------------------------------|
| **Ubicuo**      | `El sistema DEBE <acción>.`                                    |
| **Evento**      | `CUANDO <disparador>, el sistema DEBE <acción>.`               |
| **Estado**      | `MIENTRAS <estado>, el sistema DEBE <acción>.`                 |
| **Opcional**    | `DONDE <feature opcional>, el sistema DEBE <acción>.`          |
| **No deseado**  | `SI <evento no deseado> ENTONCES el sistema DEBE <acción>.`    |
| **Prohibición** | `SI <evento no deseado> ENTONCES el sistema NO DEBE <acción>.` |

La prohibición admite también la forma de los otros patrones cambiando
`DEBE` por `NO DEBE`: `El sistema NO DEBE <acción>.`,
`MIENTRAS <estado>, el sistema NO DEBE <acción>.`, etc.

Reglas duras:

- Cada requirement tiene un id estable: `R1`, `R2`, ...
- Cada requirement DEBE ser verificable por al menos un test concreto.
- No mezcles varios `DEBE` / `NO DEBE` en un mismo requirement. Si hay más
  de uno, parte.
- No uses verbos blandos ("podría", "puede", "soporta"). Solo `DEBE` / `NO DEBE`.
- Una restricción negativa se redacta con `NO DEBE`, no disfrazada de
  afirmación. Mal: «SI falla la escritura ENTONCES el sistema DEBE dejar
  el archivo como estaba». Bien: «SI falla la escritura ENTONCES el
  sistema NO DEBE modificar el archivo».

Ejemplo:

```markdown
## R1
CUANDO el usuario ejecuta `python -m src.cli recent`, el sistema DEBE
imprimir hasta 5 notas ordenadas por `created_at` descendente.

## R2
SI el flag `--limit` recibe un valor <= 0 ENTONCES el sistema DEBE
imprimir un mensaje de error en stderr y salir con código != 0.
```

## design.md — decisiones técnicas

Captura **antes** de tocar código:

- Qué archivos se crean / modifican.
- Qué firmas nuevas aparecen (funciones, clases, comandos).
- Qué excepciones se reutilizan o se añaden.
- **Contratos de datos / esquemas** (obligatorio): las estructuras de
  entrada y salida que la feature crea o cambia (DTOs, payloads JSON,
  esquemas de tabla, estados de UI), con el nombre y el tipo exactos de
  cada campo. Son los nombres que usarán todas las capas: el `implementer`
  no los inventa ni los renombra. Si la feature no crea ni cambia ninguna
  estructura, se escribe «Sin contratos de datos nuevos»; el punto no se
  omite.
- Qué alternativa se descartó y por qué (mínimo una).

NO es ingeniería desde primeros principios — apóyate en
`docs/architecture.md` y `docs/conventions.md`. El `design.md` documenta los
puntos donde tu feature roza la frontera de esas reglas.

Regla anti-sobreingeniería (regla dura):

- Toda firma, clase o archivo propuesto en `design.md` DEBE estar
  justificado por al menos un requirement de `requirements.md`: indica
  junto a cada uno los `R<n>` que lo motivan.
- Todo lo propuesto DEBE respetar los límites de `docs/architecture.md`
  (capas, dirección de dependencias).
- Lo que no se pueda ligar a un `R<n>` es una abstracción especulativa y
  se quita del diseño. No se diseña «por si acaso» ni para features
  futuras.

## tasks.md — checklist ejecutable

Pasos discretos en orden, cada uno con checkbox. Cada task referencia al
menos un `R<n>` que cubre.

Ejemplo:

```markdown
- [ ] T1 — Añadir `cmd_recent` en `src/cli.py`. Cubre: R1, R3.
- [ ] T2 — Registrar subparser `recent` con flag `--limit`. Cubre: R1, R2.
- [ ] T3 — Añadir `test_recent_default_limit` en `tests/test_cli.py`. Cubre: R1.
- [ ] T4 — Añadir `test_recent_invalid_limit` en `tests/test_cli.py`. Cubre: R2.
```

El `implementer` marca `[x]` cada task al completarla. El `reviewer`
rechaza si queda alguna `[ ]` sin justificación documentada.

## Trazabilidad (regla dura)

Esta sección es la única definición de la regla; los demás archivos la
citan.

- Cada test en `tests/` debe poder mapearse a un `R<n>` de su spec.
- Cada `R<n>` debe tener al menos un test concreto.
- El `reviewer` comprueba esta correspondencia explícitamente y rechaza
  si falta.

El `implementer` documenta el mapa en `progress/impl_<name>.md`, con este
formato:

```markdown
## Trazabilidad
- R1 → `test_recent_default_limit`
- R2 → `test_recent_invalid_limit`
- R3 → `test_recent_custom_limit`
```

## Cuándo NO aplica SDD

Las features con `"sdd": false` o sin el campo `sdd` NO tienen spec. Hay
dos casos:

- **Legacy.** Features cerradas antes de adoptar SDD: no llevan el campo
  `sdd`. SDD solo se aplica hacia adelante.
- **Cambios triviales.** Ajustes cosméticos o de texto sin lógica: cambiar
  un título, corregir una errata, retocar un mensaje, cambiar el estilo de
  un botón, renombrar una variable interna. Se registran con
  `"sdd": false` para no generar tres archivos de spec, ni hacer una
  entrevista, por un cambio de una línea. Renombrar deja de ser trivial si
  el nombre lo usan otros módulos (una función o clase pública) o forma
  parte de un contrato de datos (un campo que se guarda o se envía).

Un cambio es trivial solo si no añade ni altera lógica: ni ramas, ni
validaciones, ni firmas, ni contratos de datos, ni comportamiento que un
test tenga que comprobar. Si toca cualquiera de esas cosas, es
`"sdd": true`.

**Solo el humano decide que un cambio es trivial.** Ningún agente pone ni
cambia `"sdd": false` por su cuenta: el `leader` puede proponerlo, pero sin
un "sí" explícito del humano la feature es `"sdd": true`. Si durante la
implementación o la revisión resulta que el cambio toca lógica, el agente
para y el `leader` se lo plantea al humano.

`"sdd": false` omite solo la fase de spec. Una feature trivial que no sea
del ejemplo sigue necesitando el `APPROVED` del `reviewer` y la aprobación
final del humano para pasar a `done`: `./init.sh` falla sin ellos.
