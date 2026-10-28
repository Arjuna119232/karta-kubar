import '../../core/theme/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Ikon KUNBAR Connect (gambar buatan sendiri, bukan ikon bawaan Material).
/// Nama enum = nama file di `assets/icons/`. Dibuat oleh `design/gen_assets.py`.
enum Ik {
  accessibility,
  addPhoto,
  adminShield,
  arrowBack,
  arrowForward,
  autoMode,
  badge,
  ball,
  basket,
  bell,
  bolt,
  broom,
  calendar,
  calendarCheck,
  calendarX,
  cart,
  cash,
  camera,
  chat,
  check,
  checkCircle,
  chevronRight,
  clock,
  close,
  cloudOff,
  code,
  dot,
  download,
  drop,
  edit,
  gallery,
  flame,
  flip,
  groups,
  handHeart,
  handshake,
  help,
  history,
  home,
  lock,
  login,
  logout,
  mail,
  megaphone,
  minus,
  moon,
  motorcycle,
  mosque,
  newspaper,
  package,
  northEast,
  party,
  person,
  personCheck,
  phone,
  pinMitra,
  place,
  plus,
  qrCode,
  qrScan,
  refresh,
  route,
  search,
  shieldCheck,
  shop,
  southWest,
  star,
  sun,
  trendingUp,
  trophy,
  wallet,
  xCircle;
}

/// Pengganti `Icon`: ikon duotone yang mengikuti warna & ukuran `IconTheme`.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.ik, {
    super.key,
    this.size,
    this.color,
    this.aktif = false,
    this.semanticLabel,
  });

  final Ik ik;
  final double? size;
  final Color? color;

  /// Isian lebih pekat, dipakai untuk tab yang sedang terpilih.
  final bool aktif;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final IconThemeData tema = IconTheme.of(context);
    final double s = size ?? tema.size ?? 24;
    final Color c =
        color ?? tema.color ?? Theme.of(context).colorScheme.onSurface;
    return SvgPicture.asset(
      AppAssets.ikon('${ik.name}${aktif ? '_a' : ''}'),
      width: s,
      height: s,
      colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
    );
  }
}

/// Ilustrasi berwarna (onboarding, state kosong/error). File di `assets/ilustrasi/`.
class AppIllustration extends StatelessWidget {
  const AppIllustration(
    this.nama, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final String nama;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      AppAssets.ilustrasi(nama),
      width: width,
      height: height,
      fit: fit,
    );
  }
}

/// Gambar sampul berbingkai membulat. Tanpa [width]/[height], mengisi ruang
/// induk (induk harus punya batas ukuran, mis. di dalam Expanded).
class AppCover extends StatelessWidget {
  const AppCover(
    this.nama, {
    super.key,
    this.width,
    this.height,
    this.radius = 16,
  });

  final String nama;
  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final Widget gambar = SvgPicture.asset(
      AppAssets.ilustrasi(nama),
      width: width,
      height: height,
      fit: BoxFit.cover,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: (width == null && height == null)
          ? SizedBox.expand(child: gambar)
          : gambar,
    );
  }
}
