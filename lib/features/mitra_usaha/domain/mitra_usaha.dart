import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/order.dart';
import '../../../shared/widgets/app_icon.dart';

/// Jenis mitra usaha yang bisa jadi tujuan titip belanja (jastip).
enum JenisMitraUsaha { warung, pasar, agenGas, galon }

extension JenisMitraUsahaX on JenisMitraUsaha {
  String get label => switch (this) {
        JenisMitraUsaha.warung => 'Warung',
        JenisMitraUsaha.pasar => 'Pasar',
        JenisMitraUsaha.agenGas => 'Agen Gas',
        JenisMitraUsaha.galon => 'Galon Air',
      };

  Ik get ikon => switch (this) {
        JenisMitraUsaha.warung => Ik.cart,
        JenisMitraUsaha.pasar => Ik.package,
        JenisMitraUsaha.agenGas => Ik.motorcycle,
        JenisMitraUsaha.galon => Ik.drop,
      };

  Color get warna => switch (this) {
        JenisMitraUsaha.warung => AppColors.primary,
        JenisMitraUsaha.pasar => AppColors.warning,
        JenisMitraUsaha.agenGas => AppColors.error,
        JenisMitraUsaha.galon => AppColors.accent,
      };
}

/// Satu barang yang biasa dibeli di mitra usaha. Harga hanya perkiraan.
@immutable
class ProdukUsaha {
  const ProdukUsaha(this.nama, {this.hargaKira});

  final String nama;

  /// Perkiraan harga (Rp). null = harga bervariasi.
  final int? hargaKira;
}

/// Satu mitra usaha (warung, pasar, agen gas, depot galon).
@immutable
class MitraUsaha {
  const MitraUsaha({
    required this.id,
    required this.nama,
    required this.jenis,
    required this.alamat,
    required this.titik,
    required this.deskripsi,
    required this.jamBuka,
    this.telepon,
    this.produk = const <ProdukUsaha>[],
    this.contoh = true,
  });

  final String id;
  final String nama;
  final JenisMitraUsaha jenis;
  final String alamat;
  final TitikPeta titik;
  final String deskripsi;
  final String jamBuka;
  final String? telepon;
  final List<ProdukUsaha> produk;

  /// true = data contoh (lokasi dan harga perkiraan), belum dari server.
  final bool contoh;

  /// Jarak lurus dari pusat Kuningan Barat (km).
  double get jarakDariPusatKm => jarakKm(titikKuninganBarat, titik);

  /// Teks lokasi beli yang diisikan ke form jastip.
  String get lokasiBeliTeks => '$nama, $alamat';
}
