import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'app_icon.dart';
import 'haptics.dart';

/// Bottom sheet KUNBAR Connect — satu gaya untuk seluruh aplikasi.
///
/// Ciri: sudut atas membulat 32 dp, gagang kecil di tengah, judul + tombol
/// tutup, dan OTOMATIS naik saat keyboard muncul (`viewInsets`) — ini yang
/// paling sering lupa dipasang saat sheet punya kolom isian, sehingga kolom
/// input tertutup keyboard.
class AppSheet {
  AppSheet._();

  /// Tampilkan sheet. Mengembalikan nilai yang dikirim lewat
  /// `Navigator.of(ctx).pop(nilai)`.
  static Future<T?> tampilkan<T>(
    BuildContext context, {
    required String judul,
    String? subjudul,
    Ik? ikon,
    required Widget isi,
    EdgeInsetsGeometry? padding,
    bool gulir = true,
    bool dapatDitutup = true,
  }) {
    final double tinggiMaks = MediaQuery.sizeOf(context).height * 0.92;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: dapatDitutup,
      enableDrag: dapatDitutup,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (BuildContext ctx) {
        final AppSemantic s = ctx.semantic;
        final double keyboard = MediaQuery.viewInsetsOf(ctx).bottom;
        final double amanBawah = MediaQuery.paddingOf(ctx).bottom;

        return Padding(
          padding: EdgeInsets.only(bottom: keyboard),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: tinggiMaks),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: s.card,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.sheet),
                ),
                boxShadow: AppShadows.sheet,
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg + (keyboard > 0 ? AppSpacing.xs : amanBawah * 0.25),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: s.line,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: <Widget>[
                        if (ikon != null) ...<Widget>[
                          AppIcon(ikon, size: 22, color: ctx.colors.primary),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(judul, style: ctx.text.titleLarge),
                              if (subjudul != null)
                                Text(
                                  subjudul,
                                  style: ctx.text.bodySmall
                                      ?.copyWith(color: s.textSecondary),
                                ),
                            ],
                          ),
                        ),
                        if (dapatDitutup)
                          IconButton(
                            tooltip: 'Tutup',
                            onPressed: () {
                              Haptics.ringan();
                              Navigator.of(ctx).pop();
                            },
                            icon: const AppIcon(Ik.xCircle, size: 24),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Flexible(
                      child: gulir
                          ? SingleChildScrollView(
                              padding: padding ?? EdgeInsets.zero,
                              child: isi,
                            )
                          : Padding(
                              padding: padding ?? EdgeInsets.zero,
                              child: isi,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
