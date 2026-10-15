import 'package:flutter/material.dart';

import 'app_surface.dart';

/// Kartu permukaan standar.
///
/// Ini hanya nama pendek untuk `AppSurface` dengan setelan bawaan
/// (radius [AppRadius.card], border 1px, bayangan lembut, efek tekan).
/// Dipakai di ~33 tempat supaya kode layar tetap ringkas dan enak dibaca:
/// "kartu biasa" jelas maksudnya, sementara kasus khusus (permukaan hijau,
/// gradasi hero, tembus pandang) memakai [AppSurface] langsung.
///
/// Seluruh warna & bayangan berasal dari token tema — tidak ada warna keras
/// di sini, jadi tema terang/gelap dan Mode Lansia otomatis ikut.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.onLongPress,
    this.radius,
    this.color,
    this.tone = AppSurfaceTone.plain,
    this.elevation = AppElevation.kartu,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? radius;

  /// Warna isian khusus (mis. kartu darurat). Perhatikan kontras teksnya.
  final Color? color;

  final AppSurfaceTone tone;
  final AppElevation elevation;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      tone: tone,
      elevation: elevation,
      padding: padding,
      margin: margin,
      radius: radius,
      onTap: onTap,
      onLongPress: onLongPress,
      warna: color,
      child: child,
    );
  }
}
