# Revisión de UI

> Procedimiento del `reviewer` para comprobar una interfaz web. Vive aquí y
> no en su definición porque la mayoría de las features no lo necesitan:
> léelo solo cuando aplique.

**Cuándo aplica.** Solo si el spec aprobado justifica abrir el navegador
(`docs/verification.md`: en ningún tamaño se hace por defecto) y el cambio
toca una interfaz que se ve en el navegador (HTML, CSS, plantillas, componentes o JavaScript de cliente), o si
algún `R<n>` describe algo que el usuario ve o hace en una página. Si no, no
abras el navegador ni leas las skills. Una CLI de terminal no es una UI web:
su salida se revisa con los tests y ejecutándola.

## Qué vía usar

Elige la más ligera que compruebe lo que necesitas, y usa una sola vía por
comprobación:

| Vía | Para qué | Skill |
|-----|----------|-------|
| Procesos normales del sistema: `curl`, ejecutar la app, leer sus logs | Lo que se comprueba sin navegador: código de estado, cabeceras, redirecciones, HTML servido, respuestas de una API, errores del servidor | No tiene |
| `playwright-cli` (Playwright) | Flujos que necesitan navegador: formularios, navegación, pestañas, contenido que pinta JavaScript, vista móvil, Firefox o WebKit | `.claude/skills/playwright-cli/SKILL.md` |
| `chrome-devtools` (Puppeteer, de Google) | Diagnóstico en Chrome: auditoría Lighthouse (accesibilidad, SEO, buenas prácticas), estilos CSS aplicados, rendimiento, memoria, errores de consola con su línea en el código fuente | `.claude/skills/chrome-devtools-cli/SKILL.md` |

Antes de usar una de las dos CLI, lee su skill para conocer los comandos. Si
la skill choca con las reglas de este archivo, mandan estas reglas.

## Cómo

1. Arranca la app con el comando y la URL de `docs/verification.md` ›
   "Arrancar la interfaz web" (o de `progress/impl_<name>.md`, si la feature
   los cambia). Si no están documentados, no te los inventes: anota un
   hallazgo Menor («no está documentado cómo arrancar la UI para
   verificarla») y sigue con el resto del protocolo.
2. Trabaja con la vía elegida:
   - **Procesos normales**: solo comandos que leen, como `curl -s <url>` o
     `curl -sI <url>`. No cambies datos de la app ni archivos del
     repositorio.
   - **`playwright-cli`**: en modo headless (el de por defecto) y en la
     sesión por defecto. Comandos: `open`, `goto`, `snapshot`, `find`,
     `click`, `fill`, `type`, `press`, `select`, `check`, `hover`, `eval`,
     `console`, `requests`, `resize` y los de emulación. Para ver qué hay en
     la página, usa `snapshot` y `find`, que devuelven texto. Para atributos
     o estilos calculados, usa `eval`.
   - **`chrome-devtools`**: arráncala tú antes del primer comando, siempre
     con este bloque. Usa el Chromium de Playwright si está instalado (en
     WSL no hay Chrome) y desactiva el envío de URLs a Google (CrUX):

     ```bash
     CHROME=$(ls -d ~/.cache/ms-playwright/chromium-*/chrome-linux64/chrome 2>/dev/null | sort -V | tail -1)
     chrome-devtools start --performanceCrux=false --allowUnrestrictedPaths=false ${CHROME:+--executablePath "$CHROME"}
     ```

     Comandos: `new_page`, `navigate_page`, `list_pages`, `take_snapshot`,
     `click`, `fill`, `type_text`, `press_key`, `hover`, `evaluate_script`,
     `get_css_styles`, `list_console_messages`, `list_network_requests`,
     `get_network_request`, `emulate`, `resize_page`, `lighthouse_audit` y
     `performance_*`. Para ver qué hay en la página, usa `take_snapshot`,
     que devuelve texto.
3. Para cada `R<n>` de UI, reproduce el comportamiento y compáralo con lo que
   dice el requirement. Si no coinciden, es un hallazgo y se clasifica como
   cualquier otro.
4. Al terminar, cierra lo que abriste: `playwright-cli close` y
   `rm -rf .playwright-cli` (ahí guarda esa CLI sus snapshots y logs), o
   `chrome-devtools stop`. Después para la app como indica
   `docs/verification.md`.

**Solo las CLI.** No uses herramientas MCP de Playwright ni de Chrome
DevTools, no escribas scripts ni tests de Playwright o Puppeteer, y no uses
`npx playwright` ni `evaluate_script --sourcePath`. Si el proyecto tiene
tests de navegador, ya los ejecuta `./init.sh`.

## Capturas de pantalla: prohibidas por defecto

No uses ningún comando que genere o grabe una imagen, ni guardes en disco
informes o trazas, porque también las incluyen:

- `playwright-cli`: `screenshot`, `pdf`, `video-*`, `tracing-*`, `show` (su
  panel devuelve capturas anotadas), ni `run-code` o `eval` para capturar.
- `chrome-devtools`: `take_screenshot`, `screencast_*`, la opción
  `--experimentalVision` (sus comandos trabajan con capturas), las opciones
  `--filePath` y `--outputDirPath` (guardan trazas e informes completos de
  Lighthouse), ni `evaluate_script` para capturar. `lighthouse_audit` sin
  `--outputDirPath` sí puedes usarlo: devuelve texto.

Tampoco abras imágenes con `Read`. Lo que las skills proponen con capturas
(`show --annotate` para revisar UI, adjuntar capturas a un PR) no va
contigo.

Solo hay dos excepciones:

- **Te lo indican.** El prompt con el que te lanza el leader autoriza
  expresamente una captura de parte del humano. Haces solo esa captura, la
  miras y la borras al terminar.
- **Es realmente necesaria.** Un problema no se puede resolver sin ver la
  imagen (por ejemplo, un solapamiento o un color que los comandos de texto
  no revelan). **No la hagas**: pide permiso al humano a través del leader.
  1. Si ya tienes motivos para `CHANGES_REQUESTED`, no pidas la captura:
     emite ese veredicto y anota el punto en "Verificación de UI" para la
     siguiente ronda.
  2. Si no, termina el resto del protocolo y escribe
     `progress/review_<name>.md` con `**Veredicto:** SCREENSHOT_REQUESTED`.
     En "Verificación de UI" añade una "Solicitud de captura" con la página
     o el elemento, el comando exacto y por qué no bastan los comandos de
     texto (snapshot, estilos, `eval`).
  3. Responde `SCREENSHOT_REQUESTED -> progress/review_<name>.md`.

  El leader se lo pregunta al humano y te vuelve a lanzar con su respuesta.
  Si el humano dice que no, no haces la captura: anota en "Verificación de
  UI" lo que quedó sin verificar y emite el veredicto con lo que tienes.
