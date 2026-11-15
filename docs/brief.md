# Brief — Para qué existe el proyecto

> Este archivo casi no cambia. Define el *por qué* del proyecto y sus
> límites. Si una feature contradice algo de aquí, se discute aquí antes de
> redactar su spec.

> **Cómo usar este archivo.** Tiene dos partes con la misma estructura.
> «Ejemplo» es el brief del proyecto de muestra (CLI de notas en Python) y
> enseña cómo se rellena. «Tu proyecto» es esa estructura vacía: el leader la
> rellena contigo, preguntándote, antes de tu primera feature. No se deduce
> del código: el porqué y los límites solo los conoces tú. No borres
> «Ejemplo» a mano: lo retira el leader junto con el resto del ejemplo, y
> solo si «Tu proyecto» ya está relleno.

## Ejemplo: CLI de notas

### Visión

Un CLI mínimo para apuntar y recuperar notas personales sin salir de la
terminal. Existe sobre todo como proyecto de muestra del arnés: el código es
deliberadamente simple para que lo importante sea cómo se trabaja sobre él.

### Usuarios y qué necesitan

| Usuario                              | Momento                          | Qué necesita                                  |
|--------------------------------------|----------------------------------|-----------------------------------------------|
| Quien trabaja en la terminal         | quiere apuntar algo ya           | añadir una nota con un solo comando           |
| La misma persona, días después       | busca algo que apuntó            | listar, buscar, ver, editar y borrar notas    |
| Quien estudia el arnés               | lee el repo como ejemplo         | código pequeño, predecible y bien verificado  |

### Qué SÍ hace

- Añadir, listar, ver, borrar, buscar, editar notas y listar las más
  recientes.
- Guardar todo en un único archivo JSON local, con escritura atómica.

### Qué NO hace (y no debe hacer todavía)

- **Dependencias externas.** Solo la biblioteca estándar de Python.
- **Capas nuevas** (servicios, repositorios, ORM): tres módulos y nada más.
- **Sistema de configuración.** La ruta del archivo se pasa explícita o se
  usa la constante por defecto.
- **Otro almacenamiento** que no sea el archivo JSON local.

### Cómo se mide el éxito

Cada comando hace una sola cosa, con salida predecible y código de salida
correcto, y cada comportamiento está cubierto por un test.

## Tu proyecto

### Visión

<Qué es el proyecto y qué problema resuelve, en dos o tres frases.>

### Usuarios y qué necesitan

| Usuario                              | Momento                          | Qué necesita                                  |
|--------------------------------------|----------------------------------|-----------------------------------------------|
| <quién>                              | <en qué situación lo usa>        | <qué espera conseguir>                        |

### Qué SÍ hace

- <Capacidad que el proyecto ofrece o va a ofrecer.>

### Qué NO hace (y no debe hacer todavía)

- **<Lo que queda fuera.>** <Por qué, y qué tendría que pasar para
  reconsiderarlo.>

### Cómo se mide el éxito

<Qué resultado demuestra que el proyecto cumple su propósito. No cuentes
actividad (features hechas); cuenta el efecto que buscas.>
