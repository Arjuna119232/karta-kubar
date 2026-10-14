import 'package:flutter/foundation.dart';

/// Kartu anggota yang tampil di halaman Profil.
@immutable
class Anggota {
  const Anggota({
    required this.nama,
    required this.peran,
    required this.divisi,
    required this.nomorAnggota,
    required this.poin,
    required this.totalKegiatan,
  });

  final String nama;
  final String peran;
  final String divisi;
  final String nomorAnggota;
  final int poin;
  final int totalKegiatan;

  /// Nilai cadangan saat data gagal dimuat - layar TIDAK boleh kosong total,
  /// tapi juga tidak boleh menampilkan data photosynthetic yang tidak ada.
  static const Anggota kosong = Anggota(
    nama: 'Warga Kuningan Barat',
    peran: 'warga',
    divisi: '-',
    nomorAnggota: '-',
    poin: 0,
    totalKegiatan: 0,
  );

  factory Anggota.dariBaris(Map<String, dynamic> b) => Anggota(
        nama: (b['nama'] ?? b['display_name'] ?? '').toString(),
        peran: (b['peran'] ?? b['role'] ?? 'warga').toString(),
        divisi: (b['divisi'] ?? '').toString(),
        nomorAnggota: (b['nomor_anggota'] ?? b['member_id'] ?? '').toString(),
        poin: int.tryParse('${b['poin'] ?? 0}') ?? 0,
        totalKegiatan: int.tryParse('${b['total_kegiatan'] ?? 0}') ?? 0,
      );
}
