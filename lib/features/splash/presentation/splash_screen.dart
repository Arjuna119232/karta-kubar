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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFF1B5E20), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              const Spacer(),
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'KK',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'KUBAR CONNECT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Satu Kelurahan, Satu Komunitas, Satu Aplikasi',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Kelurahan Kuningan Barat, Jakarta Selatan',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12.5,
                ),
              ),
              const Spacer(),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
