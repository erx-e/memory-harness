# Implementación — storage_test_line_length

> F-12. Resumen de la implementación y trazabilidad `R<n> → test`.

## Resumen de cambios

- `tests/test_storage.py`
  - `test_save_then_load_roundtrip`: el dict de la línea 24 (104
    caracteres) se parte con una clave por línea y coma final, con los
    corchetes pegados, como `existing.append({…})` en
    `tests/test_cli.py:158`. Ahora ocupa las líneas 24-29.
  - No cambia nada más: ni los datos, ni el `storage.save`, ni el
    `assertEqual`.

## Trazabilidad

No aplica: feature sin spec.

## Verificación

Cada criterio de aceptación de F-12, y cómo se comprobó:

- «Ninguna línea de `tests/test_storage.py` pasa de 100 caracteres»: la
  más larga mide ahora 85 (`awk`), y `./lint.sh` sale en verde
  (`proyecto sin configurar · ejemplo en verde (6 archivos)`).
- «El test conserva los mismos datos y comprueba lo mismo»: el
  `ast.dump()` del archivo es idéntico al de `git show HEAD:tests/test_storage.py`.
  `ast.dump()` no incluye líneas ni columnas, así que el código es el mismo
  y solo cambia cómo se parte la línea.
- «`./init.sh` termina en verde»: ver la línea siguiente.

- `./init.sh` ejecutado al final, después de escribir este informe: en
  verde (código de salida 0). Análisis estático en verde (`proyecto sin
  configurar · ejemplo en verde (6 archivos)`) y 27 tests en verde.

## Tasks

No aplica: feature sin spec.

## Lecciones

- **Para comprobar que un cambio solo de formato no altera el código**,
  compara el `ast.dump()` del archivo con el de su versión antes del
  cambio, desde la raíz del repositorio: `HEAD` mientras el cambio no esté
  commiteado y, si lo está, el commit base de la feature. Si imprime
  `True`, solo cambió el formato o los comentarios: `ast.dump()` no ve los
  comentarios, así que comprueba en `git diff` que ninguna línea cambiada
  toca un `#`. Sirve al reviewer de F-12 y a cualquier feature de formato.
  (Corregida por el leader al cerrar F-12, según el hallazgo menor de
  `progress/example/review_storage_test_line_length.md`.)

  ```bash
  git show HEAD:<ruta> | python3 -c 'import ast, sys
  old = ast.dump(ast.parse(sys.stdin.read()))
  print(old == ast.dump(ast.parse(open("<ruta>", encoding="utf-8").read())))'
  ```

- **Fuera del alcance, sin tocar:** `docs/example/conventions.md` › Estilo
  Python delega la longitud de línea en `lint.sh`, que fija el máximo en 100
  caracteres (`lint.sh:138`), pero ninguno de los dos dice cómo se parte una
  línea larga. Seguí el precedente del código, una
  clave o un argumento por línea con coma final: `tests/test_cli.py:158` en
  un dict y `src/cli.py:77` en una llamada. Si hacen falta más particiones,
  el leader puede decidir si esa forma se fija en las convenciones. (Al
  cerrar F-12, el leader la codificó en `lint.sh` con el visto bueno del
  usuario.)

## Estado

Listo para review. La feature sigue en `in_progress`.
