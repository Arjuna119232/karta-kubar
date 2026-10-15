import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'app_icon.dart';
import 'primary_button.dart';

/// Geser gradasi shimmer dari kiri ke kanan.
class _GeserGradasi extends GradientTransform {
  const _GeserGradasi(this.geser);

  /// 0..1 — posisi satu putaran.
  final double geser;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (geser * 2.6 - 1.3), 0, 0);
  }
}

/// Satu controller bersama untuk sekelompok skeleton.
///
/// Kenapa perlu: dulu tiap [AppSkeleton] membuat `AnimationController`
/// sendiri. Sepuluh kartu skeleton = 10 controller berjalan bersamaan, dan
/// masing-masing berdenyut pada fase berbeda sehingga daftar terlihat
/// "berisik". Dengan satu controller, seluruh daftar berkilau seirama dan
/// biaya animasi turun.
///
/// Kalau ditulis tanpa [AppShimmer], [AppSkeleton] tetap jalan (membuat
/// controller sendiri) — jadi pemakaian lama tidak perlu diubah.
class AppShimmer extends StatefulWidget {
  const AppShimmer({super.key, required this.child});

  final Widget child;

  static Animation<double>? nilai(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_LingkupShimmer>()
        ?.animasi;
  }

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.denyut,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _LingkupShimmer(animasi: _c, child: widget.child);
  }
}

class _LingkupShimmer extends InheritedWidget {
  const _LingkupShimmer({required this.animasi, required super.child});

  final Animation<double> animasi;

  @override
  bool updateShouldNotify(_LingkupShimmer oldWidget) =>
      animasi != oldWidget.animasi;
}

/// Balok abu-abu berkilau (pengganti spinner polos saat memuat).
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    this.height = 16,
    this.width,
    this.radius = 12,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  /// Hanya dipakai kalau TIDAK berada di dalam [AppShimmer].
  AnimationController? _c;

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double>? bersama = AppShimmer.nilai(context);
    AnimationController? milik = _c;

    if (bersama == null && milik == null) {
      milik = AnimationController(vsync: this, duration: AppMotion.denyut)
        ..repeat();
      _c = milik;
    }

    final Animation<double> anim = bersama ?? milik!;
    final AppSemantic s = context.semantic;
    final bool gelap = Theme.of(context).brightness == Brightness.dark;
    final bool kurangiGerak = MediaQuery.disableAnimationsOf(context);

    final Color dasar = s.line;
    final Color kilau =
        Color.lerp(s.line, Colors.white, gelap ? 0.10 : 0.85) ?? s.line;

    if (kurangiGerak) {
      return Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: dasar,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      );
    }

    return AnimatedBuilder(
      animation: anim,
      builder: (BuildContext context, _) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              colors: <Color>[dasar, kilau, dasar],
              stops: const <double>[0.15, 0.5, 0.85],
              transform: _GeserGradasi(anim.value),
            ),
          ),
        );
      },
    );
  }
}

/// Kerangka satu kartu (judul + 2 baris isi) — bentuk paling umum di app ini.
class SkeletonKartu extends StatelessWidget {
  const SkeletonKartu({super.key, this.tinggi = 104});

  final double tinggi;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        height: tinggi,
        padding: const EdgeInsets.all(AppSpacing.screen),
        decoration: BoxDecoration(
          color: context.semantic.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: context.semantic.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const AppSkeleton(height: 14, width: 140, radius: 7),
            const SizedBox(height: AppSpacing.sm),
            AppSkeleton(height: 10, width: MediaQuery.sizeOf(context).width * 0.62, radius: 5),
            const SizedBox(height: AppSpacing.xs),
            AppSkeleton(height: 10, width: MediaQuery.sizeOf(context).width * 0.4, radius: 5),
          ],
        ),
      ),
    );
  }
}

/// Kerangka daftar — dipakai saat memuat kegiatan, berita, UMKM, dll.
class SkeletonDaftar extends StatelessWidget {
  const SkeletonDaftar({super.key, this.jumlah = 3, this.tinggi = 104});

  final int jumlah;
  final double tinggi;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < jumlah; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            SkeletonKartu(tinggi: tinggi),
          ],
        ],
      ),
    );
  }
}

/// Empty state terdesain.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    this.art = 'empty_kegiatan',
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String art;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppIllustration(art, height: 170),
            const SizedBox(height: 12),
            Text(title, style: context.text.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              message,
              style: context.text.bodyMedium?.copyWith(color: context.semantic.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...<Widget>[
              const SizedBox(height: 20),
              SizedBox(
                width: 220,
                child: PrimaryButton(label: actionLabel!, onPressed: onAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state terdesain + tombol coba lagi.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    this.message = 'Terjadi kesalahan saat memuat data.',
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const AppIllustration('error_offline', height: 170),
            const SizedBox(height: 12),
            Text('Gagal memuat', style: context.text.titleMedium),
            const SizedBox(height: 6),
            Text(
              message,
              style: context.text.bodyMedium?.copyWith(color: context.semantic.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 220,
              child: PrimaryButton(
                label: 'Coba lagi',
                icon: Ik.refresh,
                onPressed: onRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
