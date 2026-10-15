import 'package:flutter/material.dart';

/// Item daftar yang muncul berjenjang: fade + geser. [index] menentukan jeda,
/// dibatasi supaya item jauh di bawah tidak menunggu lama.
class AnimatedListItem extends StatelessWidget {
  const AnimatedListItem({
    super.key,
    required this.child,
    this.index = 0,
    this.horizontal = false,
  });

  final Widget child;
  final int index;

  /// true = geser dari kanan, false = naik dari bawah.
  final bool horizontal;

  static const int _langkahMs = 60;
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
        final Offset geser = horizontal
            ? Offset((1 - v) * 24, 0)
            : Offset(0, (1 - v) * 18);
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: geser, child: c),
        );
      },
    );
  }
}
