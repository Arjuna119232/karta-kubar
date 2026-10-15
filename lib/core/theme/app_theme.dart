import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

// Token dipisah ke berkas sendiri supaya gampang dipindah ke
// `packages/shared/` untuk APK Mitra. Di-export di sini agar kode lama yang
// meng-import `app_theme.dart` tetap mendapat AppSpacing/AppRadius.
export 'app_assets.dart';
export 'app_motion.dart';
export 'app_shadows.dart';
export 'app_spacing.dart';

/// Tema KUNBAR Connect — satu tema untuk terang & gelap.
///
/// Semua warna diambil dari [AppColors] / [AppSemantic]. TIDAK ada hex
/// yang ditulis langsung di layar: kalau butuh warna baru, turunkan dari
/// token di sini supaya terang & gelap selalu konsisten.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final TextTheme textTheme = AppTypography.textTheme(brightness);
    final AppSemantic semantic = isDark ? AppSemantic.dark : AppSemantic.light;

    // Warna tombol utama DIPISAH per tema dan kontrasnya dihitung:
    //  - terang : #1B5E20 + teks putih      = 7,9:1  (lolos AAA)
    //  - gelap  : #7BD88F + teks #06210C    = 9,8:1  (lolos AAA)
    // Tombol TIDAK memakai `scheme.primary` mentah supaya Material tidak
    // pernah memasangkan hijau terang dengan teks putih (kontras hancur).
    final Color brand = isDark ? AppColors.primaryOnDark : AppColors.primary;
    final Color onBrand = isDark ? AppColors.onPrimaryDark : AppColors.onPrimary;

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: brand,
      onPrimary: onBrand,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      error: AppColors.error,
      onError: Colors.white,
      surface: isDark ? AppColors.bgDark : AppColors.bgLight,
      onSurface: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    );

    final OutlineInputBorder fieldIdle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.field),
      borderSide: BorderSide(color: semantic.line),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[semantic],
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,

      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),

      dividerTheme: DividerThemeData(color: semantic.line, thickness: 1, space: 1),

      cardTheme: CardThemeData(
        color: semantic.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: semantic.line),
        ),
      ),

      iconTheme: IconThemeData(color: semantic.textSecondary, size: 22),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.cardDark : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: fieldIdle,
        enabledBorder: fieldIdle,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: brand,
          foregroundColor: onBrand,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: brand,
          side: BorderSide(color: semantic.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brand,
          minimumSize: const Size(48, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: textTheme.labelMedium,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        selectedColor: scheme.primary.withValues(alpha: 0.14),
        labelStyle: textTheme.labelMedium,
        side: BorderSide(color: semantic.line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
      ),

      // Dialog custom KUNBAR — dipakai lewat helper `AppDialog`.
      dialogTheme: DialogThemeData(
        backgroundColor: semantic.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.cardDark : const Color(0xFF23262F),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        indicatorShape: const StadiumBorder(),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: brand,
        foregroundColor: onBrand,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearMinHeight: 6,
        linearTrackColor: semantic.line,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xxs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }
}
