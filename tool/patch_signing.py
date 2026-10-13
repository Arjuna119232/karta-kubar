#!/usr/bin/env python3
"""Patch signing release Flutter agar memakai keystore asli, bukan debug key.

android/ di-generate ulang oleh `flutter create` di setiap CI run, sehingga
build.gradle(.kts) selalu kembali ke signing config debug. Script ini menulis
ulang blok signing release supaya membaca android/key.properties.

WAJIB pakai `keyProperties["..."]`, BUKAN `project.findProperty("...")`:
findProperty hanya membaca Gradle project properties (-P / gradle.properties),
TIDAK membaca file key.properties, jadi hasilnya null lalu build crash.

Kalau key.properties tidak ada, script keluar 0 tanpa mengubah apa pun.
"""
from __future__ import annotations

import pathlib
import re
import sys

GRADLE_CANDIDATES = [
    pathlib.Path("android/app/build.gradle.kts"),
    pathlib.Path("android/app/build.gradle"),
]
KEYPROPS = pathlib.Path("android/key.properties")

LOADER_KTS = """// --- KARTA KUBAR: kredensial signing ---
val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
"""

IMPORTS_KTS = "import java.util.Properties\nimport java.io.FileInputStream\n\n"

LOADER_GROOVY = """// --- KARTA KUBAR: kredensial signing ---
def keyProperties = new Properties()
def keyPropertiesFile = rootProject.file('key.properties')
if (keyPropertiesFile.exists()) {
    keyProperties.load(new FileInputStream(keyPropertiesFile))
}

android {
"""


def load_props() -> dict[str, str]:
    props: dict[str, str] = {}
    for line in KEYPROPS.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        props[k.strip()] = v.strip()
    return props


def patch(path: pathlib.Path, props: dict[str, str]) -> bool:
    is_kts = path.suffix == ".kts"
    src = path.read_text()
    original = src

    def value(key: str) -> str:
        return f'keyProperties["{key}"] as String' if is_kts else f'keyProperties["{key}"]'

    # 1) release buildType memakai signingConfig "release", bukan "debug"
    if is_kts:
        src, n_sig = re.subn(
            r"signingConfig\s*=\s*signingConfigs\.getByName\(\s*\"debug\"\s*\)",
            'signingConfig = signingConfigs.getByName("release")',
            src,
        )
        if n_sig == 0:
            src, n_sig = re.subn(
                r"signingConfig\s+[\"']debug[\"']",
                "signingConfig signingConfigs.release",
                src,
            )
    else:
        src, n_sig = re.subn(
            r"signingConfig\s+[\"']debug[\"']",
            "signingConfig signingConfigs.release",
            src,
        )

    # 2) nilai kredensial di dalam blok signing config release
    def sub_val(pattern: str, repl: str) -> None:
        nonlocal src
        src, _ = re.subn(pattern, repl, src, count=1, flags=re.MULTILINE)

    sub_val(
        r'storeFile\s*=\s*file\(\s*["\'][^"\']*["\']\s*\)',
        f'storeFile = file("{props["storeFile"]}")',
    )
    sub_val(r'storePassword\s*=\s*["\'][^"\']*["\']', f"storePassword = {value('storePassword')}")
    sub_val(r'keyPassword\s*=\s*["\'][^"\']*["\']', f"keyPassword = {value('keyPassword')}")
    sub_val(r'keyAlias\s*=\s*["\'][^"\']*["\']', f"keyAlias = {value('keyAlias')}")

    # Groovy: storePassword "android" / storePassword storePassword "android"
    # Bagian tengah (nama variabel Gradle) opsional.
    sub_val(
        r'storePassword\s+(?:[\w."\']+\s+)?["\'][^"\']*["\']',
        f"storePassword = {value('storePassword')}",
    )
    sub_val(
        r'keyPassword\s+(?:[\w."\']+\s+)?["\'][^"\']*["\']',
        f"keyPassword = {value('keyPassword')}",
    )
    sub_val(
        r'keyAlias\s+(?:[\w."\']+\s+)?["\'][^"\']*["\']',
        f"keyAlias = {value('keyAlias')}",
    )
    # Groovy: storeFile file("debug.keystore")
    sub_val(
        r'storeFile\s+file\(\s*["\'][^"\']*["\']\s*\)',
        f'storeFile = file("{props["storeFile"]}")',
    )

    # 3) pastikan loader key.properties ada (dibutuhkan keyProperties[...])
    if "keyProperties" not in original:
        loader = LOADER_KTS if is_kts else LOADER_GROOVY
        if "android {\n" in src:
            src = src.replace("android {\n", loader, 1)
        else:
            print(f"FAIL: blok android tidak ditemukan di {path}")
            return False

        # Kotlin DSL: `java` di-build.gradle.kts已经被 plugin Java shadowing,
        # jadi `java.util.Properties()` jadi "Unresolved reference 'util'".
        # Wajib pakai import + nama kelas langsung.
        if is_kts and "import java.util.Properties" not in src:
            src = IMPORTS_KTS + src

    if src == original:
        print(f"FAIL: {path} tidak berubah — pola Flutter berubah? periksa manual.")
        return False

    path.write_text(src)
    print(f"    + signing release: {path} (signingConfig hits={n_sig})")
    return True


def main() -> int:
    if not KEYPROPS.exists():
        print("==> patch_signing: key.properties tidak ada, dilewati")
        return 0

    props = load_props()
    missing = [k for k in ("storeFile", "storePassword", "keyPassword", "keyAlias") if k not in props]
    if missing:
        print(f"FAIL: key.properties kurang: {missing}")
        return 1

    for g in GRADLE_CANDIDATES:
        if not g.exists():
            continue
        return 0 if patch(g, props) else 1

    print("FAIL: android/app/build.gradle(.kts) tidak ditemukan")
    return 1


if __name__ == "__main__":
    sys.exit(main())