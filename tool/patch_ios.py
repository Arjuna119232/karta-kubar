#!/usr/bin/env python3
"""Idempotent iOS patches applied right after `flutter create` generates ios/.

Runs on the GitHub macOS runner (see .github/workflows/build-ios.yml). Same
pattern as tool/patch_android.sh so the generated ios/ folder never has to be
committed and never drifts from the Flutter template.

WHAT THIS DOES — and deliberately nothing else:
  * bundle id  -> id.kubarkonek.app  (already produced by --org/--project-name,
                 verified here so a Flutter template change can never pass silently)
  * name shown under the icon -> "KUBAR Connect"
  * usage descriptions for the 2 capabilities the app actually asks for on
    Android (CAMERA + fine/coarse location) — iOS menolak jalan / memblokir app kalau string ini kosong
    without a NSCameraUsageDescription / NSLocationWhenInUseUsageDescription
  * URL scheme so the karta-kubar://absen/... QR payload round-trips in go_router
  * minimum deployment target 13.0 (Flutter's floor since 3.22)

NOT touched: signing, capabilities, push notifications, App Store metadata.
Those need a real Apple Developer account and are handled manually once.

Usage: python3 tool/patch_ios.py
"""

import plistlib
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
IOS = ROOT / "ios"
INFO = IOS / "Runner" / "Info.plist"
PODFILE = IOS / "Podfile"
PBXPROJ = IOS / "Runner.xcodeproj" / "project.pbxproj"

BUNDLE_ID = "id.kubarkonek.app"
APP_NAME = "KUBAR Connect"
DEPLOYMENT_TARGET = "13.0"
URL_SCHEMES = ["kubar", "karta-kubar"]

failures = []


def fail(msg):
    failures.append(msg)
    print(f"FAIL: {msg}")


def ok(msg):
    print(f"    ok: {msg}")


# --------------------------------------------------------------------------
# preflight
# --------------------------------------------------------------------------
if not INFO.is_file():
    sys.exit(f"FAIL: {INFO} tidak ada — flutter create belum menghasilkan ios/")
if not PBXPROJ.is_file():
    sys.exit(f"FAIL: {PBXPROJ} tidak ada — ios/ tidak lengkap")

# --------------------------------------------------------------------------
# 1) Info.plist
# --------------------------------------------------------------------------
with INFO.open("rb") as fh:
    plist = plistlib.load(fh)

# 1a) bundle id — flutter create derives it from --org/--project-name, so this
#     is a VERIFICATION, not a rewrite. If a Flutter release ever changes the
#     derivation we want a loud failure here, not a wrongly-signed IPA later.
actual_id = plist.get("CFBundleIdentifier", "")
if actual_id != BUNDLE_ID:
    fail(
        f"CFBundleIdentifier = {actual_id!r}, harusnya {BUNDLE_ID!r}. "
        "Perbaiki --org/--project-name di workflow build-ios.yml."
    )
else:
    ok(f"CFBundleIdentifier = {BUNDLE_ID}")

# 1b) nama di bawah ikon
changed = False
if plist.get("CFBundleDisplayName") != APP_NAME:
    plist["CFBundleDisplayName"] = APP_NAME
    changed = True
    ok(f"CFBundleDisplayName -> {APP_NAME}")
# CFBundleName dibatasi 15 karakter oleh iOS saat submit; pakai bentuk pendek.
short_name = "KUBAR Connect"
if plist.get("CFBundleName") != short_name:
    plist["CFBundleName"] = short_name
    changed = True
    ok(f"CFBundleName -> {short_name}")

# 1c) permission strings — wajib, kalau kosong iOS langsung crash / tolak
usage = {
    "NSCameraUsageDescription":
        "Kamera dipakai untuk memindai QR absen kegiatan.",
    "NSLocationWhenInUseUsageDescription":
        "Lokasi dipakai untuk absen dan memantau kegiatan di sekitar Anda.",
    "NSPhotoLibraryUsageDescription":
        "Galeri dipakai untuk choosing foto kegiatan.",
}
for key, value in usage.items():
    if plist.get(key) != value:
        plist[key] = value
        changed = True
        ok(f"{key} diisi")

# 1d) URL scheme untuk deep link go_router (payload QR absen)
url_types = plist.get("CFBundleURLTypes") or []
types_by_name = {t.get("CFBundleURLName"): t for t in url_types}
for scheme in URL_SCHEMES:
    name = f"kubar.{scheme}"
    entry = types_by_name.get(name)
    if entry is None:
        entry = {"CFBundleURLName": name, "CFBundleURLSchemes": [scheme]}
        url_types.append(entry)
        types_by_name[name] = entry
        changed = True
        ok(f"CFBundleURLTypes += {name}")
    elif scheme not in entry.get("CFBundleURLSchemes", []):
        entry.setdefault("CFBundleURLSchemes", []).append(scheme)
        changed = True
        ok(f"CFBundleURLTypes[{name}] += {scheme}")
plist["CFBundleURLTypes"] = url_types

# 1e) iPad support — warga banyak pakai tablet; default Flutter cuma iPhone
if not plist.get("UISupportedInterfaceOrientations~ipad"):
    plist["UISupportedInterfaceOrientations~ipad"] = [
        "UIInterfaceOrientationPortrait",
        "UIInterfaceOrientationPortraitUpsideDown",
        "UIInterfaceOrientationLandscapeLeft",
        "UIInterfaceOrientationLandscapeRight",
    ]
    changed = True
    ok("orientasi iPad ditambahkan")

if changed:
    with INFO.open("wb") as fh:
        plistlib.dump(plist, fh)
    print(f"    -> {INFO.relative_to(ROOT)} ditulis ulang")

# --------------------------------------------------------------------------
# 2) Podfile — deployment target
# --------------------------------------------------------------------------
pod = PODFILE.read_text()
before = pod
pod = re.sub(
    r"^#\s*platform :ios, '[^']+'",
    f"platform :ios, '{DEPLOYMENT_TARGET}'",
    pod,
    flags=re.MULTILINE,
)
pod = re.sub(
    r"^platform :ios, '[^']+'",
    f"platform :ios, '{DEPLOYMENT_TARGET}'",
    pod,
    flags=re.MULTILINE,
)
if pod == before and f"platform :ios, '{DEPLOYMENT_TARGET}'" not in pod:
    fail("Podfile: baris platform :ios tidak ditemukan")
elif pod != before:
    PODFILE.write_text(pod)
    ok(f"Podfile platform :ios -> {DEPLOYMENT_TARGET}")

# --------------------------------------------------------------------------
# 3) project.pbxproj — deployment target + marker supaya jelas ini di-patch
# --------------------------------------------------------------------------
proj = PBXPROJ.read_text()
if "IPHONEOS_DEPLOYMENT_TARGET" in proj:
    new_proj = re.sub(
        r"IPHONEOS_DEPLOYMENT_TARGET = [\d.]+;",
        f"IPHONEOS_DEPLOYMENT_TARGET = {DEPLOYMENT_TARGET};",
        proj,
    )
    if new_proj != proj:
        PBXPROJ.write_text(new_proj)
        ok(f"IPHONEOS_DEPLOYMENT_TARGET -> {DEPLOYMENT_TARGET}")

# 3b) pastikan DEVELOPMENT_TEAM sengaja TIDAK di-hardcode di sini.
#     Signing butuh Apple Developer account dan selalu diisi manual/session env,
#     bukan commit ke repo publik.
for line in PBXPROJ.read_text().splitlines():
    if "DEVELOPMENT_TEAM" in line and line.strip().startswith("DEVELOPMENT_TEAM"):
        val = line.split("=", 1)[1].strip().rstrip(";").strip()
        if val and val != '""':
            print(f"WARN: DEVELOPMENT_TEAM terisi {val!r} di repo publik — kosongkan secara sadar, jangan di-commit")

print()
if failures:
    sys.exit("patch_ios GAGAL:\n  - " + "\n  - ".join(failures))
print("==> patch_ios: done (Info.plist + Podfile + pbxproj)")