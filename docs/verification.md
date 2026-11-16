# Verificación — Cómo demostrar que el trabajo funciona

> Regla de oro: **el agente no dice "funciona", lo demuestra**.
> Toda feature termina con evidencia ejecutable, no con afirmaciones.

> **Plantilla.** Los huecos `<...>` los rellena el leader contigo antes de tu
> primera feature (`docs/project-setup.md`); al rellenarla se quitan esta nota
> y el texto que solo explica cómo rellenar. Ejemplo relleno:
> `docs/example/verification.md`.

## Niveles de verificación

### Nivel 1 — <tipo de test> (obligatorio)

<Qué tiene que estar cubierto y con qué casos como mínimo.>

Comando:
```bash
<comando que ejecuta estos tests>
```

### Nivel 2 — <tipo de test> (<cuándo es obligatorio>)

<Qué se verifica y contra qué entorno. Acompáñalo de un ejemplo corto.>

### Nivel 3 — <comprobación manual> (opcional)

<Flujo de extremo a extremo que se ejecuta antes de cerrar la sesión.>

```bash
<comandos del flujo>
```

### Nivel 4 — Trazabilidad de requirements (obligatorio para features con `"sdd": true`)

Cada `R<n>` del spec tiene al menos un test concreto. La regla y el formato
del mapa `R<n>` → test están en `docs/specs.md` › "Trazabilidad"; no se
repiten aquí.

## Arrancar la interfaz web

El reviewer comprueba las features que tocan la UI con procesos normales
(`curl`), `playwright-cli` o `chrome-devtools` (ver `docs/ui-review.md`).
Para eso necesita saber
cómo arrancar la app, dónde abrirla y cómo pararla. Si el proyecto no tiene
interfaz web, sustituye esta lista por «No aplica: sin interfaz web».

- Comando para arrancarla: <comando, ejecutado desde la raíz del repositorio>
- URL: <dirección local donde se abre>
- Cómo pararla: <comando o acción que la detiene>

## Anti-patrones (no hacer)

- ❌ <Práctica que no cuenta como verificación.> → <qué hacer en su lugar>

## Trampas del entorno

Lo que falla al ejecutar o verificar por una razón que no está en el código
que se está cambiando: desde dónde hay que lanzar los comandos, variables de
entorno, herramientas que se comportan distinto en esta máquina, secretos.
Una fila por trampa, con el error literal para que se reconozca al verlo.

| Si haces esto                          | Pasa esto                                  | Haz esto                                   |
|----------------------------------------|--------------------------------------------|--------------------------------------------|
| <comando o acción que parece correcta> | <error literal o efecto que produce>       | <comando o acción correcta>                |

Cuando descubras una trampa nueva, añádela aquí. Si además costó rastrearla,
el leader la registra también en `docs/lessons.md`.

## Verificación final antes de cerrar

```bash
./init.sh           # debe terminar con [OK] Entorno listo
```

Si `./init.sh` está rojo, el trabajo no está terminado y nada se cierra. Si
no puedes dejarlo verde, anota el bloqueo en `progress/current.md` y para.
