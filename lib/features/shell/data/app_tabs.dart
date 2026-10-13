import 'package:flutter/material.dart';

import '../../../core/auth/user_role.dart';
import '../../absen/presentation/absen_screen.dart';
import '../../galeri/presentation/galeri_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../keuangan/presentation/keuangan_screen.dart';
import '../../kegiatan/presentation/kegiatan_screen.dart';
import '../../profile/presentation/profile_screen.dart';

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
  final IconData icon;
  final IconData selectedIcon;
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
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      screen: const HomeScreen(),
      minimalRole: UserRole.guest,
    ),
    AppTab(
      label: role.bisa(UserRole.anggota) ? 'Agenda' : 'Kegiatan',
      icon: Icons.event_outlined,
      selectedIcon: Icons.event_rounded,
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
        icon: Icons.qr_code_scanner_outlined,
        selectedIcon: Icons.qr_code_scanner_rounded,
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
        icon: Icons.account_balance_wallet_outlined,
        selectedIcon: Icons.account_balance_wallet_rounded,
        screen: KeuanganScreen(),
        minimalRole: UserRole.anggota,
      ),
    );
  } else {
    dasar.add(
      const AppTab(
        label: 'Galeri',
        icon: Icons.photo_library_outlined,
        selectedIcon: Icons.photo_library_rounded,
        screen: GaleriScreen(),
        minimalRole: UserRole.guest,
      ),
    );
  }

  dasar.add(
    const AppTab(
      label: 'Profil',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      screen: ProfileScreen(),
      minimalRole: UserRole.guest,
    ),
  );

  return dasar;
}