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
    final Color hijau = gelap ? const Color(0xFF7FC98A) : AppColors.primary;
    final Color ink = gelap ? const Color(0xFFEEF5EF) : const Color(0xFF111813);
    final Color inkLembut =
        gelap ? const Color(0xFF96A89B) : const Color(0xFF6E7C72);
    final Color track =
        gelap ? const Color(0xFF26342B) : const Color(0xFFDDE6DF);
    final Color garisBatas =
        gelap ? const Color(0xFF26342B) : const Color(0xFFE8EDE8);

    return Scaffold(
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              const Spacer(flex: 41),
              _Masuk(
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: hijau,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'K',
                    style: TextStyle(
                      color: gelap ? const Color(0xFF0E1C12) : Colors.white,
                      fontSize: 46,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 27),
              _Masuk(
                child: Text(
                  'KUNBAR',
                  style: TextStyle(
                    color: ink,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 13),
              _Masuk(
                child: Container(
                  width: 24,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _Masuk(
                child: Text(
                  'CONNECT',
                  style: TextStyle(
                    color: hijau,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4.2,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 27),
              _Masuk(
                child: Text(
                  'Satu Kelurahan, Satu Komunitas, Satu Aplikasi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: inkLembut,
                    fontSize: 13.5,
                    height: 1.3,
                  ),
                ),
              ),
              const Spacer(flex: 46),
              Container(width: 150, height: 1, color: garisBatas),
              const SizedBox(height: 13),
              Text(
                'Kelurahan Kuningan Barat  ·  Jakarta Selatan',
                style: TextStyle(color: inkLembut, fontSize: 11.5),
              ),
              const SizedBox(height: 17),
              SizedBox(
                width: 116,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: track,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      gelap ? const Color(0xFFA8E0B0) : AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

/// Masuk halus: opacity 0 -> 1 dan bergeser naik sedikit.
/// Memberi rasa hidup tanpa animasi berat yang memberatkan HP kelas bawah.
class _Masuk extends StatefulWidget {
  const _Masuk({required this.child});

  final Widget child;

  @override
  State<_Masuk> createState() => _MasukState();
}

class _MasukState extends State<_Masuk> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..forward();

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
