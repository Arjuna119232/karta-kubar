import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/utils/haptics.dart';

/// Kartu dua sisi: ketuk untuk membalik (rotasi 3D di sumbu Y).
class FlipCard extends StatefulWidget {
  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.semanticLabel = 'Kartu, ketuk untuk membalik',
  });

  final Widget front;
  final Widget back;
  final String semanticLabel;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  bool _depan = true;

  void _balik() {
    if (_c.isAnimating) return;
    Haptics.light();
    if (_depan) {
      _c.forward();
    } else {
      _c.reverse();
    }
    _depan = !_depan;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTap: _balik,
        child: AnimatedBuilder(
          animation: _c,
          builder: (BuildContext context, _) {
            final double sudut = Curves.easeInOut.transform(_c.value) * math.pi;
            final bool belakang = sudut > math.pi / 2;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(sudut),
              child: belakang
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: widget.back,
                    )
                  : widget.front,
            );
          },
        ),
      ),
    );
  }
}
