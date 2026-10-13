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

# --- 3) Permissions needed by later phases (idempotent insert before <application) ---
add_permission() {
  local perm="$1"
  grep -q "android.permission.$perm" "$MANIFEST" && return 0
  sed -i "s#<application#<uses-permission android:name=\"android.permission.$perm\"/>\n    <application#" "$MANIFEST"
  echo "    + permission: $perm"
}
add_permission INTERNET
add_permission CAMERA
add_permission ACCESS_FINE_LOCATION
add_permission ACCESS_COARSE_LOCATION

echo "==> patch_android: done"
