import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/kegiatan/domain/kegiatan.dart';
import 'app_dialogs.dart';
import 'app_icon.dart';
import 'cover_pilih.dart';

/// Detail berita dalam bottom sheet. Dipakai Beranda dan Galeri.
Future<void> bukaBerita(BuildContext context, Berita item) {
  return AppSheet.show<void>(
    context,
    builder: (BuildContext ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppCover(coverBerita(item.tag), height: 160, radius: AppRadius.xl),
        const SizedBox(height: AppSpacing.lg),
        if (item.tag.isNotEmpty)
          Text(item.tag.toUpperCase(),
              style: ctx.text.labelSmall?.copyWith(color: ctx.colors.primary)),
        const SizedBox(height: AppSpacing.xs),
        Text(item.judul, style: ctx.text.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${item.sumber}${item.waktu.isEmpty ? '' : ' - ${item.waktu}'}',
          style: ctx.text.bodySmall
              ?.copyWith(color: ctx.semantic.textSecondary),
        ),
      ],
    ),
  );
}
