import 'package:flutter/material.dart';

// KARTA KUBAR — Karang Taruna Kelurahan Kuningan Barat
// FASE 0 (fondasi): app shell + palet. Design system penuh menyusul di FASE 1.
void main() {
  runApp(const KartaKubarApp());
}

class KartaKubarApp extends StatelessWidget {
  const KartaKubarApp({super.key});

  static const Color primary = Color(0xFF1B5E20); // Hijau Karang Taruna
  static const Color secondary = Color(0xFFFFC107); // Kuning energi muda
  static const Color accent = Color(0xFF0D47A1); // Biru kepercayaan
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color surfaceDark = Color(0xFF121212);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KARTA KUBAR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: secondary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: surfaceLight,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: secondary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: surfaceDark,
      ),
      themeMode: ThemeMode.system,
      home: const FoundationScreen(),
    );
  }
}

class FoundationScreen extends StatelessWidget {
  const FoundationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: KartaKubarApp.primary,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: KartaKubarApp.primary.withValues(alpha: 0.28),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'KK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'KARTA KUBAR',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Satu Komando, Satu Karya',
                  style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  'Karang Taruna Kelurahan Kuningan Barat',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 18, color: cs.onPrimaryContainer),
                      const SizedBox(width: 8),
                      Text(
                        'Fondasi siap — FASE 0',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
