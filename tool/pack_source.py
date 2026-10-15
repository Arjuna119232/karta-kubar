#!/usr/bin/env python3
"""Kemas source KUNBAR Connect jadi ZIP untuk diedit di Acode.

    python3 tool/pack_source.py            -> nama file otomatis dari versi
    python3 tool/pack_source.py 0.11.0     -> tentukan sendiri

Aturan yang TIDAK BOLEH dilanggar:
  - `.env` TIDAK PERNAH ikut. Isinya kunci API. `.env.example` ikut.
  - `.git/`, `android/`, `ios/`, `build/` tidak ikut (digenerate ulang).
  - Pratinjau render di `design/*.png` tidak ikut (artefak kerja).
  - Aset gambar di `assets/` dan `aset-dari-user/` WAJIB ikut: itu bahan
    aplikasi, bukan buangan.

Isi zip LANGSUNG di root (tanpa folder pembungkus) supaya Acode bisa
membuka folder yang berisi `pubspec.yaml` tanpa perlu pindah file.
"""

import os
import pathlib
import sys
import zipfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
TMP = pathlib.Path(os.environ.get("TMPDIR", "/data/data/com.termux/files/usr/tmp"))

JANGAN = {
    ".env",                 # <-- kredensial. Jangan pernah masuk zip.
    "pubspec.lock",
    ".gitignore.bak",
}
JANGAN_DIR = {
    ".git", "build", ".dart_tool", "android", "ios", "linux", "macos",
    "windows", "web", ".idea", ".vscode", "__pycache__", ".github-cache",
}
GAMBAR = {".png", ".jpg", ".jpeg", ".webp"}
BUANG = pathlib.Path(os.environ.get("TMPDIR", "/tmp")) / "KUNBAR-Connect-source.zip"


def skip(path: pathlib.Path) -> bool:
    rel = path.relative_to(ROOT)
    if rel.name in JANGAN:
        return True
    if any(part in JANGAN_DIR for part in rel.parts):
        return True
    if rel.parts[0] == "design" and path.suffix.lower() in GAMBAR:
        return True
    if path.suffix in {".pyc", ".log"}:
        return True
    return False


def versi() -> str:
    if len(sys.argv) > 1:
        return sys.argv[1].lstrip("v")
    for baris in (ROOT / "pubspec.yaml").read_text(encoding="utf-8").splitlines():
        if baris.startswith("version:"):
            return baris.split(":", 1)[1].strip().split("+")[0]
    return "0.0.0"


def main() -> int:
    v = versi()
    out = TMP / f"KUNBAR-Connect-v{v}-source.zip"
    files = [p for p in ROOT.rglob("*") if p.is_file() and not skip(p)]

    if out.exists():
        out.unlink()
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        for p in sorted(files):
            z.write(p, p.relative_to(ROOT).as_posix())

    # Verifikasi: integritas + tidak ada kredensial yang bocor.
    with zipfile.ZipFile(out) as z:
        rusak = z.testzip()
        nama = z.namelist()
        bocor = [n for n in nama if n.split("/")[-1] in JANGAN]
        wajib = [x for x in ("pubspec.yaml", "CARA-ACODE.md", "lib/main.dart",
                             "supabase/schema.sql") if x not in nama]

    if rusak:
        print(f"GAGAL: zip rusak di {rusak}")
        return 1
    if bocor:
        print(f"GAGAL: berkas sensitif ikut: {bocor}")
        return 1
    if wajib:
        print(f"GAGAL: berkas wajib tidak ada: {wajib}")
        return 1

    print(f"SELESAI  : {out}")
    print(f"versi   : {v}")
    print(f"entri   : {len(files)} berkas")
    print(f"ukuran  : {out.stat().st_size / 1024 / 1024:.2f} MB")
    print("aman    : tidak ada .env / .git / android/ / pratinjau render")
    return 0


if __name__ == "__main__":
    sys.exit(main())