import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Hujan confetti singkat (~1,6 dtk) untuk momen berhasil: absen, donasi.
/// Tanpa paket tambahan. Dilewati bila animasi dimatikan di sistem.
class Confetti {
  Confetti._();

  static void tembak(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return;
    final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: _Burst(onSelesai: () => entry.remove()),
      ),
    );
    overlay.insert(entry);
  }
}

class _Burst extends StatefulWidget {
  const _Burst({required this.onSelesai});

  final VoidCallback onSelesai;

  @override
  State<_Burst> createState() => _BurstState();
}

class _BurstState extends State<_Burst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )
    ..addStatusListener((AnimationStatus s) {
      if (s == AnimationStatus.completed) widget.onSelesai();
    })
    ..forward();

  static const List<Color> _warna = <Color>[
    AppColors.primary,
    AppColors.secondary,
    AppColors.accent,
    AppColors.social,
  ];

  late final List<_Keping> _keping = List<_Keping>.generate(48, (int i) {
    final math.Random r = math.Random(i * 7919);
    return _Keping(
      x: r.nextDouble(),
      kecepatan: 0.6 + r.nextDouble() * 0.7,
      goyang: r.nextDouble() * 2 * math.pi,
      putar: r.nextDouble() * 6,
      ukuran: 6 + r.nextDouble() * 6,
      warna: _warna[i % _warna.length],
    );
  });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, _) => CustomPaint(
        size: Size.infinite,
        painter: _Pelukis(_keping, _c.value),
      ),
    );
  }
}

class _Keping {
  const _Keping({
    required this.x,
    required this.kecepatan,
    required this.goyang,
    required this.putar,
    required this.ukuran,
    required this.warna,
  });

  final double x;
  final double kecepatan;
  final double goyang;
  final double putar;
  final double ukuran;
  final Color warna;
}

class _Pelukis extends CustomPainter {
  _Pelukis(this.keping, this.t);

  final List<_Keping> keping;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint();
    for (final _Keping k in keping) {
      final double y = -20 + (size.height + 40) * (t * k.kecepatan);
      final double x =
          size.width * k.x + math.sin(t * 6 + k.goyang) * 18;
      p.color = k.warna.withValues(alpha: (1 - t).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(k.putar + t * 8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: k.ukuran, height: k.ukuran * 0.5),
          const Radius.circular(2),
        ),
        p,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Pelukis old) => old.t != t;
}
