/// Konstanta path aset KUNBAR Connect.
///
/// Kenapa dipisah: menulis `'assets/icons/home.svg'` langsung di layar
/// membuat salah tulis sulit ditemukan (aset yang salah nama **diam-diam
/// tidak tampil**, tanpa error). Lewat konstanta, salah nama jadi error
/// kompilasi.
class AppAssets {
  AppAssets._();

  static const String _icons = 'assets/icons';
  static const String _ilustrasi = 'assets/ilustrasi';
  static const String _brand = 'assets/brand';
  static const String _data = 'assets/data';

  /// Ikon SVG (dicari dari nama enum `Ik`, lihat `app_icon.dart`).
  static String ikon(String nama) => '$_icons/$nama.svg';

  /// Ilustrasi SVG untuk empty state & sampul onboarding.
  static String ilustrasi(String nama) => '$_ilustrasi/$nama.svg';

  /// Emblem aplikasi (PNG).
  static const String emblem = '$_brand/emblem-512.png';

  /// Berkas data bawaan (dipakai repository lokal).
  static String data(String nama) => '$_data/$nama';

  /// Daftar folder yang WAJIB ada di `pubspec.yaml`.
  static const List<String> folder = <String>[_icons, _ilustrasi, _brand, _data];
}
