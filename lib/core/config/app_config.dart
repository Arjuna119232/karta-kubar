import 'package:flutter/foundation.dart';

import 'app_env.dart';

/// Konfigurasi build, diatur lewat `--dart-define` saat `flutter build`.
class AppConfig {
  AppConfig._();

  /// Mode demo: kode OTP `123456` dan pengalih level akses aktif.
  ///
  /// - Mode debug (Run di Acode / `flutter run`): selalu aktif.
  /// - Build rilis: aktif hanya kalau dibuild dengan `--dart-define=KUNBAR_DEMO=true`
  ///   (CI mengisinya otomatis selama backend Supabase belum ada).
  /// - Setelah backend siap: build dengan `KUNBAR_DEMO=false`.
  static const bool demoMode =
      kDebugMode || bool.fromEnvironment('KUNBAR_DEMO', defaultValue: false);

  /// Pengalih level akses (developer tool).
  ///
  /// SENGAJA TIDAK ikut [demoMode]. Demo mode ikut nyala di APK rilis supaya
  /// kode OTP `123456` masih bisa dipakai warga, dan kalau pengalih role juga
  /// ikut nyala maka siapa pun bisa elevate dirinya jadi Admin lewat halaman
  /// Profil. Jadi dua hal ini dipisah: kode OTP demo boleh ikut di APK
  /// rilis, pengalih level akses tidak.
  ///
  /// Kalau perlu mengubah role saat menguji, jalankan dari debug/Acode
  /// (`kDebugMode` selalu true di sana), bukan dari APK rilis.
  static const bool roleSwitcher = kDebugMode;

  /// Bank data yang dipakai aplikasi.
  ///
  /// - `lokal`    : data di perangkat + seed demo. Tanpa internet, tanpa server.
  /// - `supabase` : data dari Supabase. Butuh [AppEnv] terisi lengkap.
  ///
  /// Nilai diambil dari `--dart-define` (lihat `.env.example`). Bawaan `lokal`
  /// supaya aplikasi yang belum punya konfigurasi backend tetap jalan utuh.
  static String get sumberData {
    const String v = String.fromEnvironment('SUMBER_DATA');
    return v.isEmpty ? 'lokal' : v;
  }

  /// True kalau aplikasi harus memakai sumber data Supabase.
  static bool get pakaiSupabase =>
      sumberData == 'supabase' && AppEnv.fromBuild().supabaseSiap;

  /// Konfigurasi backend hasil build.
  static AppEnv get env => AppEnv.fromBuild();
}