import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/absen/presentation/absen_screen.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/shell/presentation/app_shell.dart';
import '../features/splash/presentation/splash_screen.dart';
import 'auth/session.dart';
import 'auth/user_role.dart';
import '../shared/widgets/app_icon.dart';

/// Halaman "kamu belum punya akses" — muncul kalau guard menolak rute.
class AksesDitolakScreen extends ConsumerWidget {
  const AksesDitolakScreen({super.key, required this.minimal});

  final UserRole minimal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Session session = ref.watch(sessionProvider);

    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppIcon(Ik.lock, size: 56, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 18),
              Text('Akses perlu ${minimal.label}',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                session.sudahLogin
                    ? 'Akun kamu saat ini ${session.efektif.label}. Fitur ini khusus untuk ${minimal.label} ke atas.'
                    : 'Kamu perlu masuk terlebih dahulu untuk memakai fitur ini.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('Kembali ke beranda'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Guard rute: menolak kalau role session tidak memenuhi [minimal].
///
/// Catatan: ini guard di sisi APP. Keamanan sesungguhnya harus tetap
/// ditegakkan di sisi server lewat Row Level Security Supabase — guard
/// aplikasi cuma untuk UX, bukan pengaman.
class RoleGate extends ConsumerWidget {
  const RoleGate({
    super.key,
    required this.minimal,
    required this.child,
  });

  final UserRole minimal;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Session session = ref.watch(sessionProvider);
    // Sesi dibaca dari SharedPreferences secara async. Selama itu belum
    // selesai, `sudahLogin` masih false dan guard akan sempat menampilkan
    // "Akses Ditolak" untuk user yang sebenarnya masih masuk.
    if (!session.siap) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!session.sudahLogin || !session.efektif.bisa(minimal)) {
      return AksesDitolakScreen(minimal: minimal);
    }
    return child;
  }
}

/// Transisi halaman: fade + geser naik tipis (halus, tanpa lompatan).
CustomTransitionPage<void> _halaman(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (BuildContext context, Animation<double> anim,
        Animation<double> secondary, Widget c) {
      final Animation<double> curved =
          CurveTween(curve: Curves.easeOutCubic).animate(anim);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: c,
        ),
      );
    },
  );
}

/// Rute aplikasi.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (_, GoRouterState s) =>
          _halaman(s, const OnboardingScreen()),
    ),
    // Wajib ada: splash, tombol "Mulai" di onboarding, dan tombol "Masuk"
    // di profil semuanya menuju '/auth'. Tanpa rute ini GoRouter melempar
    // `GoException: no routes for location: /auth` = aplikasi crash.
    GoRoute(
      path: '/auth',
      pageBuilder: (_, GoRouterState s) => _halaman(s, const AuthScreen()),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (_, GoRouterState s) => _halaman(s, const AppShell()),
    ),
    GoRoute(
      path: '/absen',
      pageBuilder: (_, GoRouterState s) => _halaman(
        s,
        const RoleGate(
          minimal: UserRole.anggota,
          child: AbsenScreen(),
        ),
      ),
    ),
  ],
);