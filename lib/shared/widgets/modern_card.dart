import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import 'animated_button.dart';

/// Kartu modern: radius 20, bayangan halus, haptic + menyusut saat diketuk.
/// Boleh diberi [gradient] (mis. kartu hero).
class ModernCard extends StatelessWidget {
  const ModernCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadius.card,
    this.color,
    this.gradient,
    this.shadows,
    this.bordered = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Gradient? gradient;
  final List<BoxShadow>? shadows;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final Brightness b = Theme.of(context).brightness;
    final AppSemantic s = context.semantic;
    final BorderRadius br = BorderRadius.circular(radius);

    final Widget isi = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        color: gradient == null ? (color ?? s.card) : null,
        gradient: gradient,
        border: bordered && gradient == null ? Border.all(color: s.line) : null,
        boxShadow: shadows ?? AppShadows.adaptif(b, AppShadows.soft),
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return isi;
    return AnimatedButton(
      onTap: onTap,
      scale: 0.98,
      borderRadius: br,
      child: isi,
    );
  }
}
