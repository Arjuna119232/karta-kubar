#!/usr/bin/env python3
"""Pemeriksa cepat untuk apps/mitra (dijalankan dari root repo `apps/mitra`).

Kenapa file ini ada: `tool/check_dart.py` di ROOT repo di-hardcode untuk app
warga (`LIB=lib`, `PKG="karta_connect"`, cek `core/router.dart` +
`app_colors.dart`), jadi tidak berlaku untuk app mitra. Ini BUKAN pengganti
`flutter analyze` — oracle sebenarnya tetap CI:

    gh workflow run build-mitra.yml --ref mitra -f analyze-only=yes

Yang diperiksa (semuanya deterministik, tanpa menebak):
  1. IMPORT-HILANG   import relatif / `package:kunbar_mitra/...` yang tidak
                     menunjuk berkas nyata.
  2. BARREL-GANDA    satu berkas meng-import `design/tokens.dart` DAN
                     `core/theme.dart` sekaligus (theme = barrel tokens) ->
                     memicu lint `unnecessary_import`.
  3. NON-LATIN       huruf CJK/Kana/Hangul/fullwidth yang nyasar dari IME.
  4. KURUNG          `{}` `()` `[]` seimbang di luar komentar, dengan string
                     dikosongkan LEBIH DULU (interpolasi `'${a[0]}'` membuat
                     hitungan mentah meleset, jadi tanda kutip ditangani
                     sebagai satu token).

Exit 0 = bersih, 1 = ada masalah.
"""
from __future__ import annotations

import re
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"
PKG = "kunbar_mitra"

REL_IMPORT = re.compile(r"""^\s*import\s+['"]([^'"]+)['"]""", re.M)
PAIRS = {")": "(", "]": "[", "}": "{"}


def dart_files() -> list[Path]:
    return sorted(LIB.rglob("*.dart"))


def strip_code(src: str) -> str:
    """Buang komentar dan isi string (interpolasi ikut dibuang)."""
    out: list[str] = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if c == "/" and i + 1 < n and src[i + 1] == "/":
            while i < n and src[i] != "\n":
                i += 1
        elif c == "/" and i + 1 < n and src[i + 1] == "*":
            i += 2
            while i + 1 < n and not (src[i] == "*" and src[i + 1] == "/"):
                i += 1
            i += 2
        elif c in "'\"":
            triple = src.startswith(c * 3, i)
            q = c * 3 if triple else c
            i += len(q)
            depth = 0
            while i < n:
                if depth == 0 and src.startswith(q, i):
                    i += len(q)
                    break
                if c != "'" or True:
                    if src[i] == "\\":
                        i += 2
                        continue
                    if src[i] == "$" and i + 1 < n and src[i + 1] == "{":
                        depth += 1
                        i += 2
                        continue
                    if depth and src[i] == "}":
                        depth -= 1
                    if depth and src[i] in "'\"":
                        inner = src[i]
                        i += 1
                        while i < n and src[i] != inner:
                            i += 2 if src[i] == "\\" else 1
                if not triple and src[i] == "\n":
                    break
                i += 1
            out.append(" ")
        else:
            out.append(c)
            i += 1
    return "".join(out)


def resolve_rel(src_file: Path, target: str) -> Path:
    base = (src_file.parent / target).resolve()
    return base if base.suffix == ".dart" else base.with_suffix(".dart")


def main() -> int:
    problems: list[str] = []
    files = dart_files()
    if not files:
        print("GAGAL: tidak ada berkas .dart di", LIB)
        return 1

    for f in files:
        src = f.read_text(encoding="utf-8", errors="replace")
        rel = f.relative_to(ROOT)

        # 1. import resolve
        for target in REL_IMPORT.findall(src):
            if target.startswith("package:"):
                if not target.startswith(f"package:{PKG}/"):
                    continue  # paket pihak ketiga, bukan urusan kita
                rest = target[len(f"package:{PKG}/"):]
                if not (LIB / rest).exists():
                    problems.append(f"[IMPORT-HILANG] {rel}: {target}")
            elif target.startswith("dart:"):
                continue
            elif not resolve_rel(f, target).exists():
                problems.append(f"[IMPORT-HILANG] {rel}: {target}")

        # 2. barrel ganda
        imports = REL_IMPORT.findall(src)
        has_tokens = any(t.endswith("design/tokens.dart") for t in imports)
        has_theme = any(t.endswith("core/theme.dart") for t in imports)
        if has_tokens and has_theme:
            problems.append(f"[BARREL-GANDA] {rel}: import tokens.dart + theme.dart")

        # 3. non-latin
        for ch in src:
            if ord(ch) < 0x2100:
                continue
            if unicodedata.category(ch) in ("Lo", "Lm"):
                problems.append(f"[NON-LATIN] {rel}: {ch!r} U+{ord(ch):04X}")
                break

        # 4. kurung
        code = strip_code(src)
        stack: list[str] = []
        for ch in code:
            if ch in "([{":
                stack.append(ch)
            elif ch in ")]}":
                if not stack or stack[-1] != PAIRS[ch]:
                    problems.append(f"[KURUNG] {rel}: '{ch}' tidak berpasangan")
                    break
                stack.pop()
        else:
            if stack:
                problems.append(f"[KURUNG] {rel}: sisa {''.join(stack)}")

    for p in problems:
        print(p)
    print(f"\n{len(files)} berkas diperiksa, {len(problems)} masalah.")
    return 0 if not problems else 1


if __name__ == "__main__":
    sys.exit(main())
