import 'package:flutter/material.dart';

import '../models/models.dart';

/// Tiga layanan inti KUNBAR. Tidak ada layanan lain - itu keputusan produk.
enum KodeLayanan { jastip, ojek, kurir }

extension KodeLayananX on KodeLayanan {
  String get nama => switch (this) {
        KodeLayanan.jastip => 'Jastip',
        KodeLayanan.ojek => 'Ojek Komunitas',
        KodeLayanan.kurir => 'Kurir',
      };

  String get namaPendek => switch (this) {
        KodeLayanan.jastip => 'Jastip',
        KodeLayanan.ojek => 'Ojek',
        KodeLayanan.kurir => 'Kurir',
      };

  String get deskripsi => switch (this) {
        KodeLayanan.jastip => 'Titip beli barang untuk warga',
        KodeLayanan.ojek => 'Antar jemput warga Kuningan Barat',
        KodeLayanan.kurir => 'Antar paket dan barang',
      };

  String get contoh => switch (this) {
        KodeLayanan.jastip => 'Belanja, obat, makanan',
        KodeLayanan.ojek => 'Kantor, sekolah, pasar',
        KodeLayanan.kurir => 'Paket UMKM, dokumen, makanan',
      };

  Color get warna => switch (this) {
        KodeLayanan.jastip => const Color(0xFF1B5E20),
        KodeLayanan.ojek => const Color(0xFF0D47A1),
        KodeLayanan.kurir => const Color(0xFFF57C00),
      };

  IconData get ikon => switch (this) {
        KodeLayanan.jastip => Icons.shopping_cart_rounded,
        KodeLayanan.ojek => Icons.two_wheeler_rounded,
        KodeLayanan.kurir => Icons.inventory_2_rounded,
      };

  /// Rentang tarif rata-rata (informasi layanan, bukan janji hasil).
  String get tarif => switch (this) {
        KodeLayanan.jastip => 'Rp 8.000 - 15.000',
        KodeLayanan.ojek => 'Rp 8.000 - 25.000',
        KodeLayanan.kurir => 'Rp 10.000 - 20.000',
      };

  int get radiusAwal => switch (this) {
        KodeLayanan.jastip => 3,
        KodeLayanan.ojek => 5,
        KodeLayanan.kurir => 5,
      };

  int get radiusMaks => switch (this) {
        KodeLayanan.jastip => 5,
        KodeLayanan.ojek => 10,
        KodeLayanan.kurir => 10,
      };

  int get feeAwal => switch (this) {
        KodeLayanan.jastip => 5000,
        KodeLayanan.ojek => 8000,
        KodeLayanan.kurir => 10000,
      };

  String get tips => switch (this) {
        KodeLayanan.jastip =>
          'Foto barang saat diterima dan konfirmasi nama barang ke warga. '
              'Kalau barang hilang, Mitra yang kirim foto yang aman.',
        KodeLayanan.ojek =>
          'Warga lokal lebih suka jemput di titik yang jelas. '
              'Tanyakan titik jemput sebelum berangkat.',
        KodeLayanan.kurir =>
          'Konfirmasi penerima sebelum melepas barang. Foto barang saat diterima '
              'menghindarkan sengketa.',
      };

  String get estimasi => switch (this) {
        KodeLayanan.jastip => '20 - 45 menit per order',
        KodeLayanan.ojek => '10 - 25 menit per order',
        KodeLayanan.kurir => '15 - 40 menit per order',
      };

  static KodeLayanan dari(String? v) => KodeLayanan.values.firstWhere(
        (k) => k.name == v,
        orElse: () => KodeLayanan.jastip,
      );
}

/// Pengaturan per layanan (disimpan lokal, siap dikirim ke server).
class PengaturanLayanan {
  const PengaturanLayanan({
    required this.kode,
    required this.aktif,
    required this.radiusKm,
    required this.jamMulai,
    required this.jamSelesai,
    required this.feeMinimum,
    required this.autoTerima,
    required this.prioritas,
  });

  final KodeLayanan kode;
  final bool aktif;
  final int radiusKm;
  final int jamMulai;
  final int jamSelesai;
  final int feeMinimum;
  final bool autoTerima;
  final PrioritasLayanan prioritas;

  PengaturanLayanan salin({
    bool? aktif,
    int? radiusKm,
    int? jamMulai,
    int? jamSelesai,
    int? feeMinimum,
    bool? autoTerima,
    PrioritasLayanan? prioritas,
  }) =>
      PengaturanLayanan(
        kode: kode,
        aktif: aktif ?? this.aktif,
        radiusKm: radiusKm ?? this.radiusKm,
        jamMulai: jamMulai ?? this.jamMulai,
        jamSelesai: jamSelesai ?? this.jamSelesai,
        feeMinimum: feeMinimum ?? this.feeMinimum,
        autoTerima: autoTerima ?? this.autoTerima,
        prioritas: prioritas ?? this.prioritas,
      );

  Map<String, dynamic> toMap() => {
        'kode': kode.name,
        'aktif': aktif,
        'radius_km': radiusKm,
        'jam_mulai': jamMulai,
        'jam_selesai': jamSelesai,
        'fee_minimum': feeMinimum,
        'auto_terima': autoTerima,
        'prioritas': prioritas.name,
      };
}

enum PrioritasLayanan { rendah, normal, tinggi }

extension PrioritasLayananX on PrioritasLayanan {
  String get label => switch (this) {
        PrioritasLayanan.rendah => 'Rendah',
        PrioritasLayanan.normal => 'Normal',
        PrioritasLayanan.tinggi => 'Tinggi',
      };

  static PrioritasLayanan dari(String? v) => PrioritasLayanan.values.firstWhere(
        (p) => p.name == v,
        orElse: () => PrioritasLayanan.normal,
      );
}

/// Statistik nyata per layanan (dihitung dari order selesai).
class StatistikLayanan {
  const StatistikLayanan({
    required this.totalOrder,
    required this.totalPendapatan,
    required this.rataFee,
    required this.rating,
  });

  final int totalOrder;
  final int totalPendapatan;
  final int rataFee;
  final double rating;

  static StatistikLayanan kosong() =>
      const StatistikLayanan(totalOrder: 0, totalPendapatan: 0, rataFee: 0, rating: 0);

  factory StatistikLayanan.hitung(List<Order> order, double rating) {
    final selesai = order.where((o) => o.isDone).toList();
    final total = selesai.fold<int>(0, (a, o) => a + o.fee);
    return StatistikLayanan(
      totalOrder: selesai.length,
      totalPendapatan: total,
      rataFee: selesai.isEmpty ? 0 : total ~/ selesai.length,
      rating: rating,
    );
  }
}