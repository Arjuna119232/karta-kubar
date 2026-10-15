import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'app_icon.dart';
import 'primary_button.dart';

/// Keadaan kosong: ilustrasi melayang pelan + judul + subjudul + CTA.
class EmptyState extends StatefulWidget {
  const EmptyState({
    super.key,
    this.art = 'empty_kegiatan',
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String art;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedBuilder(
              animation: _c,
              child: AppIllustration(widget.art, height: 170),
              builder: (BuildContext context, Widget? child) {
                final double t = Curves.easeInOut.transform(_c.value);
                return Transform.translate(
                  offset: Offset(0, -8 * t),
                  child: child,
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              widget.title,
              style: context.text.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            Text(
              widget.subtitle,
              style: context.text.bodyMedium
                  ?.copyWith(color: context.semantic.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (widget.actionLabel != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: 240,
                child: PrimaryButton(
                  label: widget.actionLabel!,
                  onPressed: widget.onAction,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
