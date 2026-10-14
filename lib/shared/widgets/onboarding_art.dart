import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'app_icon.dart';

/// Tiga ilustrasi onboarding. Satu enum supaya halaman cukup menulis
/// `OnbArt.aspirasi`, bukan string nama file yang bisa salah ketik diam-diam.
///
/// Urutan enum = urutan slide di [OnboardingScreen].
enum OnbArt {
  /// aspirations - suara warga masuk dan bisa dilacak.
  aspirasi,

  /// komunitas - warga sekitar saling terhubung.
  komunitas,

  /// terhubung - pengumuman, agenda, UMKM, dan pesan balai.
  terhubung,
}

extension OnbArtX on OnbArt {
  /// Nama file di `assets/ilustrasi/` tanpa ekstensi.
  String get namaFile => switch (this) {
        OnbArt.aspirasi => 'onb_aspirasi',
        OnbArt.komunitas => 'onb_komunitas',
        OnbArt.terhubung => 'onb_terhubung',
      };

  /// Warna identitas sampul ini (dipakai untuk cahaya lembut di belakang
  /// ilustrasi). diambil dari palet aplikasi, bukan warna karangan.
  Color get warna => switch (this) {
        OnbArt.aspirasi => AppColors.social,
        OnbArt.komunitas => AppColors.primary,
        OnbArt.terhubung => AppColors.accent,
      };
}

/// Ilustrasi onboarding siap pakai.
///
/// Menungkus [AppIllustration] supaya halaman tidak perlu tahu nama file dan
/// nama file tidak scattered di beberapa tempat.
class OnboardingArt extends StatelessWidget {
  const OnboardingArt(this.art, {super.key, this.height, this.width});

  final OnbArt art;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return AppIllustration(art.namaFile, height: height, width: width);
  }
}