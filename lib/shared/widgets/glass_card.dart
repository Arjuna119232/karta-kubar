import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';

/// Kartu kaca buram (glassmorphism). Tema gelap: kaca gelap berbingkai tipis,
/// supaya teks tetap terbaca.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadius.xl,
    this.blur = 18,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;

  /// Warna dasar kaca. Default: putih (terang) / hitam (gelap), semi-transparan.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final bool gelap = Theme.of(context).brightness == Brightness.dark;
    final Color dasar = tint ??
        (gelap
            ? AppColors.white.withValues(alpha: 0.08)
            : AppColors.white.withValues(alpha: 0.62));
    final Color tepi = AppColors.white.withValues(alpha: gelap ? 0.14 : 0.7);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: gelap ? AppShadows.none : AppShadows.glass,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: dasar,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: tepi),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
