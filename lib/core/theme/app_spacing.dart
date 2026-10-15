/// Token jarak (spacing) & radius KUNBAR Connect.
///
/// Berkas ini SENGAJA terpisah dari `app_theme.dart` supaya mudah
/// dipindahkan ke `packages/shared/` kalau APK Mitra dibangun nanti.
/// `app_theme.dart` meng-`export` berkas ini, jadi kode lama yang
/// meng-import `app_theme.dart` tetap mendapat [AppSpacing] & [AppRadius]
/// tanpa perubahan apa pun.
library;

/// Skala jarak 8-pt dengan nama pendek. Nilai lama ([screen], [gap],
/// [section]) dipertahankan supaya tidak ada satu pun pemanggil yang rusak.
class AppSpacing {
  AppSpacing._();

  /// 4 dp — jarak antar ikon dan labelnya.
  static const double xxs = 4;

  /// 8 dp — jarak rapat antar elemen sejenis.
  static const double xs = 8;

  /// 12 dp — jarak antar kartu kecil.
  static const double sm = 12;

  /// 16 dp — padding sisi layar (nama lama: [screen]).
  static const double md = 16;

  /// 24 dp — jarak antar bagian (nama lama: [section]).
  static const double lg = 24;

  /// 32 dp — jeda blok besar.
  static const double xl = 32;

  /// 48 dp — jeda hero / pembuka halaman.
  static const double xxl = 48;

  // --- Nama lama, dipakai di banyak layar. ---

  /// Padding kiri-kanan layar.
  static const double screen = md;

  /// Jarak standar antar elemen dalam satu kolom.
  static const double gap = sm;

  /// Jarak antar bagian (section) dalam satu halaman.
  static const double section = lg;
}

/// Radius sudut standar.
class AppRadius {
  AppRadius._();

  /// 12 dp — chip kecil, tag, lencana.
  static const double sm = 12;

  /// 16 dp — kolom isian (field).
  static const double field = 16;

  /// 20 dp — kartu & dialog.
  static const double card = 20;

  /// 24 dp — panel besar.
  static const double lg = 24;

  /// 28 dp — tombol utama.
  static const double button = 28;

  /// 32 dp — bottom sheet.
  static const double sheet = 32;

  /// Sepenuhnya bulat (pill).
  static const double chip = 999;
}
