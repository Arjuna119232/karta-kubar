import 'package:flutter/material.dart';

/// Token desain KUNBAR - SALINAN dari APK Warga (lib/core/theme/).
/// Sumber: repo `karta-kubar`, file app_colors.dart / app_spacing.dart /
/// app_shadows.dart / app_motion.dart. Satu bahasa visual untuk dua app.

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1B5E20); // Hijau Karang Taruna
  static const Color secondary = Color(0xFFFFC107); // Kuning energi muda
  static const Color accent = Color(0xFF0D47A1); // Biru kepercayaan

  // --- Warna teks di atas warna brand (kontras dihitung, bukan dikira) ---

  /// Teks di atas [primary]: putih = 7,9:1 (lolos WCAG AA & AAA).
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Teks di atas [secondary] (kuning): HITAM = 12,9:1.
  /// Putih di atas kuning cuma 1,6:1 — GAGAL total, jangan dipakai.
  static const Color onSecondary = Color(0xFF1A1A1A);

  /// Teks di atas [primaryOnDark] (hijau terang, tema gelap): 9,8:1.
  static const Color onPrimaryDark = Color(0xFF06210C);

  /// Hijau versi TERANG — untuk teks/ikon di atas latar GELAP.
  /// Kontras terhadap `bgDark` = 10,9:1, jadi tetap terbaca di HP murah.
  /// `primary` (#1B5E20) di atas latar gelap terlalu redup.
  static const Color primaryOnDark = Color(0xFF7BD88F);

  /// Hijau sangat muda untuk latar "soft" (chip terpilih, lencana) — terang.
  static const Color primarySoft = Color(0xFFE8F5E9);

  /// Hijau soft versi gelap — pasangan [primarySoft] saat tema gelap.
  static const Color primarySoftDark = Color(0xFF1E3323);
  // Accent pink untuk highlight kegiatan sosial (identitas KUNBAR Connect).
  static const Color social = Color(0xFFE91E63);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFB26A00);

  /// Abu netral untuk status yang tidak punya warna sendiri
  /// (ditolak / tamu / topik 'lain').
  static const Color muted = Color(0xFF6A6A72);

  /// Teks di atas permukaan [error] yang terisi penuh. Putih penuh terlalu
  /// silau untuk banner darurat sepanjang paragraf.
  static const Color onErrorSoft = Color(0xFFFFD9D9);

  /// Hijau paling gelap: ujung bawah gradasi hero di tema gelap.
  static const Color primaryDeep = Color(0xFF123815);

  static const Color bgLight = Color(0xFFF6F7F9);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF6A6A72);
  static const Color lineLight = Color(0xFFECECEF);

  static const Color bgDark = Color(0xFF121214);
  static const Color cardDark = Color(0xFF1E1E22);
  static const Color textPrimaryDark = Color(0xFFF2F2F4);
  static const Color textSecondaryDark = Color(0xFF9A9AA0);
  static const Color lineDark = Color(0xFF2A2A2E);
}

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

class AppShadows {
  AppShadows._();

  /// Warna dasar bayangan (netral, gelap kebiruan seperti Material 3).
  static const Color tinta = Color(0xFF101828);

  /// Alpha bayangan dalam heksa (dikomputerkan dari persen).
  static const int _a06 = 0x0F; // 6%
  static const int _a08 = 0x14; // 8%
  static const int _a04 = 0x0A; // 4%
  static const int _a14 = 0x24; // 14%
  static const int _a16 = 0x29; // 16%
  static const int _a18 = 0x2E; // 18%

  /// Tanpa bayangan — dipakai di tema gelap.
  static const List<BoxShadow> none = <BoxShadow>[];

  /// Kartu istirahat: sangat lembut, dipakai hampir di mana-mana.
  static const List<BoxShadow> card = <BoxShadow>[
    BoxShadow(color: Color(_a06 << 24 | 0x101828), blurRadius: 16, offset: Offset(0, 4)),
  ];

  /// Kartu terangkat (kartu hero, kartu yang bisa ditekan).
  static const List<BoxShadow> raised = <BoxShadow>[
    BoxShadow(color: Color(_a08 << 24 | 0x101828), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(_a04 << 24 | 0x101828), blurRadius: 6, offset: Offset(0, 2)),
  ];

  /// Bottom sheet / panel melayang dari bawah.
  static const List<BoxShadow> sheet = <BoxShadow>[
    BoxShadow(color: Color(_a14 << 24 | 0x101828), blurRadius: 32, offset: Offset(0, -8)),
  ];

  /// Dialog di tengah layar.
  static const List<BoxShadow> dialog = <BoxShadow>[
    BoxShadow(color: Color(_a16 << 24 | 0x101828), blurRadius: 40, offset: Offset(0, 12)),
  ];

  /// Tombol melayang (FAB).
  static const List<BoxShadow> fab = <BoxShadow>[
    BoxShadow(color: Color(_a18 << 24 | 0x101828), blurRadius: 20, offset: Offset(0, 8)),
  ];

  /// Bayangan berwarna untuk aksen (mis. tombol utama hijau).
  static List<BoxShadow> glow(Color warna, {double alpha = 0.28}) => <BoxShadow>[
        BoxShadow(
          color: warna.withValues(alpha: alpha),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}

class AppMotion {
  AppMotion._();

  /// 90 ms — umpan balik sentuhan (menyusut saat tombol ditekan).
  static const Duration tap = Duration(milliseconds: 90);

  /// 160 ms — buka/tutup cepat (tooltip, ganti ikon).
  static const Duration cepat = Duration(milliseconds: 160);

  /// 260 ms — transisi standar antar-state.
  static const Duration normal = Duration(milliseconds: 260);

  /// 360 ms — halaman masuk, kartu muncul berjenjang.
  static const Duration lambat = Duration(milliseconds: 360);

  /// 1100 ms — denyut skeleton / shimmer (satu putaran).
  static const Duration denyut = Duration(milliseconds: 1100);

  /// 70 ms — jarak antar item pada animasi berjenjang (stagger).
  static const Duration langkahJenjang = Duration(milliseconds: 70);

  /// Keluar halus — dipakai hampir semua animasi masuk.
  static const Curve keluar = Curves.easeOutCubic;

  /// Emphasized (Material 3 Expressive) — untuk yang ingin terasa "hidup".
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  /// Pegas ringan (easeOutBack) — untuk logo/tombol yang "memantul" halus.
  static const Curve pegas = Curves.easeOutBack;

  /// Standar Material untuk gerak yang harus terasa netral.
  static const Curve standar = Curves.easeInOut;
}
