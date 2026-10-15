#!/usr/bin/env bash
# Membuat folder android/ lalu menambah izin, nama app, desugaring, minSdk.
# Jalankan dari apps/mitra/ (butuh Flutter SDK). Aman diulang.
set -euo pipefail
if [ ! -d android ]; then
  # `flutter create` bisa menulis ulang berkas yang sudah ada. Simpan dulu,
  # lalu kembalikan apa adanya setelah android/ dibuat.
  BK="$(mktemp -d)"
  [ -d lib ] && cp -r lib "$BK/lib"
  [ -f pubspec.yaml ] && cp pubspec.yaml "$BK/pubspec.yaml"
  [ -f analysis_options.yaml ] && cp analysis_options.yaml "$BK/analysis_options.yaml"
  flutter create --platforms=android --org id.kunbar --project-name kunbar_mitra .
  [ -d "$BK/lib" ] && rm -rf lib && cp -r "$BK/lib" lib
  [ -f "$BK/pubspec.yaml" ] && cp "$BK/pubspec.yaml" pubspec.yaml
  [ -f "$BK/analysis_options.yaml" ] && cp "$BK/analysis_options.yaml" analysis_options.yaml
  rm -rf "$BK" test
fi

M=android/app/src/main/AndroidManifest.xml
if ! grep -q ACCESS_FINE_LOCATION "$M"; then
  perl -0pi -e 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\n    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>\n    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>\n    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>\n    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>\n    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>\n    <uses-permission android:name="android.permission.VIBRATE"/>\n    <uses-permission android:name="android.permission.CALL_PHONE"/>\n    <queries><intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent><intent><action android:name="android.intent.action.VIEW"/><data android:scheme="google.navigation"/></intent><intent><action android:name="android.intent.action.DIAL"/><data android:scheme="tel"/></intent></queries>\n    <application#' "$M"
  sed -i 's/android:label="[^"]*"/android:label="KUNBAR Mitra"/' "$M"
  # layanan foreground untuk geolocator
  perl -0pi -e 's#</application>#    <service android:name="com.baseflow.geolocator.GeolocatorLocationService" android:foregroundServiceType="location" android:exported="false"/>\n    </application>#' "$M"
fi

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
echo "Android siap."
