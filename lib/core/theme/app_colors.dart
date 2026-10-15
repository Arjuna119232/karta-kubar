import 'package:flutter/material.dart';

/// Palet KUNBAR Connect + token semantik per-tema.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1B5E20); // Hijau Karang Taruna
  static const Color secondary = Color(0xFFFFC107); // Kuning energi muda
  static const Color accent = Color(0xFF0D47A1); // Biru kepercayaan
  // Accent pink untuk highlight kegiatan sosial (identitas KUNBAR Connect).
  static const Color social = Color(0xFFE91E63);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF2E7D32);
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

  // Alias semantik v6.
  static const Color highlight = social;
  static const Color info = accent;
  static const Color white = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF1A1A1A);
  static const Color black = Color(0xFF000000);
  static const Color heroSubtext = Color(0xFFFFD9D9);
  static const Color primaryOnDark = Color(0xFF7FC98A);
  static const Color successAlt = Color(0xFF1B7A43);

  // Mode lansia: kontras lebih tinggi.
  static const Color textSecondaryElderLight = Color(0xFF3A3A40);
  static const Color textSecondaryElderDark = Color(0xFFD0D0D6);
  static const Color lineElderLight = Color(0xFFB8B8C0);
  static const Color lineElderDark = Color(0xFF55555C);
}

/// Preset gradient.
class AppGradients {
  AppGradients._();

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF1B5E20), Color(0xFF2E7D32)],
  );
  static const LinearGradient warm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFFFC107), Color(0xFFFF8F00)],
  );
  static const LinearGradient sunset = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFFF8F00), Color(0xFFE91E63)],
  );
  static const LinearGradient ocean = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF0D47A1), Color(0xFF1E88E5)],
  );

  /// Gradient dari satu warna (ikon quick action, header).
  static LinearGradient dari(Color c) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color.lerp(c, AppColors.white, 0.22)!,
          c,
        ],
      );
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

  static const AppSemantic elderLight = AppSemantic(
    card: AppColors.cardLight,
    line: AppColors.lineElderLight,
    textSecondary: AppColors.textSecondaryElderLight,
    success: AppColors.success,
    warning: AppColors.warning,
    heroGradient: <Color>[Color(0xFF123815), Color(0xFF1B5E20)],
  );

  static const AppSemantic elderDark = AppSemantic(
    card: AppColors.cardDark,
    line: AppColors.lineElderDark,
    textSecondary: AppColors.textSecondaryElderDark,
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
