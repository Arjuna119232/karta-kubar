import 'package:go_router/go_router.dart';

import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/shell/presentation/app_shell.dart';
import '../features/splash/presentation/splash_screen.dart';

/// Rute aplikasi. Splash memutuskan onboarding vs langsung ke shell.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (_, __) => const AppShell(),
    ),
  ],
);
