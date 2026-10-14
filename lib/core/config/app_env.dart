import 'package:flutter/foundation.dart';

/// Konfigurasi backend hasil build.
///
/// TUJUAN: tidak ada satu pun URL atau API key yang ditulis langsung di file
/// Dart. Semuanya masuk lewat `--dart-define`, yang nilainya diambil CI dari
/// file `.env` di server (file itu tidak ikut git).
///
/// Cara pakai:
/// ```bash
/// cp .env.example .env        # isi nilainya
/// flutter run \
///   --dart-define=SUMBER_DATA=supabase \
///   --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJ...
/// ```
///
/// Kenapa `--dart-define` dan bukan membaca `.env` saat aplikasi jalan:
/// file `.env` harus ikut jadi aset kalau dibaca saat runtime, dan kalau
/// `.env` tidak ada (misal clone baru) pembacaan itu melempar error saat
/// aplikasi start. Dengan `--dart-define`, file yang tidak ada berarti
/// konfigurasi kosong -> aplikasi jatuh ke mode lokal, bukan crash.
///
/// Catatan keamanan: `SUPABASE_ANON_KEY` memang aman dipublikasikan --
/// kunci itu wajib ada di dalam aplikasi. Yang TIDAK BOLEH pernah masuk ke
/// `--dart-define` adalah `service_role` key: kalau bocor, siapa pun bisa
/// membaca/menulis seluruh database tanpa batas RLS.
@immutable
class AppEnv {
  const AppEnv({
    required this.sumberData,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.scheme,
    required this.bucketStorage,
  });

  /// Membaca konfigurasi yang di-inject saat build.
  factory AppEnv.fromBuild() => const AppEnv.fromDefine(
        sumberData: _vSumber,
        supabaseUrl: _vUrl,
        supabaseAnonKey: _vAnon,
        scheme: _vSkema.isEmpty ? 'public' : _vSkema,
        bucketStorage: _vBucket.isEmpty ? 'kunar-uploads' : _vBucket,
      );

  /// Konfigurasi dibaca dari `--dart-define`. Bentuknya const supaya bisa
  /// dipakai di `const` context; named constructor juga boleh const.
  const AppEnv.fromDefine({
    required this.sumberData,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.scheme,
    required this.bucketStorage,
  });

  /// Konfigurasi kosong untuk pratinjau/tes.
  static const AppEnv kosong = AppEnv(
    sumberData: 'lokal',
    supabaseUrl: '',
    supabaseAnonKey: '',
    scheme: 'public',
    bucketStorage: 'kunar-uploads',
  );

  static const String _vSumber = String.fromEnvironment('SUMBER_DATA');
  static const String _vUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _vAnon = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String _vSkema = String.fromEnvironment('SUPABASE_SCHEMA');
  static const String _vBucket =
      String.fromEnvironment('SUPABASE_STORAGE_BUCKET');

  /// `lokal` atau `supabase`.
  final String sumberData;

  /// https://xxxx.supabase.co
  final String supabaseUrl;

  /// Anon / publishable key (aman publik, dibatasi RLS).
  final String supabaseAnonKey;

  /// Skema Postgres, biasanya `public`.
  final String scheme;

  /// Bucket untuk foto absen dan galeri.
  final String bucketStorage;

  /// Konfigurasi sudah cukup untuk konek ke Supabase.
  bool get supabaseSiap =>
      supabaseUrl.startsWith('https://') && supabaseAnonKey.isNotEmpty;

  /// Ringkasan untuk layar "Pengaturan - Status backend". TIDAK pernah
  /// menampilkan kunci aslinya, hanya sepanjang 4 karakter terakhir supaya
  /// pengguna bisa cek key yang dipakai tanpa membocorkan.
  String get ringkasanAnonKey {
    if (supabaseAnonKey.isEmpty) return '(kosong)';
    if (supabaseAnonKey.length <= 4) return '****';
    return '...${supabaseAnonKey.substring(supabaseAnonKey.length - 4)}';
  }

  @override
  String toString() => 'AppEnv(sumber: $sumberData, siap: $supabaseSiap, '
      'anon: $ringkasanAnonKey)';
}