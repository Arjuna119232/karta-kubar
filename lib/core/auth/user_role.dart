import 'package:flutter/material.dart';

/// Lima level akses KUBAR Connect. Hierarkis: angka lebih besar = lebih tinggi.
///
///  guest      -> belum login, hanya bisa baca
///  warga      -> NIK + alamat Kuningan Barat terverifikasi
///  anggota    -> anggota Karang Taruna
///  pengurus   -> pengurus karang taruna / RT / RW / kelurahan
///  admin      -> admin super (kelola role, moderasi, analytics)
enum UserRole { guest, warga, anggota, pengurus, admin }

extension UserRoleX on UserRole {
  /// 0 = guest (terendah) ... 4 = admin (tertinggi).
  int get level => index;

  String get label => switch (this) {
        UserRole.guest => 'Tamu',
        UserRole.warga => 'Warga',
        UserRole.anggota => 'Anggota KT',
        UserRole.pengurus => 'Pengurus',
        UserRole.admin => 'Admin',
      };

  String get deskripsi => switch (this) {
        UserRole.guest => 'Baca berita, agenda, UMKM, dan profil kelurahan.',
        UserRole.warga => 'NIK + alamat terverifikasi. Bisa kirim inspirations dan lapor.',
        UserRole.anggota =>
          'Anggota Karang Taruna. Absensi QR, iuran wajib, voting internal.',
        UserRole.pengurus =>
          'Pengurus / RT / RW / kelurahan. Kelola kegiatan dan verifikasi warga.',
        UserRole.admin => 'Akses penuh: role, moderasi konten, analytics, laporan.',
      };

  /// Apakah role ini minimal [minimal] (level >= level minimal).
  bool bisa(UserRole minimal) => level >= minimal.level;

  /// Guest tidak punya session, jadi selalu perlu login dulu.
  bool get perluLogin => this != UserRole.guest;

  IconData get ikon => switch (this) {
        UserRole.guest => Icons.person_outline_rounded,
        UserRole.warga => Icons.badge_outlined,
        UserRole.anggota => Icons.groups_rounded,
        UserRole.pengurus => Icons.how_to_reg_rounded,
        UserRole.admin => Icons.admin_panel_settings_rounded,
      };

  Color get warna => switch (this) {
        UserRole.guest => const Color(0xFF6A6A72),
        UserRole.warga => const Color(0xFF1B5E20),
        UserRole.anggota => const Color(0xFF0D47A1),
        UserRole.pengurus => const Color(0xFFB26A00),
        UserRole.admin => const Color(0xFFE91E63),
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
            'Absensi kegiatan via QR + GPS',
            'Kartu anggota digital',
            'Iuran wajib + laporan kas',
            'Voting internal & poin kontribusi',
          ],
        UserRole.pengurus => <String>[
            'Semua akses anggota',
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