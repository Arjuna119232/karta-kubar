import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/order.dart';
import '../../../shared/widgets/app_icon.dart';

/// Kategori mitra usaha, dinamai mengikuti tag OpenStreetMap supaya data
/// dan kode memakai istilah yang sama. Satu mitra bisa punya lebih dari
/// satu kategori, misalnya toko roti yang sekaligus jualan apotek bukan --
/// warung yang menjual rokok pun tetap warungKelontong.
enum KategoriMitraUsaha {
  warungKelontong,
  tokoRoti,
  pasar,
  spbu,
  apotek;

  static KategoriMitraUsaha dari(String nilai) =>
      KategoriMitraUsaha.values.firstWhere(
        (KategoriMitraUsaha k) => k.name == nilai,
        orElse: () => KategoriMitraUsaha.warungKelontong,
      );

  String get label => switch (this) {
        KategoriMitraUsaha.warungKelontong => 'Warung Kelontong',
        KategoriMitraUsaha.tokoRoti => 'Toko Roti',
        KategoriMitraUsaha.pasar => 'Pasar',
        KategoriMitraUsaha.spbu => 'SPBU',
        KategoriMitraUsaha.apotek => 'Apotek',
      };

  /// Nama pendek untuk filter chip.
  String get labelPendek => switch (this) {
        KategoriMitraUsaha.warungKelontong => 'Warung',
        KategoriMitraUsaha.tokoRoti => 'Roti',
        KategoriMitraUsaha.pasar => 'Pasar',
        KategoriMitraUsaha.spbu => 'SPBU',
        KategoriMitraUsaha.apotek => 'Apotek',
      };

  /// Ikon memakai set ikon aplikasi sendiri (`Ik`), bukan ikon Material,
  /// supaya tampilan satu bahasa dengan seluruh aplikasi.
  Ik get ikon => switch (this) {
        KategoriMitraUsaha.warungKelontong => Ik.cart,
        KategoriMitraUsaha.tokoRoti => Ik.bread,
        KategoriMitraUsaha.pasar => Ik.basket,
        KategoriMitraUsaha.spbu => Ik.pump,
        KategoriMitraUsaha.apotek => Ik.pill,
      };

  /// Warna penanda peta dan lencana. Hijau brand dipakai untuk warung,
  /// warna lain hanya untuk membedakan kategori saat melihat peta.
  Color get warna => switch (this) {
        KategoriMitraUsaha.warungKelontong => AppColors.primary,
        KategoriMitraUsaha.tokoRoti => const Color(0xFFB45309),
        KategoriMitraUsaha.pasar => const Color(0xFFF57C00),
        KategoriMitraUsaha.spbu => const Color(0xFFEF4444),
        KategoriMitraUsaha.apotek => const Color(0xFF00897B),
      };

  /// Kata kunci untuk pencarian sederhana (tanpa server).
  List<String> get kataKunci => switch (this) {
        KategoriMitraUsaha.warungKelontong => const <String>[
            'warung',
            'kelontong',
            'sembako',
          ],
        KategoriMitraUsaha.tokoRoti => const <String>[
            'roti',
            'bakery',
            'kue',
            'martabak',
          ],
        KategoriMitraUsaha.pasar => const <String>[
            'pasar',
            'sayur',
            'dagang',
            'kaget',
          ],
        KategoriMitraUsaha.spbu => const <String>[
            'spbu',
            'bensin',
            'pertamina',
            'shell',
            'premium',
            'solar',
          ],
        KategoriMitraUsaha.apotek => const <String>[
            'apotek',
            'obat',
            'farmasi',
            'kimia farma',
          ],
      };
}

/// Kelurahan yang dipakai filter dan kartu.
@immutable
class Kelurahan {
  const Kelurahan(this.nama);

  final String nama;

  static const Kelurahan kuninganBarat = Kelurahan('Kuningan Barat');
  static const Kelurahan tegalParang = Kelurahan('Tegal Parang');
  static const Kelurahan pelaMampang = Kelurahan('Pela Mampang');
  static const Kelurahan mampangPrapatan = Kelurahan('Mampang Prapatan');
  static const Kelurahan bangka = Kelurahan('Bangka');

  static const List<Kelurahan> semua = <Kelurahan>[
    kuninganBarat,
    tegalParang,
    pelaMampang,
    bangka,
    mampangPrapatan,
  ];

  static Kelurahan dari(String nama) => semua.firstWhere(
        (Kelurahan k) => k.nama == nama,
        orElse: () => mampangPrapatan,
      );
}

/// Satu barang yang biasa dibeli. Harga masih perkiraan.
@immutable
class ProdukUsaha {
  const ProdukUsaha(this.nama, {this.hargaKira});

  final String nama;

  /// Perkiraan harga (Rp). Null berarti harganya berubah-ubah.
  final int? hargaKira;

  String get hargaTeks =>
      hargaKira == null ? 'Harga menyesuaikan' : 'perkiraan ${rupiah(hargaKira!)}';
}

/// Satu mitra usaha: warung, toko roti, pasar, SPBU, atau apotek.
@immutable
class MitraUsaha {
  const MitraUsaha({
    required this.id,
    required this.nama,
    required this.kategori,
    required this.alamat,
    required this.kelurahan,
    required this.fitur,
    required this.titik,
    required this.jamBuka,
    this.noHp,
    this.rating = 0,
    this.layanan = const <String>[],
    this.info,
    this.titikPerkiraan = false,
  });

  final String id;
  final String nama;
  final List<KategoriMitraUsaha> kategori;
  final String alamat;
  final Kelurahan kelurahan;
  final String fitur;
  final TitikPeta titik;

  /// Contoh: `06:00 - 22:00` atau `24 jam`.
  final String jamBuka;

  /// Tidak satu pun mitra punya nomor telepon yang sudah pasti, jadi null
  /// sampai data asli masuk. Tombol telepon disembunyikan kalau null.
  final String? noHp;

  final double rating;

  /// Layanan tambahan, mis. "Isi ulang 12 kg & 50 kg".
  final List<String> layanan;

  /// Catatan singkat, mis. "Pasar terdekat dari Kuningan Barat".
  final String? info;

  /// Benar kalau titik peta ini persis koordinat yang diberikan warga. Kalau
  /// false, alamatnya benar tapi titiknya masih titik jalan (hasil geocode)
  /// atau perkiraan lama - aplikasi wajib jujur soal ini.
  final bool titikPerkiraan;

  bool get is24Jam => jamBuka.toLowerCase().contains('24');

  /// True kalau jam buka benar-benar berasal dari warga atau catatan warga.
  /// Kalau belum, aplikasi TIDAK menampilkan lencana "buka sekarang"/
  /// "tutup sekarang": menebak jam buka sama dengan mengarang data.
  bool get jamBukaPasti =>
      is24Jam || RegExp(r'\d{2}:\d{2}\s*-\s*\d{2}:\d{2}').hasMatch(jamBuka);

  /// Apakah masih buka sekarang. Pasar yang jam bukanya tidak lengkap
  /// dianggap buka supaya tidak salah menutup warup.
  bool get isOpen {
    if (is24Jam) return true;
    final List<String> bagian = jamBuka.split('-');
    if (bagian.length != 2) return true;
    final DateTime? mulai = _jam(bagian.first);
    final DateTime? selesai = _jam(bagian.last);
    if (mulai == null || selesai == null) return true;
    final DateTime sekarang = DateTime.now();
    final int menit = sekarang.hour * 60 + sekarang.minute;
    final int a = mulai.hour * 60 + mulai.minute;
    final int b = selesai.hour * 60 + selesai.minute;
    return b <= a ? menit >= a || menit <= b : menit >= a && menit <= b;
  }

  /// Jarak lurus dari pusat Kuningan Barat (km).
  double get jarakDariPusatKm => jarakKm(titikKuninganBarat, titik);

  /// Alamat satu baris yang dipakai form jastip.
  String get lokasiBeliTeks => '$nama, $alamat';

  /// Semua kata yang bisa dicari: nama, alamat, kelurahan, fitur, kategori.
  String get kataKunciLc => <String>[
        nama,
        alamat,
        kelurahan.nama,
        fitur,
        ...kategori.map((KategoriMitraUsaha k) => k.label),
        ...kategori.expand((KategoriMitraUsaha k) => k.kataKunci),
      ].join(' ')
          .toLowerCase();

  /// Kategori utama: dipakai saat hanya satu kategori yang perlu tampil.
  KategoriMitraUsaha get kategoriUtama => kategori.first;

  static DateTime? _jam(String teks) {
    final List<String> p = teks.trim().split(':');
    if (p.length < 2) return null;
    final int? jam = int.tryParse(p.first.trim());
    final int? menit = int.tryParse(p.last.trim());
    if (jam == null || menit == null) return null;
    return DateTime(2020, 1, 1, jam, menit);
  }
}