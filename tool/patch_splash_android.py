#!/usr/bin/env python3
"""Pasang splash screen NATIVE Android 12+ (androidx.core:core-splashscreen).

KENAPA ADA SKRIP INI
--------------------
`android/` di-generate ulang dari nol setiap CI run
(`flutter create --org id.kubarkonek --project-name app --platforms=android`),
jadi file XML/Kotlin hasil editan manual HILANG. Pola proyek ini sudah
memakai patch script yang idempoten (lihat patch_signing.py); splash ikut
pola yang sama.

ATURAN YANG DITERAPKAN (spesifikasi 2026, ketat)
------------------------------------------------
1. Durasi maksimal 1.2 detik  -> `windowSplashScreenAnimationDuration` = 500ms
   (dengan TIDAK memanggil setKeepOnScreenCondition, splash hilang tepat saat
   frame pertama Flutter digambar, jadi tidak bisa lebih dari 1.2 detik)
2. HANYA logo + warna solid    -> tidak ada teks/tagline/progress di XML
3. Background = warna brand   -> `windowSplashScreenBackground` = @color/kunbar_brand
   plus `android:windowBackground` di NormalTheme = warna yang sama, supaya
   TIDAK ada frame putih/hitam di belakang frame Flutter pertama
4. API native                 -> Theme.SplashScreen + installSplashScreen()

EXIT 0 = terpasang, exit 1 = ada yang gagal.
"""
from __future__ import annotations

import pathlib
import re
import shutil
import sys

ROOT = pathlib.Path("android/app")
RES = ROOT / "src/main/res"
BUILD_GRADLE = ROOT / "build.gradle.kts"
if not BUILD_GRADLE.exists():
    BUILD_GRADLE = ROOT / "build.gradle"
MARKER = "KUNBAR-SPLASH"

# Warna brand = AppColors.primary (lib/core/theme/app_colors.dart)
BRAND_HEX = "1B5E20"
BRAND_NAME = "kunbar_brand"

# Batas keras spesifikasi: <= 1000ms
DURASI_MS = 500

DEPENDENCY = 'implementation("androidx.core:core-splashscreen:1.0.1")'

STYLES = f"""<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- {MARKER}: native splash Android 12+ (Theme.SplashScreen).
         Hanya logo + warna solid. Tanpa tagline, tanpa progress bar. -->
    <style name="LaunchTheme" parent="Theme.SplashScreen">
        <item name="windowSplashScreenBackground">@color/{BRAND_NAME}</item>
        <item name="windowSplashScreenAnimatedIcon">@drawable/splash_icon</item>
        <item name="windowSplashScreenAnimationDuration">{DURASI_MS}</item>
        <item name="postSplashScreenTheme">@style/NormalTheme</item>
    </style>

    <!-- Latar SEJAK frame pertama. Warna sama persis dengan splash, jadi
         tidak ada kedipan putih ketika Flutter mulai merender. -->
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@color/{BRAND_NAME}</item>
    </style>
</resources>
"""

COLORS = f"""<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- {MARKER} - harus sama persis dengan AppColors.primary -->
    <color name="{BRAND_NAME}">#{BRAND_HEX}</color>
</resources>
"""

# Fallback untuk Android 11 ke bawah (pre-31): inti hijau polos, tanpa teks.
# Di API 31+ file ini tidak dipakai karena Theme.SplashScreen yang menangani.
LAUNCH_BG = """<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/%s" />
</layer-list>
""" % BRAND_NAME

errors: list[str] = []
notes: list[str] = []

# `--verify-only` hanya menjalankan pemeriksaan, tanpa menulis apa pun.
# Dipakai untuk menguji apakah guard benar-benar menangkap kegagalan:
# kalau menulis ulang file tiap jalan, kerusakan yang disuntikkan akan
# diperbaiki sendiri dan guard-nya tidak pernah teruji.
VERIFY_ONLY = "--verify-only" in sys.argv


def tulis(path: pathlib.Path, isi: str) -> None:
    if VERIFY_ONLY:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(isi, encoding="utf-8")
    notes.append(f"{path} ditulis")


# --------------------------------------------------------------- 1. styles
for nama in ("values", "values-night"):
    tulis(RES / nama / "styles.xml", STYLES)

tulis(RES / "values" / "colors.xml", COLORS)
tulis(RES / "drawable" / "launch_background.xml", LAUNCH_BG)

# --------------------------------------------------------------- 2. drawable
# `nodpi` supaya Android tidak ikut menskalakan ulang per density.
sumber = pathlib.Path("assets/brand/splash_icon.png")
if not sumber.is_file():
    errors.append(f"aset ikon splash hilang: {sumber} (jalankan tool/gen_splash_icons.py)")
else:
    tujuan = RES / "drawable-nodpi" / "splash_icon.png"
    if not VERIFY_ONLY:
        tujuan.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(sumber, tujuan)
        notes.append(f"{tujuan} disalin dari {sumber}")

# --------------------------------------------------------------- 3. dependency
if not BUILD_GRADLE.exists():
    errors.append(f"tidak ditemukan: {BUILD_GRADLE}")
elif VERIFY_ONLY:
    pass
else:
    src = BUILD_GRADLE.read_text(encoding="utf-8")
    if DEPENDENCY in src:
        notes.append("dependensi core-splashscreen (sudah ada)")
    elif re.search(r"^\s*dependencies\s*\{", src, re.MULTILINE):
        # sisipkan sebagai baris pertama di dalam blok dependencies
        src = re.sub(
            r"^(\s*)dependencies\s*\{\s*$",
            lambda m: f"{m.group(1)}dependencies {{\n{m.group(1)}    {DEPENDENCY}",
            src,
            count=1,
            flags=re.MULTILINE,
        )
        BUILD_GRADLE.write_text(src, encoding="utf-8")
        notes.append(f"dependensi disuntik ke {BUILD_GRADLE}")
    else:
        blok = f"\ndependencies {{\n    {DEPENDENCY}\n}}\n"
        BUILD_GRADLE.write_text(src + blok, encoding="utf-8")
        notes.append(f"blok dependencies dibuat di {BUILD_GRADLE}")

# --------------------------------------------------------------- 4. MainActivity
def src_awal(f: pathlib.Path) -> str:
    return f.read_text(encoding="utf-8")


kt = list((ROOT / "src/main/kotlin").rglob("MainActivity.kt"))
if not kt:
    errors.append("MainActivity.kt tidak ditemukan di android/app/src/main/kotlin")
else:
    f = kt[0]
    if VERIFY_ONLY:
        pass
    elif "installSplashScreen" in src_awal(f):
        notes.append(f"{f.name} sudah punya installSplashScreen()")
    else:
        src = src_awal(f)
        paket = re.search(r"^package\s+([\w.]+)", src, re.MULTILINE)
        if not paket:
            errors.append(f"tidak bisa baca `package` dari {f}")
        else:
            src = src.replace(
                "import io.flutter.embedding.android.FlutterActivity",
                "import android.os.Bundle\n"
                "import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen\n"
                "import io.flutter.embedding.android.FlutterActivity",
                1,
            )
            # Template Flutter saat ini berbentuk SATU BARIS TANPA BODY:
            #     class MainActivity : FlutterActivity()
            # Versi lama (punyalah body) juga harus tetap tertangani, karena
            # script ini dipakai ulang saat naik versi Flutter.
            pola_body = re.compile(
                r"(class\s+MainActivity\s*:\s*FlutterActivity\s*\(\s*\)\s*\{)",
                re.MULTILINE,
            )
            polos = re.compile(
                r"class\s+MainActivity\s*:\s*FlutterActivity\s*\(\s*\)", re.MULTILINE
            )
            oncreate = (
                "\n    override fun onCreate(savedInstanceState: Bundle?) {\n"
                f"        // {MARKER}: WAJIB dipanggil SEBELUM super.onCreate().\n"
                "        installSplashScreen()\n"
                "        super.onCreate(savedInstanceState)\n"
                "    }\n"
            )
            if pola_body.search(src):
                src = pola_body.sub(lambda m: m.group(1) + oncreate, src, count=1)
                notes.append(f"{f.name}: installSplashScreen() disisipkan (body ada)")
            elif polos.search(src):
                src = polos.sub(lambda m: m.group(0) + " {" + oncreate + "}", src, count=1)
                notes.append(f"{f.name}: installSplashScreen() disisipkan (body dibuat)")
            else:
                errors.append(f"bentuk `class MainActivity: FlutterActivity()` tidak dikenali di {f}")
            if "installSplashScreen()" in src and src != f.read_text(encoding="utf-8"):
                f.write_text(src, encoding="utf-8")

# --------------------------------------------------------------- 5. verifikasi
print("=" * 62)
print("  KUNBAR Connect - native splash Android 12+")
print("=" * 62)


def cek(path: pathlib.Path, wajib: list[str]) -> None:
    if not path.exists():
        errors.append(f"verifikasi gagal: {path} tidak ada")
        return
    isi = path.read_text(encoding="utf-8")
    # Buang komentar dulu. Tanpa ini verifier bisa tertipu oleh KETERANGAN
    # yang sama persis dengan kode yang dicari: komentar di styles.xml memuat
    # kalimat "(Theme.SplashScreen)" sehingga `parent="Theme.SplashScreen"`
    # yang sudah dihapus STILL lolos dianggap benar.
    kode = re.sub(r"<!--.*?-->", "", isi, flags=re.DOTALL)
    for w in wajib:
        if w not in kode:
            errors.append(f"{path}: '{w}' tidak ditemukan")


st = RES / "values" / "styles.xml"
# Warna HEX hanya ada di colors.xml; styles.xml harus merujuk @color/<nama>.
# Dicari sebagai ATRIBUT lengkap, bukan kata "Theme.SplashScreen" telanjang.
cek(st, ['parent="Theme.SplashScreen"', f"@color/{BRAND_NAME}", "@drawable/splash_icon",
         "windowSplashScreenAnimationDuration", "postSplashScreenTheme"])
cek(RES / "values" / "colors.xml", [BRAND_NAME, BRAND_HEX])
cek(RES / "values-night" / "styles.xml", ['parent="Theme.SplashScreen"'])

# styles.xml menunjuk @drawable/splash_icon; kalau file-nya tidak ada, build
# gagal dengan error resource not found yang jauh lebih membingungkan.
ikon_res = RES / "drawable-nodpi" / "splash_icon.png"
if not ikon_res.exists():
    errors.append(f"{ikon_res} tidak ada - styles.xml menunjuk @drawable/splash_icon")

# Guard paling penting: warna splash HARUS sama dengan AppColors.primary.
# Kalau hanya membandingkan BRAND_HEX dengan dirinya sendiri, checks-nya
# selalu lulus - begitu pun kalau seseorang salah ketik BRAND_HEX jadi FFFFFF.
# Sumber kebenaran yang sesungguhnya ada di lib/core/theme/app_colors.dart.
app_colors = pathlib.Path("lib/core/theme/app_colors.dart")
if not app_colors.exists():
    errors.append(f"tidak bisa cek warna brand: {app_colors} tidak ada")
else:
    teks_warna = app_colors.read_text(encoding="utf-8")
    # Dart Color(0xAARRGGBB) = 8 digit hex. Kalau hanya menangkap 6 digit,
    # yang ikut terambil adalah ALPHA ("FF"), bukan RRGGBB - hasilnya
    # "1B5E20" dianggap tidak cocok padahal warnanya benar.
    m = re.search(
        r"static\s+const\s+Color\s+primary\s*=\s*Color\(0x[0-9A-Fa-f]{2}([0-9A-Fa-f]{6})\s*\)",
        teks_warna,
    )
    if not m:
        errors.append("AppColors.primary tidak ditemukan di app_colors.dart")
    elif m.group(1).upper() != BRAND_HEX.upper():
        errors.append(
            f"warna splash {BRAND_HEX} TIDAK sama dengan AppColors.primary "
            f"{m.group(1).upper()} di app_colors.dart"
        )
    else:
        print(f"    . warna splash #{BRAND_HEX} = AppColors.primary (cocok)")

def tanpa_komentar(isi: str) -> str:
    """Buang komentar `//` dan `/* */` tanpa menggeser urutan karakter.

    WAJIB dipakai sebelum cek posisi: baris komentar yang gw sisipkan sendiri
    berbunyi "...dipanggil SEBELUM super.onCreate()" sehingga `find("super.onCreate")`
    ketemu di KOMENTAR yang lebih dulu, bukan di pemanggilan aslinya. Akibatnya
    cek urutan selalu lapor gagal padahal kodenya sudah benar.

    Tidak ada string literal di MainActivity hasil template Flutter, jadi
    tidak mungkin ada "//" di dalam teks.
    """
    isi = re.sub(r"/\*.*?\*/", "", isi, flags=re.DOTALL)
    return "\n".join(baris.split("//")[0] for baris in isi.split("\n"))


if kt:
    isi = kt[0].read_text(encoding="utf-8")
    kode = tanpa_komentar(isi)
    if "installSplashScreen()" not in kode:
        errors.append("MainActivity.kt belum memanggil installSplashScreen()")
    else:
        # WAJIB cari PANGGILAN `installSplashScreen()`, bukan teksnya: nama yang
        # sama juga muncul di baris `import ...SplashScreen.Companion
        # .installSplashScreen` yang selalu di paling atas. Kalau cari teks
        # biasa, posisinya selalu < super.onCreate() sehingga cek urutan
        # SELALU lulus walau pemanggilannya sudah dibalik.
        panggil = kode.find("installSplashScreen()")
        super_ = kode.find("super.onCreate")
        if panggil < 0 or super_ < 0:
            errors.append("MainActivity.kt tidak punya super.onCreate()")
        elif panggil > super_:
            errors.append("installSplashScreen() dipanggil SETELAH super.onCreate()")

if BUILD_GRADLE.exists():
    if "core-splashscreen" not in BUILD_GRADLE.read_text(encoding="utf-8"):
        errors.append("dependensi androidx.core:core-splashscreen belum ada")

# Batas keras spesifikasi: windowSplashScreenAnimationDuration <= 1000ms.
# Dicek dari KONSTANTA, bukan dari XML: styles.xml ditulis ulang di awal script,
# jadi membaca file selalu mengembalikan nilai yang sama -> cek jadi sia-sia.
if DURASI_MS > 1000:
    errors.append(f"DURASI_MS={DURASI_MS} melebihi batas 1000ms")

for n in notes:
    print(f"    + {n}")

if errors:
    print("\nGAGAL:")
    for e in errors:
        print(f"    FAIL {e}")
    sys.exit(1)
print("==> patch_splash_android: OK")
