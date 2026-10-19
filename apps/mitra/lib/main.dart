import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'core/diagnostik.dart';
import 'core/theme.dart';
import 'screens/izin_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/shell.dart';
import 'services/notification_service.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Diagnostik.pasang();
  runApp(const BootApp());
}

/// Frame pertama SELALU digambar sebelum inisialisasi apa pun.
///
/// Dulu main() melakukan 4 `await` plugin sebelum runApp dan tanpa try/catch.
/// Satu plugin yang melempar/menggantung = Flutter tidak pernah menggambar
/// frame -> layar hitam polos tanpa pesan. Sekarang: splash digambar dulu,
/// tiap langkah inisialisasi diberi batas waktu, dan kegagalannya ditampilkan.
class BootApp extends StatefulWidget {
  const BootApp({super.key});

  @override
  State<BootApp> createState() => _BootAppState();
}

class _BootAppState extends State<BootApp> {
  final AppState _state = AppState();
  final List<String> _gagal = <String>[];
  String _langkah = 'Menyiapkan aplikasi';
  bool _siap = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await _coba('Supabase', () async {
      if (Config.demo) return;
      await Supabase.initialize(
        url: Config.supabaseUrl,
        publishableKey: Config.supabaseAnonKey,
      );
    });
    await _coba('Notifikasi', () => NotificationService.instance.initFcm());
    await _coba('Notifikasi lokal', () => NotificationService.instance.init());
    await _coba('Penyimpanan', () => _state.init());
    if (!mounted) return;
    setState(() => _siap = true);
  }

  Future<void> _coba(String nama, Future<void> Function() kerja) async {
    if (mounted) setState(() => _langkah = 'Menyiapkan $nama');
    try {
      // Batas waktu: plugin yang menggantung tidak boleh menahan app selamanya.
      await kerja().timeout(const Duration(seconds: 10));
    } catch (e, st) {
      _gagal.add('$nama: $e');
      Diagnostik.catat(nama, e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_siap) {
      return MaterialApp(
        title: 'KUNBAR Mitra',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: _SplashBoot(langkah: _langkah),
      );
    }
    return ChangeNotifierProvider<AppState>.value(
      value: _state,
      child: MitraApp(catatanBoot: List<String>.unmodifiable(_gagal)),
    );
  }
}

class MitraApp extends StatelessWidget {
  const MitraApp({super.key, this.catatanBoot = const <String>[]});

  /// Kegagalan saat start (kosong = semua normal).
  final List<String> catatanBoot;

  @override
  Widget build(BuildContext context) {
    final AppState s = context.watch<AppState>();
    final Widget halaman = s.loggedIn
        ? (s.onboardingBelumDitinjau
            ? const OnboardingScreen()
            : (s.izinBelumDitinjau ? const IzinScreen() : const Shell()))
        : const LoginScreen();
    return MaterialApp(
      title: 'KUNBAR Mitra',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: s.themeMode,
      home: _GerbangBoot(catatan: catatanBoot, anak: halaman),
    );
  }
}

/// Kalau ada langkah start yang gagal, tampilkan daftarnya SEKALI dengan
/// tombol "Lanjutkan" - supaya penyebabnya terbaca, bukan layar hitam.
class _GerbangBoot extends StatefulWidget {
  const _GerbangBoot({required this.catatan, required this.anak});

  final List<String> catatan;
  final Widget anak;

  @override
  State<_GerbangBoot> createState() => _GerbangBootState();
}

class _GerbangBootState extends State<_GerbangBoot> {
  bool _lanjut = false;

  @override
  Widget build(BuildContext context) {
    if (widget.catatan.isEmpty || _lanjut) return widget.anak;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(Icons.warning_amber_rounded, size: 44, color: AppColors.warning),
              const SizedBox(height: 16),
              const Text(
                'Sebagian fitur gagal disiapkan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Aplikasi tetap bisa dibuka. Kalau ada yang tidak berfungsi, '
                'screenshot layar ini dan kirim ke pengurus.',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.field),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      widget.catatan.join('\n\n'),
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => setState(() => _lanjut = true),
                  child: const Text('Lanjutkan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Splash ringan: hanya teks + spinner. Tidak menyentuh AppState/plugin,
/// jadi tidak mungkin gagal.
class _SplashBoot extends StatelessWidget {
  const _SplashBoot({required this.langkah});

  final String langkah;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(color: AppColors.onPrimary, shape: BoxShape.circle),
                child: const Icon(Icons.delivery_dining, size: 42, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              const Text(
                'KUNBAR MITRA',
                style: TextStyle(
                  color: AppColors.onPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Satu Kelurahan, Satu Komunitas',
                style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                langkah,
                style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12),
              ),
              const SizedBox(height: 8),
              // Galat global terakhir (kalau ada) supaya tidak pernah senyap.
              ValueListenableBuilder<String?>(
                valueListenable: Diagnostik.terakhir,
                builder: (BuildContext c, String? pesan, Widget? _) {
                  if (pesan == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
                    child: Text(
                      pesan,
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFFFD8D8), fontSize: 11, height: 1.35),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
