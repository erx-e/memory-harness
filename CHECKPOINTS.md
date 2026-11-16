# CHECKPOINTS — Evaluación del estado final

> En sistemas multi-agente no se evalúa el camino, se evalúa el destino.
> Estos son los checkpoints objetivos que un juez (humano o IA) puede usar
> para decidir si el proyecto está sano.

> **Quién los recorre.** El `reviewer` recorre C1-C4 y C6, marca `[x]` o
> `[ ]` y emite `CHANGES_REQUESTED` si queda alguno vacío. C5 lo comprueba el
> leader al cerrar la feature, después del `APPROVED` y de la aprobación
> final del humano: antes no existe la entrada en `progress/history.md`.
>
> **Lo que comprueba una máquina.** Un check que dice «(`./init.sh` lo
> comprueba)» o «(lo comprueba `lint.sh`)» se marca con el resultado de
> `./init.sh`, que ejecuta los dos: no se revisa leyendo.
>
> **Plantilla.** C1, C2, C5 y C6 valen para cualquier proyecto. C3 y C4
> dependen del proyecto: el leader rellena contigo sus huecos `<...>` antes
> de tu primera feature (`docs/project-setup.md`). Lo que un check de C3 o C4
> permita comprobar sin juicio va a `lint.sh`, y el check lo dice. Al revisar
> una feature de ejemplo (`"example": true`), C3 y C4 son los de
> `docs/example/checkpoints.md`, y las rutas `docs/`, `specs/` y `progress/`
> de los demás checks llevan la subcarpeta `example/`.

## C1 — El arnés está completo

- [ ] Existen los 6 archivos base: `AGENTS.md`, `init.sh`, `memory.sh`,
      `lint.sh`, `feature_list.json`, `progress/current.md`.
- [ ] Existen los docs: `docs/brief.md`, `docs/architecture.md`,
      `docs/conventions.md`, `docs/verification.md`, `docs/lessons.md` y
      `docs/tags.md`.
- [ ] Existe el registro de pendientes: `progress/pending.md`.
- [ ] `./init.sh` termina con exit code 0.

## C2 — El estado es coherente

- [ ] Como mucho una feature en `in_progress` en `feature_list.json`
      (`./init.sh` lo comprueba).
- [ ] La memoria inmediata no pasa del umbral: como mucho 20 features
      cerradas en `feature_list.json`, cada una con su fecha `closed`, y como
      mucho 20 lecciones en `docs/lessons.md` (`./init.sh` lo comprueba).
- [ ] Toda feature que ya dejó `pending` y toda lección, activa o archivada,
      llevan entre 1 y 4 tags de `docs/tags.md` (`./init.sh` lo comprueba).
- [ ] Toda feature `done` tiene tests asociados que pasan.
- [ ] Toda feature `done` (con SDD, o que no sea del ejemplo) tiene
      `progress/review_<name>.md` con veredicto `APPROVED` (`./init.sh` lo
      comprueba).
- [ ] `progress/current.md` está en su plantilla o describe la feature en
      curso (no contiene restos de features ya cerradas). `./init.sh`
      comprueba que no da como en curso una feature `done` ni conserva sus
      decisiones de la entrevista.

## C3 — El código respeta la arquitectura

- [ ] <La estructura del código coincide con lo previsto en
      `docs/architecture.md`: di qué carpeta y qué se espera encontrar.>
- [ ] <Ningún import va contra la dirección de dependencias de
      `docs/architecture.md` › Principios: di qué regla de `lint.sh` lo
      comprueba, o por qué se comprueba leyendo.>
- [ ] <Regla sobre dependencias externas y dónde se comprueba.>
- [ ] <Restos que no deben quedar en el código (salidas de debug, TODOs sin
      contexto) y qué regla de `lint.sh` los detecta.>

## C4 — La verificación es real

- [ ] <Cobertura mínima exigida: qué debe tener test.>
- [ ] <Qué recursos reales usan los tests en lugar de mocks.>
- [ ] `<comando de tests>` muestra > 0 tests y todos verdes.

## C5 — La sesión se cerró bien

- [ ] No hay archivos sin trackear sospechosos (`*.tmp`, `__pycache__`
      fuera del `.gitignore`).
- [ ] `progress/history.md` tiene una entrada por la feature cerrada.
- [ ] La feature cerrada sigue en `feature_list.json` con `status: "done"` y
      su fecha `closed`; si con ella había más de 20 cerradas, las más
      antiguas pasaron a `feature_archive.json`.
- [ ] El humano la aprobó después del `APPROVED` del reviewer, y su entrada
      en `progress/history.md` lo registra con
      `- **Aprobación del usuario:** sí` (`./init.sh` lo comprueba).
- [ ] Lo que la feature dejó abierto está en `progress/pending.md` (hallazgos
      Menores, puntos fuera del spec, decisiones sin tomar) y lo que enseñó
      está codificado en un chequeo o en `docs/lessons.md`, con su fila, sus
      tags y su `**Mecanismo:**` (y, si pasaban de 20, las menos usadas en
      `docs/lessons-archive.md`), o no había nada que registrar.

## C6 — Spec Driven Development

- [ ] Toda feature con `"sdd": true` en estado `spec_ready`, `in_progress`
      o `done` tiene su carpeta `specs/<name>/` con los 3 archivos:
      `requirements.md`, `design.md`, `tasks.md` (`./init.sh` lo comprueba).
- [ ] `requirements.md` usa EARS estricto (ver `docs/specs.md`). `./init.sh`
      comprueba el patrón y que haya un solo `DEBE` por requirement; el
      reviewer, lo que pide juicio.
- [ ] Cada task cita los `R<n>` que cubre, y una feature `done` con
      `"sdd": true` tiene todas sus tasks marcadas `[x]` (`./init.sh` lo
      comprueba).
- [ ] Cada `R<n>` de `requirements.md` está cubierto por al menos un test
      concreto en `tests/`. `./init.sh` comprueba que el mapa del informe le
      da un test que existe; el reviewer, que ese test lo verifica de verdad.
