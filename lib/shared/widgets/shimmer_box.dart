import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Efek kilau yang menyapu anak-anaknya. Satu controller untuk satu kelompok
/// skeleton, jadi hemat dibanding satu animasi per kotak.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color dasar = context.semantic.line;
    final Color kilau = Color.lerp(dasar, AppColors.white, 0.55)!;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (Rect rect) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: <Color>[dasar, kilau, dasar],
              stops: const <double>[0.3, 0.5, 0.7],
              transform: _GeserGradient(-1.0 + 2.0 * _c.value),
            ).createShader(rect);
          },
          child: child,
        );
      },
    );
  }
}

class _GeserGradient extends GradientTransform {
  const _GeserGradient(this.persen);

  final double persen;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * persen, 0, 0);
}

/// Kotak tulang (tanpa animasi sendiri). Taruh di dalam [Shimmer].
class ShimmerBone extends StatelessWidget {
  const ShimmerBone({
    super.key,
    this.height = 16,
    this.width,
    this.radius = AppRadius.md,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: context.semantic.line,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Satu kotak shimmer mandiri.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.height = 16,
    this.width,
    this.radius = AppRadius.md,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ShimmerBone(height: height, width: width, radius: radius),
    );
  }
}

/// Skeleton daftar kartu (gambar kecil + dua baris teks).
class ShimmerListSkeleton extends StatelessWidget {
  const ShimmerListSkeleton({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 88,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final Color kartu = context.semantic.card;
    return Semantics(
      label: 'Memuat data',
      child: Shimmer(
        child: ListView.separated(
          padding: padding,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: itemCount,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (BuildContext context, int i) {
            return Container(
              height: itemHeight,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: kartu,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Row(
                children: <Widget>[
                  ShimmerBone(
                    height: itemHeight - AppSpacing.xxl,
                    width: itemHeight - AppSpacing.xxl,
                    radius: AppRadius.lg,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ShimmerBone(height: 14),
                        SizedBox(height: AppSpacing.sm),
                        ShimmerBone(height: 12, width: 140),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
