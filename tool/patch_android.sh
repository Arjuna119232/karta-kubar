#!/usr/bin/env bash
# Idempotent Android patches applied right after `flutter create` generates
# android/. Keeps the generated folder in sync with KUNBAR Connect branding and
# the permissions each phase needs — WITHOUT committing the generated android/.
set -euo pipefail

MANIFEST="android/app/src/main/AndroidManifest.xml"
GRADLE="android/app/build.gradle.kts"
[ -f "$GRADLE" ] || GRADLE="android/app/build.gradle"

echo "==> patch_android: manifest=$MANIFEST gradle=$GRADLE"

# --- 1) Launcher label = real app name (never the package id) ---
sed -i 's/android:label="[^"]*"/android:label="KUNBAR Connect"/' "$MANIFEST"
grep -q 'android:label="KUNBAR Connect"' "$MANIFEST" || { echo "FAIL: label not set"; exit 1; }

# --- 2) applicationId + namespace = id.kubarkonek.app ---
sed -i 's/applicationId = "[^"]*"/applicationId = "id.kubarkonek.app"/' "$GRADLE" 2>/dev/null || true
sed -i 's/namespace = "[^"]*"/namespace = "id.kubarkonek.app"/' "$GRADLE" 2>/dev/null || true
# Groovy DSL fallback
sed -i 's/applicationId "[^"]*"/applicationId "id.kubarkonek.app"/' "$GRADLE" 2>/dev/null || true
sed -i 's/namespace "[^"]*"/namespace "id.kubarkonek.app"/' "$GRADLE" 2>/dev/null || true

# --- 3) Permissions (idempotent insert before <application) ---
add_permission() {
  local perm="$1"
  grep -q "android.permission.$perm" "$MANIFEST" && return 0
  sed -i "s#<application#<uses-permission android:name=\"android.permission.$perm\"/>\n    <application#" "$MANIFEST"
  echo "    + permission: $perm"
}
# Hanya izin yang BENAR-BENAR dipakai. Play Store menolak/mempersulit review
# kalau izin diminta tapi tidak dipakai, jadi setiap baris di sini harus punya
# fitur nyata yang membutuhkannya.
add_permission INTERNET
# Peta + lokasi: geolocator (posisi warga) dan MapLibre (titik lokasi sendiri
# di peta). Tanpa dua izin ini, peta hanya menampilkan tiles tanpa titik.
add_permission ACCESS_FINE_LOCATION
add_permission ACCESS_COARSE_LOCATION
# Kamera: pemindai QR absensi (mobile_scanner). Tanpa izin ini kamera tidak
# bisa dibuka dan absensi mati total di lapangan.
add_permission CAMERA

# --- 5) Verifikasi izin lokasi benar-benar ada ---
# Kehilangan satu baris di sini tidak selalu reddenya build: geolocator
# berhenti diam-diam (selalu "izin ditolak"), jadi manifest diperiksa ulang.
for p in ACCESS_FINE_LOCATION ACCESS_COARSE_LOCATION INTERNET CAMERA; do
  grep -q "android.permission.$p" "$MANIFEST" || {
    echo "FAIL: permission $p tidak ada di manifest"
    exit 1
  }
done
grep -q 'com.baseflow.geolocator.GeolocatorLocationService' \
  "$MANIFEST" || true

echo "==> patch_android: done"
