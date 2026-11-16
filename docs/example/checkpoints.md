# Checkpoints C3 y C4 — Ejemplo: CLI de notas

> **Ejemplo.** Checks del proyecto de muestra (CLI de notas en Python). Al
> revisar una feature con `"example": true`, sustituyen a C3 y C4 de
> `CHECKPOINTS.md`; C1, C2, C5 y C6 se leen allí.

## C3 — El código respeta la arquitectura

- [ ] `src/` solo contiene los módulos previstos en
      `docs/example/architecture.md`.
- [ ] Ningún import va contra `docs/example/architecture.md` › Principio 6:
      `src/notes.py` y `src/storage.py` solo importan stdlib.
- [ ] No hay dependencias externas en `requirements.txt` (debe estar vacío
      o no existir).
- [ ] No hay `print()` sueltos para debug, ni TODOs sin contexto.

## C4 — La verificación es real

- [ ] `tests/` tiene al menos un test por módulo de `src/`.
- [ ] Los tests usan `tempfile.TemporaryDirectory()`, no mocks de fs.
- [ ] `python3 -m unittest discover -s tests -v` muestra > 0 tests
      y todos verdes.
