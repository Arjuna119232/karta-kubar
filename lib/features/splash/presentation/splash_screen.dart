import 'dart:math' as math;

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

/// Splash 1,8 detik lalu ke beranda / onboarding (sekali) / login.
///
/// Navigasi boleh dipasang dari luar lewat [onFinished]; kalau tidak diisi,
/// splash memakai [bacaTujuanSplash] lalu navigasi sendiri seperti semula.
///
/// Tata letak: blok konten (logo - wordmark - lokasi - loading) memakai
/// `Center` di dalam `Stack`, sehingga benar-benar berada di tengah area
/// aman. `from Katar KunBar` menempel di paling bawah lewat `Positioned`.
/// Jangan pakai `Column` + `Spacer(flex:)` untuk ini: Spacer bukan centering
/// dan footer ikut merebut ruang, sehingga blok konten terlihat meleset ke atas.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onFinished});

  /// Dipanggil setelah [kDurasiSplash] habis. Beri tahu navigasi ke mana
  /// (login atau beranda) dari luar, supaya router yang memegang kendali.
  final VoidCallback? onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// Hijau muda netral untuk teks di atas hijau solid. Bukan warna karangan:
  /// diturunkan dari `AppColors.primary` dengan campuran putih.
  static const Color hijauMuda = Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    // Callback dipasang: biarkan pemanggil yang menentukan tujuan, dan jangan
    // baca prefs di sini supaya tidak jadi dua kali.
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
          Center(child: _DenyutRadial(ukuran: 250 * u)),
          // (3) Stack di dalam SafeArea: blok konten centering SEJATI di
          // tengah area aman, footer menempel di paling bawah. Jangan pakai
          // Column + Spacer(flex:) - Spacer bukan centering.
          SafeArea(
            child: Stack(
              children: <Widget>[
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // (4) logo: emblem + bernapas, masuk dengan lengkung pegas
                      _Masuk(
                        scale: true,
                        child: _LogoBernapas(ukuran: 136 * u),
                      ),
                      SizedBox(height: 30 * u),
                      // (5) wordmark: huruf muncul satu per satu
                      _Wordmark(u: u),
                      SizedBox(height: 11 * u),
                      _Masuk(
                        delay: 560,
                        child: Text(
                          'CONNECT',
                          style: TextStyle(
                            color: hijauMuda.withValues(alpha: 0.72),
                            fontSize: 10.5 * u,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 6 * u,
                            height: 1,
                          ),
                        ),
                      ),
                      SizedBox(height: 26 * u),
                      _Masuk(
                        delay: 240,
                        child: Text(
                          'Kuningan Barat  ·  Jakarta Selatan',
                          style: TextStyle(
                            color: hijauMuda.withValues(alpha: 0.80),
                            fontSize: 12.5 * u,
                            height: 1.2,
                          ),
                        ),
                      ),
                      SizedBox(height: 30 * u),
                      // (6) loading: tiga pill yang berubah bentuk
                      _Masuk(delay: 340, child: _MuatPill(u: u)),
                    ],
                  ),
                ),
                // (7) footer: paling bawah, DI BAWAH loading
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 18 * u,
                  child: _Masuk(
                    delay: 520,
                    child: Text(
                      'from Katar KunBar',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: hijauMuda.withValues(alpha: 0.55),
                        fontSize: 10.5 * u,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
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
      ..color = Colors.white.withValues(alpha: 0.15)
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

/// (2) Cahaya radial di belakang logo: jari-jari bernapas + intensitas.
/// Warnanya putih netral, bukan kuning, supaya tidak tersisa warna kuning
/// di layar splash.
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
        final double denyut = 1 + 0.05 * math.sin(_c.value * 2 * math.pi);
        return Transform.scale(
          scale: denyut,
          child: Opacity(
            opacity: 0.70 + 0.30 * _c.value,
            child: Container(
              width: widget.ukuran,
              height: widget.ukuran,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.13),
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
  const _LogoBernapas({required this.ukuran});

  final double ukuran;

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
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Transform.scale(
        scale: 1 + 0.03 * _c.value,
        child: Image.asset(
          'assets/brand/emblem-512.png',
          width: widget.ukuran,
          height: widget.ukuran,
          fit: BoxFit.contain,
          // Logos biasanya tidak ikut filter tema gelap.
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

/// (5) Wordmark KUNBAR: tiap huruf masuk bergeser dari bawah, berurutan.
class _Wordmark extends StatefulWidget {
  const _Wordmark({required this.u});

  final double u;

  @override
  State<_Wordmark> createState() => _WordmarkState();
}

class _WordmarkState extends State<_Wordmark>
    with SingleTickerProviderStateMixin {
  static const String teks = 'KUNBAR';

  /// Jeda antar huruf sebagai pecahan dari total animasi.
  static const double stagger = 0.09;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    // Logo sudah masuk duluan, jadi wordmark baru mulai sedikit kemudian.
    Future<void>.delayed(const Duration(milliseconds: 120), () {
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
    final double fs = 31 * widget.u;
    final double jarak = 5.5 * widget.u;
    final List<String> huruf = teks.split('');
    // Huruf terakhir harus selesai tepat di nilai 1.0.
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
            padding: EdgeInsets.only(
              right: i == huruf.length - 1 ? 0 : jarak,
            ),
            child: Opacity(
              opacity: k,
              child: Transform.translate(
                offset: Offset(0, 14 * (1 - k)),
                child: Text(
                  huruf[i],
                  style: TextStyle(
                    color: Colors.white,
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

/// (6) Loading modern: tiga pill yang berubah dari bulat jadi lonjong,
/// saling bergeser fase. Bentuknya "melompat" lembut, bukan titik statis.
class _MuatPill extends StatefulWidget {
  const _MuatPill({required this.u});

  final double u;

  @override
  State<_MuatPill> createState() => _MuatPillState();
}

class _MuatPillState extends State<_MuatPill>
    with SingleTickerProviderStateMixin {
  static const double lebarDasar = 7;
  static const double lebarMaks = 26;
  static const double tinggi = 7;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double jarak = 9 * widget.u;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _pill(_c.value, 0.00, jarak, true),
          _pill(_c.value, 0.18, jarak, true),
          _pill(_c.value, 0.36, jarak, false),
        ],
      ),
    );
  }

  Widget _pill(double t, double jeda, double jarak, bool adaJarak) {
    final double p = (t + jeda) % 1.0;
    // 0 -> 1 -> 0 dengan ease-in-out, lalu dihaluskan lagi (smoothstep)
    // supaya tidak terlihat "patah" di titik balik.
    final double m = 0.5 - 0.5 * math.cos(p * 2 * math.pi);
    final double k = m * m * (3 - 2 * m);
    final double lebar = lebarDasar + (lebarMaks - lebarDasar) * k;
    // Jarak hanya di antara pill. Kalau pill terakhir juga diberi padding,
    // barisnya melebar 1x jarak dan seluruh kelompok bergeser ke kiri.
    return Padding(
      padding: EdgeInsets.only(right: adaJarak ? jarak : 0),
      // Container biasa, bukan AnimatedContainer: lebarnya sudah berubah
      // tiap frame dari AnimatedBuilder, animasi tambahan justru menambah
      // jank.
      child: Container(
        width: lebar,
        height: tinggi,
        decoration: BoxDecoration(
          color: _SplashScreenState.hijauMuda.withValues(alpha: 0.55 + 0.45 * k),
          borderRadius: BorderRadius.circular(tinggi),
        ),
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
