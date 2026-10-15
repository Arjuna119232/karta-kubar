import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'app_icon.dart';
import 'primary_button.dart';

/// Keadaan galat yang ramah: ilustrasi, kalimat singkat, tombol coba lagi.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.title = 'Waduh, gagal memuat',
    this.message = 'Terjadi kesalahan saat memuat data. Coba lagi ya.',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.92, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutBack,
          builder: (BuildContext context, double v, Widget? child) =>
              Transform.scale(scale: v, child: child),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const AppIllustration('error_offline', height: 170),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: context.text.titleMedium),
              const SizedBox(height: AppSpacing.xs + 2),
              Text(
                message,
                style: context.text.bodyMedium
                    ?.copyWith(color: context.semantic.textSecondary),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: 240,
                  child: PrimaryButton(
                    label: 'Coba lagi',
                    icon: Ik.refresh,
                    onPressed: onRetry,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
