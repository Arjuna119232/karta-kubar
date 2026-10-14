import 'package:flutter/material.dart';

/// Data demo (offline-first). Nanti diganti Repository -> Supabase.
class Activity {
  const Activity({
    required this.title,
    required this.category,
    required this.date,
    required this.location,
    required this.upcoming,
  });

  final String title;
  final String category;
  final DateTime date;
  final String location;
  final bool upcoming;
}

class NewsItem {
  const NewsItem(this.title, this.source, this.time, this.tag);
  final String title;
  final String source;
  final String time;
  final String tag;
}

class Announcement {
  const Announcement(this.tag, this.title, this.body);
  final String tag;
  final String title;
  final String body;
}

class SeedData {
  SeedData._();

  static const int totalAnggota = 128;
  static const int kegiatanBulanIni = 12;

  static const List<Announcement> announcements = <Announcement>[
    Announcement('PENTING', 'Rapat Pengurus', 'Senin, 20 Okt · 19.30 · Balai RW 05'),
    Announcement('KEUANGAN', 'Iuran Oktober', 'Batas pembayaran 31 Okt 2026'),
    Announcement('KEGIATAN', 'Bakti Sosial', 'Sabtu, 18 Okt · 07.00 · Balai RW 05'),
  ];

  static final List<Activity> activities = <Activity>[
    Activity(
        title: 'Kerja Bakti Lingkungan',
        category: 'Sosial',
        date: DateTime(2026, 10, 18),
        location: 'Balai RW 05',
        upcoming: true),
    Activity(
        title: 'Latihan Futsal Rutin',
        category: 'Olahraga',
        date: DateTime(2026, 10, 21),
        location: 'GOR Kuningan',
        upcoming: true),
    Activity(
        title: 'Pengajian Bulanan',
        category: 'Keagamaan',
        date: DateTime(2026, 10, 25),
        location: 'Masjid Al-Ikhlas',
        upcoming: true),
    Activity(
        title: 'Donor Darah Bersama PMI',
        category: 'Sosial',
        date: DateTime(2026, 10, 10),
        location: 'Kantor Kelurahan',
        upcoming: false),
    Activity(
        title: 'Turnamen Badminton',
        category: 'Olahraga',
        date: DateTime(2026, 10, 2),
        location: 'GOR Kuningan',
        upcoming: false),
  ];

  static const List<String> activityCategories = <String>[
    'Semua',
    'Sosial',
    'Olahraga',
    'Keagamaan',
  ];

  static const List<NewsItem> news = <NewsItem>[
    NewsItem('Rapat Koordinasi Pengurus Bulan Oktober', 'Pengurus', '2 jam lalu',
        'Organisasi'),
    NewsItem('Pendaftaran Lomba 17-an Resmi Dibuka', 'Humas', '1 hari lalu',
        'Kegiatan'),
    NewsItem('Kas Karang Taruna Tembus Rp12 Juta', 'Bendahara', '3 hari lalu',
        'Keuangan'),
  ];

  /// Riwayat iuran (label, nominal, lunas).
  static const List<List<Object>> iuran = <List<Object>>[
    <Object>['Oktober 2026', 25000, false],
    <Object>['September 2026', 25000, true],
    <Object>['Agustus 2026', 25000, true],
    <Object>['Juli 2026', 25000, true],
  ];

  /// Kas per bulan untuk grafik (label, juta rupiah).
  static const List<List<Object>> kasBulanan = <List<Object>>[
    <Object>['Jun', 8.4],
    <Object>['Jul', 11.2],
    <Object>['Agu', 9.1],
    <Object>['Sep', 13.6],
    <Object>['Okt', 12.0],
  ];

  static const String memberName = 'Sobat Karta';
  static const String memberRole = 'Pengurus';
  static const String memberDivision = 'Divisi Sosial';
  static const String memberId = 'KK-2026-0128';
  static const int memberPoin = 340;
  static const int memberKegiatan = 18;
}

/// Warna kategori kegiatan.
Color categoryColor(String category) {
  switch (category) {
    case 'Sosial':
      return const Color(0xFF1B7A43);
    case 'Olahraga':
      return const Color(0xFF0D47A1);
    case 'Keagamaan':
      return const Color(0xFF8A5A00);
    default:
      return const Color(0xFF1B5E20);
  }
}

/// Gambar sampul menurut kategori kegiatan (file di assets/ilustrasi/).
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
      _ => 'cover_umum',
    };
