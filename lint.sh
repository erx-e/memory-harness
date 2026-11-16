#!/usr/bin/env bash
# lint.sh — Análisis estático del código
#
# Comprueba sin juicio las reglas del código que lo permiten, para que nadie
# tenga que revisarlas leyendo (.claude/agents/leader.md › «Codificar las
# lecciones en estructura»). Lo ejecuta ./init.sh en su sección 4, antes de
# los tests, y se puede lanzar solo desde la raíz del repositorio: ./lint.sh
#
# En verde imprime una línea de resumen. En rojo, una línea por fallo, con
# dónde está, qué hacer y qué doc fija la regla, y sale con código 1. El
# mensaje es la instrucción: lo que se comprueba aquí no se repite en los
# docs, que solo dicen «(lo comprueba lint.sh)».
#
# Tiene dos bloques:
#   Proyecto  el análisis estático del proyecto real. Lo escribe el leader al
#             preparar el proyecto (docs/project-setup.md, paso 4).
#   Ejemplo   las reglas mecánicas de docs/example/, solo sobre los archivos
#             del ejemplo. Se borra al retirar el ejemplo.

set -u
STATUS=0
SUMMARY=""
summary() { SUMMARY="${SUMMARY:+$SUMMARY · }$1"; }

# ── Proyecto ─────────────────────────────────────────────
# Un comando por línea dentro de project_rules, cada uno terminado en
# `|| rc=1` y sin salida en verde: el linter estándar del stack (ruff,
# eslint, golangci-lint…) configurado con las reglas de docs/conventions.md,
# y chequeos propios solo para lo que ninguna herramienta cubre, como la
# dirección de imports de docs/architecture.md › Principio 1. Al escribirlo,
# borra la línea SIN_CONFIGURAR: ./init.sh la trata como un hueco de los docs
# del proyecto. Si el humano decide no tener análisis estático, deja
# project_rules vacío, borra la línea y anota aquí su decisión.
SIN_CONFIGURAR=1
project_rules() {
  local rc=0
  return $rc
}

if [ "${SIN_CONFIGURAR:-0}" = 1 ]; then
  summary "proyecto sin configurar"
elif OUT=$(project_rules 2>&1); then
  summary "proyecto en verde"
else
  printf '%s\n' "$OUT"
  STATUS=1
fi

# ── Ejemplo (se borra al retirar el ejemplo: docs/project-setup.md) ──
# Las reglas de docs/example/ que no piden juicio. Es una comprobación propia
# con la biblioteca estándar porque el ejemplo no admite dependencias; en un
# proyecto real se usa el linter de su stack.
example_rules() {
python3 - <<'PY'
"""Las reglas mecánicas de docs/example/, sobre los archivos del ejemplo."""
import ast
import io
import json
import os
import re
import sys
import tokenize

SRC = ("src/notes.py", "src/storage.py", "src/cli.py")
TESTS = ("tests/test_notes.py", "tests/test_storage.py", "tests/test_cli.py")
ARCH = "docs/example/architecture.md"
CONV = "docs/example/conventions.md"
# Módulos de src/ que puede importar cada uno (Principio 6).
LOCAL_OK = {"src/cli.py": {"notes", "storage"}, "src/notes.py": set(), "src/storage.py": set()}
# Métodos de unittest que se redefinen con su nombre en camelCase.
UNITTEST = {"setUp", "tearDown", "setUpClass", "tearDownClass",
            "setUpModule", "tearDownModule", "asyncSetUp", "asyncTearDown"}
FS_TARGETS = ("builtins.open", "io.open", "os.", "pathlib.", "shutil.", "tempfile.")
FS_MODULES = {"builtins", "io", "os", "pathlib", "shutil", "tempfile"}
failures = []


def fail(path, line, what, source):
    failures.append(f"[FAIL]  {path}:{line} — {what} ({source})")


def is_stdlib(name):
    names = getattr(sys, "stdlib_module_names", None)  # Python 3.10+
    if names is not None:
        return name in names
    import importlib.util
    import sysconfig
    spec = importlib.util.find_spec(name)
    origin = (spec.origin or "") if spec else ""
    return spec is not None and (origin in ("built-in", "frozen") or (
        origin.startswith(sysconfig.get_paths()["stdlib"]) and "-packages" not in origin))


def imported(node):
    """(módulos de src/ que importa, módulos de fuera de src/ que importa)."""
    local, outside = set(), set()
    if isinstance(node, ast.Import):
        for alias in node.names:
            parts = alias.name.split(".")
            if parts[0] == "src":
                local.add(parts[1] if len(parts) > 1 else "src")
            else:
                outside.add(parts[0])
    elif isinstance(node, ast.ImportFrom):
        parts = (node.module or "").split(".")
        if node.level:
            local |= {parts[0]} if node.module else {a.name for a in node.names}
        elif parts[0] == "src":
            local |= {parts[1]} if len(parts) > 1 else {a.name for a in node.names}
        else:
            outside.add(parts[0])
    return local, outside


def real_features():
    found = []
    for path in ("feature_list.json", "feature_archive.json"):
        try:
            with open(path, encoding="utf-8") as fh:
                found += [f for f in json.load(fh)["features"] if not f.get("example")]
        except (OSError, ValueError, KeyError):
            pass
    return found


files = [p for p in SRC + TESTS if os.path.isfile(p)]
for path in files:
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    try:
        tree = ast.parse(text, filename=path)
    except SyntaxError as e:
        fail(path, e.lineno, f"no compila: {e.msg}", f"{ARCH} › Stack y dependencias")
        continue
    is_src = path in SRC

    for n, line in enumerate(text.splitlines(), 1):
        if len(line) > 100:
            fail(path, n, f"{len(line)} caracteres: parte la línea, el máximo es 100",
                 f"{CONV} › Estilo Python")
    for tok in tokenize.generate_tokens(io.StringIO(text).readline):
        if tok.type == tokenize.COMMENT:
            word = re.search(r"\b(TODO|FIXME|XXX|HACK)\b", tok.string)
            if word and not re.search(r"\b(F-\d+|D\d+|Q\d+)\b", tok.string):
                fail(path, tok.start[0], f"{word.group(1)} sin contexto: cita la feature, la deuda o la "
                     "decisión que lo resuelve (F-<id>, D<n> o Q<n>), o quítalo",
                     "AGENTS.md § 3 y docs/example/checkpoints.md › C3")

    # Imports: capas, solo biblioteca estándar, orden y uno por línea.
    seen_local = False
    for node in tree.body:
        if not isinstance(node, (ast.Import, ast.ImportFrom)):
            continue
        if isinstance(node, ast.ImportFrom) and node.module == "__future__":
            continue
        local, outside = imported(node)
        if outside and seen_local:
            fail(path, node.lineno, f"import de {', '.join(sorted(outside))} después de uno de src/: "
                 "primero la biblioteca estándar, luego los locales", f"{CONV} › Estilo Python")
        seen_local = seen_local or bool(local)
        if isinstance(node, ast.Import) and len(node.names) > 1:
            fail(path, node.lineno, "varios módulos en un mismo import: uno por línea",
                 f"{CONV} › Estilo Python")
    for node in ast.walk(tree):
        if not isinstance(node, (ast.Import, ast.ImportFrom)):
            continue
        local, outside = imported(node)
        for mod in sorted(outside):
            if not is_stdlib(mod):
                fail(path, node.lineno, f"importa {mod}, que no es de la biblioteca estándar",
                     f"{ARCH} › Principio 2")
        if is_src:
            allowed = LOCAL_OK.get(path, set())
            for mod in sorted(local - allowed):
                fail(path, node.lineno, f"importa {mod}: {os.path.basename(path)} solo puede importar "
                     + (", ".join(sorted(allowed)) + " y la stdlib" if allowed else "la stdlib")
                     + "; lo que necesite a varios módulos va en cli.py", f"{ARCH} › Principio 6")

    if is_src:
        body = tree.body
        first = body[0] if body else None
        if not (isinstance(first, ast.Expr) and isinstance(first.value, ast.Constant)
                and isinstance(first.value.value, str)):
            fail(path, 1, "no empieza con el docstring del módulo", f"{CONV} › Estructura de archivo")
        elif "\n" in first.value.value.strip():
            fail(path, 1, "el docstring del módulo ocupa más de una línea",
                 f"{CONV} › Estructura de archivo")
        second = body[1] if len(body) > 1 else None
        if not (isinstance(second, ast.ImportFrom) and second.module == "__future__"
                and any(a.name == "annotations" for a in second.names)):
            fail(path, getattr(second, "lineno", 1),
                 "tras el docstring tiene que ir «from __future__ import annotations»: sin ella, "
                 "`str | None` falla en Python 3.9", f"{CONV} › Estructura de archivo")

    inside_fstring = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.JoinedStr):
            inside_fstring |= {id(child) for child in ast.walk(node) if child is not node}
    for node in ast.walk(tree):
        if isinstance(node, ast.Call):
            func = node.func
            name = func.attr if isinstance(func, ast.Attribute) else getattr(func, "id", "")
            if name == "print" and isinstance(func, ast.Name) and path != "src/cli.py":
                fail(path, node.lineno, "print() fuera de src/cli.py: si es de debug, quítalo",
                     "AGENTS.md § 3 y docs/example/checkpoints.md › C3")
            if (name == "format" and isinstance(func, ast.Attribute)
                    and isinstance(func.value, ast.Constant) and isinstance(func.value.value, str)):
                fail(path, node.lineno, "interpola con .format(): usa una f-string", f"{CONV} › Estilo Python")
            if path == "src/cli.py" and name == "add_argument":
                for kw in node.keywords:
                    if kw.arg == "type" and not (isinstance(kw.value, ast.Name)
                                                 and kw.value.id in ("int", "str", "float")):
                        fail(path, kw.value.lineno, "add_argument con un type= propio: valida el flag en "
                             "su cmd_<nombre> y lanza NoteError", "docs/example/lessons.md › ADR-02")
            if path in TESTS and name == "patch" and node.args:
                target = node.args[0]
                if (isinstance(target, ast.Constant) and isinstance(target.value, str)
                        and (target.value.startswith(FS_TARGETS) or target.value.endswith(".open"))):
                    fail(path, node.lineno, f"patch({target.value!r}) simula el filesystem: usa "
                         "tempfile.TemporaryDirectory()", "docs/example/verification.md › Anti-patrones")
            if (path in TESTS and name == "object" and isinstance(func, ast.Attribute)
                    and (getattr(func.value, "id", "") == "patch" or getattr(func.value, "attr", "") == "patch")
                    and node.args and getattr(node.args[0], "id", "") in FS_MODULES):
                fail(path, node.lineno, f"patch.object({node.args[0].id}, …) simula el filesystem: usa "
                     "tempfile.TemporaryDirectory()", "docs/example/verification.md › Anti-patrones")
        elif (isinstance(node, ast.BinOp) and isinstance(node.op, ast.Mod)
              and isinstance(node.left, ast.Constant) and isinstance(node.left.value, str)):
            fail(path, node.lineno, "interpola con %: usa una f-string", f"{CONV} › Estilo Python")
        elif path in TESTS and (getattr(node, "id", None) == "mock_open"
                                or getattr(node, "attr", None) == "mock_open"):
            fail(path, node.lineno, "mock_open simula el filesystem: usa tempfile.TemporaryDirectory()",
                 "docs/example/verification.md › Anti-patrones")
        elif isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            if node.name not in UNITTEST and not re.fullmatch(r"_*[a-z][a-z0-9_]*", node.name):
                fail(path, node.lineno, f"la función {node.name} no está en snake_case", f"{CONV} › Nombres")
        elif isinstance(node, ast.ClassDef):
            if not re.fullmatch(r"_?[A-Z][A-Za-z0-9]*", node.name):
                fail(path, node.lineno, f"la clase {node.name} no está en PascalCase", f"{CONV} › Nombres")
        if (isinstance(node, ast.JoinedStr) or (isinstance(node, ast.Constant) and isinstance(node.value, str))) \
                and id(node) not in inside_fstring:
            literal = ast.get_source_segment(text, node) or ""
            if literal.lstrip("rRbBuUfF").startswith("'") and '"' not in literal:
                fail(path, node.lineno, "comillas simples: usa comillas dobles (las simples, solo si "
                     "dentro hay comillas dobles)", f"{CONV} › Estilo Python")

    # Una llamada o una colección que no cabe en una línea se parte con un
    # elemento por línea, coma final y el cierre en su propia línea. Con un
    # solo elemento que empieza y acaba en sus mismas líneas, se abrazan:
    # [{ … }] o append({ … }) (F-12).
    lines = text.splitlines()
    for node in ast.walk(tree):
        if isinstance(node, ast.Call):
            items, opens = [(a, a) for a in node.args] + [(k, k.value) for k in node.keywords], node.func.end_lineno
        elif isinstance(node, ast.Dict):
            items, opens = [(k if k is not None else v, v) for k, v in zip(node.keys, node.values)], node.lineno
        elif isinstance(node, (ast.List, ast.Tuple, ast.Set)):
            items, opens = [(e, e) for e in node.elts], node.lineno
        else:
            continue
        if not items or node.end_lineno == opens:
            continue
        items.sort(key=lambda item: (item[0].lineno, item[0].col_offset))
        first, last = items[0][0], items[-1][1]
        if len(items) == 1 and first.lineno == opens and last.end_lineno == node.end_lineno:
            continue
        if first.lineno == opens:
            why = "el primer elemento va en la línea siguiente a la que abre"
        elif any(b[0].lineno <= a[1].end_lineno for a, b in zip(items, items[1:])):
            why = "hay dos elementos en la misma línea"
        elif last.end_lineno == node.end_lineno:
            why = "el cierre va en su propia línea"
        else:
            tail = [lines[last.end_lineno - 1][last.end_col_offset:]] + lines[last.end_lineno:node.end_lineno - 1]
            # Un generador como único argumento no admite coma final.
            needs_comma = not (isinstance(last, ast.GeneratorExp) and len(items) == 1)
            why = ("falta la coma tras el último elemento"
                   if needs_comma and "," not in re.sub(r"#[^\n]*", "", "\n".join(tail)) else None)
        if why:
            fail(path, node.lineno, f"partida en varias líneas, pero {why}: va un elemento por línea, con "
                 "coma final y el cierre en su propia línea; con un solo elemento, se abrazan: [{ … }]",
                 f"{CONV} › Estilo Python")

for path in SRC:
    module = os.path.splitext(os.path.basename(path))[0]
    if os.path.isfile(path) and not os.path.isfile(f"tests/test_{module}.py"):
        fail(path, 1, f"no tiene tests/test_{module}.py: un archivo de test por módulo", f"{CONV} › Tests")

# Mientras no haya features reales, src/ y la raíz son solo del ejemplo. Un
# proyecto real que empieza en Python comparte con él src/ y puede declarar
# dependencias, así que estas dos reglas dejan de aplicar.
if not real_features():
    for root, dirs, names in os.walk("src"):
        dirs[:] = [d for d in dirs if d != "__pycache__"]
        for name in names:
            path = os.path.join(root, name).replace(os.sep, "/")
            if path.endswith(".py") and path not in SRC + ("src/__init__.py",):
                fail(path, 1, "no es uno de los tres módulos del ejemplo: no se añaden capas",
                     f"{ARCH} › Principio 1")
    if os.path.isfile("requirements.txt"):
        with open("requirements.txt", encoding="utf-8") as fh:
            if any(l.strip() and not l.lstrip().startswith("#") for l in fh):
                fail("requirements.txt", 1, "declara dependencias: el ejemplo solo usa la stdlib",
                     f"{ARCH} › Principio 2")
    if os.path.isfile("pyproject.toml"):
        fail("pyproject.toml", 1, "el ejemplo no es un paquete ni declara dependencias",
             f"{ARCH} › Stack y dependencias")

if failures:
    print("\n".join(failures))
    sys.exit(1)
print(f"ejemplo en verde ({len(files)} archivos)")
PY
}

if OUT=$(example_rules 2>&1); then
  summary "$OUT"
else
  printf '%s\n' "$OUT"
  STATUS=1
fi

[ "$STATUS" -eq 0 ] && echo "$SUMMARY"
exit "$STATUS"
