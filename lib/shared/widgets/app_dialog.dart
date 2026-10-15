import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'app_icon.dart';
import 'haptics.dart';

/// Dialog KUNBAR Connect — satu gaya untuk seluruh aplikasi.
///
/// Kenapa dipusatkan: `showDialog` + `AlertDialog` bawaan menghasilkan tampilan
/// yang berbeda-beda di tiap layar (radius, padding, warna tombol), dan
/// tombolnya tidak ada getaran. Di sini semuanya memakai token tema, animasi
/// masuk yang sama, dan getaran yang sesuai (ringan untuk ya, kuat untuk
/// aksi berbahaya).
class AppDialog {
  AppDialog._();

  /// Tanya izin (Ya/Batal). Hasil: `true` kalau pengguna menekan tombol ya.
  ///
  /// Aman dipakai setelah `await`: fungsi ini tidak memakai `context` lagi
  /// setelah dialog ditutup.
  static Future<bool> konfirmasi(
    BuildContext context, {
    required String judul,
    required String pesan,
    String labelYa = 'Ya',
    String labelBatal = 'Batal',
    Ik? ikon,
    bool bahaya = false,
  }) async {
    final bool? hasil = await tampilkan<bool>(
      context,
      judul: judul,
      pesan: pesan,
      ikon: ikon ?? (bahaya ? Ik.xCircle : Ik.help),
      warnaIkon: bahaya ? context.colors.error : context.colors.primary,
      aksi: (BuildContext ctx, void Function() tutup) => <Widget>[
        TextButton(
          onPressed: () {
            Haptics.ringan();
            tutup();
          },
          child: Text(labelBatal),
        ),
        FilledButton(
          style: bahaya
              ? FilledButton.styleFrom(
                  backgroundColor: ctx.colors.error,
                  foregroundColor: ctx.colors.onError,
                )
              : null,
          onPressed: () {
            if (bahaya) {
              Haptics.kuat();
            } else {
              Haptics.sedang();
            }
            Navigator.of(ctx).pop(true);
          },
          child: Text(labelYa),
        ),
      ],
    );
    return hasil ?? false;
  }

  /// Beri tahu sesuatu (satu tombol "Mengerti").
  static Future<void> info(
    BuildContext context, {
    required String judul,
    String? pesan,
    String labelTutup = 'Mengerti',
    Ik ikon = Ik.checkCircle,
    Color? warnaIkon,
    Widget? isi,
  }) async {
    await tampilkan<void>(
      context,
      judul: judul,
      pesan: pesan,
      ikon: ikon,
      warnaIkon: warnaIkon ?? context.colors.primary,
      isi: isi,
      aksi: (BuildContext ctx, void Function() tutup) => <Widget>[
        FilledButton(
          onPressed: () {
            Haptics.ringan();
            Navigator.of(ctx).pop();
          },
          child: Text(labelTutup),
        ),
      ],
    );
  }

  /// Dialog serbaguna — [aksi] menerima daftar tombol.
  ///
  /// [tutup] menutup dialog TANPA nilai; untuk mengembalikan nilai pakai
  /// `Navigator.of(ctx).pop(nilai)` seperti contoh di [konfirmasi].
  static Future<T?> tampilkan<T>(
    BuildContext context, {
    required String judul,
    String? pesan,
    Widget? isi,
    Ik? ikon,
    Color? warnaIkon,
    required List<Widget> Function(BuildContext context, void Function() tutup) aksi,
    bool dapatDitutup = true,
  }) {
    final bool gelap = Theme.of(context).brightness == Brightness.dark;
    final Color warnaJudul = Theme.of(context).colorScheme.onSurface;

    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: dapatDitutup,
      barrierLabel: judul,
      barrierColor: Colors.black.withValues(alpha: gelap ? 0.62 : 0.42),
      transitionDuration: AppMotion.normal,
      pageBuilder: (BuildContext ctx, _, __) {
        final AppSemantic s = ctx.semantic;
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Material(
                color: s.card,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (ikon != null) ...<Widget>[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: (warnaIkon ?? ctx.colors.primary)
                                  .withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: AppIcon(
                                ikon,
                                size: 24,
                                color: warnaIkon ?? ctx.colors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      Text(
                        judul,
                        style: ctx.text.titleLarge?.copyWith(color: warnaJudul),
                      ),
                      if (pesan != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          pesan,
                          style: ctx.text.bodyMedium
                              ?.copyWith(color: s.textSecondary),
                        ),
                      ],
                      if (isi != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.md),
                        isi,
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: aksi(ctx, () => Navigator.of(ctx).pop()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (BuildContext ctx, Animation<double> anim, _, Widget child) {
        final Animation<double> halus = CurvedAnimation(
          parent: anim,
          curve: AppMotion.emphasized,
          reverseCurve: AppMotion.keluar,
        );
        return FadeTransition(
          opacity: halus,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(halus),
            child: child,
          ),
        );
      },
    );
  }
}
