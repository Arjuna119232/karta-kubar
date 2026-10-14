import 'package:flutter/material.dart';

import '../../../core/auth/user_role.dart';
import '../../absen/presentation/absen_screen.dart';
import '../../galeri/presentation/galeri_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../keuangan/presentation/keuangan_screen.dart';
import '../../kegiatan/presentation/kegiatan_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../../shared/widgets/app_icon.dart';

/// Satu tab di bottom navigation.
class AppTab {
  const AppTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
    required this.minimalRole,
    this.badge,
  });

  final String label;
  final Ik icon;
  final Ik selectedIcon;
  final Widget screen;

  /// Role minimum yang boleh melihat tab ini.
  final UserRole minimalRole;

  /// Angka kecil di pojok ikon (mis. jumlah FISH prioritas).
  final int? badge;
}

/// Daftar tab untuk sebuah role. Semua role punya Beranda + Profil.
///
/// Guest  : hanya baca (beranda, kegiatan, keuangan, galeri, profil)
/// Warga  : + Aspirasi & Lapor Darurat (dibangun di FASE 9)
/// Anggota : + Absen QR (FASE 4, sudah ada)
/// Pengurus: + kendali
/// Admin   : akses penuh
List<AppTab> tabsUntuk(UserRole role) {
  final List<AppTab> dasar = <AppTab>[
    AppTab(
      label: 'Beranda',
      icon: Ik.home,
      selectedIcon: Ik.home,
      screen: const HomeScreen(),
      minimalRole: UserRole.guest,
    ),
    AppTab(
      label: role.bisa(UserRole.anggota) ? 'Agenda' : 'Kegiatan',
      icon: Ik.calendar,
      selectedIcon: Ik.calendar,
      screen: const KegiatanScreen(),
      minimalRole: UserRole.guest,
    ),
  ];

  // Tab khusus anggota ke atas: absensi QR.
  if (role.bisa(UserRole.anggota)) {
    dasar.insert(
      1,
      const AppTab(
        label: 'Absen',
        icon: Ik.qrScan,
        selectedIcon: Ik.qrScan,
        screen: AbsenScreen(),
        minimalRole: UserRole.anggota,
      ),
    );
  }

  // Tab keuangan hanya untuk anggota ke atas (laporan kas internal).
  if (role.bisa(UserRole.anggota)) {
    dasar.add(
      const AppTab(
        label: 'Kas',
        icon: Ik.wallet,
        selectedIcon: Ik.wallet,
        screen: KeuanganScreen(),
        minimalRole: UserRole.anggota,
      ),
    );
  } else {
    dasar.add(
      const AppTab(
        label: 'Galeri',
        icon: Ik.gallery,
        selectedIcon: Ik.gallery,
        screen: GaleriScreen(),
        minimalRole: UserRole.guest,
      ),
    );
  }

  dasar.add(
    const AppTab(
      label: 'Profil',
      icon: Ik.person,
      selectedIcon: Ik.person,
      screen: ProfileScreen(),
      minimalRole: UserRole.guest,
    ),
  );

  return dasar;
}