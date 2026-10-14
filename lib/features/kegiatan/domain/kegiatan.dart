import 'package:flutter/foundation.dart';

/// Model domain kegiatan, berita, dan pengumuman.
///
/// Dipisah dari data demo supaya tidak terikat ke sumber data apa pun. Layar
/// selalu talking ke model ini; `Supabase`/lokal ada di `features/kegiatan/data/`.

/// Satu kegiatan karang taruna / warga.
@immutable
class Kegiatan {
  const Kegiatan({
    required this.judul,
    required this.kategori,
    required this.tanggal,
    required this.lokasi,
    required this.mendatang,
  });

  final String judul;
  final String kategori;
  /// Null kalau kegiatan tidak punya tanggal (nilai cadangan / baris rusak).
  final DateTime? tanggal;
  final String lokasi;

  /// True kalau tanggalnya masih di depan (dan tanggalnya ada).
  final bool mendatang;

  /// Nilai cadangan supaya layar tidak pernah gagal total kalau daftar
  /// kegiatan kosong. Dipakai sebagai `orElse`.
  static const Kegiatan cadangan = Kegiatan(
    judul: 'Kegiatan warga',
    kategori: 'Sosial',
    tanggal: null,
    lokasi: 'Balai RW 05',
    mendatang: false,
  );

  /// Ubah baris dari database (snake_case) jadi objek aplikasi (camelCase).
  factory Kegiatan.dariBaris(Map<String, dynamic> b) => Kegiatan(
        judul: (b['judul'] ?? b['title'] ?? '').toString(),
        kategori: (b['kategori'] ?? b['category'] ?? '').toString(),
        tanggal:
            DateTime.tryParse('${b['tanggal'] ?? b['date'] ?? ''}'),
        lokasi: (b['lokasi'] ?? b['location'] ?? '').toString(),
        mendatang: (b['mendatang'] ?? b['upcoming'] ?? false) == true,
      );

  /// Bentuk yang dikirim balik ke database.
  Map<String, dynamic> keBaris() => <String, dynamic>{
        'judul': judul,
        'kategori': kategori,
        if (tanggal != null) 'tanggal': tanggal!.toIso8601String(),
        'lokasi': lokasi,
        'mendatang': mendatang,
      };

  @override
  bool operator ==(Object other) =>
      other is Kegiatan &&
      other.judul == judul &&
      other.tanggal == tanggal &&
      other.kategori == kategori &&
      other.lokasi == lokasi &&
      other.mendatang == mendatang;

  @override
  int get hashCode =>
      Object.hash(judul, kategori, tanggal, lokasi, mendatang);

  @override
  String toString() => 'Kegiatan($judul, $tanggal)';
}

/// Satu berita singkat.
@immutable
class Berita {
  const Berita(this.judul, this.sumber, this.waktu, this.tag);

  final String judul;
  final String sumber;

  /// Teks waktu yang sudah diformat, mis. "2 jam lalu".
  final String waktu;
  final String tag;

  factory Berita.dariBaris(Map<String, dynamic> b) => Berita(
        (b['judul'] ?? b['title'] ?? '').toString(),
        (b['sumber'] ?? b['source'] ?? '').toString(),
        (b['waktu'] ?? b['time'] ?? '').toString(),
        (b['tag'] ?? '').toString(),
      );

  @override
  String toString() => 'Berita($judul)';
}

/// Pengumuman singkat di beranda.
@immutable
class Pengumuman {
  const Pengumuman(this.tag, this.judul, this.isi);

  final String tag;
  final String judul;
  final String isi;

  factory Pengumuman.dariBaris(Map<String, dynamic> b) => Pengumuman(
        (b['tag'] ?? '').toString(),
        (b['judul'] ?? b['title'] ?? '').toString(),
        (b['isi'] ?? b['body'] ?? '').toString(),
      );

  @override
  String toString() => 'Pengumuman($tag, $judul)';
}