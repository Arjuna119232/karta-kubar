import 'package:flutter/material.dart';

import 'design/tokens.dart';

export 'design/tokens.dart';

/// Tema KUNBAR Mitra - memakai token yang sama dengan APK Warga.
ThemeData buildTheme(Brightness b) {
  final seed = b == Brightness.dark ? AppColors.primaryOnDark : AppColors.primary;
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: b);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg));
  const text = TextStyle(fontSize: 20, fontWeight: FontWeight.w700);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: b == Brightness.dark
        ? const Color(0xFF121214)
        : const Color(0xFFF6F7F9),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        textStyle: text,
        shape: shape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        textStyle: text,
        shape: shape,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      contentPadding: const EdgeInsets.all(18),
    ),
    listTileTheme: const ListTileThemeData(minVerticalPadding: 14),
    cardTheme: CardThemeData(
      elevation: 0,
      color: b == Brightness.dark ? const Color(0xFF1B1B1F) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: Color(0x1A000000)),
      ),
    ),
  );
}

/// Gaya visual khusus layar kerja (peta + glass + gradien).
class Gaya {
  Gaya._();

  static const double tinggiHeader = 92;


  static LinearGradient hijau(bool on) => on
      ? const LinearGradient(colors: [Color(0xFFC62828), Color(0xFFEF5350)])
      : const LinearGradient(colors: [AppColors.primary, Color(0xFF2E7D32)]);

  static LinearGradient emas() => const LinearGradient(
        colors: [AppColors.secondary, Color(0xFFFFD54F)],
      );
}