import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'core/theme.dart';
import 'screens/izin_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/shell.dart';
import 'services/notification_service.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!Config.demo) {
    await Supabase.initialize(url: Config.supabaseUrl, publishableKey: Config.supabaseAnonKey);
  }
  await NotificationService.instance.initFcm();
  await NotificationService.instance.init();
  final state = AppState();
  await state.init();
  runApp(ChangeNotifierProvider.value(value: state, child: const MitraApp()));
}

class MitraApp extends StatelessWidget {
  const MitraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return MaterialApp(
      title: 'KUNBAR Mitra',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: s.themeMode,
      home: s.loggedIn
          ? (s.onboardingBelumDitinjau
              ? const OnboardingScreen()
              : (s.izinBelumDitinjau ? const IzinScreen() : const Shell()))
          : const LoginScreen(),
    );
  }
}
