import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';

// KUNBAR Connect — Kuningan Barat Connected Community
// "Satu Kelurahan, Satu Komunitas, Satu Aplikasi"
void main() {
  runApp(const ProviderScope(child: KartaKubarApp()));
}

class KartaKubarApp extends ConsumerWidget {
  const KartaKubarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    final bool lansia = ref.watch(elderModeProvider);

    return MaterialApp.router(
      title: 'KUNBAR Connect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      routerConfig: appRouter,
      // Hormati ukuran teks sistem, tambah 20% saat Mode Lansia aktif, dan
      // batasi supaya layout tidak pecah di ukuran teks ekstrem.
      builder: (BuildContext context, Widget? child) {
        final MediaQueryData mq = MediaQuery.of(context);
        final double sistem = mq.textScaler.scale(14) / 14;
        final double akhir =
            (sistem * (lansia ? 1.2 : 1.0)).clamp(0.85, 1.6).toDouble();
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(akhir)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
