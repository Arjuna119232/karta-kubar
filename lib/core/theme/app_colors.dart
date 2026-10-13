import 'package:flutter/material.dart';

/// Palet KARTA KUBAR + token semantik per-tema.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1B5E20); // Hijau Karang Taruna
  static const Color secondary = Color(0xFFFFC107); // Kuning energi muda
  static const Color accent = Color(0xFF0D47A1); // Biru kepercayaan
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF1B7A43);
  static const Color warning = Color(0xFFB26A00);

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
    heroGradient: <Color>[Color(0xFF1B5E20), Color(0xFF2E7D32)],
  );

  static const AppSemantic dark = AppSemantic(
    card: AppColors.cardDark,
    line: AppColors.lineDark,
    textSecondary: AppColors.textSecondaryDark,
    success: AppColors.success,
    warning: AppColors.warning,
    heroGradient: <Color>[Color(0xFF123815), Color(0xFF1B5E20)],
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
