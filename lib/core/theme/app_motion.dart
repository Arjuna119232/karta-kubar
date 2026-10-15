import 'package:flutter/animation.dart';

/// Token gerak (motion) KUNBAR Connect.
///
/// Satu sumber kebenaran untuk durasi & kurva. Tujuannya dua:
/// 1. Semua layar bergerak dengan "rasa" yang sama (tidak ada satu halaman
///    yang lambat dan satu yang lompat).
/// 2. Kalau nanti Mode Lansia / "kurangi gerak" perlu memperlambat atau
///    mempercepat semuanya, cukup ubah di sini.
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
