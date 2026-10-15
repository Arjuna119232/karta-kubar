import 'package:flutter/foundation.dart';

import 'order.dart';

/// Peran mitra: kurir (jastip), driver (ojek), atau dua-duanya.
enum PeranMitra {
  kurir,
  driver,
  both;

  static PeranMitra dari(String? nilai) => PeranMitra.values.firstWhere(
        (PeranMitra p) => p.name == nilai,
        orElse: () => PeranMitra.both,
      );

  String get label => switch (this) {
        PeranMitra.kurir => 'Kurir',
        PeranMitra.driver => 'Driver',
        PeranMitra.both => 'Kurir & Driver',
      };

  /// Bisa menerima order jastip?
  bool bisaJastip => this != PeranMitra.driver;

  /// Bisa menerima order ojek?
  bool bisaOjek => this != PeranMitra.kurir;
}

/// Status ketersediaan mitra, dipakai untuk memilih whom di form order.
enum StatusMitra {
  offline,
  menunggu,
  sibuk;

  static StatusMitra dari(String? nilai) => StatusMitra.values.firstWhere(
        (StatusMitra s) => s.name == nilai,
        orElse: () => StatusMitra.offline,
      );

  String get label => switch (this) {
        StatusMitra.offline => 'Offline',
        StatusMitra.menunggu => 'Menunggu order',
        StatusMitra.sibuk => 'Sibuk',
      };
}

/// Mitra (kurir atau driver) di ecosystem KUNBAR.
@immutable
class MitraJasa {
  const MitraJasa({
    required this.id,
    required this.nama,
    required this.nomor,
    required this.peran,
    required this.status,
    required this.rating,
    required this.totalOrder,
    required this.online,
    required this.aktif,
    this.userId,
    this.kendaraan = '',
    this.platNomor = '',
    this.fotoUrl,
    this.lokasi = const TitikPeta(lat: 0, lng: 0),
    this.lokasiUpdatedAt,
  });

  factory MitraJasa.dari(Map<String, dynamic> j) => MitraJasa(
        id: bacaTeks(j['id']),
        userId: j['user_id']?.toString(),
        nama: bacaTeks(j['nama']),
        nomor: bacaTeks(j['nomor']),
        peran: PeranMitra.dari(bacaTeks(j['jenis'])),
        kendaraan: bacaTeks(j['kendaraan']),
        platNomor: bacaTeks(j['plat_nomor']),
        fotoUrl: j['foto_url']?.toString(),
        status: StatusMitra.dari(bacaTeks(j['status'])),
        lokasi: TitikPeta(
          lat: bacaAngka(j['lokasi_lat']),
          lng: bacaAngka(j['lokasi_lng']),
        ),
        lokasiUpdatedAt: bacaWaktuOpsional(j['lokasi_updated_at']),
        rating: bacaAngka(j['rating']),
        totalOrder: bacaBulat(j['total_order']),
        online: bacaBenar(j['is_online']),
        aktif: j['is_active'] == null ? true : bacaBenar(j['is_active']),
      );

  final String id;
  final String? userId;
  final String nama;
  final String nomor;
  final PeranMitra peran;
  final String kendaraan;
  final String platNomor;
  final String? fotoUrl;
  final StatusMitra status;
  final TitikPeta lokasi;
  final DateTime? lokasiUpdatedAt;
  final double rating;
  final int totalOrder;
  final bool online;
  final bool aktif;

  bool bisa(JenisOrder jenis) => jenis == JenisOrder.jastip
      ? peran.bisaJastip
      : peran.bisaOjek;

  /// Berapa lama lokasi terakhir dikirim (menampilkan "2 menit lalu").
  String get umurLokasi {
    if (lokasiUpdatedAt == null) return 'belum pernah mengirim lokasi';
    final Duration d = DateTime.now().difference(lokasiUpdatedAt!);
    if (d.inMinutes < 1) return 'baru saja';
    if (d.inHours < 1) return '${d.inMinutes} menit lalu';
    if (d.inDays < 1) return '${d.inHours} jam lalu';
    return '${d.inDays} hari lalu';
  }

  MitraJasa salin({
    StatusMitra? status,
    TitikPeta? lokasi,
    DateTime? lokasiUpdatedAt,
    bool? online,
    double? rating,
    int? totalOrder,
  }) =>
      MitraJasa(
        id: id,
        userId: userId,
        nama: nama,
        nomor: nomor,
        peran: peran,
        kendaraan: kendaraan,
        platNomor: platNomor,
        fotoUrl: fotoUrl,
        status: status ?? this.status,
        lokasi: lokasi ?? this.lokasi,
        lokasiUpdatedAt: lokasiUpdatedAt ?? this.lokasiUpdatedAt,
        rating: rating ?? this.rating,
        totalOrder: totalOrder ?? this.totalOrder,
        online: online ?? this.online,
        aktif: aktif,
      );

  Map<String, dynamic> keBaris() => <String, dynamic>{
        if (id.isNotEmpty) 'id': id,
        if (userId != null && userId!.isNotEmpty) 'user_id': userId,
        'nama': nama,
        'nomor': nomor,
        'jenis': peran.name,
        'kendaraan': kendaraan,
        'plat_nomor': platNomor,
        if (fotoUrl != null && fotoUrl!.isNotEmpty) 'foto_url': fotoUrl,
        'status': status.name,
        'lokasi_lat': lokasi.lat,
        'lokasi_lng': lokasi.lng,
        if (lokasiUpdatedAt != null)
          'lokasi_updated_at': lokasiUpdatedAt!.toUtc().toIso8601String(),
        'rating': rating,
        'total_order': totalOrder,
        'is_online': online,
        'is_active': aktif,
      };

  @override
  bool operator ==(Object lain) => lain is MitraJasa && lain.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Daftar mitra contoh supaya form ojek punya pilihan sebelum backend nyala.
///
/// Semuanya diberi nama tanpa tanda "data contoh" di sini; labelnya ditambahkan
/// di UI supaya tidak disalaharti sebagai mitra sungguhan. Backend hidup ->
/// repository mengembalikan baris nyata dan daftar ini tidak dipakai.
const List<MitraJasa> mitraContoh = <MitraJasa>[
  MitraJasa(
    id: 'contoh-1',
    nama: 'Rizky',
    nomor: '',
    peran: PeranMitra.both,
    status: StatusMitra.menunggu,
    rating: 4.8,
    totalOrder: 132,
    online: true,
    aktif: true,
  ),
  MitraJasa(
    id: 'contoh-2',
    nama: 'Dimas',
    nomor: '',
    peran: PeranMitra.driver,
    status: StatusMitra.menunggu,
    rating: 4.6,
    totalOrder: 88,
    online: true,
    aktif: true,
  ),
  MitraJasa(
    id: 'contoh-3',
    nama: 'Bayu',
    nomor: '',
    peran: PeranMitra.kurir,
    status: StatusMitra.sibuk,
    rating: 4.9,
    totalOrder: 210,
    online: true,
    aktif: true,
  ),
];
