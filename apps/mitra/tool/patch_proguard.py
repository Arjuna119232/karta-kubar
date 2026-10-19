#!/usr/bin/env python3
"""Pasang aturan R8/ProGuard untuk plugin Flutter (mode release).

KENAPA DIPERLUKAN
-----------------
`flutter build apk --release` menjalankan R8 (minify) — terbukti di APK kita:
`kotlin/coroutines/Continuation` muncul sebagai `Lji;` di dex. R8 boleh
menghapus/mengganti nama anggota kelas yang menurutnya tidak dipakai, padahal
plugin Flutter (terutama yang di-generate Pigeon) dipanggil lewat jalur yang
tidak selalu terlihat sebagai pemanggilan langsung. Gejalanya khas:

    java.lang.NoSuchMethodError: no non-static method
    "...SharedPreferencesApiRegistrar;.getAll(Ljava/lang/String;
      Ljava/util/List;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;"

Kelasnya ADA, method-nya hilang/berubah -> crash HANYA di release, debug aman.

STRATEGI (idempoten lewat marker)
---------------------------------
`android/` di-generate ulang tiap CI run, jadi kondisi awal selalu template
bersih. Script:
  1. menulis `android/app/proguard-rules.pro` berisi aturan keep,
  2. menyuntik `proguardFiles(...)` ke buildType `release` sekali saja
     (marker `// KUNBAR-PROGUARD`).

CATATAN TEKNIS
--------------
- `proguardFiles` hanya berpengaruh kalau R8/minify menyala; kalau suatu saat
  minify dimatikan, aturan ini tidak merusak apa pun.
- Urutan WAJIB di workflow: setup_android.sh -> patch_signing.py ->
  patch_proguard.py (keduanya menyentuh build.gradle.kts yang sama).
- Hindari `-keep class kotlinx.coroutines.**` (terlalu luas); cukup dontwarn.
"""
from __future__ import annotations

import pathlib
import sys

GRADLE_CANDIDATES = [
    pathlib.Path("android/app/build.gradle.kts"),
    pathlib.Path("android/app/build.gradle"),
]
RULES = pathlib.Path("android/app/proguard-rules.pro")
MARKER = "// KUNBAR-PROGUARD"

RULES_BODY = """# --- KUNBAR Mitra: aturan R8 untuk build release ---
# Plugin Flutter dipanggil lewat jalur yang tidak selalu terlihat R8. Tanpa
# keep, anggota kelas plugin bisa hilang -> NoSuchMethodError saat runtime
# (contoh: SharedPreferencesApiRegistrar.getAll(...) di shared_preferences).
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class dev.flutter.pigeon.** { *; }

# Registrar plugin (Pigeon/Kotlin) diakses oleh engine.
-keepclassmembers class **$*Registrar { public *; }
-keepclassmembers class * implements io.flutter.embedding.engine.plugins.FlutterPlugin { public *; }

# Anotasi @Keep tidak boleh dibuang.
-keepclassmembers,allowobfuscation class * {
    @androidx.annotation.Keep <methods>;
}

# Pustaka yang dipakai plugin tapi tidak selalu terlihat dari kode app.
-dontwarn kotlinx.coroutines.**
-dontwarn io.flutter.plugins.**
"""

BLOCK_KTS = f"""            {MARKER}: aturan keep plugin (proguard-rules.pro)
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
"""

BLOCK_GROOVY = f"""            {MARKER}: aturan keep plugin (proguard-rules.pro)
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
"""


def tulis_rules() -> bool:
    RULES.parent.mkdir(parents=True, exist_ok=True)
    if RULES.exists() and "io.flutter.plugins.**" in RULES.read_text():
        print(f"    + {RULES}: aturan keep (sudah ada)")
        return True
    RULES.write_text(RULES_BODY)
    print(f"    + {RULES}: dibuat ({len(RULES_BODY.splitlines())} baris)")
    return True


def patch(path: pathlib.Path) -> bool:
    is_kts = path.suffix == ".kts"
    src = path.read_text()

    if MARKER in src:
        print(f"    + {path}: proguardFiles (sudah ada)")
        return True

    if "buildTypes {" not in src:
        print(f"FAIL: blok buildTypes tidak ditemukan di {path}")
        return False

    i_bt = src.index("buildTypes {")
    i_rel = src.find("release {", i_bt)
    if i_rel < 0:
        print(f"FAIL: buildType 'release' tidak ditemukan di {path}")
        return False

    insert_at = src.index("\n", i_rel) + 1
    src = src[:insert_at] + (BLOCK_KTS if is_kts else BLOCK_GROOVY) + src[insert_at:]
    path.write_text(src)
    print(f"    + {path}: proguardFiles disuntik ke buildType release")
    return True


def verify(path: pathlib.Path) -> bool:
    out = path.read_text()
    problems: list[str] = []
    if MARKER not in out:
        problems.append("marker proguard tidak ada di build.gradle")
    if "proguard-rules.pro" not in out:
        problems.append("proguardFiles tidak merujuk proguard-rules.pro")
    if out.count(MARKER) != 1:
        problems.append(f"marker muncul {out.count(MARKER)}x (harus 1)")
    if not RULES.exists():
        problems.append("android/app/proguard-rules.pro tidak dibuat")
    elif "io.flutter.plugins.**" not in RULES.read_text():
        problems.append("aturan keep plugin tidak ada di proguard-rules.pro")
    for p in problems:
        print(f"FAIL: {p}")
    return not problems


def main() -> int:
    for g in GRADLE_CANDIDATES:
        if not g.exists():
            continue
        if not tulis_rules():
            return 1
        if not patch(g):
            return 1
        if not verify(g):
            return 1
        print("==> patch_proguard: OK")
        return 0

    print("FAIL: android/app/build.gradle(.kts) tidak ditemukan")
    return 1


if __name__ == "__main__":
    sys.exit(main())
