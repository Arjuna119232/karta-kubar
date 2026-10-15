import 'package:flutter/material.dart';

// Design system mitra. Jika packages/shared sudah ada, ganti seed & tombol di sini
// dengan token dari sana; komponen khusus mitra (tombol BESAR) tetap di file ini.
const kunbarGreen = Color(0xFF0E8F5B);

ThemeData buildTheme(Brightness b) {
  final scheme = ColorScheme.fromSeed(seedColor: kunbarGreen, brightness: b);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
  const text = TextStyle(fontSize: 20, fontWeight: FontWeight.w700);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: b == Brightness.dark ? const Color(0xFF0B0F0D) : null,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(64), textStyle: text, shape: shape),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(64), textStyle: text, shape: shape),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.all(18),
    ),
    listTileTheme: const ListTileThemeData(minVerticalPadding: 14),
  );
}
