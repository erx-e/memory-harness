#!/usr/bin/env bash
# memory.sh — Consulta la memoria del proyecto por tags e ids. Solo lee.
#
# Uso:
#   ./memory.sh F-<n>               lo conectado con una feature: lo que comparte
#                                   tags con ella y las lecciones que nacieron en
#                                   ella o que cita su spec o sus informes
#   ./memory.sh <tag> [<tag>...]    las features y lecciones con alguno de esos tags
#   ./memory.sh ADR-<n> | Bug-<n> | CS-<n>
#                                   una lección: las features que la citan y lo
#                                   que comparte tags con ella
#   ./memory.sh tags                la lista de tags y cuántas entradas usan cada uno
#
# Opciones:
#   --todo      enseña todos los resultados (por defecto, los 10 más conectados)
#   --ejemplo   busca en la memoria del proyecto de ejemplo; con F-<n> no hace
#               falta, porque lo decide la feature
#
# Devuelve una línea por entrada (id, nombre, estado, conexión y dónde leerla),
# separada en memoria inmediata y de largo plazo. Ordena primero lo conectado
# por id, después lo que comparte más tags y, a igualdad, lo más reciente.
# Nunca devuelve el contenido: abre solo lo que te sirva y cita por su id lo
# que uses. Ver README › "La memoria del proyecto".

set -u
cd "$(dirname "$0")" || exit 1
exec python3 - "$@" <<'PY'
import glob, json, os, re, sys

USAGE = "Uso: ./memory.sh F-<n> | <tag>... | ADR-<n> | Bug-<n> | CS-<n> | tags   [--todo] [--ejemplo]"
args = sys.argv[1:]
flags = {a for a in args if a.startswith("--")}
terms = [a for a in args if not a.startswith("--")]
if not terms or flags - {"--todo", "--ejemplo"}:
    sys.exit(USAGE)
LIMIT = None if "--todo" in flags else 10
TAG_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
LESSON_RE = re.compile(r"^(?:ADR|Bug|CS)-\d+$")
FEATURE_RE = re.compile(r"^F-(\d+)$")
IMMEDIATE, LONG_TERM = "inmediata", "largo plazo"
if len(terms) > 1 and any(FEATURE_RE.match(t) or LESSON_RE.match(t) for t in terms):
    sys.exit("Consulta un id cada vez y sin tags.\n" + USAGE)


def read(path):
    try:
        with open(path, encoding="utf-8") as fh:
            return fh.read()
    except OSError:
        return ""


def load_features(path, tier):
    try:
        with open(path, encoding="utf-8") as fh:
            items = json.load(fh).get("features", [])
    except (OSError, ValueError):
        return []
    return [dict(f, tier=tier, source=path) for f in items if isinstance(f, dict) and isinstance(f.get("id"), int)]


all_features = load_features("feature_list.json", IMMEDIATE) + load_features("feature_archive.json", LONG_TERM)

# La memoria del proyecto y la del ejemplo nunca se mezclan.
example = "--ejemplo" in flags
query = terms[0] if len(terms) == 1 else None
target = None
if query and FEATURE_RE.match(query):
    fid = int(FEATURE_RE.match(query).group(1))
    target = next((f for f in all_features if f["id"] == fid), None)
    if target is None:
        sys.exit(f"F-{fid} no está en feature_list.json ni en feature_archive.json")
    example = bool(target.get("example"))
DOCS = os.path.join("docs", "example") if example else "docs"
SPECS = os.path.join("specs", "example") if example else "specs"
PROGRESS = os.path.join("progress", "example") if example else "progress"
SCOPE = "memoria del ejemplo" if example else "memoria del proyecto"
features = [f for f in all_features if bool(f.get("example")) == example]


def load_registry(path):
    """Los tags de la tabla del registro, con lo que cubre cada uno."""
    registry, in_code = {}, False
    for line in read(path).splitlines():
        if line.startswith("```"):
            in_code = not in_code
            continue
        m = None if in_code else re.match(r"^\|\s*`([^`]+)`\s*\|\s*(.*?)\s*\|\s*$", line)
        if m and TAG_RE.match(m.group(1)):
            registry[m.group(1)] = m.group(2)
    return registry


def load_lessons(path, tier):
    """Las lecciones de un archivo: su fila del índice, su línea y su «Origen»."""
    index, heads, bodies = {}, {}, {}
    header, current, in_code = None, None, False
    for n, line in enumerate(read(path).splitlines(), 1):
        if line.startswith("```"):
            in_code = not in_code
            continue
        if in_code:
            continue
        if line.lstrip().startswith("|"):
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if header is None:
                header = [c.lower() for c in cells]
            elif not re.fullmatch(r"[\s|:-]+", line):
                row = dict(zip(header, cells))
                if LESSON_RE.match(row.get("id", "")):
                    index[row["id"]] = row
            continue
        header = None
        m = re.match(r"^#### ((?:ADR|Bug|CS)-\d+)\b", line)
        if m:
            current = m.group(1)
            heads[current], bodies[current] = n, []
        elif line.startswith("#"):
            current = None
        elif current:
            bodies[current].append(line)
    lessons = []
    for lid, row in index.items():
        origin = re.search(r"\*\*Origen:\*\*\s*(?:feature\s+#?|F-)(\d+)", "\n".join(bodies.get(lid, [])))
        lessons.append({
            "id": lid,
            "name": row.get("en una línea", "").replace("`", ""),
            "tags": re.findall(r"`([^`]+)`", row.get("tags", "")),
            "tier": tier,
            "where": f"{path}:L{heads[lid]}" if lid in heads else path,
            "origin": int(origin.group(1)) if origin else 0,
        })
    return lessons


REGISTRY_PATH = os.path.join(DOCS, "tags.md")
registry = load_registry(REGISTRY_PATH)
lessons = (load_lessons(os.path.join(DOCS, "lessons.md"), IMMEDIATE)
           + load_lessons(os.path.join(DOCS, "lessons-archive.md"), LONG_TERM))

# Quién cita cada lección: las features cuyo spec o informes nombran su id.
texts = {}
for f in features:
    paths = glob.glob(os.path.join(SPECS, f["name"], "*.md"))
    paths += [os.path.join(PROGRESS, f"{kind}_{f['name']}.md") for kind in ("spec", "impl", "review")]
    texts[f["id"]] = "\n".join(read(p) for p in paths)
for lesson in lessons:
    cite = re.compile(rf"\b{re.escape(lesson['id'])}\b")
    lesson["cited_by"] = [fid for fid, text in texts.items() if cite.search(text)]
    lesson["recency"] = max(lesson["cited_by"] + [lesson["origin"]])

HISTORY = os.path.join(PROGRESS, "history.md")
history_lines = read(HISTORY).splitlines()


def history_ref(name):
    heading = re.compile(rf"^#{{2,3}} .*\b{re.escape(name)}\b")
    return next((f"{HISTORY}:L{n}" for n, line in enumerate(history_lines, 1) if heading.match(line)), None)


def feature_entry(f):
    status = f.get("status", "?")
    if status == "done" and f.get("closed"):
        status = f"done {f['closed']}"
    spec_dir = os.path.join(SPECS, f["name"])
    where = [p for p in (spec_dir + "/" if os.path.isdir(spec_dir) else None, history_ref(f["name"])) if p]
    return {"id": f"F-{f['id']}", "name": f.get("name", ""), "status": status, "tags": f.get("tags") or [],
            "tier": f["tier"], "where": " · ".join(where) or f["source"], "recency": f["id"]}


def lesson_entry(lesson):
    status = f"último uso F-{lesson['recency']}" if lesson["recency"] else "sin usos"
    return {"id": lesson["id"], "name": lesson["name"], "status": status, "tags": lesson["tags"],
            "tier": lesson["tier"], "where": lesson["where"], "recency": lesson["recency"]}


def collect(base_tags, links, skip):
    """Lo conectado por tags o por id, de lo más a lo menos conectado."""
    found = []
    for entry in [feature_entry(f) for f in features] + [lesson_entry(l) for l in lessons]:
        if entry["id"] == skip:
            continue
        entry["shared"] = [t for t in base_tags if t in entry["tags"]]
        entry["link"] = links.get(entry["id"])
        if entry["shared"] or entry["link"]:
            found.append(entry)
    found.sort(key=lambda e: (e["link"] is None, -len(e["shared"]), -e["recency"]))
    return found


def cut(text, width):
    return text if len(text) <= width else text[: width - 1] + "…"


def show(header, found, note=None):
    print(header)
    if note:
        print(note)
    if not found:
        print("  Nada conectado.")
        return
    shown = found if LIMIT is None else found[:LIMIT]
    for tier, title in ((IMMEDIATE, "Inmediata"), (LONG_TERM, "Largo plazo")):
        rows = [e for e in shown if e["tier"] == tier]
        if rows:
            print(title)
        for e in rows:
            link = e["link"] or ""
            conn = " · ".join(p for p in (", ".join(e["shared"]), link) if p)
            print(f"  {e['id']:<7} {cut(e['name'], 34):<34} {cut(e['status'], 18):<18} {cut(conn, 30):<30} {e['where']}")
    if len(shown) < len(found):
        print(f"({len(found) - len(shown)} más: usa --todo)")


# ── ./memory.sh tags ──────────────────────────────────────────────────────
if terms == ["tags"]:
    if not registry:
        print(f"{REGISTRY_PATH} todavía no tiene tags: se rellena al preparar el proyecto (docs/project-setup.md).")
        sys.exit(0)

    def count(items, tag, tier):
        return sum(1 for i in items if i["tier"] == tier and tag in (i.get("tags") or []))

    print(f"Tags de {REGISTRY_PATH} ({SCOPE})")
    print(f"  {'tag':<18} {'features inm/lp':<16} {'lecciones inm/lp':<17} qué cubre")
    for tag, covers in registry.items():
        fc = f"{count(features, tag, IMMEDIATE)}/{count(features, tag, LONG_TERM)}"
        lc = f"{count(lessons, tag, IMMEDIATE)}/{count(lessons, tag, LONG_TERM)}"
        print(f"  {tag:<18} {fc:<16} {lc:<17} {covers}")
    sys.exit(0)

# ── ./memory.sh F-<n> ─────────────────────────────────────────────────────
if target is not None:
    fid = target["id"]
    links = {}
    for lesson in lessons:
        if lesson["origin"] == fid:
            links[lesson["id"]] = "origen"
        elif fid in lesson["cited_by"]:
            links[lesson["id"]] = "citada"
    tags = target.get("tags") or []
    header = f"Memoria conectada con F-{fid} {target['name']} [{', '.join(tags)}] · {target['tier']} · {SCOPE}"
    note = None if tags else "  Esta feature todavía no tiene tags: solo salen sus conexiones por id."
    show(header, collect(tags, links, f"F-{fid}"), note)
    sys.exit(0)

# ── ./memory.sh ADR-<n> | Bug-<n> | CS-<n> ────────────────────────────────
if query and LESSON_RE.match(query):
    lesson = next((l for l in lessons if l["id"] == query), None)
    if lesson is None:
        hint = "" if example else " (si es del ejemplo, añade --ejemplo)"
        sys.exit(f"{query} no está en {DOCS}/lessons.md ni en {DOCS}/lessons-archive.md{hint}")
    links = {}
    for f in features:
        if f["id"] == lesson["origin"]:
            links[f"F-{f['id']}"] = "origen"
        elif f["id"] in lesson["cited_by"]:
            links[f"F-{f['id']}"] = "la cita"
    header = (f"{query} · {lesson['name']} [{', '.join(lesson['tags'])}] · {lesson['tier']} · "
              f"{lesson['where']} · {SCOPE}")
    show(header, collect(lesson["tags"], links, query))
    sys.exit(0)

# ── ./memory.sh <tag>... ──────────────────────────────────────────────────
bad = [t for t in terms if not TAG_RE.match(t)]
if bad:
    sys.exit(f"No es un id ni un tag válido: {', '.join(bad)}\n{USAGE}")
unknown = [t for t in terms if t not in registry]
if unknown:
    print(f"Aviso: {', '.join(unknown)} no está en {REGISTRY_PATH}; ninguna entrada puede llevarlo.", file=sys.stderr)
show(f"Memoria con los tags [{', '.join(terms)}] · {SCOPE}", collect(terms, {}, None))
PY
