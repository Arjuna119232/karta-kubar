#!/usr/bin/env python3
"""Cek karakter non-Latin di seluruh repo (kode + komentar + dokumen).

Kenapa perlu alat terpisah, bukan cuma `tool/check_dart.py`:
  - `check_dart.py` hanya melihat `.dart`.
  - Karakter CJK/Hangul pernah nyempet masuk ke komentar Python dan Markdown
    dari IME, lalu membingungkan siapa pun yang membaca.
  - Emoji dipakai sebagai penanda status di dokumen Markdown itu SAH; yang
    dicek di sini hanya huruf non-Latin (CJK, Kana, Hangul,_fullwidth).

Jalankan:  python3 tool/check_nonlatin.py     # exit 0 = bersih, 1 = ada
"""

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

LEWATI_DIR = {'.git', 'build', '.dart_tool', '.idea', 'vscode', 'node_modules'}
LEWATI_EXT = {
    '.png', '.jpg', '.jpeg', '.webp', '.gif', '.zip', '.gz',
    '.keystore', '.jks', '.p12', '.so', '.dex', '.apk', '.aab',
    '.bin', '.jar', '.ttf', '.otf', '.ico',
}
# Rentang huruf non-Latin yang tidak boleh muncul di source kita.
RENTANG = [
    (0x1100, 0x11FF),    # Hangul Jamo
    (0x2E80, 0x2EFF),    # CJK Radikal
    (0x3000, 0x303F),    # CJK Simbol & punctuated
    (0x3040, 0x30FF),    # Hiragana + Katakana
    (0x3130, 0x318F),    # Hangul kompatibilitas
    (0x3400, 0x4DBF),    # CJK Extension A
    (0x4E00, 0x9FFF),    # CJK Unified
    (0xA960, 0xA97F),    # Hangul Jamo Extended-A
    (0xAC00, 0xD7AF),    # Hangul Syllables
    (0xF900, 0xFAFF),    # CJK Compatibility Ideographs
    (0xFF00, 0xFFEF),    # Halfwidth & Fullwidth Forms
    (0x20000, 0x2A6DF),  # CJK Extension B
]


def non_latin(ch: str) -> bool:
    c = ord(ch)
    return any(a <= c <= b for a, b in RENTANG)


def main() -> int:
    masalah: list[str] = []
    jumlah_file = 0

    for p in sorted(ROOT.rglob('*')):
        if not p.is_file():
            continue
        if any(d in p.parts for d in LEWATI_DIR):
            continue
        if p.suffix.lower() in LEWATI_EXT:
            continue
        try:
            teks = p.read_text(encoding='utf-8')
        except (UnicodeDecodeError, OSError):
            continue

        jumlah_file += 1
        for nomor, baris in enumerate(teks.splitlines(), 1):
            salah = sorted({c for c in baris if non_latin(c)})
            if salah:
                rel = p.relative_to(ROOT)
                masalah.append(
                    f"{rel}:{nomor}  {' '.join(salah)}  |  {baris.strip()[:90]}"
                )

    print("=" * 62)
    print("KUNBAR Connect - cek karakter non-Latin")
    print("=" * 62)
    print(f"file diperiksa : {jumlah_file}")

    if not masalah:
        print("\nOK - 0 masalah.")
        return 0

    print(f"\nMASALAH ({len(masalah)}):")
    for m in masalah:
        print(f"  {m}")
    print("\nGanti hurufnya dengan padanan Latin/Indonesia. Jangan pakai")
    print("pinyin atau arti harfiah - tulis kalimatnya dalam bahasa Indonesia.")
    return 1


if __name__ == '__main__':
    sys.exit(main())