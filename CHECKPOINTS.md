# CHECKPOINTS — Evaluación del estado final

> En sistemas multi-agente no se evalúa el camino, se evalúa el destino.
> Estos son los checkpoints objetivos que un juez (humano o IA) puede usar
> para decidir si el proyecto está sano.

> **Cómo usar esta plantilla.** C1, C2, C5 y C6 valen para cualquier proyecto.
> C3 y C4 dependen del proyecto y tienen dos partes: «Ejemplo», con los
> checks reales del proyecto de muestra (CLI de notas en Python), y «Tu
> proyecto», con la misma estructura vacía. Los checks de «Ejemplo» se
> evalúan solo al revisar una feature de ejemplo (`"example": true`), y ahí
> los de «Tu proyecto» se ignoran. En tus features se evalúan solo los de «Tu
> proyecto»: el leader los rellena contigo antes de la primera, y `./init.sh`
> falla si una feature tuya avanza con huecos `<...>`. No borres «Ejemplo» a
> mano: lo retira el leader, y solo si «Tu proyecto» ya está relleno.

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
- [ ] `progress/current.md` está vacío o describe la sesión activa
      (no contiene basura de sesiones anteriores).

## C3 — El código respeta la arquitectura

### Ejemplo: CLI de notas

- [ ] `src/` solo contiene los módulos previstos en `docs/architecture.md`.
- [ ] Ningún import va contra `docs/architecture.md` › Principio 6:
      `src/notes.py` y `src/storage.py` solo importan stdlib.
- [ ] No hay dependencias externas en `requirements.txt` (debe estar vacío
      o no existir).
- [ ] No hay `print()` sueltos para debug, ni TODOs sin contexto.

### Tu proyecto

- [ ] <La estructura del código coincide con lo previsto en
      `docs/architecture.md`: di qué carpeta y qué se espera encontrar.>
- [ ] <Ningún import va contra la dirección de dependencias de
      `docs/architecture.md` › Principios: di cómo se comprueba.>
- [ ] <Regla sobre dependencias externas y dónde se comprueba.>
- [ ] <Restos que no deben quedar en el código: salidas de debug, TODOs sin
      contexto.>

## C4 — La verificación es real

### Ejemplo: CLI de notas

- [ ] `tests/` tiene al menos un test por módulo de `src/`.
- [ ] Los tests usan `tempfile.TemporaryDirectory()`, no mocks de fs.
- [ ] `python3 -m unittest discover -s tests -v` muestra > 0 tests
      y todos verdes.

### Tu proyecto

- [ ] <Cobertura mínima exigida: qué debe tener test.>
- [ ] <Qué recursos reales usan los tests en lugar de mocks.>
- [ ] `<comando de tests>` muestra > 0 tests y todos verdes.

## C5 — La sesión se cerró bien

- [ ] No hay archivos sin trackear sospechosos (`*.tmp`, `__pycache__`
      fuera del `.gitignore`).
- [ ] `progress/history.md` tiene una entrada por la última sesión.
- [ ] La última feature trabajada está reflejada en su estado correcto.
- [ ] Si la feature está `done`, el humano la aprobó después del `APPROVED`
      del reviewer, y su entrada en `progress/history.md` lo registra con
      `- **Aprobación del usuario:** sí` (`./init.sh` lo comprueba).
- [ ] Lo que la feature dejó abierto está en `progress/pending.md` (hallazgos
      Menores, puntos fuera del spec, decisiones sin tomar) y lo que enseñó
      está en `docs/lessons.md`, o no había nada que registrar.

## C6 — Spec Driven Development

- [ ] Toda feature con `"sdd": true` en estado `spec_ready`, `in_progress`
      o `done` tiene su carpeta `specs/<name>/` con los 3 archivos:
      `requirements.md`, `design.md`, `tasks.md`.
- [ ] `requirements.md` usa EARS estricto (ver `docs/specs.md`).
- [ ] Toda feature `done` con `"sdd": true` tiene todas sus tasks marcadas
      `[x]` en `tasks.md`.
- [ ] Cada `R<n>` de `requirements.md` está cubierto por al menos un test
      concreto en `tests/`.

---

**Cómo usar este archivo:** un agente revisor (`.claude/agents/reviewer.md`)
recorre cada checkbox de C1-C4 y C6, marca `[x]` o `[ ]`, y emite
`CHANGES_REQUESTED` si queda alguno vacío. C5 lo comprueba el leader al
cerrar la sesión, después del `APPROVED` y de la aprobación final del
humano: antes de ese momento todavía no existe la entrada en
`progress/history.md`.
