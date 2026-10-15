import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/haptics.dart';
import 'app_icon.dart';
import 'primary_button.dart';

/// Dialog & bottom sheet kustom (pengganti AlertDialog polos).
class AppSheet {
  AppSheet._();

  /// Bottom sheet membulat 32px, aman dari keyboard, bisa digulir.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool dismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: dismissible,
      enableDrag: dismissible,
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            child: builder(ctx),
          ),
        );
      },
    );
  }
}

class AppDialog {
  AppDialog._();

  /// Konfirmasi dua tombol. Mengembalikan true bila disetujui.
  static Future<bool> konfirmasi(
    BuildContext context, {
    required String judul,
    required String pesan,
    String labelYa = 'Ya',
    String labelBatal = 'Batal',
    Ik? ikon,
    Color? warna,
  }) async {
    final bool? hasil = await _tampil<bool>(
      context,
      (BuildContext ctx) => _Kerangka(
        ikon: ikon,
        warna: warna,
        judul: judul,
        isi: Text(pesan, style: ctx.text.bodyMedium, textAlign: TextAlign.center),
        aksi: <Widget>[
          PrimaryButton(
            label: labelYa,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(labelBatal),
          ),
        ],
      ),
    );
    return hasil ?? false;
  }

  /// Dialog dengan kolom catatan. null = dibatalkan, '' = dikirim kosong.
  static Future<String?> catatan(
    BuildContext context, {
    required String judul,
    String? subjudul,
    String label = 'Catatan (opsional)',
    String labelYa = 'Simpan',
    int maxPanjang = 240,
  }) {
    final TextEditingController c = TextEditingController();
    return _tampil<String>(
      context,
      (BuildContext ctx) => _Kerangka(
        judul: judul,
        isi: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (subjudul != null) ...<Widget>[
              Text(subjudul, style: ctx.text.bodyMedium),
              const SizedBox(height: AppSpacing.md),
            ],
            TextField(
              controller: c,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              maxLength: maxPanjang,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: label),
            ),
          ],
        ),
        aksi: <Widget>[
          PrimaryButton(
            label: labelYa,
            onPressed: () => Navigator.of(ctx).pop(c.text.trim()),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
        ],
      ),
    ).whenComplete(c.dispose);
  }

  static Future<T?> _tampil<T>(
    BuildContext context,
    Widget Function(BuildContext) isi,
  ) {
    Haptics.light();
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tutup',
      barrierColor: AppColors.black.withValues(alpha: 0.45),
      transitionDuration: AppMotion.normal,
      pageBuilder: (BuildContext ctx, _, __) => SafeArea(child: isi(ctx)),
      transitionBuilder: (BuildContext ctx, Animation<double> a, _, Widget c) {
        final Animation<double> k =
            CurvedAnimation(parent: a, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
          child: ScaleTransition(scale: Tween<double>(begin: 0.9, end: 1).animate(k), child: c),
        );
      },
    );
  }
}

class _Kerangka extends StatelessWidget {
  const _Kerangka({
    required this.judul,
    required this.isi,
    required this.aksi,
    this.ikon,
    this.warna,
  });

  final String judul;
  final Widget isi;
  final List<Widget> aksi;
  final Ik? ikon;
  final Color? warna;

  @override
  Widget build(BuildContext context) {
    final Color w = warna ?? context.colors.primary;
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Material(
          color: context.semantic.card,
          borderRadius: BorderRadius.circular(AppRadius.dialog),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (ikon != null) ...<Widget>[
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: w.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: AppIcon(ikon!, size: 28, color: w)),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  Text(judul,
                      style: context.text.titleLarge,
                      textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.md),
                  isi,
                  const SizedBox(height: AppSpacing.xl),
                  ...aksi,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
