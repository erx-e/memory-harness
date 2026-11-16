# CHECKPOINTS — Evaluación del estado final

> En sistemas multi-agente no se evalúa el camino, se evalúa el destino.
> Estos son los checkpoints objetivos que un juez (humano o IA) puede usar
> para decidir si el proyecto está sano.

> **Quién los recorre.** El `reviewer` recorre C1-C4 y C6, marca `[x]` o
> `[ ]` y emite `CHANGES_REQUESTED` si queda alguno vacío. C5 lo comprueba el
> leader al cerrar la feature, después del `APPROVED` y de la aprobación
> final del humano: antes no existe la entrada en `progress/history.md`.
>
> **Plantilla.** C1, C2, C5 y C6 valen para cualquier proyecto. C3 y C4
> dependen del proyecto: el leader rellena contigo sus huecos `<...>` antes
> de tu primera feature (`docs/project-setup.md`). Al revisar una feature de
> ejemplo (`"example": true`), C3 y C4 son los de
> `docs/example/checkpoints.md`, y las rutas `specs/` y `progress/` de los
> demás checks llevan la subcarpeta `example/`.

## C1 — El arnés está completo

- [ ] Existen los 4 archivos base: `AGENTS.md`, `init.sh`, `feature_list.json`,
      `progress/current.md`.
- [ ] Existen los docs: `docs/brief.md`, `docs/architecture.md`,
      `docs/conventions.md`, `docs/verification.md`, `docs/lessons.md`.
- [ ] Existe el registro de pendientes: `progress/pending.md`.
- [ ] `./init.sh` termina con exit code 0.

## C2 — El estado es coherente

- [ ] Como mucho una feature en `in_progress` en `feature_list.json`.
- [ ] Toda feature `done` tiene tests asociados que pasan.
- [ ] Toda feature `done` (con SDD, o que no sea del ejemplo) tiene
      `progress/review_<name>.md` con veredicto `APPROVED` (`./init.sh` lo
      comprueba).
- [ ] `progress/current.md` está en su plantilla o describe la feature en
      curso (no contiene restos de features ya cerradas).

## C3 — El código respeta la arquitectura

- [ ] <La estructura del código coincide con lo previsto en
      `docs/architecture.md`: di qué carpeta y qué se espera encontrar.>
- [ ] <Ningún import va contra la dirección de dependencias de
      `docs/architecture.md` › Principios: di cómo se comprueba.>
- [ ] <Regla sobre dependencias externas y dónde se comprueba.>
- [ ] <Restos que no deben quedar en el código: salidas de debug, TODOs sin
      contexto.>

## C4 — La verificación es real

- [ ] <Cobertura mínima exigida: qué debe tener test.>
- [ ] <Qué recursos reales usan los tests en lugar de mocks.>
- [ ] `<comando de tests>` muestra > 0 tests y todos verdes.

## C5 — La sesión se cerró bien

- [ ] No hay archivos sin trackear sospechosos (`*.tmp`, `__pycache__`
      fuera del `.gitignore`).
- [ ] `progress/history.md` tiene una entrada por la feature cerrada.
- [ ] La feature cerrada está en `feature_archive.json` con `status: "done"`
      y ya no figura en `feature_list.json`.
- [ ] El humano la aprobó después del `APPROVED` del reviewer, y su entrada
      en `progress/history.md` lo registra con
      `- **Aprobación del usuario:** sí` (`./init.sh` lo comprueba).
- [ ] Lo que la feature dejó abierto está en `progress/pending.md` (hallazgos
      Menores, puntos fuera del spec, decisiones sin tomar) y lo que enseñó
      está en `docs/lessons.md`, con su fila en el índice, o no había nada
      que registrar.

## C6 — Spec Driven Development

- [ ] Toda feature con `"sdd": true` en estado `spec_ready`, `in_progress`
      o `done` tiene su carpeta `specs/<name>/` con los 3 archivos:
      `requirements.md`, `design.md`, `tasks.md`.
- [ ] `requirements.md` usa EARS estricto (ver `docs/specs.md`).
- [ ] Toda feature `done` con `"sdd": true` tiene todas sus tasks marcadas
      `[x]` en `tasks.md`.
- [ ] Cada `R<n>` de `requirements.md` está cubierto por al menos un test
      concreto en `tests/`.
