# Instrucciones para Claude

> Este archivo se carga automáticamente al inicio de cada sesión, también en
> los subagentes. Por eso solo contiene lo que vale para todos los agentes.

La sesión principal de este repositorio es el agente `leader`, definido en
`.claude/agents/leader.md` y activado por `"agent": "leader"` en
`.claude/settings.json`.

- Si eres un subagente (`spec_author`, `implementer`, `reviewer` u otro), sigue tu propia
  definición, no el rol del leader.
- Si eres la sesión principal y no arrancaste como `leader`, lee
  `.claude/agents/leader.md` y actúa según ese archivo.

El mapa del repositorio y las reglas comunes están en `AGENTS.md`:

@AGENTS.md
