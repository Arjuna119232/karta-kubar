import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/order.dart';
import '../../../shared/widgets/app_icon.dart';

/// Kategori mitra usaha. Satu mitra bisa punya lebih dari satu kategori,
/// misalnya agen gas yang sekaligus menjual galon air.
enum KategoriMitraUsaha {
  warungKelontong,
  warungMadura,
  pasar,
  agenGas,
  galonAir;

  static KategoriMitraUsaha dari(String nilai) =>
      KategoriMitraUsaha.values.firstWhere(
        (KategoriMitraUsaha k) => k.name == nilai,
        orElse: () => KategoriMitraUsaha.warungKelontong,
      );

  String get label => switch (this) {
        KategoriMitraUsaha.warungKelontong => 'Warung Kelontong',
        KategoriMitraUsaha.warungMadura => 'Warung Madura',
        KategoriMitraUsaha.pasar => 'Pasar',
        KategoriMitraUsaha.agenGas => 'Agen Gas',
        KategoriMitraUsaha.galonAir => 'Galon Air',
      };

  /// Nama pendek untuk filter chip.
  String get labelPendek => switch (this) {
        KategoriMitraUsaha.warungKelontong => 'Warung',
        KategoriMitraUsaha.warungMadura => 'Madura',
        KategoriMitraUsaha.pasar => 'Pasar',
        KategoriMitraUsaha.agenGas => 'Gas',
        KategoriMitraUsaha.galonAir => 'Air',
      };

  /// Ikon memakai set ikon aplikasi sendiri (`Ik`), bukan ikon Material,
  /// supaya tampilan satu bahasa dengan seluruh aplikasi.
  Ik get ikon => switch (this) {
        KategoriMitraUsaha.warungKelontong => Ik.cart,
        KategoriMitraUsaha.warungMadura => Ik.shop,
        KategoriMitraUsaha.pasar => Ik.basket,
        KategoriMitraUsaha.agenGas => Ik.flame,
        KategoriMitraUsaha.galonAir => Ik.drop,
      };

  /// Warna penanda peta dan lencana. Hijau brand dipakai untuk warung,
  /// warna lain hanya untuk membedakan kategori saat melihat peta.
  Color get warna => switch (this) {
        KategoriMitraUsaha.warungKelontong => AppColors.primary,
        KategoriMitraUsaha.warungMadura => const Color(0xFF0D3D11),
        KategoriMitraUsaha.pasar => const Color(0xFFF57C00),
        KategoriMitraUsaha.agenGas => const Color(0xFFEF4444),
        KategoriMitraUsaha.galonAir => AppColors.accent,
      };

  /// Kata kunci untuk pencarian sederhana (tanpa server).
  List<String> get kataKunci => switch (this) {
        KategoriMitraUsaha.warungKelontong => const <String>[
            'warung',
            'kelontong',
            'sembako',
          ],
        KategoriMitraUsaha.warungMadura => const <String>[
            'warung',
            'madura',
            'sembako',
            '24 jam',
          ],
        KategoriMitraUsaha.pasar => const <String>[
            'pasar',
            'sayur',
            'dagang',
            'kaget',
          ],
        KategoriMitraUsaha.agenGas => const <String>[
            'gas',
            'elpiji',
            'refill',
            'blue gaz',
          ],
        KategoriMitraUsaha.galonAir => const <String>[
            'galon',
            'air',
            'aqua',
            'cleo',
            'mineral',
            'minum',
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

/// Satu mitra usaha: warung, pasar, agen gas, atau depot air minum.
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

  bool get is24Jam => jamBuka.toLowerCase().contains('24');

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