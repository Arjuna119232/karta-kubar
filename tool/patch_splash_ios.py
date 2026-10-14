#!/usr/bin/env python3
"""Pasang splash screen NATIVE iOS (UILaunchScreen) untuk KUNBAR Connect.

KENAPA ADA SKRIP INI
--------------------
Sama seperti Android: folder `ios/` di-generate ulang tiap CI run oleh
`flutter create --platforms=ios`, jadi perubahan manual hilang. Pola ini
mengikuti tool/patch_splash_android.py.

ATURAN YANG DITERAPKAN (spesifikasi 2026, ketat)
------------------------------------------------
1. Durasi maksimal 1,2 detik  -> iOS tidak menyediakan pengaturan durasi;
   launch screen dikendalikan sistem dan selalu jauh lebih pendek dari itu.
   Yang gw pastikan hanya tidak ada animasi buatan yang menambah waktu.
2. HANYA logo + warna solid   -> `UILaunchScreen` diisi HANYA UIColorName +
   UIImageName. Tanpa UILabel, tanpa tagline, tanpa progress.
3. Background = warna brand  -> UIColorName -> colorset LaunchBackground
   yang warnanya persis sama dengan AppColors.primary.
4. API native                -> UILaunchScreen (Info.plist), BUKAN storyboard
   custom.

CATATAN PENTANG SOAL UKURAN GAMBAR
----------------------------------
`UILaunchScreen` memakai UKURAN INTRINSIC gambar dalam POINT - Android
membuat mask lingkaran 192dp, iOS tidak. Karena itu aset iOS dibuat terpisah
(160pt pada @1x, plus @2x/@3x). Memakai PNG Android 512px akan tampil
512pt dan memenuhi layar.

EXIT 0 = terpasang, exit 1 = ada yang gagal.
"""
from __future__ import annotations

import json
import pathlib
import plistlib
import re
import shutil
import sys

ROOT = pathlib.Path(".")
IOS = ROOT / "ios"
RUNNER = IOS / "Runner"
INFO = RUNNER / "Info.plist"
XCCASSETS = RUNNER / "Assets.xcassets"
STORYBOARD = RUNNER / "Base.lproj" / "LaunchScreen.storyboard"

MARKER = "KUNBAR-SPLASH"
BRAND_HEX = "1B5E20"          # AppColors.primary
COLOR_NAME = "LaunchBackground"
IMAGE_NAME = "splash_icon"

errors: list[str] = []
notes: list[str] = []


def rgb_komponen(hex6: str) -> dict[str, str]:
    r, g, b = (int(hex6[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
    return {"red": f"{r:.5f}", "green": f"{g:.5f}", "blue": f"{b:.5f}", "alpha": "1.00000"}


# --------------------------------------------------------------- preflight
if not INFO.is_file():
    sys.exit(f"FAIL: {INFO} tidak ada - flutter create belum menghasilkan ios/")
if not XCCASSETS.is_dir():
    sys.exit(f"FAIL: {XCCASSETS} tidak ada - ios/ tidak lengkap")

# --------------------------------------------------------------- 1. colorset
colorset = XCCASSETS / f"{COLOR_NAME}.colorset"
colorset.mkdir(parents=True, exist_ok=True)
(colorset / "Contents.json").write_text(
    json.dumps(
        {
            "colors": [
                {
                    "color": {
                        "color-space": "srgb",
                        "components": rgb_komponen(BRAND_HEX),
                    },
                    "idiom": "universal",
                }
            ],
            "info": {"author": "xcode", "version": 1},
        },
        indent=2,
    )
    + "\n",
    encoding="utf-8",
)
notes.append(f"{colorset.name}.colorset dibuat (#{BRAND_HEX})")

# --------------------------------------------------------------- 2. imageset
imageset = XCCASSETS / f"{IMAGE_NAME}.imageset"
imageset.mkdir(parents=True, exist_ok=True)
entries = []
for skala, suffix in (("1x", ""), ("2x", "@2x"), ("3x", "@3x")):
    src = pathlib.Path(f"assets/brand/{IMAGE_NAME}_ios{suffix}.png")
    if not src.is_file():
        errors.append(f"aset iOS hilang: {src} (jalankan tool/gen_splash_icons.py)")
        continue
    shutil.copyfile(src, imageset / f"{IMAGE_NAME}{suffix}.png")
    entries.append({"filename": f"{IMAGE_NAME}{suffix}.png", "idiom": "universal", "scale": skala})
notes.append(f"{imageset.name}.imageset dibuat ({len(entries)} skala)")

(imageset / "Contents.json").write_text(
    json.dumps({"images": entries, "info": {"author": "xcode", "version": 1}}, indent=2) + "\n",
    encoding="utf-8",
)

# --------------------------------------------------------------- 3. Info.plist
with INFO.open("rb") as fh:
    plist = plistlib.load(fh)

# WAJIB diganti utuh, bukan di-merge: kalau ada key lain yang pernah tertinggal
# dari percobaan sebelumnya, key itu akan tetap dipakai iOS.
before = plist.get("UILaunchScreen")
plist["UILaunchScreen"] = {"UIColorName": COLOR_NAME, "UIImageName": IMAGE_NAME}
if before != plist["UILaunchScreen"]:
    notes.append(f"Info.plist UILaunchScreen diperbarui (sebelumnya: {before!r})")

# Hapus UILaunchStoryboardName kalau ada: presence both bikin Xcode/Apple
# memperingatkan, dan iOS 14+ sudah mengabaikan storyboard.
if plist.pop("UILaunchStoryboardName", None) is not None:
    notes.append("UILaunchStoryboardName dihapus (UILaunchScreen yang dipakai)")

with INFO.open("wb") as fh:
    plistlib.dump(plist, fh)

# --------------------------------------------------------------- 4. storyboard
# Hanya relevan untuk iOS 13 (UILaunchScreen baru ada di iOS 14). Template
# Flutter memberi warna LATAR PUTIH -> inilah sumber kedip putih di iOS 13.
if STORYBOARD.is_file():
    sb = STORYBOARD.read_text(encoding="utf-8")
    putih = '<color key="backgroundColor" red="1" green="1" blue="1" alpha="1"'
    k = rgb_komponen(BRAND_HEX)
    hijau = (
        f'<color key="backgroundColor" red="{k["red"]}" green="{k["green"]}" '
        f'blue="{k["blue"]}" alpha="{k["alpha"]}"'
    )
    if putih in sb:
        STORYBOARD.write_text(sb.replace(putih, hijau, 1), encoding="utf-8")
        notes.append("LaunchScreen.storyboard: latar putih -> hijau brand (iOS 13)")
    elif hijau not in sb:
        errors.append("LaunchScreen.storyboard: tidak ada baris backgroundColor yang dikenali")

# --------------------------------------------------------------- 5. verifikasi
print("=" * 62)
print("  KUNBAR Connect - native splash iOS (UILaunchScreen)")
print("=" * 62)

# Warna harus sama dengan AppColors.primary - sumber kebenaran ada di Dart.
app_colors = ROOT / "lib/core/theme/app_colors.dart"
if not app_colors.is_file():
    errors.append("lib/core/theme/app_colors.dart tidak ada")
else:
    # Color(0xAARRGGBB) = 8 digit hex; yang dibutuhkan 6 digit terakhir.
    m = re.search(
        r"static\s+const\s+Color\s+primary\s*=\s*Color\(0x[0-9A-Fa-f]{2}([0-9A-Fa-f]{6})\s*\)",
        app_colors.read_text(encoding="utf-8"),
    )
    if not m:
        errors.append("AppColors.primary tidak ditemukan di app_colors.dart")
    elif m.group(1).upper() != BRAND_HEX:
        errors.append(f"warna splash {BRAND_HEX} != AppColors.primary {m.group(1).upper()}")
    else:
        print(f"    . warna splash #{BRAND_HEX} = AppColors.primary (cocok)")

if "UILaunchScreen" not in plist:
    errors.append("Info.plist tidak punya UILaunchScreen")
else:
    ui = plist["UILaunchScreen"]
    if set(ui) != {"UIColorName", "UIImageName"}:
        errors.append(
            f"UILaunchScreen punya key tambahan {sorted(set(ui) - {'UIColorName', 'UIImageName'})} - "
            "spesifikasi melarang apa pun selain UIColorName + UIImageName"
        )
    if ui.get("UIColorName") != COLOR_NAME:
        errors.append(f"UIColorName = {ui.get('UIColorName')!r}, harusnya {COLOR_NAME!r}")
    if ui.get("UIImageName") != IMAGE_NAME:
        errors.append(f"UIImageName = {ui.get('UIImageName')!r}, harusnya {IMAGE_NAME!r}")
    if len(ui) == 2:
        print("    . UILaunchScreen hanya UIColorName + UIImageName (tanpa label/animasi)")

for wajib in (colorset / "Contents.json", imageset / "Contents.json"):
    if not wajib.is_file():
        errors.append(f"{wajib} tidak ada")

if not (imageset / f"{IMAGE_NAME}.png").is_file():
    errors.append(f"{imageset}/{IMAGE_NAME}.png tidak ada")

for n in notes:
    print(f"    + {n}")

if errors:
    print("\nGAGAL:")
    for e in errors:
        print(f"    FAIL {e}")
    sys.exit(1)
print("==> patch_splash_ios: OK")
