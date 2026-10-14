import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'app_card.dart';
import 'app_icon.dart';

/// Kartu statistik: ikon dalam lingkaran tint + nilai besar + label.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.tint,
  });

  final Ik icon;
  final String value;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: AppIcon(icon, color: tint, size: 22),
          ),
          const SizedBox(height: 14),
          Text(value, style: context.text.headlineSmall),
          const SizedBox(height: 2),
          Text(label, style: context.text.bodySmall?.copyWith(color: context.semantic.textSecondary)),
        ],
      ),
    );
  }
}
