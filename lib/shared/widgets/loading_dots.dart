import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Pemuat tiga titik melompat (pengganti spinner polos).
class LoadingDots extends StatefulWidget {
  const LoadingDots({super.key, this.color, this.size = 10});

  final Color? color;
  final double size;

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color warna = widget.color ?? context.colors.primary;
    return Semantics(
      label: 'Memuat',
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < 3; i++)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: widget.size * 0.28),
                  child: _titik(warna, (_c.value - i * 0.16) % 1.0),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _titik(Color warna, double t) {
    // Lompat di paruh pertama siklus, diam di paruh kedua.
    final double lompat = t < 0.5 ? Curves.easeOut.transform(t * 2) : 0;
    final double naik = t < 0.5 ? (lompat < 0.5 ? lompat * 2 : (1 - lompat) * 2) : 0;
    return Transform.translate(
      offset: Offset(0, -widget.size * 0.9 * naik),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: warna.withValues(alpha: 0.5 + 0.5 * naik),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Pemuat satu layar penuh (dipakai saat menunggu sesi).
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: LoadingDots(size: 12)));
  }
}
