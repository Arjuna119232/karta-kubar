import 'package:flutter/material.dart';

import '../../core/utils/haptics.dart';
import 'app_icon.dart';

/// FAB extended: muncul dengan skala halus, bisa mengecil jadi ikon saja
/// (mis. saat daftar digulir) lewat [extended].
class AnimatedFab extends StatelessWidget {
  const AnimatedFab({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.extended = true,
    this.heroTag,
  });

  final Ik icon;
  final String label;
  final VoidCallback onPressed;
  final bool extended;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (BuildContext context, double v, Widget? child) =>
          Transform.scale(scale: v, child: child),
      child: FloatingActionButton.extended(
        heroTag: heroTag,
        isExtended: extended,
        tooltip: label,
        onPressed: () {
          Haptics.medium();
          onPressed();
        },
        icon: AppIcon(icon, size: 22),
        label: Text(label),
      ),
    );
  }
}
