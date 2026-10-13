import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';

// KUBAR Connect — Kuningan Barat Connected Community
// "Satu Kelurahan, Satu Komunitas, Satu Aplikasi"
void main() {
  runApp(const ProviderScope(child: KartaKubarApp()));
}

class KartaKubarApp extends ConsumerWidget {
  const KartaKubarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'KUBAR Connect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      routerConfig: appRouter,
    );
  }
}
