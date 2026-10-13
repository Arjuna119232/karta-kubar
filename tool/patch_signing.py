#!/usr/bin/env python3
"""Pasang signing release Flutter memakai keystore asli (bukan debug key).

KENAPA DIPERLUKAN
-----------------
Template resmi Flutter (`android-kotlin.tmpl/app/build.gradle.kts.tmpl`)
TIDAK punya blok `signingConfigs` sama sekali — di buildTypes release hanya
`signingConfig = signingConfigs.getByName("debug")`. Karena `android/` di-generate
ulang tiap CI run, tanpa patch ini APK release tertandatangani `CN=Android Debug`.

STRATEGI (idempoten lewat marker)
---------------------------------
android/ selalu di-generate ulang, jadi kondisi awal file selalu template
bersih. Script menyuntikkan satu blok bertanda; kalau marker sudah ada, blok
tidak disuntik lagi (mencegah file korup saat dijalankan berulang).

CATATAN TEKNIS
--------------
- `java` di build.gradle.kts sudah di-shadow plugin Gradle Java, jadi
  `java.util.Properties()` -> "Unresolved reference 'util'".
  Wajib `import java.util.Properties` + `Properties()`.
- Kredensial WAJIB `keyProperties["..."] as String`, BUKAN
  `project.findProperty("...")` (tidak membaca key.properties, hasilnya null).
- `storeFile` relatif terhadap `android/app/` (tempat build.gradle.kts).
"""
from __future__ import annotations

import pathlib
import sys

GRADLE_CANDIDATES = [
    pathlib.Path("android/app/build.gradle.kts"),
    pathlib.Path("android/app/build.gradle"),
]
KEYPROPS = pathlib.Path("android/key.properties")
MARKER = "// KARTA-KUBAR-SIGNING"

IMPORTS_KTS = "import java.util.Properties\nimport java.io.FileInputStream\n\n"

LOADER_KTS = """// --- KARTA KUBAR: kredensial signing ---
val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
"""

LOADER_GROOVY = """// --- KARTA KUBAR: kredensial signing ---
def keyProperties = new Properties()
def keyPropertiesFile = rootProject.file('key.properties')
if (keyPropertiesFile.exists()) {
    keyProperties.load(new FileInputStream(keyPropertiesFile))
}

android {
"""

SIGNING_BLOCK_KTS = f"""    signingConfigs {{
        // {MARKER}
        create("release") {{
            keyAlias = keyProperties["keyAlias"] as String
            keyPassword = keyProperties["keyPassword"] as String
            storeFile = file(keyProperties["storeFile"] as String)
            storePassword = keyProperties["storePassword"] as String
        }}
    }}
"""

SIGNING_BLOCK_GROOVY = f"""    signingConfigs {{
        // {MARKER}
        release {{
            keyAlias keyProperties["keyAlias"]
            keyPassword keyProperties["keyPassword"]
            storeFile file(keyProperties["storeFile"])
            storePassword keyProperties["storePassword"]
        }}
    }}
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


def patch(path: pathlib.Path) -> bool:
    is_kts = path.suffix == ".kts"
    src = path.read_text()
    notes: list[str] = []

    if "android {\n" not in src:
        print(f"FAIL: blok 'android {{' tidak ditemukan di {path}")
        return False

    # 1) release buildType memakai signingConfig "release", bukan "debug"
    needle = 'signingConfig = signingConfigs.getByName("release")' if is_kts \
        else "signingConfig signingConfigs.release"
    if needle not in src:
        if is_kts:
            src = src.replace(
                'signingConfig = signingConfigs.getByName("debug")', needle
            ).replace('signingConfig "debug"', "signingConfig signingConfigs.release")
        else:
            src = src.replace('signingConfig "debug"', needle)
        notes.append("signingConfig->release")
    else:
        notes.append("signingConfig->release (sudah)")

    # 2) suntik blok signingConfigs + loader hanya sekali (pakai marker)
    if MARKER in src:
        notes.append("blok signingConfigs (sudah ada)")
    else:
        src = src.replace(
            "android {\n",
            "android {\n" + (SIGNING_BLOCK_KTS if is_kts else SIGNING_BLOCK_GROOVY),
            1,
        )
        src = src.replace(
            "android {\n",
            (LOADER_KTS if is_kts else LOADER_GROOVY),
            1,
        )
        if is_kts and "import java.util.Properties" not in src:
            src = IMPORTS_KTS + src
        notes.append("blok signingConfigs + loader: disuntik")

    path.write_text(src)
    print(f"    + {path}: " + ", ".join(notes))
    return True


def verify(path: pathlib.Path) -> bool:
    out = path.read_text()
    is_kts = path.suffix == ".kts"
    problems = []
    if MARKER not in out:
        problems.append("marker blok signing tidak ada")
    if "keyProperties[" not in out:
        problems.append("kredensial tidak membaca keyProperties")
    expected = 'getByName("release")' if is_kts else "signingConfigs.release"
    if expected not in out:
        problems.append(f"buildTypes masih bukan {expected}")
    if 'getByName("debug")' in out or 'signingConfig "debug"' in out:
        problems.append("masih ada signingConfig debug")
    if is_kts and "import java.util.Properties" not in out:
        problems.append("import Properties hilang")
    if out.count("signingConfigs {") != 1:
        problems.append(f"signingConfigs块 jumlah = {out.count('signingConfigs {')}")
    for p in problems:
        print(f"FAIL: {p}")
    return not problems


def main() -> int:
    if not KEYPROPS.exists():
        print("==> patch_signing: key.properties tidak ada, dilewati")
        return 0

    props = load_props()
    missing = [
        k for k in ("storeFile", "storePassword", "keyPassword", "keyAlias")
        if k not in props
    ]
    if missing:
        print(f"FAIL: key.properties kurang: {missing}")
        return 1

    for g in GRADLE_CANDIDATES:
        if not g.exists():
            continue
        if not patch(g):
            return 1
        if not verify(g):
            return 1
        print("==> patch_signing: OK")
        return 0

    print("FAIL: android/app/build.gradle(.kts) tidak ditemukan")
    return 1


if __name__ == "__main__":
    sys.exit(main())