# Checkpoints C3 y C4 — Ejemplo: CLI de notas

> **Ejemplo.** Checks del proyecto de muestra (CLI de notas en Python). Al
> revisar una feature con `"example": true`, sustituyen a C3 y C4 de
> `CHECKPOINTS.md`; C1, C2, C5 y C6 se leen allí. Los que dicen «(lo
> comprueba `lint.sh`)» se marcan con el resultado de `./init.sh`.

## C3 — El código respeta la arquitectura

- [ ] `src/` solo contiene los módulos previstos en
      `docs/example/architecture.md` (lo comprueba `lint.sh`).
- [ ] Ningún import va contra `docs/example/architecture.md` › Principio 6:
      `src/notes.py` y `src/storage.py` solo importan stdlib (lo comprueba
      `lint.sh`).
- [ ] No hay dependencias externas: ni imports de fuera de la stdlib ni
      `requirements.txt` con contenido (lo comprueba `lint.sh`).
- [ ] No hay `print()` sueltos para debug, ni TODOs sin contexto (lo
      comprueba `lint.sh`).

## C4 — La verificación es real

- [ ] `tests/` tiene un archivo de test por módulo de `src/` (lo comprueba
      `lint.sh`).
- [ ] Los tests usan `tempfile.TemporaryDirectory()`, no mocks de fs.
      `lint.sh` rechaza los mocks del filesystem; que cada test use su
      carpeta temporal y limpie tras de sí se comprueba leyendo.
- [ ] `python3 -m unittest discover -s tests -v` muestra > 0 tests
      y todos verdes.
