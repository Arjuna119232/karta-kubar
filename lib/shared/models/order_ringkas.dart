import 'package:flutter/foundation.dart';

import 'order.dart';
import 'order_jastip.dart';
import 'order_ojek.dart';

/// Tampilan seragam untuk dua jenis order.
///
/// Layar (riwayat, daftar, beranda) tidak perlu tahu bedanya: cukup baca
/// [jenis], [ringkas], [status], [tarif]. Layar detail dan form tetap memakai
/// model aslinya supaya kuat tipe.
@immutable
class OrderRingkas {
  const OrderRingkas({
    required this.jenis,
    required this.id,
    required this.kode,
    required this.status,
    required this.tarif,
    required this.dibuat,
    required this.ringkas,
    required this.asal,
  });

  factory OrderRingkas.dariJastip(OrderJastip o) => OrderRingkas(
        jenis: JenisOrder.jastip,
        id: o.id,
        kode: o.kode,
        status: o.status,
        tarif: o.tarif,
        dibuat: o.dibuat,
        ringkas: o.ringkas,
        asal: o,
      );

  factory OrderRingkas.dariOjek(OrderOjek o) => OrderRingkas(
        jenis: JenisOrder.ojek,
        id: o.id,
        kode: o.kode,
        status: o.status,
        tarif: o.tarif,
        dibuat: o.dibuat,
        ringkas: o.ringkas,
        asal: o,
      );

  /// Bentuk baris database, untuk dipakai layer penyimpanan bersama.
  factory OrderRingkas.dariBaris(JenisOrder jenis, Map<String, dynamic> baris) =>
      jenis == JenisOrder.ojek
          ? OrderRingkas.dariOjek(OrderOjek.dari(baris))
          : OrderRingkas.dariJastip(OrderJastip.dari(baris));

  final JenisOrder jenis;
  final String id;
  final String kode;
  final StatusOrder status;
  final double tarif;
  final DateTime dibuat;
  final String ringkas;

  /// Objek aslinya: `OrderJastip` atau `OrderOjek`.
  final Object asal;

  bool get aktif => status.aktif;

  OrderJastip? get sebagaiJastip =>
      asal is OrderJastip ? asal as OrderJastip : null;

  OrderOjek? get sebagaiOjek => asal is OrderOjek ? asal as OrderOjek : null;

  /// Ringkas + status + tanggal, untuk card di daftar.
  String get judulBaris {
    if (ringkas.trim().isEmpty) return kode.isEmpty ? jenis.label : kode;
    return '$kode · $ringkas'.trim();
  }
}
