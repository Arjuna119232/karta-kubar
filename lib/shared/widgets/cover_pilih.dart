import 'dart:ui';

import '../../core/theme/app_colors.dart';

/// Pemilih sampul + warna berdasarkan kategori / tag.
///
/// Dipisah ke `shared` karena tiga layar (kegiatan, beranda, galeri)
/// membutuhkannya, dan ini murni urusan tampilan - bukan sumber data.

/// Warna kategori kegiatan. Turunan dari palet aplikasi, bukan warna karangan.
Color warnaKategori(String kategori) => switch (kategori) {
      'Sosial' => AppColors.success,
      'Olahraga' => AppColors.accent,
      'Keagamaan' => AppColors.warning,
      _ => AppColors.primary,
    };

/// Gambar sampul menurut kategori kegiatan (file di `assets/ilustrasi/`).
String coverKategori(String kategori) => switch (kategori) {
      'Sosial' => 'cover_sosial',
      'Olahraga' => 'cover_olahraga',
      'Keagamaan' => 'cover_religi',
      _ => 'cover_umum',
    };

/// Gambar sampul menurut tag berita.
String coverBerita(String tag) => switch (tag) {
      'Organisasi' => 'cover_rapat',
      'Kegiatan' => 'cover_lomba',
      'Keuangan' => 'cover_keuangan',
      'Donor' => 'cover_donor',
      'Relay' => 'cover_olahraga',
      _ => 'cover_umum',
    };
