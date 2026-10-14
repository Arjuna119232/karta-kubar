#!/usr/bin/env python3
"""Dart static checker untuk KUNBAR Connect.

`flutter analyze` tidak bisa jalan di Termux (Flutter tidak terpasang), jadi
script ini memeriksa hal yang sama yang paling sering jadi masalah nyata:

  1. import tidak resolve (file hilang / typo path)
  2. import tidak terpakai  (build tetap hijau, tapi analyzer CI di-parse `|| true`)
  3. file mati            (tidak terjangkau dari lib/main.dart)
  4. deklarasi top-level private yang tidak pernah dipakai
  5. provider yang didefinisikan tapi tidak pernah di-watch/read/listen
  6. kurung kurawal tidak seimbang (setelah string & komentar dibuang)
  7. karakter non-Latin bocor ke source (bocor IME)
  8. aset di pubspec yang kosong / tidak ada

Exit 0 = bersih, exit 1 = ada masalah.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"
PKG = "karta_connect"

problems = []
notes = []


def bad(kind, path, msg):
    problems.append((kind, str(path.relative_to(ROOT)), msg))


def note(msg):
    notes.append(msg)


# ---------------------------------------------------------------- stripper
def strip(src):
    """Buang komentar + isi string, ganti dengan spasi (offset terjaga)."""
    out = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        two = src[i:i + 2]
        # raw string
        if c in "'\"" and src[i:i + 4] in ("r'''", 'r"""'):
            q = src[i + 1:i + 4]
            i += 4
            while i < n:
                if src[i] == "\\":
                    i += 2
                    continue
                if src[i:i + 3] == q:
                    i += 3
                    break
                i += 1
            out.append(' ')
            continue
        # string 3-kutip
        if src[i:i + 3] in ("'''", '"""'):
            q = src[i:i + 3]
            i += 3
            while i < n:
                if src[i] == "\\":
                    i += 2
                    continue
                if src[i:i + 3] == q:
                    i += 3
                    break
                i += 1
            out.append(' ')
            continue
        # string biasa
        if c in "'\"":
            q = c
            i += 1
            while i < n:
                if src[i] == "\\":
                    i += 2
                    continue
                if src[i] == q:
                    i += 1
                    break
                if src[i] == "\n":
                    break
                i += 1
            out.append(' ')
            continue
        # komentar
        if two == "//":
            while i < n and src[i] != "\n":
                i += 1
            out.append(' ')
            continue
        if two == "/*":
            depth, i = 1, i + 2
            while i < n and depth:
                if src[i:i + 2] == "/*":
                    depth += 1
                    i += 2
                elif src[i:i + 2] == "*/":
                    depth -= 1
                    i += 2
                else:
                    i += 1
            out.append(' ')
            continue
        out.append(c)
        i += 1
    return "".join(out)


# ---------------------------------------------------------------- files
files = sorted(LIB.rglob("*.dart"))
if not files:
    sys.exit("FAIL: lib/ kosong")

raw = {f: f.read_text(encoding="utf-8") for f in files}
code = {f: strip(raw[f]) for f in files}
rel = {f: str(f.relative_to(LIB)).replace("\\", "/") for f in files}

IMPORT_RE = re.compile(
    r"""^[ \t]*(import|export)\s+(['"])([^'"]+)\2([^;]*);""",
    re.MULTILINE,
)
PART_RE = re.compile(r"""^[ \t]*part\s+(['"])([^'"]+)\1\s*;""", re.MULTILINE)

TOPLEVEL_RE = re.compile(
    r"^\s*(?:abstract\s+|final\s+|base\s+|sealed\s+|mixin\s+)*"
    r"(?:class|enum|mixin|extension|typedef)\s+([A-Za-z_$][\w$]*)",
    re.MULTILINE,
)
TOPFUNC_RE = re.compile(
    r"^([A-Za-z_$][\w$]*)\s*(?:<[^>]*>)?\s*\([^;{]*\)\s*(?:async\s*)?[{=]",
    re.MULTILINE,
)
TOPVAR_RE = re.compile(
    r"^(?:const|final)\s+(?:[\w<>,?\s.]+\s+)?([a-z_$][\w$]*)\s*=",
    re.MULTILINE,
)


def resolve(spec, origin):
    if spec.startswith("dart:"):
        return None  # SDK
    if spec.startswith("package:"):
        # "package:<nama>/<path>" — buang "package:", lalu potong setelah nama.
        rest = spec[len("package:"):]
        name, _, p = rest.partition("/")
        if name != PKG:
            return None  # package pihak ketiga -> tidak bisa dicek di sini
        cand = LIB / p
        return cand if cand.is_file() else ("MISSING", cand)
    cand = (origin.parent / spec).resolve()
    return cand if cand.is_file() else ("MISSING", cand)


def declared_names(body):
    names = set(TOPLEVEL_RE.findall(body))
    names |= set(TOPFUNC_RE.findall(body))
    names |= set(TOPVAR_RE.findall(body))
    return names


def extension_members(body):
    """Nama member di dalam extension.

    Penting: extension dipakai IMPLISIT lewat `.member`, jadi nama `extension`
    sendiri tidak pernah muncul di kode pemanggil. Tanpa daftar member ini,
    `import app_colors.dart` akan salah dianggap "tak terpakai" padahal dipakai
    lewat `context.colors` / `context.text` / `context.semantic`.
    """
    members = set()
    for m in re.finditer(r"\bextension\s+\w+\s+on\s+[\w<>,?\s]+?\{", body):
        # body extension = dari '{' yang cocok sampai '}' pasangannya
        depth, i = 0, m.end() - 1
        start = i + 1
        while i < len(body):
            if body[i] == "{":
                depth += 1
            elif body[i] == "}":
                depth -= 1
                if depth == 0:
                    break
            i += 1
        blk = body[start:i]
        members |= set(re.findall(r"\bget\s+(\w+)", blk))
        members |= set(re.findall(r"\bset\s+(\w+)", blk))
        members |= set(re.findall(r"^[\w<>,?\s]*?\b(\w+)\s*\(", blk, re.MULTILINE))
        members |= set(re.findall(r"\boperator\s+(\w+)", blk))
    return members


# ---------------------------------------------------------------- 1. import resolve + 3. reachability
edges = {f: set() for f in files}
imports_of = {f: [] for f in files}

for f in files:
    # PENTING: cari import di kode ASLI (raw), bukan di `code`.
    # `code` = string literal sudah diganti spasi, jadi nama path import hilang
    # dan tidak ada satu pun import yang terdeteksi.
    body = raw[f]
    for kind, _, spec, tail in IMPORT_RE.findall(body):
        r = resolve(spec, f)
        if r is None:
            continue
        if isinstance(r, tuple):
            bad("IMPORT-RESOLVE", f, f"'{spec}' -> file tidak ada")
            continue
        imports_of[f].append((r, spec, tail))
        if kind == "import":
            edges[f].add(r)
    for _, spec in PART_RE.findall(body):
        r = resolve(spec, f)
        if isinstance(r, tuple):
            bad("IMPORT-RESOLVE", f, f"part '{spec}' -> file tidak ada")
        elif r is not None:
            edges[f].add(r)

entry = LIB / "main.dart"
if not entry.is_file():
    sys.exit("FAIL: lib/main.dart tidak ada")
live, stack = {entry}, [entry]
while stack:
    cur = stack.pop()
    for nxt in edges[cur]:
        if nxt not in live:
            live.add(nxt)
            stack.append(nxt)

dead = [f for f in files if f not in live]
for f in dead:
    bad("DEAD-FILE", f, "tidak terjangkau dari lib/main.dart")

# ---------------------------------------------------------------- 2. unused import
IDENT = re.compile(r"[A-Za-z_$][\w$]*")

for f in files:
    body = code[f]
    # import dibuang dari teks "dipakai" supaya nama yang di-import tidak
    # ikut terhitung sebagai pemakaian.
    used_text = IMPORT_RE.sub(" ", PART_RE.sub(" ", raw[f]))
    used_idents = set(IDENT.findall(used_text))
    # PENTING: extension yang dicek adalah milik FILE TARGET, bukan file ini.
    # Kalau salah, `import app_colors.dart` akan selalu dianggap tak terpakai
    # padahal dipakai implisit lewat `context.colors` / `context.text`.
    ext_members = set()
    for target, spec, tail in imports_of[f]:
        tcode = code[target]
        ext_members |= extension_members(tcode)
        alias = re.search(r"\bas\s+([A-Za-z_$][\w$]*)", tail)
        show = re.search(r"\bshow\s+([^;]+)", tail)
        hide = re.search(r"\bhide\s+([^;]+)", tail)
        if alias:
            if f"{alias.group(1)}." not in used_text:
                bad("UNUSED-IMPORT", f, f"'{spec}' (prefix {alias.group(1)}. tidak dipakai)")
            continue
        names = declared_names(tcode)
        if show:
            cand = {x.strip() for x in show.group(1).split(",") if x.strip()}
        else:
            cand = set(names)
            if hide:
                cand -= {x.strip() for x in hide.group(1).split(",")}
        # import tanpa prefix: nama level-atas muncul sebagai identifier,
        # atau member extension dipakai lewat `.member`.
        if any(x in used_idents for x in cand):
            continue
        if ext_members and re.search(
            r"\.(" + "|".join(map(re.escape, sorted(ext_members))) + r")\b", used_text
        ):
            continue
        bad("UNUSED-IMPORT", f, f"'{spec}' — nama: {', '.join(sorted(cand)) or 'tidak ada'}")

# ---------------------------------------------------------------- 4. private top-level mati
for f in files:
    if f in dead:
        continue
    body = code[f]
    # PENTING: garis bawah harus ikut tertangkap. Kalau tidak, nama yang
    # dicari jadi "QrPainter" lalu `\bQrPainter\b` TIDAK PERNAH cocok di dalam
    # "_QrPainter" (karena `_` adalah karakter kata) -> semua State/painter
    #private dilaporkan mati padahal jelas dipakai.
    priv = set(re.findall(r"^\s*(?:class|enum|mixin|extension)\s+(_[A-Za-z_$][\w$]*)", body, re.MULTILINE))
    priv |= set(re.findall(r"^[A-Za-z_$][\w$<>,?\s]*\s(_[a-z_$][\w$]*)\s*\(", body, re.MULTILINE))
    if not priv:
        continue
    for name in sorted(priv):
        uses = len(re.findall(r"\b" + re.escape(name) + r"\b", body))
        if uses <= 1:
            bad("UNUSED-PRIVATE", f, f"'{name}' dideklarasi tapi tidak pernah dipakai")

# ---------------------------------------------------------------- 5. provider tak terpakai
for f in files:
    if f in dead:
        continue
    body = code[f]
    provs = set(re.findall(r"(?:StateNotifier|State|Stream|Notifier|Future)?Provider(?:Family)?<[^>]*>*\s*\w+", body))
    for m in re.finditer(r"\b(\w*[Pp]rovider)\s*(?:<[^=]*?>)?\s*=\s*(\w+)?\s*\(", body):
        name = m.group(2) or m.group(1)
        hits = 0
        for g in files:
            if g == f:
                continue
            hits += len(re.findall(r"\b" + re.escape(name) + r"\b", code[g]))
        if hits == 0:
            bad("UNUSED-PROVIDER", f, f"'{name}' tidak pernah di-watch/read/listen di file lain")

# ---------------------------------------------------------------- 6. kurung
for f in files:
    for ch_open, ch_close in (("{", "}"), ("(", ")"), ("[", "]")):
        a = code[f].count(ch_open)
        b = code[f].count(ch_close)
        if a != b:
            bad("BRACE", f, f"'{ch_open}{ch_close}' tidak seimbang: {a} buka vs {b} tutup")

# ---------------------------------------------------------------- 7. karakter non-Latin
for f in files:
    for i, line in enumerate(raw[f].split("\n"), 1):
        hits = {c for c in line if ord(c) > 0x2100}
        if hits:
            bad("NON-LATIN", f, f"baris {i}: {' '.join(sorted(hits))} -> '{line.strip()[:60]}'")

# ---------------------------------------------------------------- 8. aset
pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
m = re.search(r"^assets:\n((?:\s*-\s*\S+\n?)+)", pubspec, re.MULTILINE)
if m:
    for line in m.group(1).strip().split("\n"):
        relpath = line.strip().lstrip("- ").strip()
        d = ROOT / relpath
        if not d.exists():
            bad("ASSET", "pubspec.yaml", f"'{relpath}' tidak ada")
        else:
            files_in = [p for p in d.rglob("*") if p.is_file() and p.name != ".gitkeep"]
            if not files_in:
                note(f"assets/{relpath} kosong (hanya .gitkeep) - aman, tapi tidak ada file yang dipaket")

# ---------------------------------------------------------------- 9. import yang HILANG
# Ini kelas bug paling berbahaya: file yang tidak terjangkau dari main.dart
# TIDAK PERNAH dikompilasi, jadi `undefined name` di dalamnya lolos dari CI.
# Contoh nyata yang pernah terjadi: otp_screen.dart memakai `sessionProvider`
# tapi tidak meng-import core/auth/session.dart - build tetap hijau 4 rilis.
#
# Cara ceknya: untuk setiap simbol yang dideklarasikan project (kelas, top-level
# function, top-level variable), cari file LAIN yang memakainya. Kalau file itu
# tidak meng-import yang mendeklarasikan = compile error.
symbols = {}   # nama -> {file yang mendeklarasikan}
for f in files:
    for name in declared_names(code[f]):
        symbols.setdefault(name, set()).add(f)

for name, owners in sorted(symbols.items()):
    if len(owners) != 1:
        continue                      # ambigu -> tidak bisa disimpulkan
    src_file = next(iter(owners))
    pat = re.compile(r"\b" + re.escape(name) + r"\b")
    for f in files:
        if f == src_file:
            continue
        if not pat.search(code[f]):
            continue
        if src_file in edges[f]:      # sudah di-import
            continue
        if rel[src_file] in code[f]:  # di-'part' tanpa import
            continue
        bad("MISSING-IMPORT", f,
            f"pakai `{name}` yang dideklarasikan di {rel[src_file]}, "
            f"tapi file itu tidak di-import -> `undefined name` saat kompilasi")

# ---------------------------------------------------------------- 10. rute tak terdaftar
router_path = LIB / "core/router.dart"
if router_path.is_file():
    registered = set(re.findall(r"path:\s*'([^']+)'", raw[router_path]))
    # WAJIB scan kode ASLI: nama rute adalah string literal, sedangkan `code`
    # sudah mengganti string dengan spasi -> tidak akan pernah ketemu.
    for f in files:
        for target in re.findall(r"context\.(?:go|push|replace|goNamed)\(\s*'([^']+)'", raw[f]):
            if target.startswith("/") and target not in registered:
                bad("ROUTE-UNKNOWN", f,
                    f"navigasi ke '{target}' tapi rute itu tidak terdaftar di core/router.dart "
                    f"(terdaftar: {', '.join(sorted(registered))}) -> GoException saat runtime")

# ---------------------------------------------------------------- report
print("=" * 62)
print("  KUNBAR Connect - Dart static check")
print("=" * 62)
print(f"file diperiksa : {len(files)}")
print(f"file hidup     : {len(live)}")
print(f"file mati      : {len(dead)}")
print(f"baris kode     : {sum(len(raw[f].splitlines()) for f in files)}")
if notes:
    print("\nCATATAN:")
    for n in notes:
        print(f"  · {n}")
if problems:
    print(f"\nMASALAH ({len(problems)}):")
    order = {"DEAD-FILE": 0, "MISSING-IMPORT": 1, "ROUTE-UNKNOWN": 2,
             "IMPORT-RESOLVE": 3, "UNUSED-IMPORT": 4, "UNUSED-PRIVATE": 5,
             "UNUSED-PROVIDER": 6, "BRACE": 7, "NON-LATIN": 8, "ASSET": 9}
    for kind, path, msg in sorted(problems, key=lambda p: (order.get(p[0], 9), p[1])):
        print(f"  [{kind}] {path}\n      {msg}")
    sys.exit(1)
print("\nOK - 0 masalah.")