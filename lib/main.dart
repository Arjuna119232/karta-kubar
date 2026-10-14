import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/boot.dart';
import 'core/providers.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';

// KUNBAR Connect — Kuningan Barat Connected Community
// "Satu Kelurahan, Satu Komunitas, Satu Aplikasi"
//
// SPLASH
// -----
// Tidak ada widget splash di sisi Dart. Yang tampil adalah splash NATIVE:
//   Android 12+ -> Theme.SplashScreen + androidx.core:core-splashscreen
//   iOS          -> UILaunchScreen di Info.plist
// keduanya hanya logo + warna solid, maksimal 1,2 detik.
//
// Urutan di bawah penting: `tentukanLokasiAwal()` membaca SharedPreferences
// SELALU splash native masih menutupi layar, jadi pengguna tidak pernah
// melihat halaman kosong. Setelah tujuannya diketahui, `runApp` langsung
// menggambar halaman yang benar - tidak ada rute '/' perantara.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final LokasiAwal awal = await tentukanLokasiAwal();
  runApp(
    ProviderScope(
      child: KartaKubarApp(router: buatRouter(awal)),
    ),
  );
}

class KartaKubarApp extends ConsumerWidget {
  const KartaKubarApp({super.key, required this.router});

  /// Dibuat satu kali di [main] dan diteruskan lewat constructor.
  ///
  /// Jangan dibuat di dalam `build()`: router yang dibangun ulang akan
  /// membuang seluruh riwayat navigasi setiap kali state provider berubah
  /// (mis. saat pengguna mengganti tema atau masuk akun).
  final GoRouter router;

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
      routerConfig: router,
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
