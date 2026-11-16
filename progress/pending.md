# Pendientes — Decisiones del usuario y deuda

> Lo que está pendiente y **no es una feature**: decisiones que esperan al
> usuario, y deuda o mejoras detectadas fuera del alcance de una feature. Las
> features viven en `feature_list.json`; no se copian aquí.

> **Cómo usar este archivo.** Lo escribe el leader. Cada entrada lleva un id
> estable (`Q<n>` para decisiones, `D<n>` para deuda) que no se reutiliza:
> otros archivos citan el id, no copian el detalle. **Hecho es fuera:** cuando
> una decisión se toma, o una deuda se convierte en feature o se descarta, su
> entrada se borra de aquí; el rastro queda en `progress/history.md` o en
> `docs/lessons.md`. No anotes aquí estado que `./init.sh` ya sabe (tests en
> verde, features cerradas). Entradas rellenas de muestra:
> `progress/example/pending.md`.

## Decisiones pendientes del usuario

_Ninguna._

## Deuda y mejoras

_Ninguna._

## Estructura de las entradas

Copia el bloque que corresponda en su sección y quita la línea "Ninguna".

```markdown
### Q<n> · <La pregunta, tal como hay que respondérsela al usuario>

- **Contexto:** <por qué hace falta decidir>
- **Opciones:** <opción A> · <opción B>
- **Bloquea:** <qué feature o trabajo espera esta decisión, o "nada">
- **Origen:** <feature, revisión o conversación de donde salió>

### D<n> · <El problema, en una frase>

- **Problema:** <qué está mal o qué se podría mejorar>
- **Dónde:** <archivo:línea>
- **Arreglo propuesto:** <qué habría que hacer>
- **Gravedad:** <alta | media | baja> · **Esfuerzo:** <alto | medio | bajo>
- **Origen:** F-<id> (<informe o spec donde está el detalle>)
```
