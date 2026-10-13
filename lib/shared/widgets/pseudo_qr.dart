import 'package:flutter/material.dart';

/// QR bergaya (deterministik dari seed) — placeholder sampai backend Supabase.
/// Bukan QR fungsional; murni visual untuk kartu anggota digital.
class PseudoQr extends StatelessWidget {
  const PseudoQr({
    super.key,
    required this.seed,
    this.size = 168,
    this.modules = 25,
    this.color,
  });

  final String seed;
  final double size;
  final int modules;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _QrPainter(
        seed: seed,
        modules: modules,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter({required this.seed, required this.modules, required this.color});

  final String seed;
  final int modules;
  final Color color;

  bool _bit(int x, int y) {
    int h = 2166136261;
    for (final int c in '$seed:$x:$y'.codeUnits) {
      h ^= c;
      h = (h * 16777619) & 0xFFFFFFFF;
    }
    return (h % 100) > 47;
  }

  bool _inFinder(int x, int y) {
    bool corner(int ox, int oy) =>
        x >= ox && x < ox + 7 && y >= oy && y < oy + 7;
    return corner(0, 0) || corner(modules - 7, 0) || corner(0, modules - 7);
  }

  bool _finderOn(int x, int y) {
    int ox = 0;
    int oy = 0;
    if (x >= modules - 7 && y < 7) {
      ox = modules - 7;
    } else if (x < 7 && y >= modules - 7) {
      oy = modules - 7;
    }
    final int lx = x - ox;
    final int ly = y - oy;
    final bool ring = lx == 0 || lx == 6 || ly == 0 || ly == 6;
    final bool center = lx >= 2 && lx <= 4 && ly >= 2 && ly <= 4;
    return ring || center;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.width / modules;
    final Paint paint = Paint()..color = color;
    for (int y = 0; y < modules; y++) {
      for (int x = 0; x < modules; x++) {
        final bool on = _inFinder(x, y) ? _finderOn(x, y) : _bit(x, y);
        if (on) {
          canvas.drawRect(
            Rect.fromLTWH(x * cell, y * cell, cell + 0.3, cell + 0.3),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.color != color;
}
