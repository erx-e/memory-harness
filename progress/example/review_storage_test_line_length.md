# Review — F-12

**Veredicto:** APPROVED

## Trazabilidad requirements ↔ tests
No aplica: feature sin spec.

## Tasks completas
No aplica: feature sin spec.

## Checkpoints
- C1: [x] — existen los 6 archivos base, los docs del ejemplo
  (`docs/example/`: `brief.md`, `architecture.md`, `conventions.md`,
  `verification.md`, `lessons.md`, `tags.md`) y
  `progress/example/pending.md`. `./init.sh` sale con código 0.
- C2: [x] — `./init.sh` en verde comprueba la parte mecánica. Los 27 tests
  pasan, y `progress/current.md:8-39` describe F-12, sin restos de otras
  features.
- C3: [x] — `lint.sh` comprueba los cuatro checks de
  `docs/example/checkpoints.md`, y el análisis estático está en verde
  (`ejemplo en verde (6 archivos)`).
- C4: [x] — hay un archivo de test por módulo (`lint.sh`).
  `tests/test_storage.py:14,18` crea y limpia su `TemporaryDirectory`, y el
  test cambiado escribe en `self.path`, dentro de ella. `tests/test_cli.py:17,24`
  hace lo mismo, y `tests/test_notes.py` no toca el disco.
  `python3 -m unittest discover -s tests` (el comando de `init.sh:492`) da
  27 tests, todos en verde.
- C6: [x] — F-12 es `"sdd": false`, así que no tiene spec ni `R<n>` que
  juzgar. `./init.sh` en verde comprueba la parte mecánica de las features
  con SDD. El test cambiado conserva su nombre y su comportamiento, y
  ningún mapa `R<n>` → test de otra feature lo cita.

## Fortalezas
- `tests/test_storage.py:24-29` — el dict se parte con una clave por línea,
  coma final y los delimitadores pegados, igual que `existing.append({…})`
  en `tests/test_cli.py:158-163`. No introduce un estilo nuevo.
- El cambio es mínimo y lo comprobé por mi cuenta. Son 6 líneas añadidas y
  1 quitada, en un solo statement, y no cambia nada más en `src/` ni en
  `tests/`:
  - El `ast.dump()` del archivo es idéntico al de `HEAD` (`True`).
  - Las líneas añadidas no tienen ningún `#`.
  - La línea más larga mide ahora 85 caracteres
    (`tests/test_storage.py:39`). En `HEAD`, la 24 medía 104.
  - `graphify affected "test_save_then_load_roundtrip"` no da dependientes.
    El test solo llama a `storage.save()` y `storage.load()`, que no
    cambian.
- `progress/example/impl_storage_test_line_length.md:21-34` — cada criterio
  de aceptación tiene su comprobación, con el método y el resultado, y todas
  se reproducen tal cual.
- `progress/current.md:26-33` — la bitácora se escribió mientras se
  trabajaba, con el plan anotado antes del cambio.

## Hallazgos

### Críticos (bloquean)
- Ninguno.

### Importantes (bloquean)
- Ninguno.

### Menores (no bloquean)
- `progress/example/impl_storage_test_line_length.md:43-44` — la lección
  propuesta dice «Si imprime `True`, solo cambió el formato», pero
  `ast.dump()` ignora los comentarios. Si se añade, se quita o se cambia un
  comentario, también imprime `True`: lo probé con `x = [1, 2]` frente a la
  misma lista partida en varias líneas con un `# TODO`. En F-12 la
  conclusión vale, porque las líneas añadidas no tienen ningún `#`. · Si
  el leader copia la lección tal cual a `docs/example/lessons.md`, un
  reviewer podría dar por «solo formato» un cambio que borra un comentario
  que explica un *por qué*, que son los únicos que admite
  `docs/example/conventions.md` › Comentarios. Debería decir «solo cambió
  el formato o los comentarios» y pedir que se compruebe en `git diff` que
  ninguna línea cambiada toca un `#`. Además, comparar con `HEAD` solo sirve
  mientras el cambio no esté commiteado; si lo está, la referencia es el
  commit base de la feature.

## Descartado por estar fuera del spec
- Dar a `tests/test_storage.py:34` (un dict de una sola línea, de 73
  caracteres) la misma forma que a las líneas 24-29 — el `acceptance` pide
  partir solo la línea 24 y dice que «solo cambia cómo se parte la línea».
  La 34 ya cumple el máximo.
- Los demás cambios sin commitear del árbol de trabajo (`init.sh`,
  `lint.sh`, docs, definiciones de agentes) — el leader indicó que no son
  de F-12, así que no los juzgué.

## Recomendaciones
- Ningún doc dice cómo se parte una línea larga, como señala el
  implementer en `progress/example/impl_storage_test_line_length.md:53-59`.
  Para F-12 no hace falta, porque hay precedente (`tests/test_cli.py:158`,
  `src/cli.py:77`) y el cambio lo sigue. Si el leader decide fijarlo,
  debería ser un chequeo de `lint.sh` y no una regla que se compruebe
  leyendo. `docs/example/conventions.md` › Estilo Python dice «Formato a
  mano: lo aplica la herramienta» y «Reglas que la herramienta no detecta:
  ninguna».
