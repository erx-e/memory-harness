# Tags — Vocabulario de la memoria

> Los tags dicen de qué trata cada feature y cada lección. Son los puntos de
> conexión de la memoria: una feature y una lección con el mismo tag tratan
> el mismo tema, estén en la memoria inmediata o en la de largo plazo.

> **Plantilla.** La rellena el leader contigo al preparar el proyecto
> (`docs/project-setup.md`), a partir de las capas y módulos de
> `docs/architecture.md`; al rellenarla se quita esta nota. Ejemplo relleno:
> `docs/example/tags.md`.

## Reglas

- Solo valen los tags de esta lista: `./init.sh` falla si una feature o una
  lección usa otro.
- Cada feature lleva entre 1 y 4 tags en cuanto deja `pending` (campo
  `"tags"` de su entrada), y cada lección, entre 1 y 4 en su fila del índice
  de `docs/lessons.md` o `docs/lessons-archive.md`.
- Formato: minúsculas, sin tildes y con las palabras unidas por guiones
  (`persistencia`, `validacion-entrada`).
- Un tema, un tag. Antes de añadir uno, comprueba que ninguno de la lista lo
  cubre ya: dos sinónimos parten las conexiones en dos.
- Los añade el leader, en el mismo cambio que la feature o la lección que
  los necesita. Un tag no se renombra ni se borra mientras lo use alguna
  entrada, activa o archivada.

## Tags

| Tag | Qué cubre |
|-----|-----------|
| `<tag>` | <Qué temas cubre y en qué partes del código; una línea por tag.> |
