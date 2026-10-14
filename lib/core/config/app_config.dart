import 'package:flutter/foundation.dart';

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
}
