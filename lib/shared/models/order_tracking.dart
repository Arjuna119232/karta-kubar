import 'package:flutter/foundation.dart';

import 'order.dart';

/// Satu titik perjalanan mitra untuk satu order.
///
/// Tabelnya satu untuk jastip dan ojek (`order_tracking`), jadi model ini
/// membawa [jenis] supaya tidak perlu dua class terpisah.
@immutable
class OrderTracking {
  const OrderTracking({
    required this.orderId,
    required this.jenis,
    required this.status,
    required this.catatan,
    required this.dibuat,
    this.id = 0,
    this.lokasi = const TitikPeta(lat: 0, lng: 0),
  });

  factory OrderTracking.dari(Map<String, dynamic> j) => OrderTracking(
        id: bacaBulat(j['id']),
        orderId: bacaTeks(j['order_id']),
        jenis: JenisOrder.dari(bacaTeks(j['order_jenis'])),
        status: bacaTeks(j['status']),
        lokasi: TitikPeta(
          lat: bacaAngka(j['lat']),
          lng: bacaAngka(j['lng']),
        ),
        catatan: bacaTeks(j['catatan']),
        dibuat: bacaWaktu(j['dibuat']),
      );

  final int id;
  final String orderId;
  final JenisOrder jenis;
  final String status;
  final TitikPeta lokasi;
  final String catatan;
  final DateTime dibuat;

  bool get punyaTitik => lokasi.valid;

  Map<String, dynamic> keBaris() => <String, dynamic>{
        'order_id': orderId,
        'order_jenis': jenis.name,
        'status': status,
        'lat': lokasi.lat,
        'lng': lokasi.lng,
        'catatan': catatan,
      };

  @override
  bool operator ==(Object other) =>
      other is OrderTracking && other.id == id && other.dibuat == dibuat;

  @override
  int get hashCode => Object.hash(id, dibuat);
}

/// Hasil rute dari server routing (OSRM).
///
/// Dipakai untuk estimasi tarif dan ETA. Kalau server tidak bisa dihubungi,
/// [jarakKm] diisi dari haversine dan [dariServer] bernilai false supaya UI
/// bisa jujur membedakan "estimasi kasar" dari "rute asli".
@immutable
class Rute {
  const Rute({
    required this.jarakKm,
    required this.durasiMenit,
    required this.dariServer,
    this.polyline,
    this.garis,
  });

  /// Rute cadangan: hanya jarak lurus.
  factory Rute.estimasi(double km) => Rute(
        jarakKm: km,
        durasiMenit: km <= 0 ? 0 : (km / 18 * 60).round(),
        dariServer: false,
      );

  factory Rute.dariServer({
    required double jarakKm,
    required int durasiMenit,
    String? polyline,
    List<TitikPeta>? garis,
  }) =>
      Rute(
        jarakKm: jarakKm,
        durasiMenit: durasiMenit,
        dariServer: true,
        polyline: polyline,
        garis: garis,
      );

  final double jarakKm;
  final int durasiMenit;
  final bool dariServer;
  final String? polyline;

  /// Titik-titik garis rute jalan (sudah diringkas). null bila rute berasal
  /// dari perkiraan garis lurus.
  final List<TitikPeta>? garis;

  String get jarakTeks => jarakKm <= 0
      ? 'belum dihitung'
      : jarakKm < 1
          ? '${(jarakKm * 1000).round()} m'
          : '${jarakKm.toStringAsFixed(1)} km';

  String get durasiTeks {
    if (durasiMenit <= 0) return 'belum dihitung';
    if (durasiMenit < 60) return '$durasiMenit menit';
    final int jam = durasiMenit ~/ 60;
    final int sisa = durasiMenit % 60;
    return sisa == 0 ? '$jam jam' : '$jam jam $sisa menit';
  }
}