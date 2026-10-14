import '../domain/kegiatan.dart';

/// Data demo kegiatan (dipakai saat backend belum dinyalakan).
///
/// Ini adalah SATU-SATUNYA sumber data lokal. Repository
/// `KegiatanRepository` membungkus kelas ini, jadi layer atas tidak pernah
/// menyentuh data demo secara langsung.
class KegiatanLokal {
  KegiatanLokal._();

  static const List<Pengumuman> pengumuman = <Pengumuman>[
    Pengumuman('PENTING', 'Rapat Pengurus', 'Senin, 20 Okt · 19.30 · Balai RW 05'),
    Pengumuman('KEUANGAN', 'Iuran Oktober', 'Batas pembayaran 31 Okt 2026'),
    Pengumuman('KEGIATAN', 'Bakti Sosial', 'Sabtu, 18 Okt · 07.00 · Balai RW 05'),
  ];

  static final List<Kegiatan> kegiatan = <Kegiatan>[
    Kegiatan(
      judul: 'Kerja Bakti Lingkungan',
      kategori: 'Sosial',
      tanggal: DateTime(2026, 10, 18),
      lokasi: 'Balai RW 05',
      mendatang: true,
    ),
    Kegiatan(
      judul: 'Latihan Futsal Rutin',
      kategori: 'Olahraga',
      tanggal: DateTime(2026, 10, 21),
      lokasi: 'GOR Kuningan',
      mendatang: true,
    ),
    Kegiatan(
      judul: 'Pengajian Bulanan',
      kategori: 'Keagamaan',
      tanggal: DateTime(2026, 10, 25),
      lokasi: 'Masjid Al-Ikhlas',
      mendatang: true,
    ),
    Kegiatan(
      judul: 'Donor Darah Bersama PMI',
      kategori: 'Sosial',
      tanggal: DateTime(2026, 10, 10),
      lokasi: 'Kantor Kelurahan',
      mendatang: false,
    ),
    Kegiatan(
      judul: 'Turnamen Badminton',
      kategori: 'Olahraga',
      tanggal: DateTime(2026, 10, 2),
      lokasi: 'GOR Kuningan',
      mendatang: false,
    ),
  ];

  static const List<String> kategori = <String>[
    'Semua',
    'Sosial',
    'Olahraga',
    'Keagamaan',
  ];

  static const List<Berita> berita = <Berita>[
    Berita('Rapat Koordinasi Pengurus Bulan Oktober', 'Pengurus',
        '2 jam lalu', 'Organisasi'),
    Berita('Pendaftaran Lomba 17-an Resmi Dibuka', 'Humas', '1 hari lalu',
        'Kegiatan'),
    Berita('Kas Karang Taruna Tembus Rp12 Juta', 'Bendahara', '3 hari lalu',
        'Keuangan'),
  ];

  static const int totalAnggota = 128;
  static const int kegiatanBulanIni = 12;
}
