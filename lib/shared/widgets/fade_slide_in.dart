import 'package:flutter/material.dart';

/// Memunculkan [child] dengan fade + geser naik, berjenjang menurut [index].
/// Otomatis dilewati kalau pengguna mematikan animasi di pengaturan sistem.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  static const int _langkahMs = 70;
  static const int _dasarMs = 380;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    final int i = index.clamp(0, 8);
    final int total = _dasarMs + i * _langkahMs;
    final Curve kurva = Interval(
      (i * _langkahMs) / total,
      1.0,
      curve: Curves.easeOutCubic,
    );

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: kurva,
      child: child,
      builder: (BuildContext context, double v, Widget? c) {
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 18),
            child: c,
          ),
        );
      },
    );
  }
}
