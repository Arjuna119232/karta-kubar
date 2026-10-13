import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';

// KARTA KUBAR — Karang Taruna Kelurahan Kuningan Barat
// "Satu Komando, Satu Karya"
void main() {
  runApp(const ProviderScope(child: KartaKubarApp()));
}

class KartaKubarApp extends ConsumerWidget {
  const KartaKubarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'KARTA KUBAR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      routerConfig: appRouter,
    );
  }
}
