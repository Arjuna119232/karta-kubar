#!/usr/bin/env bash
# Membuat folder android/ lalu menambah izin, nama app, desugaring, minSdk.
# Jalankan dari apps/mitra/ (butuh Flutter SDK). Aman diulang.
set -euo pipefail
if [ ! -d android ]; then
  # `flutter create` bisa menulis ulang berkas yang sudah ada. Simpan dulu,
  # lalu kembalikan apa adanya setelah android/ dibuat.
  BK="$(mktemp -d)"
  { [ -d lib ] && cp -r lib "$BK/lib"; } || true
  { [ -f pubspec.yaml ] && cp pubspec.yaml "$BK/pubspec.yaml"; } || true
  { [ -f analysis_options.yaml ] && cp analysis_options.yaml "$BK/analysis_options.yaml"; } || true
  flutter create --platforms=android --org id.kunbar --project-name kunbar_mitra .
  { [ -d "$BK/lib" ] && rm -rf lib && cp -r "$BK/lib" lib; } || true
  { [ -f "$BK/pubspec.yaml" ] && cp "$BK/pubspec.yaml" pubspec.yaml; } || true
  { [ -f "$BK/analysis_options.yaml" ] && cp "$BK/analysis_options.yaml" analysis_options.yaml; } || true
  rm -rf "$BK" test
fi

M=android/app/src/main/AndroidManifest.xml

# Semua izin aplikasi KUNBAR Mitra. Satu blok, idempotent (dilarang ada duplikat).
# Referensi: android/app/src/main/AndroidManifest.xml wajib memuat NAMA-NAMA ini,
# kalau tidak Android diam-diam menolak dialognya (symptom: izin tidak muncul).
if ! grep -q 'android.permission.CAMERA' "$M"; then
  perl -0pi -e 's#<application#<uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.CALL_PHONE"/>
    <uses-permission android:name="android.permission.READ_PHONE_STATE"/>
    <uses-permission android:name="android.permission.READ_CONTACTS"/>
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation"/>
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
    <uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES"/>
    <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28"/>
    <queries><intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent><intent><action android:name="android.intent.action.VIEW"/><data android:scheme="google.navigation"/></intent><intent><action android:name="android.intent.action.DIAL"/><data android:scheme="tel"/></intent></queries>
    <application#' "$M"
fi
sed -i 's/android:label="[^"]*"/android:label="KUNBAR Mitra"/' "$M"

# Layanan foreground untuk geolocator: inilah sumber notifikasi "Sedang ONLINE"
# yang tidak bisa di-swipe (setOngoing: true).
if ! grep -q 'GeolocatorLocationService' "$M"; then
  perl -0pi -e 's#</application>#    <service android:name="com.baseflow.geolocator.GeolocatorLocationService" android:foregroundServiceType="location" android:exported="false"/>
    </application>#' "$M"
fi

# permission_handler Android 13+ memakai READ_MEDIA_*; blok di atas sudah menutupnya.
G=android/app/build.gradle.kts
if [ -f "$G" ]; then
  grep -q isCoreLibraryDesugaringEnabled "$G" || {
    perl -0pi -e 's/(compileOptions\s*\{)/$1\n        isCoreLibraryDesugaringEnabled = true/' "$G"
    printf '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")\n}\n' >> "$G"
  }
  perl -pi -e 's/minSdk\s*=\s*flutter\.minSdkVersion/minSdk = 23/' "$G"
else
  G=android/app/build.gradle
  grep -q coreLibraryDesugaringEnabled "$G" || {
    perl -0pi -e 's/(compileOptions\s*\{)/$1\n        coreLibraryDesugaringEnabled true/' "$G"
    printf '\ndependencies {\n    coreLibraryDesugaring "com.android.tools:desugar_jdk_libs:2.0.4"\n}\n' >> "$G"
  }
  perl -pi -e 's/minSdkVersion\s+flutter\.minSdkVersion/minSdkVersion 23/' "$G"
fi

# Guard: izin yang dipakai kode WAJIB ada di manifest.
for izin in CAMERA RECORD_AUDIO ACCESS_FINE_LOCATION POST_NOTIFICATIONS \
            READ_CONTACTS CALL_PHONE READ_MEDIA_IMAGES READ_MEDIA_VIDEO \
            BLUETOOTH_SCAN USE_FULL_SCREEN_INTENT; do
  grep -q "android.permission.$izin" "$M" || { echo "GAGAL: izin $izin tidak ada di manifest"; exit 1; }
done
echo "Android siap."
