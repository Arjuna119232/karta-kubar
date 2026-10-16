import 'package:flutter/foundation.dart';

import 'order.dart';

/// Order ojek komunitas (antar-jemput di dalam kelurahan).
@immutable
class OrderOjek {
  const OrderOjek({
    required this.id,
    required this.kode,
    required this.wargaKunci,
    required this.wargaNama,
    required this.wargaNomor,
    required this.lokasiJemput,
    required this.lokasiTujuan,
    required this.catatan,
    required this.tarif,
    required this.status,
    required this.metodeBayar,
    required this.dibuat,
    this.wargaId,
    this.mitraId,
    this.latJemput = 0,
    this.lngJemput = 0,
    this.latTujuan = 0,
    this.lngTujuan = 0,
    this.jarakKm = 0,
    this.durasiMenit,
    this.alasanBatal = '',
    this.diterimaAt,
    this.dijemputAt,
    this.dikirimAt,
    this.selesaiAt,
  });

  factory OrderOjek.dari(Map<String, dynamic> j) => OrderOjek(
        id: bacaTeks(j['id']),
        kode: bacaTeks(j['kode']),
        wargaKunci: bacaTeks(j['warga_kunci']),
        wargaNama: bacaTeks(j['warga_nama']),
        wargaNomor: bacaTeks(j['warga_nomor']),
        wargaId: j['warga_id']?.toString(),
        mitraId: j['mitra_id']?.toString(),
        lokasiJemput: bacaTeks(j['lokasi_jemput']),
        latJemput: bacaAngka(j['lat_jemput']),
        lngJemput: bacaAngka(j['lng_jemput']),
        lokasiTujuan: bacaTeks(j['lokasi_tujuan']),
        latTujuan: bacaAngka(j['lat_tujuan']),
        lngTujuan: bacaAngka(j['lng_tujuan']),
        jarakKm: bacaAngka(j['jarak_km']),
        durasiMenit: j['durasi_menit'] == null ? null : bacaBulat(j['durasi_menit']),
        tarif: bacaAngka(j['tarif']),
        catatan: bacaTeks(j['catatan']),
        metodeBayar: MetodeBayar.dari(j['metode_bayar']?.toString()),
        status: StatusOrder.dari(bacaTeks(j['status'])),
        alasanBatal: bacaTeks(j['alasan_batal']),
        dibuat: bacaWaktu(j['dibuat']),
        diterimaAt: bacaWaktuOpsional(j['diterima_at']),
        dijemputAt: bacaWaktuOpsional(j['dijemput_at']),
        dikirimAt: bacaWaktuOpsional(j['dikirim_at']),
        selesaiAt: bacaWaktuOpsional(j['selesai_at']),
      );

  final String id;
  final String kode;
  final String wargaKunci;
  final String wargaNama;
  final String wargaNomor;
  final String? wargaId;
  final String? mitraId;
  final String lokasiJemput;
  final double latJemput;
  final double lngJemput;
  final String lokasiTujuan;
  final double latTujuan;
  final double lngTujuan;
  final double jarakKm;
  final int? durasiMenit;
  final double tarif;
  final String catatan;
  final MetodeBayar metodeBayar;
  final StatusOrder status;
  final String alasanBatal;
  final DateTime dibuat;
  final DateTime? diterimaAt;
  final DateTime? dijemputAt;
  final DateTime? dikirimAt;
  final DateTime? selesaiAt;

  static const JenisOrder jenis = JenisOrder.ojek;
  static const String tabel = 'order_ojek';

  TitikPeta get titikJemput => TitikPeta(lat: latJemput, lng: lngJemput);
  TitikPeta get titikTujuan => TitikPeta(lat: latTujuan, lng: lngTujuan);

  /// Ringkasan satu baris untuk daftar: "Rumah -> Pasar".
  String get ringkas =>
      '${lokasiJemput.isEmpty ? 'Lokasi jemput' : lokasiJemput} -> ${lokasiTujuan.isEmpty ? 'tujuan' : lokasiTujuan}';

  /// Estimasi tiba, dipakai di layar tracking.
  DateTime? get estimasiTiba {
    if (durasiMenit == null || durasiMenit! <= 0) return null;
    return dibuat.add(Duration(minutes: durasiMenit!));
  }

  OrderOjek salin({
    String? id,
    String? kode,
    String? mitraId,
    double? tarif,
    double? jarakKm,
    int? durasiMenit,
    StatusOrder? status,
    String? alasanBatal,
    DateTime? diterimaAt,
    DateTime? dijemputAt,
    DateTime? dikirimAt,
    DateTime? selesaiAt,
  }) =>
      OrderOjek(
        id: id ?? this.id,
        kode: kode ?? this.kode,
        wargaKunci: wargaKunci,
        wargaNama: wargaNama,
        wargaNomor: wargaNomor,
        wargaId: wargaId,
        mitraId: mitraId ?? this.mitraId,
        lokasiJemput: lokasiJemput,
        latJemput: latJemput,
        lngJemput: lngJemput,
        lokasiTujuan: lokasiTujuan,
        latTujuan: latTujuan,
        lngTujuan: lngTujuan,
        jarakKm: jarakKm ?? this.jarakKm,
        durasiMenit: durasiMenit ?? this.durasiMenit,
        tarif: tarif ?? this.tarif,
        catatan: catatan,
        metodeBayar: metodeBayar,
        status: status ?? this.status,
        alasanBatal: alasanBatal ?? this.alasanBatal,
        dibuat: dibuat,
        diterimaAt: diterimaAt ?? this.diterimaAt,
        dijemputAt: dijemputAt ?? this.dijemputAt,
        dikirimAt: dikirimAt ?? this.dikirimAt,
        selesaiAt: selesaiAt ?? this.selesaiAt,
      );

  Map<String, dynamic> keBaris() => <String, dynamic>{
        if (id.isNotEmpty) 'id': id,
        'kode': kode,
        'warga_kunci': wargaKunci,
        'warga_nama': wargaNama,
        'warga_nomor': wargaNomor,
        if (mitraId != null && mitraId!.isNotEmpty) 'mitra_id': mitraId,
        'lokasi_jemput': lokasiJemput,
        'lat_jemput': latJemput,
        'lng_jemput': lngJemput,
        'lokasi_tujuan': lokasiTujuan,
        'lat_tujuan': latTujuan,
        'lng_tujuan': lngTujuan,
        'jarak_km': jarakKm,
        if (durasiMenit != null) 'durasi_menit': durasiMenit,
        'tarif': tarif,
        'catatan': catatan,
        'metode_bayar': metodeBayar.name,
        'status': status.name,
        'alasan_batal': alasanBatal,
      };

  @override
  bool operator ==(Object other) => other is OrderOjek && other.id == id;

  @override
  int get hashCode => id.hashCode;
}