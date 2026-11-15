#!/usr/bin/env bash
# init.sh — Verificación e inicialización del entorno
#
# Este script lo ejecuta el agente al COMENZAR una sesión y antes de
# declarar cualquier tarea como `done`. Si falla, la sesión no debe avanzar.
#
# Salida esperada: códigos de salida claros y bloques marcados con [OK]/[FAIL].
#
# Uso:
#   ./init.sh            verificación completa (tests y grafo incluidos)
#   ./init.sh --status   solo validaciones rápidas y el estado del trabajo;
#                        lo usa el hook SessionStart para que cada sesión
#                        empiece con el estado real y no con lo último escrito

set -u
STATUS_ONLY=0
[ "${1:-}" = "--status" ] && STATUS_ONLY=1
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

ok()    { printf "${GREEN}[OK]${NC}    %s\n" "$1"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$1"; }
fail()  { printf "${RED}[FAIL]${NC}  %s\n" "$1"; }

EXIT_CODE=0

echo "── 1. Verificando entorno ─────────────────────────────"

# Python disponible
if ! command -v python3 >/dev/null 2>&1; then
  fail "python3 no está instalado"
  exit 1
fi
ok "python3 -> $(python3 --version)"

# Versión mínima 3.9 (dataclasses + typing moderno)
PY_VERSION_OK=$(python3 -c 'import sys; print(int(sys.version_info >= (3, 9)))')
if [ "$PY_VERSION_OK" != "1" ]; then
  fail "Se requiere Python >= 3.9"
  exit 1
fi
ok "Versión de Python compatible"

echo ""
echo "── 2. Verificando archivos base del arnés ──────────────"

for f in AGENTS.md feature_list.json progress/current.md progress/pending.md docs/brief.md docs/architecture.md docs/conventions.md docs/verification.md docs/lessons.md CHECKPOINTS.md; do
  if [ ! -f "$f" ]; then
    fail "Falta archivo base: $f"
    EXIT_CODE=1
  else
    ok "Existe $f"
  fi
done

echo ""
echo "── 3. Validando feature_list.json y specs ─────────────"

python3 - <<'PY'
import json, os, re, sys
try:
    data = json.load(open("feature_list.json"))
    valid = {"pending", "spec_ready", "in_progress", "done", "blocked"}
    in_progress = [f for f in data["features"] if f["status"] == "in_progress"]
    if len(in_progress) > 1:
        print(f"[FAIL]  Hay {len(in_progress)} features en in_progress (máximo 1)")
        sys.exit(1)
    requires_spec = {"spec_ready", "in_progress", "done"}
    spec_errors = []
    for f in data["features"]:
        if f["status"] not in valid:
            print(f"[FAIL]  Estado inválido en feature {f['id']}: {f['status']}")
            sys.exit(1)
        if f.get("sdd") and f["status"] in requires_spec:
            spec_dir = os.path.join("specs", f["name"])
            for fname in ("requirements.md", "design.md", "tasks.md"):
                if not os.path.isfile(os.path.join(spec_dir, fname)):
                    spec_errors.append(
                        f"feature {f['id']} ({f['name']}) en {f['status']} "
                        f"sin {spec_dir}/{fname}"
                    )
    if spec_errors:
        for e in spec_errors:
            print(f"[FAIL]  {e}")
        sys.exit(1)
    # Ninguna feature se cierra sin revisión: toda feature `done` con SDD, o
    # que no sea del proyecto de muestra, necesita un veredicto APPROVED.
    approved = re.compile(r"^\*\*Veredicto:\*\*\s*APPROVED\s*$", re.M)
    review_errors = []
    for f in data["features"]:
        if f["status"] != "done" or not (f.get("sdd") or not f.get("example")):
            continue
        review = os.path.join("progress", f"review_{f['name']}.md")
        if not os.path.isfile(review):
            review_errors.append(f"feature {f['id']} ({f['name']}) en done sin {review}")
        elif not approved.search(open(review, encoding="utf-8").read()):
            review_errors.append(
                f"feature {f['id']} ({f['name']}) en done sin veredicto APPROVED en {review}"
            )
    if review_errors:
        for e in review_errors:
            print(f"[FAIL]  {e}")
        sys.exit(1)
    # Quien aprueba el cambio final es el humano: toda feature real `done`
    # (sin "example") necesita una entrada en progress/history.md con la
    # línea "- **Aprobación del usuario:** sí".
    history = ""
    if os.path.isfile(os.path.join("progress", "history.md")):
        history = open(os.path.join("progress", "history.md"), encoding="utf-8").read()
    history = re.sub(r"^```.*?^```", "", history, flags=re.M | re.S)
    entries = re.split(r"^(?=#{2,3} )", history, flags=re.M)
    user_ok = re.compile(r"^- \*\*Aprobación del usuario:\*\*\s*s[ií]\b", re.M | re.I)
    approval_errors = []
    for f in data["features"]:
        if f["status"] != "done" or f.get("example"):
            continue
        heading = re.compile(rf"^#{{2,3}} .*\b{re.escape(f['name'])}\b")
        mine = [e for e in entries if heading.match(e)]
        if not mine:
            approval_errors.append(
                f"feature {f['id']} ({f['name']}) en done sin entrada en progress/history.md"
            )
        elif not any(user_ok.search(e) for e in mine):
            approval_errors.append(
                f"feature {f['id']} ({f['name']}) en done sin '- **Aprobación del usuario:** sí' "
                f"en su entrada de progress/history.md"
            )
    if approval_errors:
        for e in approval_errors:
            print(f"[FAIL]  {e}")
        sys.exit(1)
    # Ninguna feature real avanza con los docs del proyecto sin rellenar: las
    # reglas de «Ejemplo» valen solo para las features de ejemplo, así que un
    # hueco `<...>` en «Tu proyecto» deja a los agentes sin regla propia.
    # Solo se mira el texto corrido: lo que va entre comillas invertidas o en
    # un bloque de código puede usar `<así>` como notación (`test_<módulo>`).
    html_tags = {
        "a", "b", "br", "code", "details", "div", "em", "hr", "i", "img", "kbd",
        "li", "ol", "p", "pre", "span", "strong", "sub", "summary", "sup",
        "table", "tbody", "td", "th", "thead", "tr", "u", "ul",
    }
    harness_tokens = {"n", "name", "id", "feature"}
    def holes(path):
        try:
            text = open(path, encoding="utf-8").read()
        except OSError:
            return []
        m = re.search(r"^#{2,3} Tu proyecto\s*$", text, flags=re.M)
        if m:
            text = text[m.end():]
        text = re.sub(r"^```.*?^```", "", text, flags=re.M | re.S)
        text = re.sub(r"`[^`\n]*`", "", text)
        found = []
        for h in re.findall(r"<(\.\.\.|[^\W\d_][^<>]{0,400})>", text):
            first = re.split(r"[\s/]", h, maxsplit=1)[0].lower()
            if first in html_tags or h in harness_tokens:
                continue
            found.append("<" + " ".join(h.split()) + ">")
        return found
    gated = ("docs/architecture.md", "docs/conventions.md", "docs/verification.md", "CHECKPOINTS.md")
    real = [f for f in data["features"] if not f.get("example")]
    started = [f for f in real if f["status"] in requires_spec]
    unfilled = {p: h for p in gated if (h := holes(p))}
    if unfilled and started:
        s = started[0]
        for p, h in unfilled.items():
            print(
                f"[FAIL]  {p} › «Tu proyecto» tiene {len(h)} hueco(s) sin rellenar "
                f"(p. ej. {h[0][:60]}) y la feature {s['id']} ({s['name']}) ya está en {s['status']}"
            )
        print("[FAIL]  Rellénalos con el usuario antes de avanzar; lo no decidido se escribe como «Sin decidir», no se deja el hueco")
        sys.exit(1)
    for p, h in (unfilled.items() if real else ()):
        print(f"[WARN]  {p} › «Tu proyecto» tiene {len(h)} hueco(s): rellénalo antes del primer spec del proyecto")
    print(f"[OK]    feature_list.json válido ({len(data['features'])} features)")
    if real and not unfilled:
        print(f"[OK]    Docs del proyecto sin huecos en «Tu proyecto»")
    print(f"[OK]    Specs presentes para features sdd con estado no-pending")
    print(f"[OK]    Toda feature done tiene revisión APPROVED")
    print(f"[OK]    Toda feature real done tiene la aprobación del usuario en history.md")
except SystemExit:
    raise
except Exception as e:
    print(f"[FAIL]  feature_list.json o specs inválidos: {e}")
    sys.exit(1)
PY

if [ $? -ne 0 ]; then EXIT_CODE=1; fi

if [ "$STATUS_ONLY" -eq 0 ]; then

echo ""
echo "── 4. Ejecutando tests ─────────────────────────────────"

if [ -d "tests" ]; then
  if python3 -m unittest discover -s tests -v 2>&1; then
    ok "Todos los tests pasan"
  else
    fail "Hay tests rotos"
    EXIT_CODE=1
  fi
else
  warn "Carpeta tests/ no existe todavía"
fi

echo ""
echo "── 5. Grafo de contexto (graphify) ─────────────────────"

# Opcional: nunca cambia EXIT_CODE. Sin graphify el arnés funciona igual,
# pero los agentes tienen que leer el código para orientarse.
# `graphify update` solo analiza el código y los .md en local: no usa ningún
# modelo ni clave de API. Ver docs/graphify.md.
if command -v graphify >/dev/null 2>&1; then
  if GRAPH_OUT=$(graphify update . 2>&1); then
    GRAPH_SIZE=$(printf '%s\n' "$GRAPH_OUT" | sed -n 's/.*Rebuilt: //p' | head -1)
    ok "Grafo actualizado en graphify-out/ (${GRAPH_SIZE:-sin cambios})"
    # Wiki navegable: un artículo por grupo de código y un index.md de entrada.
    # Si nadie ha etiquetado los grupos con un modelo, usa los nombres
    # provisionales que graphify deduce en local.
    WIKI_LABELS=""
    if ! grep -q '[^{}[:space:]]' graphify-out/.graphify_labels.json 2>/dev/null \
       && [ -s graphify-out/.graphify_labels.pending.json ]; then
      WIKI_LABELS="graphify-out/.graphify_labels.pending.json"
    fi
    if WIKI_OUT=$(graphify export wiki ${WIKI_LABELS:+--labels "$WIKI_LABELS"} 2>&1); then
      ok "Wiki actualizado en graphify-out/wiki/ ($(printf '%s\n' "$WIKI_OUT" | sed -n 's/^Wiki: \([0-9]* articles\).*/\1/p' | head -1))"
    else
      warn "graphify export wiki falló; el wiki puede estar desactualizado"
    fi
  else
    warn "graphify update falló; el grafo puede estar desactualizado:"
    printf '%s\n' "$GRAPH_OUT" | tail -3
  fi
else
  warn "graphify no está instalado: no hay grafo de contexto (ver docs/graphify.md)"
fi

fi  # STATUS_ONLY

echo ""
echo "── 6. Estado del trabajo ───────────────────────────────"

# Informativo: nunca cambia EXIT_CODE. Es el estado REAL, derivado de los
# archivos en este momento. Manda sobre cualquier estado escrito a mano.
python3 - <<'PY'
import json, os, re, subprocess

def read(path):
    try:
        return open(path, encoding="utf-8").read()
    except OSError:
        return ""

def own_section(text):
    """La parte «Tu proyecto» (o todo el archivo si no hay partes), sin bloques de código."""
    text = re.sub(r"^```.*?^```", "", text, flags=re.M | re.S)
    m = re.search(r"^## Tu proyecto\s*$", text, flags=re.M)
    return text[m.end():] if m else text

try:
    feats = json.load(open("feature_list.json", encoding="utf-8"))["features"]
except Exception as e:
    print(f"[WARN]  No se pudo leer feature_list.json: {e}")
    raise SystemExit(0)

order = ["in_progress", "spec_ready", "blocked", "pending", "done"]
def counts(fs):
    return ", ".join(f"{n} {s}" for s in order if (n := sum(1 for f in fs if f.get("status") == s))) or "ninguna"

real = [f for f in feats if not f.get("example")]
example = [f for f in feats if f.get("example")]
print(f"  Features del proyecto: {counts(real)}")
if example:
    print(f"  Features de ejemplo:   {counts(example)}")

approved = re.compile(r"^\*\*Veredicto:\*\*\s*APPROVED\s*$", re.M)
changes = re.compile(r"^\*\*Veredicto:\*\*\s*CHANGES_REQUESTED\s*$", re.M)
for f in feats:
    name, st = f.get("name"), f.get("status")
    tag = f"#{f.get('id')} {name}"
    if st == "spec_ready":
        print(f"  ESPERA AL USUARIO:     {tag} tiene el spec en specs/{name}/; falta que lo apruebe")
    elif st == "in_progress":
        review = read(os.path.join("progress", f"review_{name}.md"))
        if approved.search(review):
            print(f"  ESPERA AL USUARIO:     {tag} está revisada (APPROVED); falta su aprobación final")
        elif changes.search(review):
            print(f"  En curso:              {tag}; el reviewer pidió cambios (progress/review_{name}.md)")
        elif os.path.isfile(os.path.join("progress", f"impl_{name}.md")):
            print(f"  En curso:              {tag}; implementada, falta la revisión")
        else:
            print(f"  En curso:              {tag}; en implementación")
    elif st == "blocked":
        print(f"  Bloqueada:             {tag}; ver progress/current.md")

pending = [f for f in real if f.get("status") == "pending"] or [f for f in example if f.get("status") == "pending"]
if pending:
    nxt = pending[0]
    kind = " (de ejemplo)" if nxt.get("example") else ""
    print(f"  Siguiente pendiente:   #{nxt.get('id')} {nxt.get('name')}{kind}")

reg = own_section(read(os.path.join("progress", "pending.md")))
q = len(re.findall(r"^#### Q\d+", reg, flags=re.M))
d = len(re.findall(r"^#### D\d+", reg, flags=re.M))
print(f"  Fuera de las features: {q} decisión(es) pendiente(s) del usuario, {d} deuda(s) (progress/pending.md)")

if real and re.search(r"<[^<>\n]{3,}>", own_section(read(os.path.join("docs", "brief.md")))):
    print("[WARN]  docs/brief.md › «Tu proyecto» tiene huecos sin rellenar y ya hay features del proyecto")

def git(*args):
    return subprocess.run(["git", *args], capture_output=True, text=True, timeout=10)
try:
    if git("rev-parse", "--is-inside-work-tree").stdout.strip() == "true":
        branch = git("rev-parse", "--abbrev-ref", "HEAD").stdout.strip() or "?"
        dirty = len([l for l in git("status", "--porcelain").stdout.splitlines() if l.strip()])
        print(f"  Git:                   rama {branch}, {dirty} archivo(s) con cambios sin commitear")
    else:
        print("  Git:                   esta carpeta no es un repositorio git")
except Exception:
    print("  Git:                   no se pudo consultar")
PY

echo ""
echo "── 7. Resumen ──────────────────────────────────────────"

if [ "$STATUS_ONLY" -eq 1 ]; then
  if [ $EXIT_CODE -eq 0 ]; then
    ok "Validaciones rápidas en verde. Tests y grafo NO ejecutados: usa ./init.sh"
  else
    fail "Hay validaciones en rojo. Ejecuta ./init.sh y resuélvelas antes de avanzar."
  fi
  exit $EXIT_CODE
fi

if [ $EXIT_CODE -eq 0 ]; then
  ok "Entorno listo. Puedes empezar a trabajar."
else
  fail "Entorno NO está listo. Resuelve los errores antes de avanzar."
fi

exit $EXIT_CODE
