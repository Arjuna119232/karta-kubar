import 'package:flutter/foundation.dart';

import 'order.dart';

/// Order jasa titip.
///
/// Sengaja tanpa dependensi Flutter selain `foundation`, supaya file yang sama
/// bisa dipakai APK Mitra dan web admin tanpa perubahan.
@immutable
class OrderJastip {
  const OrderJastip({
    required this.id,
    required this.kode,
    required this.wargaKunci,
    required this.wargaNama,
    required this.wargaNomor,
    required this.barang,
    required this.qty,
    required this.lokasiBeli,
    required this.alamatAntar,
    required this.catatan,
    required this.tarif,
    required this.status,
    required this.metodeBayar,
    required this.dibuat,
    this.wargaId,
    this.mitraId,
    this.latBeli = 0,
    this.lngBeli = 0,
    this.latAntar = 0,
    this.lngAntar = 0,
    this.fotoReferensi,
    this.jarakKm = 0,
    this.estimasiBiayaBarang,
    this.alasanBatal = '',
    this.diterimaAt,
    this.dibeliAt,
    this.dikirimAt,
    this.selesaiAt,
  });

  factory OrderJastip.dari(Map<String, dynamic> j) => OrderJastip(
        id: bacaTeks(j['id']),
        kode: bacaTeks(j['kode']),
        wargaKunci: bacaTeks(j['warga_kunci']),
        wargaNama: bacaTeks(j['warga_nama']),
        wargaNomor: bacaTeks(j['warga_nomor']),
        wargaId: j['warga_id']?.toString(),
        mitraId: j['mitra_id']?.toString(),
        barang: bacaTeks(j['barang']),
        qty: bacaBulat(j['qty']),
        lokasiBeli: bacaTeks(j['lokasi_beli']),
        latBeli: bacaAngka(j['lat_beli']),
        lngBeli: bacaAngka(j['lng_beli']),
        alamatAntar: bacaTeks(j['alamat_antar']),
        latAntar: bacaAngka(j['lat_antar']),
        lngAntar: bacaAngka(j['lng_antar']),
        catatan: bacaTeks(j['catatan']),
        fotoReferensi: j['foto_referensi']?.toString(),
        jarakKm: bacaAngka(j['jarak_km']),
        fee: bacaAngka(j['fee']),
        estimasiBiayaBarang: j['estimasi_biaya_barang'] == null
            ? null
            : bacaAngka(j['estimasi_biaya_barang']),
        metodeBayar: MetodeBayar.dari(j['metode_bayar']?.toString()),
        status: StatusOrder.dari(bacaTeks(j['status'])),
        alasanBatal: bacaTeks(j['alasan_batal']),
        dibuat: bacaWaktu(j['dibuat']),
        diterimaAt: bacaWaktuOpsional(j['diterima_at']),
        dibeliAt: bacaWaktuOpsional(j['dibeli_at']),
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
  final String barang;
  final int qty;
  final String lokasiBeli;
  final double latBeli;
  final double lngBeli;
  final String alamatAntar;
  final double latAntar;
  final double lngAntar;
  final String catatan;
  final String? fotoReferensi;

  /// Jarak lokasi beli ke alamat antar, dalam km.
  final double jarakKm;
  final double tarif;
  final double? estimasiBiayaBarang;
  final MetodeBayar metodeBayar;
  final StatusOrder status;
  final String alasanBatal;
  final DateTime dibuat;
  final DateTime? diterimaAt;
  final DateTime? dibeliAt;
  final DateTime? dikirimAt;
  final DateTime? selesaiAt;

  static const JenisOrder jenis = JenisOrder.jastip;
  static const String tabel = 'order_jastip';

  TitikPeta get titikBeli => TitikPeta(lat: latBeli, lng: lngBeli);
  TitikPeta get titikAntar => TitikPeta(lat: latAntar, lng: lngAntar);

  /// Ringkasan satu baris untuk daftar: "2 pcs Beras 5 kg".
  String get ringkas =>
      '$qty x $barang' + (lokasiBeli.isEmpty ? '' : ' - $lokasiBeli');

  /// Total yang harus siapkan warga = fee + perkiraan harga barang.
  double get total => tarif + (estimasiBiayaBarang ?? 0);

  OrderJastip salin({
    String? id,
    String? kode,
    String? mitraId,
    double? tarif,
    double? jarakKm,
    double? estimasiBiayaBarang,
    StatusOrder? status,
    String? alasanBatal,
    DateTime? diterimaAt,
    DateTime? dibeliAt,
    DateTime? dikirimAt,
    DateTime? selesaiAt,
  }) =>
      OrderJastip(
        id: id ?? this.id,
        kode: kode ?? this.kode,
        wargaKunci: wargaKunci,
        wargaNama: wargaNama,
        wargaNomor: wargaNomor,
        wargaId: wargaId,
        mitraId: mitraId ?? this.mitraId,
        barang: barang,
        qty: qty,
        lokasiBeli: lokasiBeli,
        latBeli: latBeli,
        lngBeli: lngBeli,
        alamatAntar: alamatAntar,
        latAntar: latAntar,
        lngAntar: lngAntar,
        catatan: catatan,
        fotoReferensi: fotoReferensi,
        jarakKm: jarakKm ?? this.jarakKm,
        tarif: tarif ?? this.tarif,
        estimasiBiayaBarang: estimasiBiayaBarang ?? this.estimasiBiayaBarang,
        metodeBayar: metodeBayar,
        status: status ?? this.status,
        alasanBatal: alasanBatal ?? this.alasanBatal,
        dibuat: dibuat,
        diterimaAt: diterimaAt ?? this.diterimaAt,
        dibeliAt: dibeliAt ?? this.dibeliAt,
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
        'barang': barang,
        'qty': qty,
        'lokasi_beli': lokasiBeli,
        'lat_beli': latBeli,
        'lng_beli': lngBeli,
        'alamat_antar': alamatAntar,
        'lat_antar': latAntar,
        'lng_antar': lngAntar,
        'catatan': catatan,
        if (fotoReferensi != null && fotoReferensi!.isNotEmpty)
          'foto_referensi': fotoReferensi,
        'jarak_km': jarakKm,
        'fee': tarif,
        if (estimasiBiayaBarang != null)
          'estimasi_biaya_barang': estimasiBiayaBarang,
        'metode_bayar': metodeBayar.name,
        'status': status.name,
        'alasan_batal': alasanBatal,
      };

  @override
  bool operator ==(Object lain) => lain is OrderJastip && lain.id == id;

  @override
  int get hashCode => id.hashCode;
}