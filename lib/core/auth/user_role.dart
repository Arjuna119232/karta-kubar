import 'package:flutter/material.dart';
import '../../shared/widgets/app_icon.dart';
import '../theme/app_colors.dart';

/// Peran KUNBAR Connect. Hierarkis: level lebih besar = akses lebih luas.
///
///  guest      -> belum login, hanya bisa baca
///  warga      -> warga terdaftar
///  anggota    -> anggota Karang Taruna (kartu anggota digital)
///  rt         -> Ketua/Perangkat RT (level sama dengan pengurus)
///  rw         -> Ketua RW (level sama dengan pengurus)
///  pengurus   -> pengurus karang taruna / kelurahan
///  admin      -> admin super — hanya lewat web, tidak di APK
enum UserRole { guest, warga, anggota, rt, rw, pengurus, admin }

extension UserRoleX on UserRole {
  /// 0 = tamu (terendah) ... 4 = akses penuh.
  /// rt & rw sejajar pengurus, jadi level-nya dihitung eksplisit
  /// (bukan `index`, yang berubah kalau urutan enum bergeser).
  int get level => switch (this) {
        UserRole.guest => 0,
        UserRole.warga => 1,
        UserRole.anggota => 2,
        UserRole.rt => 3,
        UserRole.rw => 3,
        UserRole.pengurus => 3,
        UserRole.admin => 4,
      };

  String get label => switch (this) {
        UserRole.guest => 'Tamu',
        UserRole.warga => 'Warga',
        UserRole.anggota => 'Karang Taruna',
        UserRole.rt => 'RT',
        UserRole.rw => 'RW',
        UserRole.pengurus => 'Pengurus',
        UserRole.admin => 'Admin',
      };

  String get deskripsi => switch (this) {
        UserRole.guest => 'Baca berita, agenda, UMKM, dan profil kelurahan.',
        UserRole.warga => 'Bisa kirim aspirasi, lapor, order, dan forum warga.',
        UserRole.anggota =>
          'Anggota Karang Taruna. Kartu anggota, absensi QR, iuran wajib.',
        UserRole.rt => 'Ketua / perangkat RT. Kelola kegiatan wilayah RT.',
        UserRole.rw => 'Ketua RW. Kelola kegiatan wilayah RW dan verifikasi warga.',
        UserRole.pengurus =>
          'Pengurus karang taruna / kelurahan. Kelola kegiatan dan absensi.',
        UserRole.admin => 'Akses penuh: role, moderasi konten, analytics, laporan.',
      };

  /// Apakah role ini minimal [minimal] (level >= level minimal).
  bool bisa(UserRole minimal) => level >= minimal.level;

  /// Guest tidak punya session, jadi selalu perlu login dulu.
  bool get perluLogin => this != UserRole.guest;

  Ik get ikon => switch (this) {
        UserRole.guest => Ik.person,
        UserRole.warga => Ik.badge,
        UserRole.anggota => Ik.groups,
        UserRole.rt => Ik.home,
        UserRole.rw => Ik.handshake,
        UserRole.pengurus => Ik.personCheck,
        UserRole.admin => Ik.adminShield,
      };

  Color get warna => switch (this) {
        UserRole.guest => AppColors.textSecondaryLight,
        UserRole.warga => AppColors.primary,
        UserRole.anggota => AppColors.accent,
        UserRole.rt => AppColors.success,
        UserRole.rw => AppColors.warning,
        UserRole.pengurus => AppColors.social,
        UserRole.admin => AppColors.error,
      };

  /// Ringkasan hak akses — dipakai di layar profil & dokumentasi.
  List<String> get hakAkses => switch (this) {
        UserRole.guest => <String>[
            'Baca berita & pengumuman',
            'Lihat agenda kegiatan',
            'Lihat katalog UMKM warga',
            'Lihat profil & peta kelurahan',
          ],
        UserRole.warga => <String>[
            'Semua akses tamu',
            'Kirim aspirasi & pengaduan',
            'Daftar kegiatan & forum warga',
            'Lapor darurat + booking fasilitas',
            'Donasi / iuran sukarela',
          ],
        UserRole.anggota => <String>[
            'Semua akses warga',
            'Kartu anggota Karang Taruna digital',
            'Absensi kegiatan via QR + GPS',
            'Iuran wajib + laporan kas',
            'Voting internal & poin kontribusi',
          ],
        UserRole.rt => <String>[
            'Semua akses Karang Taruna',
            'Buat sesi absensi & QR',
            'Kelola kegiatan wilayah RT',
            'Broadcast pengumuman RT',
          ],
        UserRole.rw => <String>[
            'Semua akses RT',
            'Kelola kegiatan wilayah RW',
            'Verifikasi warga RW',
            'Broadcast pengumuman resmi RW',
          ],
        UserRole.pengurus => <String>[
            'Semua akses Karang Taruna',
            'Buat sesi absensi & QR',
            'Kelola kegiatan & verifikasi warga',
            'Broadcast pengumuman resmi',
            'Dashboard monitoring',
          ],
        UserRole.admin => <String>[
            'Akses penuh semua fitur',
            'Kelola role & moderasi konten',
            'Analytics & laporan',
          ],
      };
}

/// Nama peran yang disimpan di database (cocok dengan enum Postgres).
String roleToDb(UserRole role) => role.name;