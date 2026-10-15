import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'app_icon.dart';
import 'haptics.dart';

/// Tombol utama: pill full-width 56dp + getaran.
///
/// Perbaikan penting: warna spinner TIDAK lagi dipatok `Colors.white`.
/// Di tema gelap tombol ini berwarna hijau TERANG, sehingga spinner putih
/// nyaris tak terlihat (kontras ~1,4:1). Sekarang warnanya mengikuti token
/// tema: `onPrimary` untuk tombol isi, `primary` untuk tombol garis.
///
/// Tombol yang sedang memuat tetap berwarna brand (bukan abu-abu) supaya
/// tidak terlihat seperti tombol mati/error — tapi tetap tidak bisa ditekan
/// dua kali.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.tone = PrimaryButtonTone.filled,
    this.menyala = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Ik? icon;
  final bool loading;
  final PrimaryButtonTone tone;

  /// Beri bayangan berwarna brand di tema terang (efek "menyala").
  final bool menyala;

  @override
  Widget build(BuildContext context) {
    final bool gelap = Theme.of(context).brightness == Brightness.dark;
    final Color brand = context.colors.primary;
    final Color onBrand = context.colors.onPrimary;
    final Color warnaIsi = tone == PrimaryButtonTone.outlined ? brand : onBrand;

    void handle() {
      Haptics.sedang();
      onPressed?.call();
    }

    final Widget isi = loading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: warnaIsi,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                AppIcon(icon!, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final ButtonStyle? gayaTetapBrand = loading
        ? FilledButton.styleFrom(
            backgroundColor: brand,
            foregroundColor: onBrand,
            disabledBackgroundColor: brand,
            disabledForegroundColor: onBrand,
          )
        : null;

    if (tone == PrimaryButtonTone.outlined) {
      return OutlinedButton(
        onPressed: loading ? null : handle,
        style: loading
            ? OutlinedButton.styleFrom(
                foregroundColor: brand,
                disabledForegroundColor: brand,
              )
            : null,
        child: isi,
      );
    }

    final Widget tombol = FilledButton(
      onPressed: loading ? null : handle,
      style: gayaTetapBrand,
      child: isi,
    );

    if (!menyala || gelap || loading) return tombol;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.button),
        boxShadow: AppShadows.glow(brand, alpha: 0.22),
      ),
      child: tombol,
    );
  }
}

enum PrimaryButtonTone { filled, outlined }
