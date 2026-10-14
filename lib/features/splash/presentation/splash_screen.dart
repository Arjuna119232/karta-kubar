import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/auth/session.dart';
import '../../../core/theme/app_colors.dart';

/// Berapa lama splash tampil sebelum lanjut.
const Duration kDurasiSplash = Duration(milliseconds: 1800);

/// Tujuan setelah splash selesai.
enum SplashTujuan {
  /// Belum pernah lewat onboarding.
  onboarding,

  /// Sudah masuk dan sesi masih hidup -> beranda.
  beranda,

  /// Belum masuk -> halaman login.
  auth,
}

/// Membaca tujuan dari penyimpanan perangkat.
///
/// Dipakai dua pihak: splash (kalau tidak ada [SplashScreen.onFinished]) dan
/// router (kalau callback-nya dipasang). JANGAN dipanggil dua kali untuk satu
/// perpindahan supaya prefs tidak dibaca berulang.
Future<SplashTujuan> bacaTujuanSplash() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool seen = prefs.getBool('onboarding_seen') ?? false;
  // Kunci prefs di sini harus sama persis dengan yang ditulis SessionNotifier.
  final bool sudahMasuk =
      prefs.getString(SessionKeys.user)?.isNotEmpty ?? false;

  if (!seen) return SplashTujuan.onboarding;
  if (sudahMasuk) return SplashTujuan.beranda;
  return SplashTujuan.auth;
}

/// Splash minimalis 1,8 detik — solid brand, logo + wordmark, 3 titik loading.
///
/// Gaya Gojek: bersih, tidak ribet, fokus pada brand.
/// Tata letak: `Center` di `Stack` + `Positioned` footer.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onFinished});

  /// Dipanggil setelah [kDurasiSplash] habis.
  final VoidCallback? onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Color _putih = Colors.white;
  static const Color _putihMuda = Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    if (widget.onFinished != null) {
      await Future<void>.delayed(kDurasiSplash);
      if (!mounted) return;
      widget.onFinished!.call();
      return;
    }
    final SplashTujuan tujuan = await bacaTujuanSplash();
    await Future<void>.delayed(kDurasiSplash);
    if (!mounted) return;
    _pergi(tujuan);
  }

  void _pergi(SplashTujuan tujuan) {
    switch (tujuan) {
      case SplashTujuan.onboarding:
        context.go('/onboarding');
      case SplashTujuan.beranda:
        context.go('/home');
      case SplashTujuan.auth:
        context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size layar = MediaQuery.sizeOf(context);
    final double u = (layar.shortestSide / 360).clamp(1.0, 1.22);

    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 0.9,
      maxScaleFactor: 1.1,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Stack(
            children: <Widget>[
              // Konten tengah: logo -> wordmark -> loading
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Logo: masuk dengan spring, lalu idle (tanpa bernapas berulang)
                    _Masuk(scale: true, child: _Logo(ukuran: 120 * u)),
                    SizedBox(height: 28 * u),
                    // Wordmark: huruf muncul satu per satu
                    _Wordmark(u: u),
                    SizedBox(height: 10 * u),
                    _Masuk(
                      delay: 560,
                      child: Text(
                        'CONNECT',
                        style: TextStyle(
                          color: _putihMuda.withValues(alpha: 0.72),
                          fontSize: 10.5 * u,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 6 * u,
                          height: 1,
                        ),
                      ),
                    ),
                    SizedBox(height: 36 * u),
                    // Loading: 3 titik sederhana (seperti Gojek)
                    _MuatTitikTiga(u: u),
                  ],
                ),
              ),
              // Footer: paling bawah
              Positioned(
                left: 0,
                right: 0,
                bottom: 20 * u,
                child: _Masuk(
                  delay: 600,
                  child: Text(
                    'from Katar KunBar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _putihMuda.withValues(alpha: 0.55),
                      fontSize: 10.5 * u,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Logo emblem putih, masuk spring sekali, lalu diam.
class _Logo extends StatefulWidget {
  const _Logo({required this.ukuran});
  final double ukuran;

  @override
  State<_Logo> createState() => _LogoState();
}

class _LogoState extends State<_Logo> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Transform.scale(
        scale: 0.85 + 0.15 * Curves.easeOutBack.transform(_c.value.clamp(0.0, 1.0)),
        child: Opacity(
          opacity: _c.value.clamp(0.0, 1.0),
          child: Image.asset(
            'assets/brand/emblem-512.png',
            width: widget.ukuran,
            height: widget.ukuran,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

/// Wordmark KUNBAR: huruf masuk bergeser dari bawah, berurutan.
class _Wordmark extends StatefulWidget {
  const _Wordmark({required this.u});
  final double u;

  @override
  State<_Wordmark> createState() => _WordmarkState();
}

class _WordmarkState extends State<_Wordmark>
    with SingleTickerProviderStateMixin {
  static const String teks = 'KUNBAR';
  static const double stagger = 0.09;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double fs = 28 * widget.u;
    final double jarak = 5 * widget.u;
    final List<String> huruf = teks.split('');
    final double rentang = 1 - stagger * (huruf.length - 1);

    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List<Widget>.generate(huruf.length, (int i) {
          final double v =
              ((_c.value - stagger * i) / rentang).clamp(0.0, 1.0);
          final double k = Curves.easeOutCubic.transform(v);
          return Padding(
            padding: EdgeInsets.only(right: i == huruf.length - 1 ? 0 : jarak),
            child: Opacity(
              opacity: k,
              child: Transform.translate(
                offset: Offset(0, 12 * (1 - k)),
                child: Text(
                  huruf[i],
                  style: TextStyle(
                    color: _putih,
                    fontSize: fs,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// 3 titik loading minimalis — seperti Gojek.
class _MuatTitikTiga extends StatefulWidget {
  const _MuatTitikTiga({required this.u});
  final double u;

  @override
  State<_MuatTitikTiga> createState() => _MuatTitikTigaState();
}

class _MuatTitikTigaState extends State<_MuatTitikTiga>
    with SingleTickerProviderStateMixin {
  static const double diameter = 6;
  static const double jarak = 8;

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
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _titik(_c.value, 0.0),
          _titik(_c.value, 0.2),
          _titik(_c.value, 0.4),
        ],
      ),
    );
  }

  Widget _titik(double t, double jeda) {
    final double p = (t + jeda) % 1.0;
    // 0 -> 1 -> 0 smooth
    final double k = 1 - (1 - (p < 0.5 ? p * 2 : (1 - p) * 2)).abs();
    final double skala = 0.6 + 0.4 * k;
    final double alpha = 0.35 + 0.65 * k;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: jarak * widget.u / 2),
      child: Transform.scale(
        scale: skala,
        child: Opacity(
          opacity: alpha,
          child: Container(
            width: diameter * widget.u,
            height: diameter * widget.u,
            decoration: const BoxDecoration(
              color: _putih,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget animasi masuk reusable.
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