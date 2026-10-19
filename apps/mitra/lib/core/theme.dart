import 'package:flutter/material.dart';

import 'design/tokens.dart';

export 'design/tokens.dart';

/// Tema KUNBAR Mitra — token yang sama dengan APK Warga, dengan skala
/// tipografi & bentuk ala aplikasi driver modern: kartu bersudut besar,
/// angka tebal, dan permukaan datar tanpa gradient berlebih.
ThemeData buildTheme(Brightness b) {
  final palet = Palet.dari(b);
  final seed = b == Brightness.dark ? AppColors.primaryOnDark : AppColors.primary;
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: b,
    surface: palet.kartu,
  );

  final tombol = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.field),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: palet.latar,
    canvasColor: palet.latar,
    splashFactory: InkSparkle.splashFactory,
    textTheme: _teks(palet),
    appBarTheme: AppBarTheme(
      backgroundColor: palet.latar,
      surfaceTintColor: Colors.transparent,
      foregroundColor: palet.teks,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: Teks.judul.copyWith(color: palet.teks),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: tombol,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: tombol,
        side: BorderSide(color: palet.garis),
        foregroundColor: palet.teks,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palet.brand,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palet.kartuAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: BorderSide(color: palet.brand, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(color: palet.teks2),
      hintStyle: TextStyle(color: palet.teks2.withValues(alpha: 0.8)),
    ),
    listTileTheme: ListTileThemeData(
      minVerticalPadding: 14,
      iconColor: palet.teks2,
      titleTextStyle: Teks.isi.copyWith(color: palet.teks, fontWeight: FontWeight.w600),
      subtitleTextStyle: Teks.ket.copyWith(color: palet.teks2),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: palet.kartu,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: palet.garis),
      ),
    ),
    dividerTheme: DividerThemeData(color: palet.garis, thickness: 1, space: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: palet.kartu,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      titleTextStyle: Teks.judul.copyWith(color: palet.teks),
      contentTextStyle: Teks.isi.copyWith(color: palet.teks2),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palet.kartu,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: palet.kartu,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      showDragHandle: false,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: palet.gelap ? const Color(0xFF2C2C31) : const Color(0xFF23262B),
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palet.kartuAlt,
      side: BorderSide.none,
      labelStyle: Teks.ket.copyWith(color: palet.teks, fontWeight: FontWeight.w600),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : palet.teks2,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? palet.brand : palet.kartuAlt,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: palet.brand,
      linearMinHeight: 6,
      borderRadius: BorderRadius.circular(99),
    ),
  );
}

/// Teks dasar: ukuran, ketebalan, dan warna teks utama/sekunder.
TextTheme _teks(Palet p) {
  final dasar = Typography.material2021().black.apply(
        bodyColor: p.teks,
        displayColor: p.teks,
      );
  return dasar.copyWith(
    displaySmall: Teks.angka.copyWith(color: p.teks),
    headlineMedium: Teks.halaman.copyWith(color: p.teks),
    titleLarge: Teks.judul.copyWith(color: p.teks),
    titleMedium: Teks.isi.copyWith(color: p.teks, fontWeight: FontWeight.w700),
    bodyLarge: Teks.isi.copyWith(color: p.teks),
    bodyMedium: Teks.ket.copyWith(color: p.teks2),
    labelLarge: Teks.tebal.copyWith(color: p.teks),
    labelSmall: Teks.label.copyWith(color: p.teks2),
  );
}

/// Gaya visual khusus layar kerja (peta + gradien status).
class Gaya {
  Gaya._();

  static const double tinggiHeader = 92;

  /// Gradien tombol status: merah saat ONLINE (untuk mematikan),
  /// hijau tua saat OFFLINE (untuk menyalakan).
  static LinearGradient hijau(bool on) => on
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC62828), Color(0xFFE53935)],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF2E7D32)],
        );

  static LinearGradient emas() => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.secondary, Color(0xFFFFD54F)],
      );

  /// Gradien hero halaman (profil, pendapatan, performa).
  static LinearGradient hero(Brightness b) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: b == Brightness.dark
            ? const [AppColors.primaryDeep, Color(0xFF1E4D24)]
            : const [AppColors.primary, Color(0xFF2E7D32)],
      );
}
