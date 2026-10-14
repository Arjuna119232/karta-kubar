import 'package:shared_preferences/shared_preferences.dart';

import 'auth/session.dart';

/// Kunci prefs "sudah lewat onboarding".
///
/// Dipublikasikan supaya OnboardingScreen dan [tentukanLokasiAwal] menulis dan
/// membaca string yang PERSIS sama. Kalau hanya salah satu yang berubah,
/// pengguna terjebak balik ke onboarding setiap app dibuka.
const String kPrefsOnboardingSeen = 'onboarding_seen';

/// Halaman pertama aplikasi, ditentukan sebelum Flutter menggambar apa pun.
///
/// Kenapa harus diketahui SEBELUM `runApp`: splash native Android (dan iOS)
/// hanya menutupi proses sampai frame pertama Flutter digambar. Kalau
/// tujuannya baru diputuskan setelah frame pertama, aplikasi sempat
/// menggambar satu halaman kosong lebih dulu - dan itulah yang kelihatan
/// seperti "kedip putih".
enum LokasiAwal {
  /// Pengguna baru, belum pernah melewati onboarding.
  onboarding,

  /// Sudah masuk dan sesinya masih tersimpan.
  beranda,

  /// Sudah lewat onboarding tapi belum masuk.
  auth,
}

/// Rute yang dipakai untuk tiap [LokasiAwal].
String pathUntuk(LokasiAwal lokasi) => switch (lokasi) {
      LokasiAwal.onboarding => '/onboarding',
      LokasiAwal.beranda => '/home',
      LokasiAwal.auth => '/auth',
    };

/// Baca tujuan pertama dari penyimpanan perangkat.
///
/// Sengaja dipanggil SEBELUM `runApp` (lihat main.dart). Reading prefs hanya
/// perlu SharedPreferences sudah ter-cache, jadi wajar antara 20-200 ms -
/// seluruh waktu itu masih tertutup splash native.
Future<LokasiAwal> tentukanLokasiAwal() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool seen = prefs.getBool(kPrefsOnboardingSeen) ?? false;
  // Kunci prefs di sini harus sama persis dengan yang ditulis SessionNotifier.
  final bool sudahMasuk =
      prefs.getString(SessionKeys.user)?.isNotEmpty ?? false;

  if (!seen) return LokasiAwal.onboarding;
  if (sudahMasuk) return LokasiAwal.beranda;
  return LokasiAwal.auth;
}
