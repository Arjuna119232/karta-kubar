import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Kartu permukaan standar: radius 20, border 1px, bayangan sangat lembut
/// (hanya tema terang) dan efek menyusut halus saat ditekan.
class AppCard extends StatefulWidget {
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
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _ditekan = false;

  @override
  Widget build(BuildContext context) {
    final double r = widget.radius ?? AppRadius.card;
    final AppSemantic s = context.semantic;
    final bool gelap = Theme.of(context).brightness == Brightness.dark;
    final bool bisaTap = widget.onTap != null;
    final bool kurangiGerak = MediaQuery.disableAnimationsOf(context);

    return AnimatedScale(
      scale: (_ditekan && bisaTap && !kurangiGerak) ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r),
          boxShadow: gelap
              ? null
              : const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x0F101828),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: widget.color ?? s.card,
          borderRadius: BorderRadius.circular(r),
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: bisaTap
                ? (bool v) => setState(() => _ditekan = v)
                : null,
            borderRadius: BorderRadius.circular(r),
            child: Container(
              padding: widget.padding ?? const EdgeInsets.all(AppSpacing.screen),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(r),
                border: Border.all(color: s.line),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
