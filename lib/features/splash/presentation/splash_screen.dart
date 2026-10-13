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
    final bool gelap = Theme.of(context).brightness == Brightness.dark;

    // Ukuran TIDAK dikunci dalam dp. Versi sebelumnya memakai angka tetap
    // (mark 104dp, wordmark 40sp) yang hanya cocok di satu lebar layar, dan
    // memakai Spacer(flex:) untuk "centering" - padahal footer ikut terhitung
    // di dalam Column sehingga blok konten tidak pernah benar-benar di tengah.
    // Sekarang semua diturunkan dari lebar layar, dan centering memakai
    // Stack + Center (= titik tengah area aman, bukan titik tengah semu).
    final Size layar = MediaQuery.sizeOf(context);
    final double u = (layar.shortestSide / 360).clamp(1.0, 1.22);

    final Color hijau = gelap ? const Color(0xFF7FC98A) : AppColors.primary;
    final Color hijauMuda =
        gelap ? const Color(0xFFA8E0B0) : AppColors.primary;
    final Color ink = gelap ? const Color(0xFFEEF5EF) : const Color(0xFF111813);
    final Color inkLembut =
        gelap ? const Color(0xFF96A89B) : const Color(0xFF6E7C72);
    final Color garis =
        gelap ? const Color(0xFF26342B) : const Color(0xFFE8EDE8);
    final Color track =
        gelap ? const Color(0xFF26342B) : const Color(0xFFDDE6DF);

    // Setting font besar dari sistem tidak boleh merusak tata letak splash.
    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 0.9,
      maxScaleFactor: 1.15,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              // ---- blok konten: centering SEJATI ----
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _Masuk(
                      delay: 0,
                      child: Container(
                        width: 88 * u,
                        height: 88 * u,
                        decoration: BoxDecoration(
                          color: hijau,
                          borderRadius: BorderRadius.circular(24 * u),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'K',
                          style: TextStyle(
                            color: gelap
                                ? const Color(0xFF0E1C12)
                                : Colors.white,
                            fontSize: 40 * u,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 22 * u),
                    _Masuk(
                      delay: 70,
                      child: Text(
                        'KUNBAR',
                        style: TextStyle(
                          color: ink,
                          fontSize: 30 * u,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3.2 * u,
                          height: 1,
                        ),
                      ),
                    ),
                    SizedBox(height: 11 * u),
                    _Masuk(
                      delay: 130,
                      child: Container(
                        width: 22 * u,
                        height: 3 * u,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(2 * u),
                        ),
                      ),
                    ),
                    SizedBox(height: 12 * u),
                    _Masuk(
                      delay: 180,
                      child: Text(
                        'CONNECT',
                        style: TextStyle(
                          color: hijau,
                          fontSize: 10.5 * u,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3.6 * u,
                          height: 1,
                        ),
                      ),
                    ),
                    SizedBox(height: 15 * u),
                    _Masuk(
                      delay: 240,
                      child: Text(
                        'Satu Kelurahan, Satu Komunitas, Satu Aplikasi',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: inkLembut,
                          fontSize: 12.5 * u,
                          height: 1.3,
                        ),
                      ),
                    ),
                    SizedBox(height: 15 * u),
                    _Masuk(
                      delay: 290,
                      child: Text(
                        'Dibuat bersama warga Kuningan Barat',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: inkLembut,
                          fontSize: 12.5 * u,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ---- footer: dipin di dasar area aman ----
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _Masuk(
                  delay: 340,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(width: 120 * u, height: 1, color: garis),
                      SizedBox(height: 12 * u),
                      Text(
                        'Kelurahan Kuningan Barat  ·  Jakarta Selatan',
                        style: TextStyle(color: inkLembut, fontSize: 10.5 * u),
                      ),
                      SizedBox(height: 18 * u),
                      SizedBox(
                        width: 108 * u,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2 * u),
                          child: LinearProgressIndicator(
                            minHeight: 3 * u,
                            backgroundColor: track,
                            valueColor: AlwaysStoppedAnimation<Color>(hijauMuda),
                          ),
                        ),
                      ),
                      SizedBox(height: 20 * u),
                    ],
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

/// Masuk halus berjenjang: opacity 0 -> 1 plus geser naik 14 dp.
class _Masuk extends StatefulWidget {
  const _Masuk({required this.child, this.delay = 0});

  final Widget child;
  final int delay;

  @override
  State<_Masuk> createState() => _MasukState();
}

class _MasukState extends State<_Masuk> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
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
      curve: Curves.easeOutCubic,
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, Widget? kid) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - anim.value)),
          child: kid,
        ),
      ),
      child: widget.child,
    );
  }
}
