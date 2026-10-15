import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'haptics.dart';

/// Nada permukaan (isian) — satu-satunya tempat warna permukaan ditentukan.
enum AppSurfaceTone {
  /// Permukaan biasa (putih di tema terang).
  plain,

  /// Panel lembut berwarna hijau brand (info, lencana, chip terpilih).
  soft,

  /// Permukaan hijau penuh — teks WAJIB pakai [AppSurface.warnaTeks].
  brand,

  /// Gradasi hero (kartu saldo, sambutan).
  gradien,

  /// Sedikit tembus pandang (kartu di atas peta/foto).
  tembus,
}

/// Tingkat bayangan. Di tema gelap bayangan dimatikan otomatis — latar yang
/// sudah gelap membuat bayangan tak terbaca dan terlihat kotor; sebagai
/// gantinya border 1px yang memisahkan permukaan.
enum AppElevation { rata, kartu, naik }

/// Permukaan serbaguna: kartu, panel, ubin, kartu hero.
///
/// Kenapa ada: dulu tiap layar menulis `BoxDecoration` + `boxShadow` +
/// `InkWell` + `AnimatedScale` sendiri-sendiri, sehingga warna & bayangan
/// berbeda antar halaman. Sekarang semua permukaan lewat sini.
///
/// Susunan lapisan (penting, jangan diubah tanpa alasan):
/// (1) AnimatedContainer - hanya bayangan;
/// (2) Material - warna isian;
/// (3) InkWell - riak sentuhan;
/// (4) Ink - gradasi/garis tepi + padding.
/// Riak TIDAK terlihat kalau warna isian dipasang di lapisan paling luar.
class AppSurface extends StatefulWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.tone = AppSurfaceTone.plain,
    this.elevation = AppElevation.kartu,
    this.padding,
    this.margin,
    this.radius,
    this.onTap,
    this.onLongPress,
    this.border,
    this.gradient,
    this.warna,
    this.bayangan,
    this.glowBrand = false,
    this.width,
    this.height,
  });

  final Widget child;
  final AppSurfaceTone tone;
  final AppElevation elevation;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? radius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// `false` = tanpa garis tepi. Bawaan: ada, untuk nada plain/soft/tembus.
  final bool? border;

  /// Khusus [AppSurfaceTone.gradien] — kalau kosong pakai gradasi hero tema.
  final List<Color>? gradient;

  /// Warna isian khusus (menimpa pilihan [tone]).
  ///
  /// Dipakai untuk permukaan bertema tertentu, mis. kartu darurat merah.
  /// Kalau memakai ini, pastikan kontras teks di atasnya sudah dihitung —
  /// jangan asal pasang `Colors.white`.
  final Color? warna;

  /// Timpa bayangan bawaan (mis. [AppShadows.dialog]).
  final List<BoxShadow>? bayangan;

  /// Bayangan berwarna brand (kartu/tombol utama yang ingin ditonjolkan).
  final bool glowBrand;

  final double? width;
  final double? height;

  /// Warna teks/ikon yang AMAN di atas nada tertentu.
  ///
  /// Bukan hiasan: putih di atas [AppColors.secondary] (kuning) cuma 1,6:1 —
  /// tidak terbaca. Fungsi ini memaksa pilihan yang benar.
  static Color warnaTeks(BuildContext context, AppSurfaceTone tone) {
    final bool gelap = Theme.of(context).brightness == Brightness.dark;
    switch (tone) {
      case AppSurfaceTone.brand:
        return gelap ? AppColors.onPrimaryDark : AppColors.onPrimary;
      case AppSurfaceTone.gradien:
        return AppColors.onPrimary;
      case AppSurfaceTone.soft:
      case AppSurfaceTone.plain:
      case AppSurfaceTone.tembus:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  @override
  State<AppSurface> createState() => _AppSurfaceState();
}

class _AppSurfaceState extends State<AppSurface> {
  bool _ditekan = false;

  @override
  Widget build(BuildContext context) {
    final AppSemantic s = context.semantic;
    final bool gelap = Theme.of(context).brightness == Brightness.dark;
    final double r = widget.radius ?? AppRadius.card;
    final BorderRadius br = BorderRadius.circular(r);
    final bool bisaTap = widget.onTap != null || widget.onLongPress != null;
    final bool kurangiGerak = MediaQuery.disableAnimationsOf(context);

    final Color isian = widget.warna ??
        switch (widget.tone) {
          AppSurfaceTone.plain => s.card,
          AppSurfaceTone.soft =>
            gelap ? AppColors.primarySoftDark : AppColors.primarySoft,
          AppSurfaceTone.brand =>
            gelap ? AppColors.primaryOnDark : AppColors.primary,
          AppSurfaceTone.gradien => Colors.transparent,
          AppSurfaceTone.tembus => s.card.withValues(alpha: 0.66),
        };

    final List<Color>? grad = widget.tone == AppSurfaceTone.gradien
        ? (widget.gradient ?? s.heroGradient)
        : widget.gradient;

    final bool pakaiBorder = widget.border ??
        (widget.warna != null ||
            widget.tone == AppSurfaceTone.plain ||
            widget.tone == AppSurfaceTone.soft ||
            widget.tone == AppSurfaceTone.tembus);

    final List<BoxShadow> bayang = widget.bayangan ??
        (widget.glowBrand
            ? AppShadows.glow(gelap ? AppColors.primaryOnDark : AppColors.primary)
            : switch (widget.elevation) {
                AppElevation.rata => AppShadows.none,
                AppElevation.kartu => gelap ? AppShadows.none : AppShadows.card,
                AppElevation.naik => gelap ? AppShadows.none : AppShadows.raised,
              });

    final Widget kartu = AnimatedScale(
      scale: (_ditekan && bisaTap && !kurangiGerak) ? 0.98 : 1.0,
      duration: AppMotion.tap,
      curve: AppMotion.keluar,
      child: AnimatedContainer(
        duration: AppMotion.tap,
        curve: AppMotion.keluar,
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: br,
          boxShadow: (_ditekan && widget.elevation != AppElevation.rata)
              ? AppShadows.none
              : bayang,
        ),
        child: Material(
          color: grad == null ? isian : Colors.transparent,
          borderRadius: br,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap == null
                ? null
                : () {
                    Haptics.ringan();
                    widget.onTap!.call();
                  },
            onLongPress: widget.onLongPress == null
                ? null
                : () {
                    Haptics.sedang();
                    widget.onLongPress!.call();
                  },
            onHighlightChanged: bisaTap
                ? (bool v) => setState(() => _ditekan = v)
                : null,
            borderRadius: br,
            splashColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            child: Ink(
              width: widget.width,
              height: widget.height,
              padding: widget.padding ?? const EdgeInsets.all(AppSpacing.screen),
              decoration: BoxDecoration(
                gradient: grad == null
                    ? null
                    : LinearGradient(
                        colors: grad,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: br,
                border: pakaiBorder ? Border.all(color: s.line) : null,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    return widget.margin == null
        ? kartu
        : Padding(padding: widget.margin!, child: kartu);
  }
}
