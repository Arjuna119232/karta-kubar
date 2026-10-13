import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Kartu permukaan standar: radius 20, border 1px, rata (tanpa gradien).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.radius,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double? radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final double r = radius ?? AppRadius.card;
    final AppSemantic s = context.semantic;

    return Material(
      color: color ?? s.card,
      borderRadius: BorderRadius.circular(r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r),
        child: Container(
          padding: padding ?? const EdgeInsets.all(AppSpacing.screen),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r),
            border: Border.all(color: s.line),
          ),
          child: child,
        ),
      ),
    );
  }
}
