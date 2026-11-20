#!/usr/bin/env bash
# init.sh — Verificación del harness
#
# Comprueba el entorno, la cola de features y el código (lint.sh y los tests),
# e imprime el estado real del trabajo, que manda sobre lo escrito a mano en
# progress/. Si falla, nada se da por terminado.
#
# Uso:
#   ./init.sh             verificación completa: una vez por feature, la ejecuta
#                         quien implementa al terminar. En verde, deja anotado
#                         qué código comprobó
#   ./init.sh --status    solo validaciones rápidas y el estado del trabajo, con
#                         si esa verificación sigue valiendo para el código
#                         actual: la usan el hook de inicio de sesión y quien
#                         recibe el trabajo de otro
#   ./init.sh --check     solo las validaciones rápidas, sin el estado del
#                         trabajo: la usa el hook de fin de turno, que solo
#                         mira si algo está en rojo
#   ./init.sh --close <id>  cierra la feature tras la aprobación final del
#                         humano: `done`, su fecha y progress/current.md en su
#                         plantilla. No repite la verificación: exige que valga.
#                         Tampoco enseña el estado del trabajo (--status)

set -u
STATUS_ONLY=0
CHECK_ONLY=0
CLOSE_ID=""
case "${1:-}" in
  "") ;;
  --status) STATUS_ONLY=1 ;;
  --check) STATUS_ONLY=1; CHECK_ONLY=1 ;;
  --close)
    STATUS_ONLY=1
    CHECK_ONLY=1
    CLOSE_ID="${2:-}"
    if [ -z "$CLOSE_ID" ]; then
      echo "Uso: ./init.sh --close <id>   (el número de la feature: 3 o F-3)"
      exit 1
    fi
    ;;
  *)
    echo "Uso: ./init.sh [--status | --check | --close <id>]"
    exit 1
    ;;
esac

# La última verificación completa en verde se anota en $STAMP con la huella del
# código que comprobó, para no repetirla: --status y --close solo miran si esa
# huella sigue siendo la del código actual. CODE_PATHS son las carpetas que
# vigila H1 (.claude/settings.json) y estos dos scripts: si tu código vive en
# otras, cámbialas en los dos sitios.
export STAMP=".claude/state/verified.json"
export CODE_PATHS="src tests init.sh lint.sh"

# stamp check          → 0 si la última verificación en verde vale para el código actual
# stamp save <tests>   → la anota, con la feature que está en curso
stamp() {
  python3 - "$@" <<'PY'
import hashlib, json, os, subprocess, sys, time

paths = os.environ["CODE_PATHS"].split()

def files():
    # Con git, lo que no ignora .gitignore; sin git, todo lo que hay.
    try:
        r = subprocess.run(
            ["git", "ls-files", "-co", "--exclude-standard", "-z", "--", *paths], capture_output=True, timeout=30
        )
        if r.returncode == 0:
            return sorted({f for f in r.stdout.decode("utf-8", "surrogateescape").split("\0") if f})
    except Exception:
        pass
    found = []
    for p in paths:
        if os.path.isfile(p):
            found.append(p)
        for base, dirs, names in os.walk(p):
            dirs[:] = [d for d in dirs if d != "__pycache__" and not d.startswith(".")]
            found += [os.path.join(base, n) for n in names if not n.endswith(".pyc")]
    return sorted(found)

def state():
    h = hashlib.sha256()
    for f in files():
        h.update(os.fsencode(f))
        try:
            with open(f, "rb") as fh:
                h.update(hashlib.sha256(fh.read()).digest())
        except OSError:
            h.update(b"ausente")
    return h.hexdigest()

stamp = os.environ["STAMP"]
if sys.argv[1] == "save":
    feats = json.load(open("feature_list.json", encoding="utf-8"))["features"]
    current = next((f.get("id") for f in feats if f.get("status") == "in_progress"), None)
    os.makedirs(os.path.dirname(stamp), exist_ok=True)
    with open(stamp, "w", encoding="utf-8") as fh:
        json.dump({"code": state(), "feature": current, "tests": sys.argv[2], "at": time.strftime("%Y-%m-%d %H:%M")}, fh)
else:
    try:
        saved = json.load(open(stamp, encoding="utf-8")).get("code")
    except (OSError, ValueError):
        saved = None
    sys.exit(0 if saved == state() else 1)
PY
}
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
echo "── 2. Verificando archivos base del harness ────────────"

for f in AGENTS.md lint.sh feature_list.json progress/current.md progress/pending.md docs/brief.md docs/architecture.md docs/conventions.md docs/verification.md docs/lessons.md; do
  if [ ! -f "$f" ]; then
    fail "Falta archivo base: $f"
    EXIT_CODE=1
  else
    ok "Existe $f"
  fi
done

# Cierre de una feature (leader.md › Cierre). Va antes de validar la cola, para
# que las secciones 3 y 5 comprueben y enseñen el estado ya cerrado. Si algo no
# cuadra, no toca nada.
if [ -n "$CLOSE_ID" ]; then
  echo ""
  echo "── Cierre de la feature ───────────────────────────────"
  VERIFIED=0
  stamp check && VERIFIED=1
  VERIFIED=$VERIFIED python3 - "$CLOSE_ID" <<'PY'
import json, os, sys, time

TEMPLATE = """# Feature en curso

> Se vacía, dejando esta plantilla, al cerrar o abandonar la feature; no al
> cerrar la sesión.

- **Feature:** _ninguna_
- **Tamaño:** _—_
- **Estado:** _—_ (qué falta y quién lo tiene: el humano, el implementer…)

<!-- Debajo, cuando existen: «Decisiones — F-<id>», «Plan — F-<id>»,
«Diseño — F-<id>» y «Cambios pedidos por el usuario». Su formato está en
.claude/agents/leader.md. -->
"""

def stop(msg):
    print(f"[FAIL]  {msg}")
    sys.exit(1)

wanted = sys.argv[1].upper().removeprefix("F-")
try:
    data = json.load(open("feature_list.json", encoding="utf-8"))
except Exception as e:
    stop(f"feature_list.json inválido: {e}")
feat = next((f for f in data["features"] if str(f.get("id")) == wanted), None)
if feat is None:
    stop(f"No hay ninguna feature F-{wanted} en feature_list.json")
tag = f"F-{feat['id']} ({feat.get('name')})"
if feat.get("status") != "in_progress":
    stop(f"{tag} está en «{feat.get('status')}»: solo se cierra una feature in_progress")
if os.environ.get("VERIFIED") != "1":
    stop(
        f"{tag} no se cierra: el código cambió desde la última verificación completa en verde, "
        "o no hay ninguna. Ejecuta ./init.sh y vuelve a cerrar"
    )
feat["status"] = "done"
feat["closed"] = time.strftime("%Y-%m-%d")
with open("feature_list.json", "w", encoding="utf-8", newline="\n") as fh:
    fh.write(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
with open("progress/current.md", "w", encoding="utf-8", newline="\n") as fh:
    fh.write(TEMPLATE)
print(f"[OK]    {tag} cerrada el {feat['closed']}; progress/current.md, en su plantilla")
PY
  if [ $? -ne 0 ]; then
    fail "La feature no se cerró: no se ha cambiado nada"
    exit 1
  fi
fi

echo ""
echo "── 3. Validando la cola de features y los specs ───────"

python3 - <<'PY'
import json, os, re, sys

def read_text(path, strip_code=False):
    try:
        text = open(path, encoding="utf-8").read()
    except OSError:
        return None
    return re.sub(r"^```.*?^```", "", text, flags=re.M | re.S) if strip_code else text

def area(f, base):
    """Lo de una feature de ejemplo vive en la subcarpeta example/ de cada área."""
    return os.path.join(base, "example") if f.get("example") else base

try:
    data = json.load(open("feature_list.json", encoding="utf-8"))
    features = data["features"]
    VALID = {"pending", "spec_ready", "in_progress", "done", "blocked"}
    SIZES = ("small", "medium", "large")
    # El spec de una feature large es corto (.claude/agents/spec_author.md). Se
    # mira también en pending, para que el spec_author lo vea antes de entregarlo.
    SPEC_MAX = 150
    errors = []
    ids = [f.get("id") for f in features]
    for i in sorted({i for i in ids if ids.count(i) > 1}, key=str):
        errors.append(f"Id de feature repetido en feature_list.json: F-{i}")
    if sum(1 for f in features if f.get("status") == "in_progress") > 1:
        errors.append("Hay más de una feature en in_progress (máximo 1)")
    for f in features:
        tag = f"F-{f.get('id')} ({f.get('name')})"
        st, size = f.get("status"), f.get("size")
        if st not in VALID:
            errors.append(f"{tag}: estado «{st}» inválido (vale {', '.join(sorted(VALID))})")
            continue
        if size == "trivial":
            errors.append(f"{tag}: un cambio trivial no es una feature: sácalo de feature_list.json (.claude/agents/leader.md › Cambio trivial)")
        elif size is not None and size not in SIZES:
            errors.append(f"{tag}: size «{size}» inválido: vale {', '.join(SIZES)} (docs/verification.md)")
        if st in ("spec_ready", "in_progress") and size is None:
            errors.append(f"{tag} está en {st} sin «size»: lo pone el leader al confirmar la entrevista")
        if st == "done" and not re.fullmatch(r"\d{4}-\d{2}-\d{2}", str(f.get("closed", ""))):
            errors.append(
                f"{tag} está done sin su fecha «closed» (AAAA-MM-DD), que se pone con la aprobación final del humano"
            )
        if size == "large" and st != "done":
            spec_path = os.path.join(area(f, "specs"), str(f.get("name")), "spec.md")
            spec = read_text(spec_path)
            if spec is None:
                if st in ("spec_ready", "in_progress"):
                    errors.append(f"{tag} es large y está en {st} sin {spec_path}")
            else:
                used = sum(1 for line in spec.splitlines() if line.strip())
                if used > SPEC_MAX:
                    errors.append(
                        f"{spec_path} tiene {used} líneas con texto (máximo {SPEC_MAX}): recórtalo a frases "
                        "cortas (.claude/agents/spec_author.md)"
                    )
    # progress/current.md describe la feature en curso o está en su plantilla:
    # si conserva una ya cerrada, el siguiente agente leería decisiones ajenas.
    current = read_text(os.path.join("progress", "current.md"), strip_code=True) or ""
    current = re.sub(r"<!--.*?-->", "", current, flags=re.S)
    closed = {f.get("id"): f.get("name") for f in features if f.get("status") == "done"}
    cited = re.findall(r"\*\*Feature:\*\*[ \t]*F-(\d+)", current)
    cited += re.findall(r"^## (?:Decisiones|Plan|Diseño) — F-(\d+)", current, flags=re.M)
    for fid in sorted({int(i) for i in cited} & set(closed)):
        errors.append(
            f"progress/current.md conserva F-{fid} ({closed[fid]}), ya cerrada: déjalo en su plantilla "
            "(leader.md › Cierre)"
        )
    if errors:
        for e in errors:
            print(f"[FAIL]  {e}")
        sys.exit(1)
    # Ninguna feature real avanza con los docs del proyecto sin rellenar: las
    # reglas de docs/example/ valen solo para las features de ejemplo, así que
    # un hueco `<...>` en docs/ deja a los agentes sin regla propia. Solo cuenta
    # el texto corrido: lo que va entre comillas invertidas o en un bloque de
    # código puede usar `<así>` como notación (`test_<módulo>`).
    html_tags = {
        "a", "b", "br", "code", "details", "div", "em", "hr", "i", "img", "kbd",
        "li", "ol", "p", "pre", "span", "strong", "sub", "summary", "sup",
        "table", "tbody", "td", "th", "thead", "tr", "u", "ul",
    }
    harness_tokens = {"n", "name", "id", "feature"}
    def holes(path):
        text = read_text(path)
        if text is None:
            return []
        text = re.sub(r"^```.*?^```", "", text, flags=re.M | re.S)
        text = re.sub(r"`[^`\n]*`", "", text)
        found = []
        for h in re.findall(r"<(\.\.\.|[^\W\d_][^<>]{0,400})>", text):
            first = re.split(r"[\s/]", h, maxsplit=1)[0].lower()
            if first in html_tags or h in harness_tokens:
                continue
            found.append("<" + " ".join(h.split()) + ">")
        return found
    gated = ("docs/architecture.md", "docs/conventions.md", "docs/verification.md")
    real = [f for f in features if not f.get("example")]
    started = [f for f in real if f.get("status") != "pending"]
    unfilled = {p: h for p in gated if (h := holes(p))}
    # lint.sh lleva SIN_CONFIGURAR hasta que el leader escribe el análisis
    # estático del proyecto: es un hueco más de los docs.
    if re.search(r"^SIN_CONFIGURAR=1\b", read_text("lint.sh") or "", flags=re.M):
        unfilled["lint.sh"] = ["SIN_CONFIGURAR"]
    if unfilled and started:
        s = started[0]
        for p, h in unfilled.items():
            print(
                f"[FAIL]  {p} tiene {len(h)} hueco(s) sin rellenar "
                f"(p. ej. {h[0][:60]}) y la feature F-{s['id']} ({s['name']}) ya está en {s['status']}"
            )
        print("[FAIL]  Rellénalos con el humano antes de avanzar (docs/project-setup.md); lo no decidido se escribe como «Sin decidir», no se deja el hueco")
        sys.exit(1)
    for p, h in (unfilled.items() if real else ()):
        print(f"[WARN]  {p} tiene {len(h)} hueco(s): rellénalo antes de la primera feature del proyecto")
    print(f"[OK]    feature_list.json válido ({len(features)} features)")
    if real and not unfilled:
        print("[OK]    Docs del proyecto sin huecos")
    print("[OK]    Specs de las features large presentes y cortos")
    print("[OK]    progress/current.md sin restos de features cerradas")
except SystemExit:
    raise
except Exception as e:
    print(f"[FAIL]  feature_list.json inválido: {e}")
    sys.exit(1)
PY

if [ $? -ne 0 ]; then EXIT_CODE=1; fi

if [ "$STATUS_ONLY" -eq 0 ]; then

echo ""
echo "── 4. Análisis estático y tests ───────────────────────"

# lint.sh comprueba sin juicio las reglas del código que lo permiten (ver su
# cabecera). Como con los tests, en verde se imprime una línea y en rojo, sus
# fallos, que dicen dónde, qué hacer y qué doc fija la regla.
if [ -f lint.sh ]; then
  if LINT_OUT=$(bash lint.sh 2>&1); then
    ok "Análisis estático en verde ($(printf '%s\n' "$LINT_OUT" | tail -1))"
  else
    LINT_LINES=$(printf '%s\n' "$LINT_OUT" | wc -l)
    if [ "$LINT_LINES" -gt 40 ]; then
      echo "(primeros 40 de $LINT_LINES fallos; todos: ./lint.sh)"
    fi
    printf '%s\n' "$LINT_OUT" | head -40
    fail "Análisis estático en rojo (lint.sh)"
    EXIT_CODE=1
  fi
fi

# En verde solo se imprime el recuento: la lista de tests crece con la suite y
# cada agente la pagaría en contexto en cada ejecución. En rojo se imprime la
# salida de unittest sin -v, que solo detalla los tests que fallan.
if [ -d "tests" ]; then
  if TEST_OUT=$(python3 -m unittest discover -s tests 2>&1); then
    TEST_COUNT=$(printf '%s\n' "$TEST_OUT" | sed -n 's/^Ran \([0-9][0-9]* tests*\) in .*/\1/p' | tail -1)
    ok "Todos los tests pasan (${TEST_COUNT:-recuento no disponible})"
  else
    TEST_LINES=$(printf '%s\n' "$TEST_OUT" | wc -l)
    if [ "$TEST_LINES" -gt 80 ]; then
      echo "(últimas 80 de $TEST_LINES líneas; salida completa: python3 -m unittest discover -s tests)"
    fi
    printf '%s\n' "$TEST_OUT" | tail -80
    fail "Hay tests rotos"
    EXIT_CODE=1
  fi
else
  warn "Carpeta tests/ no existe todavía"
fi

# En verde, se anota qué código se comprobó: --status y --close miran esa
# huella en vez de repetir la verificación.
if [ $EXIT_CODE -eq 0 ]; then
  stamp save "${TEST_COUNT:-sin recuento de tests}"
fi

fi  # STATUS_ONLY

if [ "$CHECK_ONLY" -eq 0 ]; then

VERIFIED=0
stamp check && VERIFIED=1
export VERIFIED

echo ""
echo "── 5. Estado del trabajo ───────────────────────────────"

# Informativo: nunca cambia EXIT_CODE. Es el estado REAL, derivado de los
# archivos en este momento. Manda sobre cualquier estado escrito a mano.
python3 - <<'PY'
import json, os, re, subprocess

def read(path):
    try:
        return open(path, encoding="utf-8").read()
    except OSError:
        return ""

def prose(text):
    """El texto sin bloques de código: lo que hay en ellos es plantilla, no contenido."""
    return re.sub(r"^```.*?^```", "", text, flags=re.M | re.S)

def area(f, base):
    """Lo de una feature de ejemplo vive en la subcarpeta example/ de cada área."""
    return os.path.join(base, "example") if f.get("example") else base

try:
    feats = json.load(open("feature_list.json", encoding="utf-8"))["features"]
except Exception as e:
    print(f"[WARN]  No se pudo leer feature_list.json: {e}")
    raise SystemExit(0)

verified = os.environ.get("VERIFIED") == "1"
try:
    stamp = json.load(open(os.environ["STAMP"], encoding="utf-8"))
except (OSError, ValueError, KeyError):
    stamp = {}

order = ["in_progress", "spec_ready", "blocked", "pending", "done"]
def counts(fs):
    return ", ".join(f"{n} {s}" for s in order if (n := sum(1 for f in fs if f.get("status") == s))) or "ninguna"

real = [f for f in feats if not f.get("example")]
example = [f for f in feats if f.get("example")]
print(f"  Features del proyecto: {counts(real)}")
# Del proyecto de ejemplo solo se dice que existe: es una guía, no trabajo
# pendiente, así que sus features no se cuentan ni se anuncian. La línea
# desaparece al retirar el ejemplo (docs/project-setup.md).
if example:
    print("  Ejemplos:              incluidos solo como guía (carpetas example/)")

approved = re.compile(r"^\*\*Veredicto:\*\*\s*APPROVED\s*$", re.M)
changes = re.compile(r"^\*\*Veredicto:\*\*\s*CHANGES_REQUESTED\s*$", re.M)
screenshot = re.compile(r"^\*\*Veredicto:\*\*\s*SCREENSHOT_REQUESTED\s*$", re.M)
current = prose(read(os.path.join("progress", "current.md")))
for f in real:
    name, st, size = f.get("name"), f.get("status"), f.get("size")
    tag = f"F-{f.get('id')} {name}"
    review_path = os.path.join(area(f, "progress"), f"review_{name}.md")
    implemented = os.path.isfile(os.path.join(area(f, "progress"), f"impl_{name}.md"))
    # Una small la implementa el leader, sin informe: su señal es la
    # verificación completa en verde hecha con ella en curso.
    small_done = size == "small" and verified and stamp.get("feature") == f.get("id")
    if st == "pending" and re.search(rf"^## Plan — F-{f.get('id')}\b", current, flags=re.M):
        print(f"  ESPERA AL USUARIO:     {tag} tiene su plan en progress/current.md; falta que lo apruebe")
    elif st == "spec_ready":
        print(f"  ESPERA AL USUARIO:     {tag} tiene su spec en {area(f, 'specs')}/{name}/spec.md; falta que lo apruebe")
    elif st == "in_progress":
        review = read(review_path)
        if approved.search(review):
            print(f"  ESPERA AL USUARIO:     {tag} está revisada (APPROVED); falta su aprobación final")
        elif changes.search(review):
            print(f"  En curso:              {tag}; el reviewer pidió cambios ({review_path})")
        elif screenshot.search(review):
            print(f"  ESPERA AL USUARIO:     {tag}; el reviewer pide permiso para una captura de pantalla ({review_path})")
        elif small_done:
            print(f"  ESPERA AL USUARIO:     {tag} está implementada y verificada; falta su aprobación final")
        elif implemented and size != "large":
            print(f"  ESPERA AL USUARIO:     {tag} está implementada; falta su aprobación final")
        elif implemented:
            print(f"  En curso:              {tag}; implementada, falta la revisión")
        else:
            print(f"  En curso:              {tag}; en implementación")
    elif st == "blocked":
        print(f"  Bloqueada:             {tag}; ver progress/current.md")

pending = [f for f in real if f.get("status") == "pending"]
if pending:
    print(f"  Siguiente pendiente:   F-{pending[0].get('id')} {pending[0].get('name')}")
# Cuenta también las de ejemplo: un id no se reutiliza.
used = [f.get("id") for f in feats if isinstance(f.get("id"), int)]
print(f"  Siguiente id libre:    F-{max(used, default=0) + 1}")
if verified:
    print(f"  Verificación completa: en verde para el código actual ({stamp.get('tests')}, {stamp.get('at')}): no la repitas")
else:
    print("  Verificación completa: el código cambió desde la última en verde, o no hay ninguna: ./init.sh")

reg = prose(read(os.path.join("progress", "pending.md")))
q = len(re.findall(r"^#{3,4} Q\d+", reg, flags=re.M))
d = len(re.findall(r"^#{3,4} D\d+", reg, flags=re.M))
print(f"  Fuera de las features: {q} decisión(es) pendiente(s) del usuario, {d} deuda(s) (progress/pending.md)")

brief = re.sub(r"`[^`\n]*`", "", prose(read(os.path.join("docs", "brief.md"))))
if real and re.search(r"<[^<>\n]{3,}>", brief):
    print("[WARN]  docs/brief.md tiene huecos sin rellenar y ya hay features del proyecto")

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

fi  # CHECK_ONLY

echo ""
echo "── 6. Resumen ──────────────────────────────────────────"

if [ "$STATUS_ONLY" -eq 1 ]; then
  if [ $EXIT_CODE -eq 0 ]; then
    ok "Validaciones rápidas en verde. Análisis estático y tests NO ejecutados: usa ./init.sh"
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
