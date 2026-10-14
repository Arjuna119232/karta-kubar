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
    // Semua warna diambil dari token tema, BUKAN angka karangan.
    // Versi sebelumnya memakai hex hijau-tinted sendiri padahal theme app
    // abu netral -> layar melompat warna begitu splash selesai.
    final ThemeData tema = Theme.of(context);
    final bool gelap = tema.brightness == Brightness.dark;

    final Color permukaan = tema.scaffoldBackgroundColor;
    final Color hijau =
        gelap ? const Color(0xFF7FC98A) : AppColors.primary;
    final Color hijauMuda =
        gelap ? const Color(0xFFA8E0B0) : AppColors.success;
    final Color ink = gelap ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final Color inkLembut =
        gelap ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final Color garis = gelap ? AppColors.lineDark : AppColors.lineLight;
    final Color track = gelap ? AppColors.cardDark : AppColors.lineLight;

    // Gradasian aksen: permukaan dicampur sedikit warna brand.
    // Tipis, tapi cukup supaya tidak terlihat datar (gaya Material 3 Expressive).
    final Color tint = Color.alphaBlend(
      hijau.withValues(alpha: gelap ? 0.05 : 0.07),
      permukaan,
    );

    // Ukuran TIDAK dikunci dalam dp: semua diturunkan dari lebar layar.
    // Centering memakai Stack + Center (titik tengah area aman), footer
    // dipin dengan Positioned - bukan Spacer(flex:) yang pernah bikin isi
    // bergeser ke atas.
    final Size layar = MediaQuery.sizeOf(context);
    final double u = (layar.shortestSide / 360).clamp(1.0, 1.22);

    // Setting font besar dari sistem tidak boleh merusak tata letak.
    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 0.9,
      maxScaleFactor: 1.15,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[permukaan, tint],
          ),
        ),
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
                      scale: true,
                      child: _Mark(
                        ukuran: 88 * u,
                        hijau: hijau,
                        gelap: gelap,
                        bayangan: gelap
                            ? (Color.fromRGBO(0, 0, 0, 0.55))
                            : (Color.fromRGBO(16, 48, 24, 0.26)),
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(hijauMuda),
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

/// Mark: cahaya radial halus di belakangnya, kotak hijau, bayangan lembut.
class _Mark extends StatelessWidget {
  const _Mark({
    required this.ukuran,
    required this.hijau,
    required this.gelap,
    required this.bayangan,
  });

  final double ukuran;
  final Color hijau;
  final bool gelap;
  final Color bayangan;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ukuran,
      height: ukuran,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // cahaya radial (2,9x ukuran mark)
          Container(
            width: ukuran * 2.9,
            height: ukuran * 2.9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  hijau.withValues(alpha: gelap ? 0.16 : 0.13),
                  hijau.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          Container(
            width: ukuran,
            height: ukuran,
            decoration: BoxDecoration(
              color: hijau,
              borderRadius: BorderRadius.circular(ukuran * 0.265),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: bayangan,
                  blurRadius: ukuran * 0.38,
                  offset: Offset(0, ukuran * 0.09),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              'K',
              style: TextStyle(
                color: gelap ? const Color(0xFF0E1C12) : Colors.white,
                fontSize: ukuran * 0.46,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Masuk halus berjenjang.
///
/// [scale] memakai lengkung pegas (ada sedikit lewat lalu kembali) - itulah
/// yang bikin terasa "hidup" di Material 3 Expressive. Teks cukup pakai
/// kurva emphasized Material 3.
class _Masuk extends StatefulWidget {
  const _Masuk({required this.child, this.delay = 0, this.scale = false});

  final Widget child;
  final int delay;

  /// true = pakai skala pegas, false = geser naik + fade.
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
      // easeOutBack = pegas: nilai sedikit melewati 1 lalu settle.
      curve: widget.scale ? Curves.easeOutBack : Curves.easeInOutCubicEmphasized,
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, Widget? kid) {
        final double v = anim.value.clamp(0.0, 1.2);
        if (widget.scale) {
          return Opacity(
            opacity: v.clamp(0.0, 1.0),
            child: Transform.scale(scale: 0.86 + 0.14 * v, child: kid),
          );
        }
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: kid),
        );
      },
      child: widget.child,
    );
  }
}
