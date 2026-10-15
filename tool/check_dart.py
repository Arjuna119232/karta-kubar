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
# Fungsi top-level yang ADA tipe return-nya, mis.
#     GoRouter buatRouter(LokasiAwal awal) => GoRouter(
#     Future<LokasiAwal> tentukanLokasiAwal() async {
# Tanpa pola ini semua fungsi bertipe TIDAK TERDAFTAR sebagai simbol, sehingga
# cek UNUSED-IMPORT salah Trophy (router.dart dilaporkan tidak dipakai) dan
# cek MISSING-IMPORT buta huruf.
#
# Syarat penting: (1) baris harus mulai dari kolom 0 -> method di dalam class
# selalu berindentasi, jadi tidak ikut tertangkap; (2) nama fungsi WAJIB mulai
# huruf kecil supaya `Widget Build(...)` tidak dianggap fungsi.
TOPFUNC_TYPED_RE = re.compile(
    r"^(?:[A-Za-z_$][\w$]*(?:<[^>]*>)?\??\s+)([a-z_$][\w$]*)\s*"
    r"\([^;{]*\)\s*(?:async\s*)?[{=>]",
    re.MULTILINE,
)
# Tipe diakhiri `>>` atau `[]` TANPA spasi sebelum nama variabel:
#   final AsyncNotifierProvider<Notifier, List<Baris>>namaProvider =
# Pola lama mewajibkan spasi setelah tipe, jadi deklarasi ini tidak pernah
# tertangkap dan import-nya dilaporkan "tak terpakai" (false positive).
TOPVAR_RE = re.compile(
    r"^(?:const|final)\s+([\w<>,?\s.\[\]]*?)([a-z_$][\w$]*)\s*=",
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
    names |= set(TOPFUNC_TYPED_RE.findall(body))
    names |= set(m.group(2) for m in TOPVAR_RE.finditer(body))
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
exports_of = {f: set() for f in files}

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
        if kind == "export":
            # `export` BUKAN import: simbolnya ikut tersedia untuk peng-import
            # (transitif), tapi pernyataan export sendiri tidak pernah
            # "tak terpakai". Dart asli memperlakukan export sebagai bagian
            # program, jadi ia juga harus jadi edge keterjangkauan.
            exports_of[f].add(r)
            edges[f].add(r)
        else:
            imports_of[f].append((r, spec, tail))
            edges[f].add(r)
    for _, spec in PART_RE.findall(body):
        r = resolve(spec, f)
        if isinstance(r, tuple):
            bad("IMPORT-RESOLVE", f, f"part '{spec}' -> file tidak ada")
        elif r is not None:
            edges[f].add(r)

def provides(f, _seen=None):
    """Himpunan library yang simbolnya TERLIHAT oleh peng-import `f`.

    `export` bersifat transitif (barrel file), `import` TIDAK pernah
    meneruskan simbol ke peng-import-nya. Contoh nyata:
      app_theme.dart  : import app_colors.dart  + export app_spacing.dart
      layar.dart      : import app_theme.dart
      -> `AppSpacing` terlihat di layar.dart  (ikut export)   = BOLEH
      -> `AppColors`  TIDAK terlihat          (hanya import)  = DILARANG

    Kalau batas ini tidak dijaga, cek MISSING-IMPORT jadi buta: import
    `app_theme.dart` akan dianggap cukup untuk memakai apa pun yang
    disentuh app_theme.dart, dan bug `undefined name` lolos.
    """
    if f in provides_cache:
        return provides_cache[f]
    _seen = _seen or set()
    if f in _seen:
        return set()
    _seen = _seen | {f}
    out = {f}
    for e in exports_of[f]:
        out |= provides(e, _seen)
    provides_cache[f] = out
    return out


provides_cache = {}

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
    # Member extension yang namanya DIMILIKI lebih dari satu target tidak
    # boleh jadi bukti pakai: `label` ada di UserRoleX, StatusAspirasiX,
    # KategoriAspirasiX, dan PaketKartuX. Kalau tidak dibatasi, file yang
    # menulis `a.label` akan membuat `import user_role.dart` lolos walau
    # `UserRole` sama sekali tidak disebut.
    ext_owner = {}
    for target, _spec, _tail in imports_of[f]:
        for tgt in provides(target):
            for member in extension_members(code[tgt]):
                ext_owner.setdefault(member, set()).add(target)

    for target, spec, tail in imports_of[f]:
        # WAJIB di-reset di dalam loop. Kalau himpunan ini dikumpulkan di luar
        # loop, extension dari import PERTAMA ikut considers untuk import
        # BERIKUTNYA: sebuah file yang memakai `.text` (dari app_theme.dart)
        # akan lolos declared_names untuk SEMUA import lain, termasuk yang
        # benar-benar tidak dipakai. Akibatnya cek UNUSED-IMPORT praktis mati
        # untuk file yang punya akses ke extension.
        ext_members = set()
        for tgt in provides(target):
            ext_members |= extension_members(code[tgt])
        alias = re.search(r"\bas\s+([A-Za-z_$][\w$]*)", tail)
        show = re.search(r"\bshow\s+([^;]+)", tail)
        hide = re.search(r"\bhide\s+([^;]+)", tail)
        if alias:
            if f"{alias.group(1)}." not in used_text:
                bad("UNUSED-IMPORT", f, f"'{spec}' (prefix {alias.group(1)}. tidak dipakai)")
            continue
        names = set()
        for tgt in provides(target):
            names |= declared_names(code[tgt])
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
        unik = {x for x in ext_members if len(ext_owner.get(x, ())) == 1}
        if unik and re.search(
            r"\.(" + "|".join(map(re.escape, sorted(unik))) + r")\b", used_text
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
    # Method private di dalam kelas: baris `  void _segera(...) {`. Polanya
    # harus Nullable dengan indentation >= 2 spasi, kalau tidak `^` ikut
    # mencocokkan baris yang lebih dalam dan nama member kelas ikut dianggap
    # "method private".
    priv |= set(re.findall(r"^\s{2,}[A-Za-z_$][\w$<>,?\s]*\s(_[a-z_$][\w$]*)\s*\(",
                           body, re.MULTILINE))
    if not priv:
        continue
    for name in sorted(priv):
        # Dihitung dari teks ASLI, bukan `body` yang string-nya sudah diganti
        # spasi: pemanggilan di dalam interpolasi string ('Rp ${_format(x)}')
        # akan hilang kalau dihitung dari body, lalu method yang sebenarnya
        # dipakai dilaporkan mati (false positive).
        uses = len(re.findall(r"\b" + re.escape(name) + r"\b", raw[f]))
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
        # Terlihat kalau di-import LANGSUNG, atau di-export ulang oleh salah
        # satu import kita (barrel). `edges` tidak dipakai di sini karena
        # edges juga menelusuri `import` biasa -> akan menganggap semua
        # yang disentuh app_theme.dart seolah ter-import (cek jadi buta).
        if any(src_file in provides(t) for t, _s, _t in imports_of[f]):
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


# ------------------------------------------------- 11. MEMBER TIDAK ADA DI KELAS PROYEK
# Bug yang DITEMUKAN CI tapi lolos analyzer: `a.title` padahal field-nya sudah
# di-rename jadi `a.judul`. Cek import saja tidak menangkapnya, karena `a`
# bukan simbol project.
#
# Cara: kumpulkan member tiap kelas project (field + getter + method), lalu
# untuk setiap pemakaian `variance.member` - kalau tipe `variance` adalah kelas
# project, pastikan member itu ada.
PROJECT_TYPES = {}
for f in files:
    body = raw[f]
    for m in re.finditer(r"\b(?:class|enum|extension)\s+(\w+)", body):
        nama = m.group(1)
        # body kelas = dari '{' hingga '}' pasangannya
        i = body.find('{', m.end() - 1)
        if i < 0:
            continue
        depth, j = 0, i
        while j < len(body):
            if body[j] == "{":
                depth += 1
            elif body[j] == "}":
                depth -= 1
                if depth == 0:
                    break
            j += 1
        blk = body[i:j]
        member = set(re.findall(r"\bget\s+(\w+)", blk))
        member |= set(re.findall(r"\bset\s+(\w+)", blk))
        member |= set(re.findall(r"^\s*(?:static\s+|final\s+|late\s+|const\s+)*"
                                 r"[\w<>,?\s\[\]]*?\b(\w+)\s*(?:=|;)", blk, re.MULTILINE))
        member |= set(re.findall(r"^[\w<>,?\s\[\]]*?\b(\w+)\s*\(", blk, re.MULTILINE))
        member |= set(re.findall(r"\boperator\s*\[?=?\]?\s*(\w+)", blk))
        # Parameter boleh punya satu tingkat kurung bersarang. Tanpa ini,
        # `Hasil<R> peta<R>(R Function(T nilai) ubah) {` TIDAK ikut tertangkap
        # (karena `[^)]*` berhenti di `Function(`) sehingga pemanggilan
        # `hasil.peta(...)` dilaporkan "`Hasil` tidak punya member 'peta'"
        # padahal methodnya ada. Gejalanya: pesan error menunjuk file yang
        # BENAR, jadi mudah disalahkan.
        member |= set(re.findall(r"\b(\w+)(?:<[^()<>]*>)?\s*\((?:[^()]|\([^()]*\))*\)\s*"
                                 r"(?:async\s*)?\{", blk))
        member |= {"hashCode", "toString", "runtimeType", "noSuchMethod"}
        # enum punya `values`, `name`, `index` + nama konstantanya
        if m.group(0).startswith("enum"):
            member |= {"values", "name", "index"}
            member |= set(re.findall(r"^\s*(\w+)\s*(?:,|$)", blk, re.MULTILINE))
        # extension: nama method-nya adalah member yang dipakai implisit
        if m.group(0).startswith("extension"):
            member = extension_members(body) | {"toString", "hashCode", "runtimeType"}
        PROJECT_TYPES.setdefault(nama, member)

# tipe yang diketahui:
#   `final X v = ...`   `for (final X v in ...)`   `late final X v`
#   `final X v;`  (field kelas)   `const X v = ...`
# `_?` WAJIB: tanpa itu kelas privat (`_MediaContoh`) tidak pernah dikenali,
# sehingga `final _MediaContoh media;` hilang dari peta dan `media.cover`
# salah disimpulkan memakai tipe kelas lain yang kebetulan bernama sama.
# Gejalanya: FALSE POSITIVE UNDEF-MEMBER pada kode yang benar.
VAR_TIPE = re.compile(
    r"\b(?:final|const|late\s+final|var)\s+(_?[A-Z]\w+)(?:<[^>]*>)?\s+(\w+)\s*"
    r"(?:;|=|\bin\b)"
)
# Parameter closure `(Kegiatan a) => ...` jugashitipe dikenal.
VAR_CLOSURE = re.compile(r"\(\s*(_?[A-Z]\w+)(?:<[^>]*>)?\s+(\w+)\s*\)\s*(?:async\s*)?=>")
for f in files:
    body = code[f]          # string sudah diganti spasi -> import tidak ikut
    # nama -> himpunan TIPE kandidat.
    #
    # BUKAN nama -> satu tipe. Kalau `media` dipakai 2 kelas berbeda di satu
    # file (`final MediaGaleri media;` di satu widget, `final _MediaContoh
    # media;` di widget lain), versi lama hanya memakai salah satu tipe:
    # (a) FALSE POSITIVE pada kode yang benar, dan (b) begitu nama ambigu
    # dibuang, TYPO sungguhan (`media.sampulTypo`) ikut lolos tanpa terdeteksi.
    # Sekarang: dilaporkan HANYA kalau member tidak ada di SATU pun kandidat.
    vars_diketahui = {}
    for m in list(VAR_TIPE.finditer(body)) + list(VAR_CLOSURE.finditer(body)):
        tipe, nama = m.group(1), m.group(2)
        if tipe not in PROJECT_TYPES:
            continue
        vars_diketahui.setdefault(nama, set()).add(tipe)
    ext_member = {x for o in files for x in extension_members(raw[o])}
    for nama, tipes in vars_diketahui.items():
        member_boleh = set()
        for tipe in tipes:
            member_boleh |= PROJECT_TYPES[tipe]
        member_boleh |= ext_member
        for m in re.finditer(r"(?<![\w.])" + re.escape(nama) + r"\.(\w+)", body):
            attr = m.group(1)
            if attr in member_boleh:
                continue
            # fungsi/method milik Flutter yang sah (dipanggil di receiver)
            if attr in {"toString", "hashCode", "copyWith", "when", "fold", "map", "where",
                        "toList", "toSet", "first", "last", "isEmpty", "isNotEmpty", "length",
                        "add", "remove", "clear", "contains", "sublist", "reversed", "indexed",
                        "addAll", "removeAt", "sort", "join", "containsKey"}:
                continue
            baris = body[:m.start()].count("\n") + 1
            semua = sorted(tipes)
            ada = sorted(x for x in member_boleh if not x.startswith("_"))[:12]
            bad("UNDEF-MEMBER", f,
                f"`{nama}.{attr}` tapi {' / '.join(semua)} tidak punya "
                f"member '{attr}' (ada: {', '.join(ada)}) -> compile error")

# ------------------------------------------------- 12. CONSTRUCTOR TIDAK ADA
# `Hasil.galat(...)` padahal named constructor-nya `Hasil.gagal`. Compiler
# Dart menolaknya; analyzer statis kita tidak melihatnya.
CTORS = {}


def _body_kelas(teks, nama):
    """Blok { ... } milik kelas `nama`, atau None."""
    i = teks.find("class " + nama)
    if i < 0:
        return None
    j = teks.find("{", i)
    if j < 0:
        return None
    depth, k = 0, j
    while k < len(teks):
        if teks[k] == "{":
            depth += 1
        elif teks[k] == "}":
            depth -= 1
            if depth == 0:
                return teks[j:k]
        k += 1
    return None


for f in files:
    for m in re.finditer(r"\bclass\s+(\w+)", raw[f]):
        nama = m.group(1)
        # named constructor: `const X.name(` / `factory X.name(`
        for c in re.findall(r"\b(?:const\s+|factory\s+)?" + nama + r"\.(\w+)\s*\(", raw[f]):
            CTORS.setdefault(nama, set()).add(c)
        # static method: `static <T> nama(...)` di dalam body kelas
        blk = _body_kelas(raw[f], nama)
        if blk:
            CTORS.setdefault(nama, set()).update(
                re.findall(r"\bstatic\s+[\w<>,?\s\[\]]*?\b(\w+)\s*\(", blk)
            )
KNOWN_RUNTIME = {"new", "fromJson", "values", "keys", "generate"}
for f in files:
    for nama, ctor in re.findall(
            r"(?<![\w.])([A-Z]\w+)(?:<[^;{}=]*?>)?\.(\w+)\s*\(", code[f]):
        if nama not in CTORS:
            continue
        if ctor in CTORS[nama] or ctor in KNOWN_RUNTIME:
            continue
        bad("CTOR-UNKNOWN", f,
            f"`{nama}.{ctor}()` tidak ada. Named constructor yang ada: "
            f"{', '.join(sorted(CTORS[nama])) or '(nama constructor saja)'} -> compile error")


# ------------------------------------------- 13. FIELD KELAS UNTUK PARAM this.X
# Bug NYATA yang lolos semua cek lama dan hanya ketahuan saat CI compile:
#
#   const _Chip({required this.selected, ...});
#   final String label;          <-- field `selected` TIDAK pernah ditulis
#   ... color: selected ? ...    <-- pemakaiannya ada
#
# Gejalanya 4 baris error "The getter 'selected' isn't defined for type
# '_Chip'". Akar masalahnya satu baris deklarasi yang lupa. Cek ini menutup
# kelas bug itu: setiap `this.X` di constructor WAJIB punya field/getter X.
# Indentasi 2 spasi = anggota kelas. Method di dalam kelas selalu indentasi
# lebih dalam, jadi variabel lokal di dalam method tidak ikut terhitung.
FIELD_DECL_RE = re.compile(
    r"^\s{0,2}(?:late\s+)?(?:final|const|var)\s+[^;={}]*?\b(\w+)\s*(?:;|=)",
    re.MULTILINE,
)
GETTER_RE = re.compile(r"\bget\s+(\w+)")
for f in files:
    for m in re.finditer(r"\bclass\s+(\w+)\b", raw[f]):
        nama = m.group(1)
        blk = _body_kelas(raw[f], nama)
        if not blk:
            continue
        # Hanya parameter constructor. Parameter punya 3 bentuk:
        #   `this.x,`   (wajib, lalu koma)      -> `[,]`
        #   `this.x)`   (wajib, akhir kurung)   -> `[)]`
        #   `this.x = 0` (opsional, ada default)-> `[=]`
        # Yang TIDAK boleh ikut: `: this.gagal(e)` di constructor
        # pengalihan, karena diakhiri `(` dan itu bukan field.
        dipakai = set(re.findall(r"\bthis\.(\w+)\s*[,)=]", blk))
        if not dipakai:
            continue
        punya = set(FIELD_DECL_RE.findall(blk)) | set(GETTER_RE.findall(blk))
        # setter / field tanpa tipe (`int x;` ditulis sebagai `final int x;`
        # sudah tertangkap; `late bool x;` juga) + field dari superclass tidak
        # terlihat, jadi cukup laporkan yang jelas-jelas hilang.
        for nama_field in sorted(dipakai - punya):
            baris = raw[f][: raw[f].index(blk) + blk[: blk.index(nama_field)].count("\n")].count("\n") + 1
            bad("FIELD-HILANG", f,
                f"constructor {nama} memakai `this.{nama_field}` tapi field/getter "
                f"`{nama_field}` tidak dideklarasikan -> compile error")


# ------------------------------- 14. EXTENSION CONTEXT DIPAKAI, IMPORT HILANG
# Bug NYATA (v0.11.0, build CI gagal): `context.colors` / `context.text` /
# `context.semantic` adalah getter dari extension yang dideklarasikan di
# app_colors.dart dan app_theme.dart. Kalau import itu terhapus karena
# "tidak ada simbol yang dipakai", seluruh file gagal compile dengan
# "The getter 'colors' isn't defined for the type 'BuildContext'" - dozens
# of baris, padahal perbaikannya satu baris import.
# KETIGANYA berasal dari SATU extension `AppSemanticX` di app_colors.dart.
# (Janganonica pendek: `context.text` TIDAK ada di app_theme.dart - itu
# jebakan yang membuat verifikasi ini sempat menuduh 2 file lama.)
EXT_KONTEKSTUAL = {
    "colors": "core/theme/app_colors.dart",
    "semantic": "core/theme/app_colors.dart",
    "text": "core/theme/app_colors.dart",
}
for f in files:
    body = code[f]
    dipakai = sorted(m for m in EXT_KONTEKSTUAL
                     if re.search(r"\bcontext\." + m + r"\b", body))
    if not dipakai:
        continue
    targets = {str(Path(t).resolve()) for t, _s, _x in imports_of[f]}
    for m in dipakai:
        butuh = str((LIB / EXT_KONTEKSTUAL[m]).resolve())
        if butuh not in targets:
            bad("EXT-HILANG", f,
                "pakai `context.%s` tapi import `%s` tidak ada -> compile error"
                % (m, EXT_KONTEKSTUAL[m]))

# ------------------------------------------------- 11b. ref/context di field initializer
# KELAS BUG NYATA (ketahuan dari CI 15 Okt 2026, run `main` GAGAL):
#   class _XState extends ConsumerState<X> {
#     final TextEditingController _nik = TextEditingController(
#         text: ref.read(sessionProvider).user?.nik ?? '');   // <-- 4 error
# Dart tidak mengizinkan akses member INSTANCE di initializer field, jadi
# `final` biasa = compile error "Undefined name 'ref'". `late final` lolos
# kompilasi (initializer ditunda) tapi runtime-nya baru jalan saat dibaca.
# `check_dart.py` TIDAK bisa menangkapnya dari symbol table karena `ref`
# memang ada sebagai member - jadi harus dicek dari bentuk kodenya.
#
# POLA WAJIB (sudah diuji dengan fault injection):
#   - hanya field di body class (indent 2 spasi, kelas mulai kolom 0)
#   - SKIP `late` (legal, initializer ditunda)
#   - SKIP `static` (tidak punya akses ke instance sama sekali)
#   - SKIP getter (`=>`) dan initializer yang cuma `const`/literal
#   - initializer boleh multiline: kumpulkan sampai kurung seimbang DAN ';'
MEMBER_FIELD = re.compile(r"\b(ref|context|widget)\s*\.\s*\w")
FIELD_DECL = re.compile(
    r"^  (?!late\b)(?!static\b)(?:covariant\b\s+)?final\b[^=;]*?\s(\w+)\s*=\s*(.*)$"
)
for f in files:
    if f in dead:
        continue
    lines = raw[f].split("\n")
    in_class = False
    for i, ln in enumerate(lines, 1):
        if re.match(r"^(?:abstract\s+)?class\s", ln):
            in_class = True
            continue
        if in_class and ln.startswith("}"):
            in_class = False
            continue
        if not in_class or "=>" in ln:
            continue
        m = FIELD_DECL.match(ln)
        if not m:
            continue
        buf = m.group(2)
        j = i
        while j < len(lines) and j - i < 8 and not (
            buf.count("(") == buf.count(")") and ";" in buf
        ):
            j += 1
            buf += " " + lines[j - 1].strip()
        hit = MEMBER_FIELD.search(buf)
        if hit:
            bad("REF-FIELD-AWAL", f,
                "field `final %s` memakai `%s.` di initializer - Dart menolak "
                "akses member instance di field initializer (compile error "
                "'Undefined name'). Pindah ke initState()." % (m.group(1), hit.group(1))
            )

# --------------------------------------------- 11c. Hasil.gagal() harus GalatData
# KELAS BUG NYATA (15 Okt 2026, ketahuan dari CI): `Hasil<T>.gagal('teks')`
# gagal kompilasi karena parameter bertipe `GalatData?`, BUKAN String.
# Cek UNDEF-MEMBER tidak menangkapnya (method-nya memang ada), dan `galat` punya
# alias `Hasil.galat(...)` yang pepperinya sama - jadi pemanggilannya terlihat
# benar di mata.
GALAT_STRING = re.compile(r"\bHasil\s*(?:<[^()<>]*>)?\s*\.\s*(?:gagal|galat)\s*\(\s*(['\"])")
for f in files:
    for m in GALAT_STRING.finditer(raw[f]):
        baris = raw[f][:m.start()].count("\n") + 1
        bad("GALAT-TIPE", f,
            "Hasil.%s() diberi String di baris %d - parameter bertipe "
            "`GalatData?`. Bungkus: GalatData('...')" % (m.group(0).split(".")[1].split("(")[0], baris))

# --------------------------------------- 11d. context.push/pop tanpa import go_router
# KELAS BUG NYATA (15 Okt 2026, ketahuan dari CI): `context.push/pop/canPop`
# adalah EXTENSION dari package `go_router`, BUKANG method bawaan BuildContext.
# File yang sebelumnya tidak pernah memanggil navigasi sama sekali (galeri)
# jadi tidak punya import itu -> "The method 'push' isn't defined for the
# type 'BuildContext'". Checker tidak menangkapnya karena `pop`/`canPop` bukan
# simbol project.
GO_ROUTER_EXT = re.compile(r"(?<![\w.])context\s*\.\s*(go|push|pop|canPop|replace|goNamed|pushNamed)\s*\(")
for f in files:
    body = raw[f]
    nama = sorted({m.group(1) for m in GO_ROUTER_EXT.finditer(body)})
    if not nama:
        continue
    if not re.search(r"import\s+'package:go_router/go_router\.dart'", body):
        daftar = " dan ".join("context.%s()" % x for x in nama)
        bad("IMPORT-GO-ROUTER", f,
            "memakai %s tapi `package:go_router/go_router.dart` tidak "
            "di-import - method itu EXTENSION dari go_router, bukan method "
            "bawaan BuildContext" % daftar)

# ------------------------------------- 11e. paket `package:` harus ada di pubspec
# KELAS BUG NYATA (16 Okt 2026, ketahuan dari CI): ZIP baru menimpa
# `pubspec.yaml` dan FOUR dependensi hilang (share_plus, cross_file,
# image_picker, path_provider) -> CI compiling dengan
# "Undefined name 'Share'" dan "Method not found: 'XFile'".
# Cek IMPORT-RESOLVE tidak menangkapnya karena yang hilang itu paket, bukan
# file di dalam lib/ - dan `flutter analyze` di workflow memang `|| true`.
PKG_IMPORT = re.compile(r"""import\s+'package:([a-z0-9_]+)/""")
pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8") \
    if (ROOT / "pubspec.yaml").exists() else ""
paket_dipakai = {}
for f in files:
    for m in PKG_IMPORT.finditer(raw[f]):
        paket_dipakai.setdefault(m.group(1), set()).add(f)
SDK_BUILTIN = {"flutter", "flutter_test", "flutter_localizations"}
for paket,astic in sorted(paket_dipakai.items()):
    if paket == PKG or paket in SDK_BUILTIN:
        continue
    if re.search(r"^\s{2}%s\s*:" % re.escape(paket), pubspec, re.M):
        continue
    bad("PAKET-HILANG", sorted(astic)[0],
        "`package:%s/...` di-import tapi tidak terdaftar di pubspec.yaml - "
        "build gagal dengan 'Undefined name'. %d file memakainya, contoh: %s"
        % (paket, len(astic), ", ".join(sorted(p.name for p in list(astic)[:3]))))

# -------------------------------- 12. komponen yang sengaja disimpan tapi belum dipakai
# KEPUTUSAN USER (16 Okt 2026): "jangan ada yang dipangkas sekarang segala
# apapun apk dalam proyek kunbar, tak apa ukurannya besar yang important
# terbaik, sempurna dan modern". Jadi komponen yang tidak terpakai TIDAK
# dihapus; hanya dicatat di `tool/keep_unused.txt` supaya DEAD-FILE di sana
# jadi CATATAN, bukan MASALAH yang memblokir build.
#
# File di daftar itu tetap wajib bisa dikompilasi - Dart tidak mengompilasi
# file yang tidak terjangkau dari main.dart, jadi build tidak akan menangkap
# kerusakan di dalamnya.
KEEP = ROOT / "tool" / "keep_unused.txt"
disimap = set()
if KEEP.exists():
    for baris in KEEP.read_text(encoding="utf-8").splitlines():
        b = baris.strip()
        if b and not b.startswith("#"):
            disimap.add(b)

if disimap:
    tetap_problem = [p for p in problems if p[0] == "DEAD-FILE" and p[1] in disimap]
    problems = [p for p in problems if p not in tetap_problem]
    for _, path, _ in tetap_problem:
        note("disimpan sengaja (tool/keep_unused.txt), belum dipakai: %s" % path)
    for p in sorted(disimap):
        if not any(x[1] == p for x in tetap_problem):
            note("tool/keep_unused.txt mendaftarkan %s tapi file itu tidak mati - "
                 "hapus daftarnya supaya daftarnya jujur" % p)

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
    order = {"DEAD-FILE": 0, "MISSING-IMPORT": 1, "UNDEF-MEMBER": 2,
             "CTOR-UNKNOWN": 3, "ROUTE-UNKNOWN": 4,
             "IMPORT-RESOLVE": 5, "UNUSED-IMPORT": 6, "UNUSED-PRIVATE": 7,
             "UNUSED-PROVIDER": 8, "BRACE": 9, "NON-LATIN": 10, "ASSET": 11,
             "FIELD-HILANG": 2, "EXT-HILANG": 2, "REF-FIELD-AWAL": 2,
             "GALAT-TIPE": 2, "IMPORT-GO-ROUTER": 6, "PAKET-HILANG": 5}
    for kind, path, msg in sorted(problems, key=lambda p: (order.get(p[0], 9), p[1])):
        print(f"  [{kind}] {path}\n      {msg}")
    sys.exit(1)
print("\nOK - 0 masalah.")