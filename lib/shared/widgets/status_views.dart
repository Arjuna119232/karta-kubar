import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import 'empty_state.dart';
import 'error_state.dart';
import 'shimmer_box.dart';

/// Skeleton shimmer. Nama lama dipertahankan supaya semua layar ikut
/// memakai efek shimmer tanpa perubahan kode.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    this.height = 16,
    this.width,
    this.radius = AppRadius.md,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) =>
      ShimmerBox(height: height, width: width, radius: radius);
}

/// Empty state terdesain (ilustrasi melayang + CTA).
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    this.art = 'empty_kegiatan',
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String art;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => EmptyState(
        art: art,
        title: title,
        subtitle: message,
        actionLabel: actionLabel,
        onAction: onAction,
      );
}

/// Error state ramah + tombol coba lagi.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    this.message = 'Terjadi kesalahan saat memuat data.',
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) =>
      ErrorState(message: message, onRetry: onRetry);
}
