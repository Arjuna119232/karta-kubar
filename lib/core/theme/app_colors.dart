import 'package:flutter/material.dart';

/// Palet KUNBAR Connect + token semantik per-tema.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1B5E20); // Hijau Karang Taruna
  static const Color secondary = Color(0xFFFFC107); // Kuning energi muda
  static const Color accent = Color(0xFF0D47A1); // Biru kepercayaan

  // --- Warna teks di atas warna brand (kontras dihitung, bukan dikira) ---

  /// Teks di atas [primary]: putih = 7,9:1 (lolos WCAG AA & AAA).
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Teks di atas [secondary] (kuning): HITAM = 12,9:1.
  /// Putih di atas kuning cuma 1,6:1 — GAGAL total, jangan dipakai.
  static const Color onSecondary = Color(0xFF1A1A1A);

  /// Teks di atas [primaryOnDark] (hijau terang, tema gelap): 9,8:1.
  static const Color onPrimaryDark = Color(0xFF06210C);

  /// Hijau versi TERANG — untuk teks/ikon di atas latar GELAP.
  /// Kontras terhadap `bgDark` = 10,9:1, jadi tetap terbaca di HP murah.
  /// `primary` (#1B5E20) di atas latar gelap terlalu redup.
  static const Color primaryOnDark = Color(0xFF7BD88F);

  /// Hijau sangat muda untuk latar "soft" (chip terpilih, lencana) — terang.
  static const Color primarySoft = Color(0xFFE8F5E9);

  /// Hijau soft versi gelap — pasangan [primarySoft] saat tema gelap.
  static const Color primarySoftDark = Color(0xFF1E3323);
  // Accent pink untuk highlight kegiatan sosial (identitas KUNBAR Connect).
  static const Color social = Color(0xFFE91E63);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFB26A00);

  /// Abu netral untuk status yang tidak punya warna sendiri
  /// (ditolak / tamu / topik 'lain').
  static const Color muted = Color(0xFF6A6A72);

  /// Teks di atas permukaan [error] yang terisi penuh. Putih penuh terlalu
  /// silau untuk banner darurat sepanjang paragraf.
  static const Color onErrorSoft = Color(0xFFFFD9D9);

  /// Hijau paling gelap: ujung bawah gradasi hero di tema gelap.
  static const Color primaryDeep = Color(0xFF123815);

  static const Color bgLight = Color(0xFFF6F7F9);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF6A6A72);
  static const Color lineLight = Color(0xFFECECEF);

  static const Color bgDark = Color(0xFF121214);
  static const Color cardDark = Color(0xFF1E1E22);
  static const Color textPrimaryDark = Color(0xFFF2F2F4);
  static const Color textSecondaryDark = Color(0xFF9A9AA0);
  static const Color lineDark = Color(0xFF2A2A2E);
}

/// Warna semantik yang tidak ada di Material ColorScheme.
@immutable
class AppSemantic extends ThemeExtension<AppSemantic> {
  const AppSemantic({
    required this.card,
    required this.line,
    required this.textSecondary,
    required this.success,
    required this.warning,
    required this.heroGradient,
  });

  final Color card;
  final Color line;
  final Color textSecondary;
  final Color success;
  final Color warning;
  final List<Color> heroGradient;

  static const AppSemantic light = AppSemantic(
    card: AppColors.cardLight,
    line: AppColors.lineLight,
    textSecondary: AppColors.textSecondaryLight,
    success: AppColors.success,
    warning: AppColors.warning,
    heroGradient: <Color>[AppColors.primary, AppColors.success],
  );

  static const AppSemantic dark = AppSemantic(
    card: AppColors.cardDark,
    line: AppColors.lineDark,
    textSecondary: AppColors.textSecondaryDark,
    success: AppColors.success,
    warning: AppColors.warning,
    heroGradient: <Color>[AppColors.primaryDeep, AppColors.primary],
  );

  @override
  AppSemantic copyWith({
    Color? card,
    Color? line,
    Color? textSecondary,
    Color? success,
    Color? warning,
    List<Color>? heroGradient,
  }) {
    return AppSemantic(
      card: card ?? this.card,
      line: line ?? this.line,
      textSecondary: textSecondary ?? this.textSecondary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      heroGradient: heroGradient ?? this.heroGradient,
    );
  }

  @override
  AppSemantic lerp(ThemeExtension<AppSemantic>? other, double t) {
    if (other is! AppSemantic) return this;
    return AppSemantic(
      card: Color.lerp(card, other.card, t)!,
      line: Color.lerp(line, other.line, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      heroGradient: other.heroGradient,
    );
  }
}

extension AppSemanticX on BuildContext {
  AppSemantic get semantic => Theme.of(this).extension<AppSemantic>()!;
  TextTheme get text => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
}
