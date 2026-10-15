import 'package:flutter/material.dart';

import '../../../shared/widgets/app_icon.dart';

/// Kategori usaha warga. Namanya sama persis dengan nilai yang diterima
/// database (kolom `kategori` di tabel `umkm`).
enum KategoriUmkm { makanan, minuman, fesyen, jasa, kerajinan, lain }

extension KategoriUmkmX on KategoriUmkm {
  String get label => switch (this) {
        KategoriUmkm.makanan => 'Makanan',
        KategoriUmkm.minuman => 'Minuman',
        KategoriUmkm.fesyen => 'Fesyen',
        KategoriUmkm.jasa => 'Jasa',
        KategoriUmkm.kerajinan => 'Kerajinan',
        KategoriUmkm.lain => 'Lainnya',
      };

  Ik get ikon => switch (this) {
        KategoriUmkm.makanan => Ik.broom,
        KategoriUmkm.minuman => Ik.drop,
        KategoriUmkm.fesyen => Ik.gallery,
        KategoriUmkm.jasa => Ik.handHeart,
        KategoriUmkm.kerajinan => Ik.trophy,
        KategoriUmkm.lain => Ik.groups,
      };

  static KategoriUmkm fromDb(String? v) => KategoriUmkm.values.firstWhere(
        (KategoriUmkm k) => k.name == v,
        orElse: () => KategoriUmkm.lain,
      );
}

/// Satu usaha milik warga.
@immutable
class Umkm {
  const Umkm({
    required this.id,
    required this.nama,
    required this.kategori,
    required this.deskripsi,
    required this.alamat,
    this.noTelepon,
    this.jamBuka,
    this.diverifikasi = false,
    this.contoh = false,
  });

  factory Umkm.dariBaris(Map<String, dynamic> b) => Umkm(
        id: (b['id'] ?? '').toString(),
        nama: (b['nama'] ?? '').toString(),
        kategori: KategoriUmkmX.fromDb(b['kategori']?.toString()),
        deskripsi: (b['deskripsi'] ?? '').toString(),
        alamat: (b['alamat'] ?? '').toString(),
        noTelepon: b['no_telepon']?.toString(),
        jamBuka: b['jam_buka']?.toString(),
        diverifikasi: b['diverifikasi'] == true,
        contoh: b['contoh'] == true,
      );

  Map<String, dynamic> keBaris() => <String, dynamic>{
        if (id.startsWith('umkm-')) 'id': id,
        'nama': nama,
        'kategori': kategori.name,
        'deskripsi': deskripsi,
        'alamat': alamat,
        if (noTelepon != null) 'no_telepon': noTelepon,
        if (jamBuka != null) 'jam_buka': jamBuka,
        'contoh': contoh,
      };

  final String id;
  final String nama;
  final KategoriUmkm kategori;
  final String deskripsi;
  final String alamat;
  final String? noTelepon;
  final String? jamBuka;

  /// Hanya pengurus yang bisa menyalakan ini (lewat panel web).
  final bool diverifikasi;

  /// Baris bawaan aplikasi, bukan data nyata warga.
  final bool contoh;

  Umkm denganVerifikasi(bool v) => Umkm(
        id: id,
        nama: nama,
        kategori: kategori,
        deskripsi: deskripsi,
        alamat: alamat,
        noTelepon: noTelepon,
        jamBuka: jamBuka,
        diverifikasi: v,
        contoh: contoh,
      );

  @override
  bool operator ==(Object other) =>
      other is Umkm && other.id == id && other.nama == nama;

  @override
  int get hashCode => Object.hash(id, nama);

  @override
  String toString() => 'Umkm($nama, ${kategori.name})';
}