import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografi: Plus Jakarta Sans (heading) + Inter (body).
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(Brightness brightness) {
    final Color onSurface = brightness == Brightness.dark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final pjs = GoogleFonts.plusJakartaSans;
    final inter = GoogleFonts.inter;

    return TextTheme(
      displaySmall: pjs(
          fontSize: 28, fontWeight: FontWeight.w800, color: onSurface, height: 1.15),
      headlineMedium: pjs(
          fontSize: 24, fontWeight: FontWeight.w700, color: onSurface, height: 1.2),
      headlineSmall:
          pjs(fontSize: 21, fontWeight: FontWeight.w700, color: onSurface),
      titleLarge:
          pjs(fontSize: 19, fontWeight: FontWeight.w700, color: onSurface),
      titleMedium:
          pjs(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface),
      titleSmall:
          pjs(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface),
      bodyLarge: inter(
          fontSize: 15, fontWeight: FontWeight.w400, color: onSurface, height: 1.45),
      bodyMedium: inter(
          fontSize: 13.5, fontWeight: FontWeight.w400, color: onSurface, height: 1.45),
      bodySmall:
          inter(fontSize: 12, fontWeight: FontWeight.w400, color: onSurface),
      labelLarge:
          inter(fontSize: 15, fontWeight: FontWeight.w600, color: onSurface),
      labelMedium:
          inter(fontSize: 12, fontWeight: FontWeight.w600, color: onSurface),
      labelSmall: inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.08,
          color: onSurface),
    );
  }
}
