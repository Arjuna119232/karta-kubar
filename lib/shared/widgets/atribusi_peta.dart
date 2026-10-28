import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Atribusi ubin peta — WAJIB ditampilkan oleh aturan pemakaian
/// OpenStreetMap, bukan hiasan. Ditaruh kecil di pojok supaya tidak
/// mengganggu tombol peta.
class AtribusiPeta extends StatelessWidget {
  const AtribusiPeta({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: context.colors.surface.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '© OpenStreetMap',
          style: context.text.labelSmall?.copyWith(
            fontSize: 10,
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
