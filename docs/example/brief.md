# Brief — Ejemplo: CLI de notas

> **Ejemplo.** Brief del proyecto de muestra (CLI de notas en Python). Marca los límites solo de
> las features con `"example": true`; las del proyecto real se rigen por
> `docs/brief.md`.

## Visión

Un CLI mínimo para apuntar y recuperar notas personales sin salir de la
terminal. Existe sobre todo como proyecto de muestra del arnés: el código es
deliberadamente simple para que lo importante sea cómo se trabaja sobre él.

## Usuarios y qué necesitan

| Usuario                              | Momento                          | Qué necesita                                  |
|--------------------------------------|----------------------------------|-----------------------------------------------|
| Quien trabaja en la terminal         | quiere apuntar algo ya           | añadir una nota con un solo comando           |
| La misma persona, días después       | busca algo que apuntó            | listar, buscar, ver, editar y borrar notas    |
| Quien estudia el arnés               | lee el repo como ejemplo         | código pequeño, predecible y bien verificado  |

## Qué SÍ hace

- Añadir, listar, ver, borrar, buscar, editar notas y listar las más
  recientes.
- Guardar todo en un único archivo JSON local, con escritura atómica.

## Qué NO hace (y no debe hacer todavía)

- **Dependencias externas.** Solo la biblioteca estándar de Python.
- **Capas nuevas** (servicios, repositorios, ORM): tres módulos y nada más.
- **Sistema de configuración.** La ruta del archivo se pasa explícita o se
  usa la constante por defecto.
- **Otro almacenamiento** que no sea el archivo JSON local.

## Cómo se mide el éxito

Cada comando hace una sola cosa, con salida predecible y código de salida
correcto, y cada comportamiento está cubierto por un test.
