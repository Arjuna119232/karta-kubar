import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Jenis order yang ditangani aplikasi warga, mitra, dan web.
enum JenisOrder {
  /// Jasa titip: belanja barang di tempat lain, lalu diantar ke warga.
  jastip,

  /// Ojek komunitas: antar-jemput di dalam kelurahan.
  ojek;

  static JenisOrder dari(String? nilai) => JenisOrder.values.firstWhere(
        (JenisOrder j) => j.name == nilai,
        orElse: () => JenisOrder.jastip,
      );

  String get label => this == JenisOrder.jastip ? 'Jastip' : 'Ojek';

  String get labelJamak =>
      this == JenisOrder.jastip ? 'Jasa Titip' : 'Ojek Komunitas';
}

/// Status order. SATU daftar untuk jastip dan ojek supaya tiga aplikasi
/// tidak punya kosakata status yang berbeda.
///
/// Alur: menunggu -> diterima -> diproses -> dalam perjalanan -> selesai.
/// `batal` dipakai warga, `dibatalkan` dipakai mitra atau pengelola.
enum StatusOrder {
  menunggu,
  diterima,
  diproses,
  dalamPerjalanan,
  selesai,
  batal,
  dibatalkan;

  static StatusOrder dari(String? nilai) => StatusOrder.values.firstWhere(
        (StatusOrder s) => s.name == nilai,
        orElse: () => StatusOrder.menunggu,
      );

  String get label => switch (this) {
        StatusOrder.menunggu => 'Menunggu mitra',
        StatusOrder.diterima => 'Diterima mitra',
        StatusOrder.diproses => 'Sedang dikerjakan',
        StatusOrder.dalamPerjalanan => 'Dalam perjalanan',
        StatusOrder.selesai => 'Selesai',
        StatusOrder.batal => 'Dibatalkan warga',
        StatusOrder.dibatalkan => 'Dibatalkan mitra',
      };

  /// Status yang masih berjalan: perlu tampil di "Order Aktif".
  bool get aktif => this != StatusOrder.selesai &&
      this != StatusOrder.batal &&
      this != StatusOrder.dibatalkan;

  /// Urutan untuk timeline (0 berarti belum terjadi / dibatalkan).
  int get urutan => switch (this) {
        StatusOrder.menunggu => 1,
        StatusOrder.diterima => 2,
        StatusOrder.diproses => 3,
        StatusOrder.dalamPerjalanan => 4,
        StatusOrder.selesai => 5,
        StatusOrder.batal => 0,
        StatusOrder.dibatalkan => 0,
      };

  /// Boleh warga membatalkan sendiri? Hanya sebelum mitra mulai bekerja.
  bool get bisaDibatalWarga =>
      this == StatusOrder.menunggu || this == StatusOrder.diterima;

  /// Boleh masih ada aksi operasional di sisi mitra.
  bool get bisaDiotorasi =>
      this == StatusOrder.diterima ||
      this == StatusOrder.diproses ||
      this == StatusOrder.dalamPerjalanan;

  static StatusOrder berikutnya(StatusOrder sekarang) => switch (sekarang) {
        StatusOrder.menunggu => StatusOrder.diterima,
        StatusOrder.diterima => StatusOrder.diproses,
        StatusOrder.diproses => StatusOrder.dalamPerjalanan,
        StatusOrder.dalamPerjalanan => StatusOrder.selesai,
        StatusOrder.selesai => StatusOrder.selesai,
        StatusOrder.batal => StatusOrder.batal,
        StatusOrder.dibatalkan => StatusOrder.dibatalkan,
      };
}

/// Cara bayar. QRIS belum ada (butuh akun merchant), jadi sekarang CASH saja.
enum MetodeBayar {
  cash,
  qris;

  static MetodeBayar dari(String? nilai) => MetodeBayar.values.firstWhere(
        (MetodeBayar m) => m.name == nilai,
        orElse: () => MetodeBayar.cash,
      );

  String get label =>
      this == MetodeBayar.cash ? 'Tunai (bayar ke mitra)' : 'QRIS';
}

/// Satu koordinat WGS84.
@immutable
class TitikPeta {
  const TitikPeta({required this.lat, required this.lng});

  factory TitikPeta.dari(Object? nilai) {
    if (nilai is! Map) return const TitikPeta(lat: 0, lng: 0);
    return TitikPeta(
      lat: bacaAngka(nilai['lat']),
      lng: bacaAngka(nilai['lng']),
    );
  }

  final double lat;
  final double lng;

  bool get valid => lat != 0 || lng != 0;

  /// Bahasa manusia supaya tidak tampil "null" di UI.
  String get teks => valid
      ? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'
      : 'Belum ada';

  Map<String, dynamic> keJson() => <String, dynamic>{'lat': lat, 'lng': lng};

  @override
  bool operator ==(Object lain) =>
      lain is TitikPeta && lain.lat == lat && lain.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);
}

/// Hitung jarak dua titik dalam kilometer (rumus haversine).
///
/// Dipakai sebagai cadangan ketika server rute tidak bisa dihubungi, dan untuk
/// estimasi tarif SEBELUM rute dihitung.
double jarakKm(TitikPeta a, TitikPeta b) {
  if (!a.valid || !b.valid) return 0;
  const double r = 6371.0; // jari-jari bumi dalam km
  final double dLat = _rad(b.lat - a.lat);
  final double dLng = _rad(b.lng - a.lng);
  final double h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_rad(a.lat)) * math.cos(_rad(b.lat)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(h.clamp(0.0, 1.0)));
}

double _rad(double derajat) => derajat * math.pi / 180.0;

// ------------------------------------------------------------ pembaca nilai

/// Kolom `numeric` di Postgres sering kembali sebagai String. Tanpa pembaca
/// angka ini, nilai yang sebenarnya ada bisa terbaca nol.
double bacaAngka(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

int bacaBulat(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

String bacaTeks(Object? v) => v?.toString() ?? '';

DateTime bacaWaktu(Object? v) =>
    DateTime.tryParse(v?.toString() ?? '')?.toLocal() ?? DateTime.now();

/// Waktu yang boleh null (mis. `diterima_at` yang belum terjadi).
DateTime? bacaWaktuOpsional(Object? v) {
  if (v == null) return null;
  final DateTime? w = DateTime.tryParse(v.toString());
  return w?.toLocal();
}

bool bacaBenar(Object? v) => v == true || v == 'true' || v == 1;

/// Angka uang untuk tampilan: `12500` -> `Rp12.500`.
String rupiah(num nilai) {
  final int bulat = nilai.round();
  final String s = bulat.abs().toString();
  final StringBuilder out = StringBuilder(bulat < 0 ? '-Rp' : 'Rp');
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write('.');
    out.write(s[i]);
  }
  return out.toString();
}

/// Jarak dalam bahasa manusia: `0.8 km`, `450 m`.
String jarakPendek(double km) {
  if (km <= 0) return 'jarak belum dihitung';
  if (km < 1) return '${(km * 1000).round()} m';
  return '${km.toStringAsFixed(1)} km';
}