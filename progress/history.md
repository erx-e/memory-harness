# Bitácora histórica (append-only)

> Cada vez que se cierra una feature, el leader añade su resumen aquí, al
> final. No edites entradas anteriores. `./init.sh` exige que la entrada de
> cada feature cerrada lleve la línea `- **Aprobación del usuario:** sí`.
> Entradas rellenas de muestra: `progress/example/history.md`.

## Estructura de una entrada

Copia el bloque al final del archivo por cada feature cerrada y rellénalo:

```markdown
### AAAA-MM-DD — F-<id>: <name>
- **Agente:** <quién trabajó, p. ej. leader → implementer → reviewer>
- **Plan:** <qué se quería conseguir, en una frase>
- **Cambios:** <archivos tocados y qué cambió en cada uno>
- **Verificación:** <resultado de `./init.sh` y veredicto, con la ruta del informe de revisión>
- **Aprobación del usuario:** <sí, AAAA-MM-DD; y los cambios que pidió antes de aprobar, si los hubo>
- **Cierre:** <estado final de la feature y próximo paso>
```

## Entradas

<!-- Añade cada entrada al final del archivo, debajo de este título. -->
