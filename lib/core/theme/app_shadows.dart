import 'package:flutter/material.dart';

/// Bayangan berlapis: lembut, tidak kasar. Di tema gelap pakai [none]
/// karena bayangan hampir tak terlihat di latar gelap.
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> none = <BoxShadow>[];

  static const List<BoxShadow> soft = <BoxShadow>[
    BoxShadow(color: Color(0x0F101828), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> medium = <BoxShadow>[
    BoxShadow(color: Color(0x14101828), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0A101828), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> large = <BoxShadow>[
    BoxShadow(color: Color(0x1F101828), blurRadius: 40, offset: Offset(0, 16)),
    BoxShadow(color: Color(0x0F101828), blurRadius: 10, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> elevated = <BoxShadow>[
    BoxShadow(color: Color(0x26101828), blurRadius: 32, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x14101828), blurRadius: 8, offset: Offset(0, 3)),
  ];

  static const List<BoxShadow> glass = <BoxShadow>[
    BoxShadow(color: Color(0x1A000000), blurRadius: 30, offset: Offset(0, 10)),
  ];

  /// Bayangan berwarna (mis. tombol utama, ikon gradient).
  static List<BoxShadow> colored(Color c, {double alpha = 0.32}) =>
      <BoxShadow>[
        BoxShadow(
          color: c.withValues(alpha: alpha),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> adaptif(Brightness b, List<BoxShadow> terang) =>
      b == Brightness.dark ? none : terang;
}
