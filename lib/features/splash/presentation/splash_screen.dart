import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/auth/session.dart';
import '../../../core/theme/app_colors.dart';

/// Splash 1,8 detik lalu ke beranda / onboarding (sekali) / login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool seen = prefs.getBool('onboarding_seen') ?? false;
    // Baca langsung dari prefs dengan kunci yang sama persis seperti yang
    // ditulis SessionNotifier. SEBELUMNYA splash selalu membawa user ke
    // '/auth' walau sesi masih aktif, jadi warga harus masuk ulang tiap
    // kali aplikasi dibuka.
    final bool sudahMasuk = prefs.getString(SessionKeys.user)?.isNotEmpty ?? false;

    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    if (!seen) {
      context.go('/onboarding');
    } else if (sudahMasuk) {
      context.go('/home');
    } else {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ukuran responsif dari lebar layar (bukan angka dp mati).
    final Size layar = MediaQuery.sizeOf(context);
    final double u = (layar.shortestSide / 360).clamp(1.0, 1.22);

    // Setting font besar dari sistem tidak boleh merusak tata letak.
    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 0.9,
      maxScaleFactor: 1.1,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // (1) latar: hijau brand solid + grid yang bergerak
          Container(color: AppColors.primary),
          const _GridBergerak(),
          // (2) cahaya berdenyut di belakang logo
          Center(child: _DenyutRadial(ukuran: 210 * u)),
          // (3) blok konten: centering sejati di area aman
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // (4) logo: emblem + bernapas
                  const _LogoBernapas(),
                  SizedBox(height: 34 * u),
                  // teks
                  _Masuk(
                    delay: 0,
                    scale: true,
                    child: Column(
                      children: <Widget>[
                        Text(
                          'KUNBAR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30 * u,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 5.0 * u,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: 9 * u),
                        Container(
                          width: 26 * u,
                          height: 3 * u,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(2 * u),
                          ),
                        ),
                        SizedBox(height: 9 * u),
                        Text(
                          'CONNECT',
                          style: TextStyle(
                            color: const Color(0xFFC8E6C9),
                            fontSize: 11 * u,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 5.5 * u,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 26 * u),
                  _Masuk(
                    delay: 220,
                    child: Text(
                      'Kuningan Barat  ·  Jakarta Selatan',
                      style: TextStyle(
                        color: const Color(0xFFC8E6C9).withValues(alpha: 0.78),
                        fontSize: 12.5 * u,
                        height: 1.2,
                      ),
                    ),
                  ),
                  SizedBox(height: 12 * u),
                  _Masuk(
                    delay: 300,
                    child: Text(
                      'from Katar KunBar',
                      style: TextStyle(
                        color: const Color(0xFFC8E6C9).withValues(alpha: 0.55),
                        fontSize: 10 * u,
                        height: 1.2,
                      ),
                    ),
                  ),
                  SizedBox(height: 46 * u),
                  // (5) tiga titik loading berdenyut
                  _TitikMemuat(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// (1) Grid latar bergerak: 0,0 -> 100,100 -> 0,0 dalam 12 detik.
class _GridBergerak extends StatefulWidget {
  const _GridBergerak();

  @override
  State<_GridBergerak> createState() => _GridBergerakState();
}

class _GridBergerakState extends State<_GridBergerak>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => CustomPaint(
        painter: _GridPainter(_c.value),
        size: Size.infinite,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.t);

  /// 0 -> 1 -> 0 (bolak-balik), memberi gerakan keluar-masuk.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final double k = 1 - (1 - (t < 0.5 ? t * 2 : (1 - t) * 2)).abs();
    final double geser = k * 100;
    final Paint cat = Paint()
      ..color = AppColors.success.withValues(alpha: 0.30)
      ..strokeWidth = 0.9;

    canvas.save();
    canvas.translate(geser, geser);
    // gambar 3x3 sel supaya menutup layar meski sudah digeser
    for (int i = -1; i <= 2; i++) {
      for (int j = -1; j <= 2; j++) {
        final double x = i * 100.0;
        final double y = j * 100.0;
        canvas.drawLine(Offset(x + 100, y), Offset(x, y), cat);
        canvas.drawLine(Offset(x, y + 100), Offset(x, y), cat);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.t != t;
}

/// (2) Cahaya radial: jari-jari bernapas 430 -> 470 -> 430 (4 detik).
class _DenyutRadial extends StatefulWidget {
  const _DenyutRadial({required this.ukuran});

  final double ukuran;

  @override
  State<_DenyutRadial> createState() => _DenyutRadialState();
}

class _DenyutRadialState extends State<_DenyutRadial>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final double denyut = 1 + 0.045 * math.sin(_c.value * 2 * math.pi);
        return Transform.scale(
          scale: denyut,
          child: Opacity(
            opacity: 0.82 + 0.18 * _c.value,
            child: Container(
              width: widget.ukuran,
              height: widget.ukuran,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    AppColors.secondary.withValues(alpha: 0.16),
                    AppColors.primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// (4) Logo emblem (PNG monokrom putih) + bernapas 1 -> 1.03 -> 1 (3 detik).
class _LogoBernapas extends StatefulWidget {
  const _LogoBernapas();

  @override
  State<_LogoBernapas> createState() => _LogoBernapasState();
}

class _LogoBernapasState extends State<_LogoBernapas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size layar = MediaQuery.sizeOf(context);
    final double u = (layar.shortestSide / 360).clamp(1.0, 1.22);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Transform.scale(
        scale: 1 + 0.03 * _c.value,
        child: Image.asset(
          'assets/brand/emblem-512.png',
          width: 150 * u,
          height: 150 * u,
          fit: BoxFit.contain,
          // Logos biasanya tidak ikut filter tema gelap.
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

/// (5) Tiga titik loading berdenyut, jeda 0,2 dan 0,4 detik.
class _TitikMemuat extends StatefulWidget {
  @override
  State<_TitikMemuat> createState() => _TitikMemuatState();
}

class _TitikMemuatState extends State<_TitikMemuat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size layar = MediaQuery.sizeOf(context);
    final double u = (layar.shortestSide / 360).clamp(1.0, 1.22);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _titik(_c.value, 0),
          SizedBox(width: 14 * u),
          _titik(_c.value, 0.2),
          SizedBox(width: 14 * u),
          _titik(_c.value, 0.4),
        ],
      ),
    );
  }

  Widget _titik(double t, double jeda) {
    // geser fase supaya titik berikutnya ikut berdenyut
    final double p = ((t + jeda) % 1.0);
    final double v = 0.35 + 0.65 * (0.5 - 0.5 * math.cos(p * 2 * math.pi));
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFC8E6C9).withValues(alpha: v),
      ),
    );
  }
}

/// Teks masuk halus. [scale] memakai lengkung pegas.
class _Masuk extends StatefulWidget {
  const _Masuk({required this.child, this.delay = 0, this.scale = false});

  final Widget child;
  final int delay;
  final bool scale;

  @override
  State<_Masuk> createState() => _MasukState();
}

class _MasukState extends State<_Masuk> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == 0) {
      _c.forward();
    } else {
      Future<void>.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CurvedAnimation anim = CurvedAnimation(
      parent: _c,
      curve: widget.scale ? Curves.easeOutBack : Curves.easeInOutCubicEmphasized,
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, Widget? kid) {
        final double v = anim.value.clamp(0.0, 1.2);
        if (widget.scale) {
          return Opacity(
            opacity: v.clamp(0.0, 1.0),
            child: Transform.scale(scale: 0.90 + 0.10 * v, child: kid),
          );
        }
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: kid),
        );
      },
      child: widget.child,
    );
  }
}
