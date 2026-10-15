import 'package:flutter/material.dart';

/// Preset bayangan (elevation) KUNBAR Connect.
///
/// Semua bayangan memakai satu warna dasar netral (`#101828`) dengan alpha
/// rendah — bukan hitam pekat — supaya terasa lembut, bukan "kotor" di atas
/// latar terang. Di tema gelap bayangan tidak terbaca mata (latar sudah
/// gelap), jadi pakai [none] dan biarkan border 1px yang memisahkan
/// permukaan.
///
/// Semua nilai memakai `Color(0xAARRGGBB)` heksadesimal supaya pasti
/// const (tidak bergantung pada `Color.fromRGBO`).
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
