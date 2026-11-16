#!/usr/bin/env bash
# init.sh — Verificación e inicialización del entorno
#
# Este script lo ejecuta el agente al COMENZAR una sesión y antes de
# declarar cualquier tarea como `done`. Si falla, la sesión no debe avanzar.
#
# Salida esperada: códigos de salida claros y bloques marcados con [OK]/[FAIL].
#
# Uso:
#   ./init.sh            verificación completa (análisis estático, tests y grafo)
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

for f in AGENTS.md memory.sh lint.sh feature_list.json progress/current.md progress/pending.md docs/brief.md docs/architecture.md docs/conventions.md docs/verification.md docs/lessons.md docs/tags.md CHECKPOINTS.md; do
  if [ ! -f "$f" ]; then
    fail "Falta archivo base: $f"
    EXIT_CODE=1
  else
    ok "Existe $f"
  fi
done

# memory.sh es como los agentes consultan la memoria: si no responde con los
# archivos actuales, ningún protocolo puede seguir sus pasos de consulta.
if [ -f memory.sh ]; then
  if bash memory.sh tags >/dev/null 2>&1 && bash memory.sh tags --ejemplo >/dev/null 2>&1; then
    ok "memory.sh responde"
  else
    fail "memory.sh no responde: ejecuta ./memory.sh tags (y con --ejemplo) para ver el error"
    EXIT_CODE=1
  fi
fi

echo ""
echo "── 3. Validando feature_list.json y specs ─────────────"

python3 - <<'PY'
import glob, json, os, re, sys
try:
    data = json.load(open("feature_list.json", encoding="utf-8"))
    # feature_list.json es la cola: al cerrarse, una feature pasa a
    # feature_archive.json para que los agentes no carguen lo ya hecho. Las
    # validaciones de las features `done` recorren los dos archivos.
    archive = []
    if os.path.isfile("feature_archive.json"):
        archive = json.load(open("feature_archive.json", encoding="utf-8"))["features"]
    features = data["features"] + archive
    # Lo de una feature de ejemplo vive en la subcarpeta example/ de cada área.
    def area(f, base):
        return os.path.join(base, "example") if f.get("example") else base
    valid = {"pending", "spec_ready", "in_progress", "done", "blocked"}
    not_done = [f for f in archive if f["status"] != "done"]
    if not_done:
        f = not_done[0]
        print(f"[FAIL]  F-{f['id']} ({f['name']}) está en feature_archive.json con estado {f['status']}: ahí solo van las done")
        sys.exit(1)
    ids = [f["id"] for f in features]
    repeated = sorted({i for i in ids if ids.count(i) > 1})
    if repeated:
        print(f"[FAIL]  Ids de feature repetidos entre feature_list.json y feature_archive.json: {', '.join(f'F-{i}' for i in repeated)}")
        sys.exit(1)
    in_progress = [f for f in features if f["status"] == "in_progress"]
    if len(in_progress) > 1:
        print(f"[FAIL]  Hay {len(in_progress)} features en in_progress (máximo 1)")
        sys.exit(1)
    requires_spec = {"spec_ready", "in_progress", "done"}
    spec_errors = []
    for f in features:
        if f["status"] not in valid:
            print(f"[FAIL]  Estado inválido en F-{f['id']}: {f['status']}")
            sys.exit(1)
        if f.get("sdd") and f["status"] in requires_spec:
            spec_dir = os.path.join(area(f, "specs"), f["name"])
            for fname in ("requirements.md", "design.md", "tasks.md"):
                if not os.path.isfile(os.path.join(spec_dir, fname)):
                    spec_errors.append(
                        f"F-{f['id']} ({f['name']}) en {f['status']} "
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
    for f in features:
        if f["status"] != "done" or not (f.get("sdd") or not f.get("example")):
            continue
        review = os.path.join(area(f, "progress"), f"review_{f['name']}.md")
        if not os.path.isfile(review):
            review_errors.append(f"F-{f['id']} ({f['name']}) en done sin {review}")
        elif not approved.search(open(review, encoding="utf-8").read()):
            review_errors.append(
                f"F-{f['id']} ({f['name']}) en done sin veredicto APPROVED en {review}"
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
    for f in features:
        if f["status"] != "done" or f.get("example"):
            continue
        heading = re.compile(rf"^#{{2,3}} .*\b{re.escape(f['name'])}\b")
        mine = [e for e in entries if heading.match(e)]
        if not mine:
            approval_errors.append(
                f"F-{f['id']} ({f['name']}) en done sin entrada en progress/history.md"
            )
        elif not any(user_ok.search(e) for e in mine):
            approval_errors.append(
                f"F-{f['id']} ({f['name']}) en done sin '- **Aprobación del usuario:** sí' "
                f"en su entrada de progress/history.md"
            )
    if approval_errors:
        for e in approval_errors:
            print(f"[FAIL]  {e}")
        sys.exit(1)
    # Memoria inmediata y de largo plazo. Las features cerradas se quedan en
    # feature_list.json hasta que hay más de THRESHOLD; entonces las más
    # antiguas pasan a feature_archive.json. Las lecciones de docs/lessons.md
    # pasan a docs/lessons-archive.md empezando por las menos usadas. Los tags
    # conectan las entradas de las dos memorias y solo valen los registrados.
    THRESHOLD = 20
    tag_re = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
    date_re = re.compile(r"^\d{4}-\d{2}-\d{2}$")
    lesson_id = r"(?:ADR|Bug|CS)-\d+"
    def docs_dir(example):
        return os.path.join("docs", "example") if example else "docs"
    def read_text(path, strip_code=False):
        try:
            text = open(path, encoding="utf-8").read()
        except OSError:
            return None
        return re.sub(r"^```.*?^```", "", text, flags=re.M | re.S) if strip_code else text
    def registry(example):
        path = os.path.join(docs_dir(example), "tags.md")
        text = read_text(path, strip_code=True) or ""
        return path, {t for t in re.findall(r"^\|\s*`([^`]+)`\s*\|", text, flags=re.M) if tag_re.match(t)}
    registries = {example: registry(example) for example in (False, True)}
    def tag_errors(tags, owner, example):
        path, known = registries[example]
        if not isinstance(tags, list) or not 1 <= len(tags) <= 4:
            return [f"{owner} debe llevar entre 1 y 4 tags de {path}"]
        errors = []
        for t in tags:
            if not isinstance(t, str) or not tag_re.match(t):
                errors.append(f"{owner}: el tag {t!r} no sigue el formato (minúsculas, sin tildes, palabras unidas con guiones)")
            elif t not in known:
                errors.append(f"{owner}: el tag '{t}' no está en {path}")
        return errors
    def lessons(path):
        """Las entradas (id → texto) y el índice (id → tags) de un archivo de lecciones."""
        text = read_text(path, strip_code=True)
        if text is None:
            return None
        entries = {}
        for block in re.split(r"^(?=#### )", text, flags=re.M):
            m = re.match(rf"#### ({lesson_id})\b", block)
            if m:
                entries[m.group(1)] = block
        index, header = {}, None
        for line in text.splitlines():
            if not line.lstrip().startswith("|"):
                header = None
                continue
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if header is None:
                header = [c.lower() for c in cells]
            elif not re.fullmatch(r"[\s|:-]+", line):
                row = dict(zip(header, cells))
                if re.fullmatch(lesson_id, row.get("id", "")):
                    index[row["id"]] = re.findall(r"`([^`]+)`", row.get("tags", ""))
        return entries, index
    memory_errors = []
    for f in features:
        if "tags" in f or f["status"] in requires_spec:
            memory_errors += tag_errors(f.get("tags"), f"F-{f['id']} ({f['name']})", bool(f.get("example")))
        if "closed" in f and not date_re.match(str(f["closed"])):
            memory_errors.append(f"F-{f['id']} ({f['name']}): 'closed' debe ser una fecha AAAA-MM-DD")
    for example in (False, True):
        closed = [f for f in data["features"] if f["status"] == "done" and bool(f.get("example")) == example]
        memory_errors += [
            f"F-{f['id']} ({f['name']}) está done en feature_list.json sin su fecha 'closed'"
            for f in closed if "closed" not in f
        ]
        if len(closed) > THRESHOLD:
            oldest = sorted(closed, key=lambda f: (str(f.get("closed", "")), f["id"]))[: len(closed) - THRESHOLD]
            memory_errors.append(
                f"feature_list.json tiene {len(closed)} features cerradas (tope {THRESHOLD}): pasa a "
                "feature_archive.json las más antiguas: " + ", ".join(f"F-{f['id']} {f['name']}" for f in oldest)
            )
        active = os.path.join(docs_dir(example), "lessons.md")
        archived = os.path.join(docs_dir(example), "lessons-archive.md")
        parsed = {path: lessons(path) for path in (active, archived)}
        for path, found in parsed.items():
            entries, index = found or ({}, {})
            for lid in entries:
                if lid not in index:
                    memory_errors.append(f"{path}: {lid} no tiene fila en el índice, así que no tiene tags")
                else:
                    memory_errors += tag_errors(index[lid], f"{path} › {lid}", example)
        # Cada lección activa dice qué la hace cumplir: un chequeo, la D<n> que
        # lo creará o el juicio de quien la lee (leader.md › «Codificar las
        # lecciones en estructura»). Una D<n> citada sigue abierta en pending.md.
        debts_path = os.path.join("progress", "example", "pending.md") if example else os.path.join("progress", "pending.md")
        open_debts = set(re.findall(r"^#{3,4} (D\d+)\b", read_text(debts_path, strip_code=True) or "", flags=re.M))
        for lid, block in (parsed[active] or ({}, {}))[0].items():
            field = re.search(r"^- \*\*Mecanismo:\*\*(.*?)(?=^- \*\*|^#|\Z)", block, flags=re.M | re.S)
            if not field or not field.group(1).strip():
                memory_errors.append(
                    f"{active} › {lid} no tiene «- **Mecanismo:**»: di qué lo comprueba sin juicio, "
                    "qué D<n> lo hará o por qué requiere juicio"
                )
                continue
            for debt in sorted(set(re.findall(r"\bD\d+\b", field.group(1))) - open_debts):
                memory_errors.append(
                    f"{active} › {lid} cita {debt} como mecanismo, pero ya no está en {debts_path}: "
                    "pon el chequeo que la resolvió o «Requiere juicio»"
                )
        entries = (parsed[active] or ({}, {}))[0]
        if len(entries) <= THRESHOLD:
            continue
        # Último uso de una lección: la feature de id más alto que la cita en su
        # spec o en sus informes, o la de su «Origen». Se archivan primero las
        # de último uso más antiguo.
        texts = {}
        for f in features:
            if bool(f.get("example")) != example:
                continue
            paths = glob.glob(os.path.join(area(f, "specs"), f["name"], "*.md"))
            paths += [os.path.join(area(f, "progress"), f"{kind}_{f['name']}.md") for kind in ("spec", "impl", "review")]
            texts[f["id"]] = "\n".join(t for t in map(read_text, paths) if t)
        def last_use(lid):
            uses = [int(n) for n in re.findall(r"\*\*Origen:\*\*\s*(?:feature\s+#?|F-)(\d+)", entries[lid])[:1]]
            uses += [fid for fid, text in texts.items() if re.search(rf"\b{re.escape(lid)}\b", text)]
            return max(uses, default=0)
        use = {lid: last_use(lid) for lid in entries}
        order = list(entries)
        surplus = sorted(order, key=lambda lid: (use[lid], order.index(lid)))[: len(entries) - THRESHOLD]
        memory_errors.append(
            f"{active} tiene {len(entries)} lecciones (tope {THRESHOLD}): pasa a {archived} las menos usadas: "
            + ", ".join(f"{lid} (último uso: " + (f"F-{use[lid]}" if use[lid] else "ninguno") + ")" for lid in surplus)
        )
    if memory_errors:
        for e in memory_errors:
            print(f"[FAIL]  {e}")
        sys.exit(1)
    # El spec y el informe del implementer, contra las reglas de docs/specs.md
    # que no piden juicio; el reviewer conserva las que sí. El formato se mira
    # en el spec de toda feature sin cerrar, también en pending, para que el
    # spec_author lo compruebe antes de entregarlo; el de una feature done se
    # comprobó mientras estaba abierta.
    ears = re.compile(
        r"(?:(?:CUANDO|MIENTRAS|DONDE) .+?, el sistema|SI .+? ENTONCES el sistema|El sistema)"
        r" (?:NO )?DEBE\b"
    )
    soft_verb = re.compile(r"\bel sistema (?:podría|puede|soporta)\b", re.I)
    def section(text, title):
        m = re.search(rf"^## {title}\b[^\n]*\n(.*?)(?=^## |\Z)", text, flags=re.M | re.S)
        return m.group(1) if m else ""
    def tests_text():
        # La carpeta de tests del proyecto: si no es tests/, cámbiala aquí y en
        # la sección 4 (docs/project-setup.md, paso 4).
        chunks = []
        for root, dirs, names in os.walk("tests"):
            dirs[:] = [d for d in dirs if d != "__pycache__"]
            for name in names:
                try:
                    chunks.append(open(os.path.join(root, name), encoding="utf-8", errors="ignore").read())
                except OSError:
                    pass
        return "\n".join(chunks)
    format_errors = []
    for f in features:
        if not f.get("sdd"):
            continue
        spec_dir = os.path.join(area(f, "specs"), f["name"])
        req = read_text(os.path.join(spec_dir, "requirements.md"), strip_code=True)
        tasks_md = read_text(os.path.join(spec_dir, "tasks.md"), strip_code=True)
        reqs = re.findall(r"^## (R\d+)[ \t]*\n(.*?)(?=^#{1,2} |\Z)", req or "", flags=re.M | re.S)
        rids = [r for r, _ in reqs]
        tasks = re.findall(r"^- \[([ xX])\] (T\d+)\b(.*?)(?=^- \[|^#{1,3} |\Z)", tasks_md or "", flags=re.M | re.S)
        open_tasks = [t for state, t, _ in tasks if state == " "]
        if f["status"] == "done":
            if open_tasks:
                format_errors.append(
                    f"F-{f['id']} ({f['name']}) está done con tasks en [ ] en {spec_dir}/tasks.md: {', '.join(open_tasks)}"
                )
            continue
        where = f"{spec_dir}/requirements.md"
        if req is not None and not reqs:
            format_errors.append(f"{where} no tiene requirements con la forma «## R<n>» y su párrafo debajo (docs/specs.md › EARS)")
        for rid in sorted({r for r in rids if rids.count(r) > 1}):
            format_errors.append(f"{where}: {rid} está repetido; cada requirement tiene un id propio")
        for rid, body in reqs:
            prose = re.sub(r"`[^`\n]*`", "``", " ".join(body.split()))
            if not ears.match(prose):
                why = ("usa DEBE o NO DEBE, no un verbo blando" if soft_verb.search(prose)
                       else "no sigue ninguno de los seis patrones EARS")
                format_errors.append(f"{where} › {rid} {why} (docs/specs.md › EARS): «{prose[:70]}»")
            elif len(re.findall(r"\bDEBE\b", prose)) > 1:
                format_errors.append(f"{where} › {rid} tiene más de un DEBE o NO DEBE: pártelo en dos requirements")
        for _, tid, body in tasks:
            cited = re.findall(r"\bR\d+\b", body.split("Cubre:", 1)[1]) if "Cubre:" in body else []
            if not cited:
                format_errors.append(
                    f"{spec_dir}/tasks.md › {tid} no dice qué requirements cubre («Cubre: R1, R2»). Un paso de "
                    "proceso (escribir la trazabilidad, ejecutar ./init.sh) no es una task: ya está en el protocolo del implementer"
                )
            elif req is not None:
                unknown = sorted(set(cited) - set(rids), key=lambda r: int(r[1:]))
                if unknown:
                    format_errors.append(f"{spec_dir}/tasks.md › {tid} cubre {', '.join(unknown)}, que no existe en requirements.md")
        # El informe del implementer de la feature en curso: el mapa R<n> → test
        # está completo, sus tests existen y cada task en [ ] dice por qué.
        impl_path = os.path.join(area(f, "progress"), f"impl_{f['name']}.md")
        impl = read_text(impl_path, strip_code=True) if f["status"] == "in_progress" else None
        if impl is None:
            continue
        trace = {}
        for line in section(impl, "Trazabilidad").splitlines():
            m = re.match(r"\s*- (R\d+)\s*(?:→|->)(.*)", line)
            if m:
                trace.setdefault(m.group(1), []).extend(re.findall(r"`([^`]+)`", m.group(2).split("(", 1)[0]))
        for rid in rids:
            if not trace.get(rid):
                format_errors.append(f"{impl_path} › Trazabilidad: {rid} no tiene test («- {rid} → `nombre_del_test`»)")
        for rid in sorted(set(trace) - set(rids), key=lambda r: int(r[1:])):
            format_errors.append(f"{impl_path} › Trazabilidad cita {rid}, que no existe en requirements.md")
        corpus = tests_text()
        for name in sorted({n for names in trace.values() for n in names}):
            if not re.search(rf"(?<!\w){re.escape(name)}(?!\w)", corpus):
                format_errors.append(f"{impl_path} › Trazabilidad cita `{name}`, que no aparece en tests/")
        reasons = section(impl, "Tasks")
        for tid in open_tasks:
            if not re.search(rf"^\s*- {tid}\b\s*[:—–-]", reasons, flags=re.M):
                format_errors.append(
                    f"{tid} sigue en [ ] en {spec_dir}/tasks.md y {impl_path} › Tasks no dice por qué («- {tid}: <motivo>»)"
                )
    # progress/current.md describe la feature en curso o está en su plantilla:
    # si conserva una feature ya cerrada, el siguiente spec_author o
    # implementer recibiría decisiones de otra feature.
    current = read_text(os.path.join("progress", "current.md"), strip_code=True) or ""
    current = re.sub(r"<!--.*?-->", "", current, flags=re.S)
    closed = {f["id"]: f["name"] for f in features if f["status"] == "done"}
    cited = re.findall(r"Feature en curso:\**[ \t]*(?:F-)?(\d+)", current)
    cited += re.findall(r"^#{2,3} Decisiones de la entrevista\b[^\n]*?\bF-(\d+)", current, flags=re.M)
    for fid in sorted({int(i) for i in cited} & set(closed)):
        format_errors.append(
            f"progress/current.md conserva F-{fid} ({closed[fid]}), ya cerrada: déjalo en su plantilla "
            "(leader.md › Cierre de una feature)"
        )
    if format_errors:
        for e in format_errors:
            print(f"[FAIL]  {e}")
        sys.exit(1)
    # Ninguna feature real avanza con los docs del proyecto sin rellenar: las
    # reglas de docs/example/ valen solo para las features de ejemplo, así que
    # un hueco `<...>` en docs/ deja a los agentes sin regla propia.
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
        text = re.sub(r"^```.*?^```", "", text, flags=re.M | re.S)
        text = re.sub(r"`[^`\n]*`", "", text)
        found = []
        for h in re.findall(r"<(\.\.\.|[^\W\d_][^<>]{0,400})>", text):
            first = re.split(r"[\s/]", h, maxsplit=1)[0].lower()
            if first in html_tags or h in harness_tokens:
                continue
            found.append("<" + " ".join(h.split()) + ">")
        return found
    gated = ("docs/architecture.md", "docs/conventions.md", "docs/verification.md", "docs/tags.md", "CHECKPOINTS.md")
    real = [f for f in features if not f.get("example")]
    started = [f for f in real if f["status"] in requires_spec]
    unfilled = {p: h for p in gated if (h := holes(p))}
    # lint.sh lleva SIN_CONFIGURAR hasta que el leader escribe el análisis
    # estático del proyecto (docs/project-setup.md, paso 4): es un hueco más.
    if re.search(r"^SIN_CONFIGURAR=1\b", read_text("lint.sh") or "", flags=re.M):
        unfilled["lint.sh"] = ["SIN_CONFIGURAR"]
    if unfilled and started:
        s = started[0]
        for p, h in unfilled.items():
            print(
                f"[FAIL]  {p} tiene {len(h)} hueco(s) sin rellenar "
                f"(p. ej. {h[0][:60]}) y la feature F-{s['id']} ({s['name']}) ya está en {s['status']}"
            )
        print("[FAIL]  Rellénalos con el usuario antes de avanzar; lo no decidido se escribe como «Sin decidir», no se deja el hueco")
        sys.exit(1)
    for p, h in (unfilled.items() if real else ()):
        print(f"[WARN]  {p} tiene {len(h)} hueco(s): rellénalo antes del primer spec del proyecto")
    print(f"[OK]    feature_list.json válido ({len(data['features'])} features, {len(archive)} archivadas)")
    if real and not unfilled:
        print(f"[OK]    Docs del proyecto sin huecos")
    print(f"[OK]    Specs presentes para features sdd con estado no-pending")
    print(f"[OK]    Specs con formato válido (EARS, tasks con sus R<n>) y trazabilidad completa en la feature en curso")
    print(f"[OK]    Toda feature done tiene revisión APPROVED")
    print(f"[OK]    Toda feature real done tiene la aprobación del usuario en history.md")
    print(f"[OK]    progress/current.md sin restos de features cerradas")
    print(f"[OK]    Memoria dentro del umbral ({THRESHOLD} features cerradas y {THRESHOLD} lecciones activas), con tags registrados y el mecanismo de cada lección")
except SystemExit:
    raise
except Exception as e:
    print(f"[FAIL]  feature_list.json o specs inválidos: {e}")
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

def prose(text):
    """El texto sin bloques de código: lo que hay en ellos es plantilla, no contenido."""
    return re.sub(r"^```.*?^```", "", text, flags=re.M | re.S)

def area(f, base):
    """Lo de una feature de ejemplo vive en la subcarpeta example/ de cada área."""
    return os.path.join(base, "example") if f.get("example") else base

try:
    feats = json.load(open("feature_list.json", encoding="utf-8"))["features"]
    if os.path.isfile("feature_archive.json"):
        feats = feats + json.load(open("feature_archive.json", encoding="utf-8"))["features"]
except Exception as e:
    print(f"[WARN]  No se pudo leer feature_list.json o feature_archive.json: {e}")
    raise SystemExit(0)

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
for f in real:
    name, st = f.get("name"), f.get("status")
    tag = f"F-{f.get('id')} {name}"
    review_path = os.path.join(area(f, "progress"), f"review_{name}.md")
    if st == "spec_ready":
        print(f"  ESPERA AL USUARIO:     {tag} tiene el spec en {area(f, 'specs')}/{name}/; falta que lo apruebe")
    elif st == "in_progress":
        review = read(review_path)
        if approved.search(review):
            print(f"  ESPERA AL USUARIO:     {tag} está revisada (APPROVED); falta su aprobación final")
        elif changes.search(review):
            print(f"  En curso:              {tag}; el reviewer pidió cambios ({review_path})")
        elif screenshot.search(review):
            print(f"  ESPERA AL USUARIO:     {tag}; el reviewer pide permiso para una captura de pantalla ({review_path})")
        elif os.path.isfile(os.path.join(area(f, "progress"), f"impl_{name}.md")):
            print(f"  En curso:              {tag}; implementada, falta la revisión")
        else:
            print(f"  En curso:              {tag}; en implementación")
    elif st == "blocked":
        print(f"  Bloqueada:             {tag}; ver progress/current.md")

pending = [f for f in real if f.get("status") == "pending"]
if pending:
    print(f"  Siguiente pendiente:   F-{pending[0].get('id')} {pending[0].get('name')}")
# Cuenta también las archivadas: un id no se reutiliza.
used = [f.get("id") for f in feats if isinstance(f.get("id"), int)]
print(f"  Siguiente id libre:    F-{max(used, default=0) + 1}")

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

echo ""
echo "── 7. Resumen ──────────────────────────────────────────"

if [ "$STATUS_ONLY" -eq 1 ]; then
  if [ $EXIT_CODE -eq 0 ]; then
    ok "Validaciones rápidas en verde. Análisis estático, tests y grafo NO ejecutados: usa ./init.sh"
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
