import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import 'app_icon.dart';

/// Tombol utama: pill full-width 56dp + haptic feedback.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.tone = PrimaryButtonTone.filled,
  });

  final String label;
  final VoidCallback? onPressed;
  final Ik? icon;
  final bool loading;
  final PrimaryButtonTone tone;

  @override
  Widget build(BuildContext context) {
    void handle() {
      HapticFeedback.lightImpact();
      onPressed?.call();
    }

    final Widget child = loading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                AppIcon(icon!, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    if (tone == PrimaryButtonTone.outlined) {
      return OutlinedButton(
        onPressed: loading ? null : handle,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        child: child,
      );
    }

    return FilledButton(
      onPressed: loading ? null : handle,
      child: child,
    );
  }
}

enum PrimaryButtonTone { filled, outlined }
