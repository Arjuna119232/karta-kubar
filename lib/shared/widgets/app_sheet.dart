import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_theme.dart';
import 'app_icon.dart';
import 'haptics.dart';

/// Bottom sheet KUNBAR Connect — satu gaya untuk seluruh aplikasi.
///
/// Ciri: sudut atas membulat 32 dp, gagang kecil di tengah, judul + tombol
/// tutup, dan OTOMATIS naik saat keyboard muncul (`viewInsets`) — ini yang
/// paling sering lupa dipasang saat sheet punya kolom isian, sehingga kolom
/// input tertutup keyboard.
///
/// Dua bentuk header:
/// - teks (gagang + judul + tombol tutup), atau
/// - bergambar lewat [gambar] (mis. sampul kegiatan) + judul di bawahnya.
class AppSheet {
  AppSheet._();

  /// Tampilkan sheet. Mengembalikan nilai yang dikirim lewat
  /// `Navigator.of(ctx).pop(nilai)`.
  ///
  /// Minimal salah satu dari [judul] atau [gambar] harus diisi, kalau tidak
  /// sheet tampil tanpa identitas dan tanpa tombol tutup.
  static Future<T?> tampilkan<T>(
    BuildContext context, {
    String? judul,
    String? subjudul,
    Ik? ikon,
    Widget? gambar,
    required Widget isi,
    EdgeInsetsGeometry? padding,
    bool gulir = true,
    bool dapatDitutup = true,
  }) {
    assert(
      judul != null || gambar != null,
      'AppSheet: isi `judul` atau `gambar` supaya sheet punya identitas.',
    );
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
                boxShadow: AppShadows.large,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (gambar != null)
                    SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: gambar,
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: s.line,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.lg +
                          (keyboard > 0 ? AppSpacing.xs : amanBawah * 0.25),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (judul != null || subjudul != null)
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
                                    if (judul != null)
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
                        if (judul != null || subjudul != null)
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
