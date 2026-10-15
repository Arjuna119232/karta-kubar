import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:geolocator/geolocator.dart';

import '../../core/data/hasil.dart';
import '../models/mitra_jasa.dart';
import '../models/order.dart';
import '../models/order_tracking.dart';

/// Semua peta dan lokasi di KUNBAR lewat satu kelas ini.
///
/// Tiga sumber gratis tanpa API key:
///   1. `geolocator` -> posisi perangkat (butuh izin lokasi)
///   2. Photon       -> cari koordinat dari teks alamat (OpenStreetMap)
///   3. OSRM demo    -> rute jalan kaki + jarak + ETA
///
/// Kalau jaringan gagal, hasil tetap dikembalikan dari haversine dan ditandai
/// `dariServer: false`, supaya UI bisa jujur membedakan "rute asli" dari
/// "perkiraan kasar".
class LokasiService {
  LokasiService();

  /// Batas waktu satu panggilan jaringan. Peta harus terasa cepat; lebih dari
  /// 6 detik dianggap gagal agar layar tidak menggantung.
  static const Duration batas = Duration(seconds: 6);

  static const String _photon = 'https://photon.komoot.io/api';

  /// Mode `foot` dipakai karena KUNBAR adalah layanan lingkungan: jalan kaki
  /// lebih masuk akal daripada mobil untuk jarak 1-3 km.
  static const String _osrm = 'https://router.project-osrm.org/route/v1/foot';

  HttpClient? _klien;

  HttpClient _http() {
    _klien ??= HttpClient()
      ..connectionTimeout = const Duration(seconds: 5)
      ..userAgent = 'KUNBARConnect/0.13 (warga)';
    return _klien!;
  }

  void buang() {
    _klien?.close(force: true);
    _klien = null;
  }

  // ------------------------------------------------------------------ izin

  /// Izin yang dibaca app ini. Dicatat supaya layar Pengaturan bisa
  /// menjelaskannya tanpa menebak.
  static const List<String> hakDipakai = <String>[
    'ACCESS_FINE_LOCATION',
    'ACCESS_COARSE_LOCATION',
  ];

  static bool _boleh(LocationPermission p) =>
      p == LocationPermission.whileInUse || p == LocationPermission.always;

  /// Tolak permanen butuh tindakan di Pengaturan HP; pesannya harus beda.
  static bool permanen(LocationPermission p) =>
      p == LocationPermission.deniedForever;

  /// Cek + minta izin lokasi. Mengembalikan pesan human kalau gagal.
  Future<String?> mintaIzinLokasi() async {
    try {
      final bool svc = await Geolocator.isLocationServiceEnabled();
      if (!svc) {
        return 'Lokasi HP masih mati. Nyalakan dulu di Pengaturan HP.';
      }
      LocationPermission izin = await Geolocator.checkPermission();
      if (izin == LocationPermission.denied) {
        izin = await Geolocator.requestPermission();
      }
      if (_boleh(izin)) return null;
      return permanen(izin)
          ? 'Izin lokasi ditolak permanen. Buka Pengaturan aplikasi.'
          : 'Izin lokasi ditolak. Aktifkan dari Pengaturan HP.';
    } catch (e) {
      return 'Tidak bisa membaca izin lokasi: $e';
    }
  }

  // --------------------------------------------------------------- posisi

  /// Posisi perangkat sekarang.
  Future<Hasil<TitikPeta>> posisiSaya() async {
    try {
      final bool svc = await Geolocator.isLocationServiceEnabled();
      if (!svc) {
        return const Hasil<TitikPeta>.galat(
          GalatData('Lokasi HP masih mati. Nyalakan di Pengaturan HP.',
              kode: 'lokasi_mati'),
        );
      }
      LocationPermission izin = await Geolocator.checkPermission();
      if (izin == LocationPermission.denied) {
        izin = await Geolocator.requestPermission();
      }
      if (!_boleh(izin)) {
        return Hasil<TitikPeta>.galat(
          GalatData(
            permanen(izin)
                ? 'Izin lokasi ditolak permanen. Buka Pengaturan aplikasi.'
                : 'Izin lokasi ditolak.',
            kode: 'izin_lokasi',
          ),
        );
      }
      // CATATAN: geolocator 12 memakai `desiredAccuracy`.
      // `locationSettings` hanya ada di 13.x. Naikkan paket dulu kalau
      // memang mau API baru, jangan campur keduanya.
      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: batas,
      );
      return Hasil<TitikPeta>.berhasil(
        TitikPeta(lat: pos.latitude, lng: pos.longitude),
      );
    } on TimeoutException {
      return const Hasil<TitikPeta>.galat(
        GalatData('Lokasi tidak ditemukan dalam 6 detik. Coba di tempat terbuka.',
            kode: 'gps_timeout'),
      );
    } catch (e) {
      return Hasil<TitikPeta>.galat(
        GalatData('Gagal membaca lokasi: $e', kode: 'gps_gagal'),
      );
    }
  }

  // -------------------------------------------------------------- geocoding

  /// Cari koordinat dari teks alamat (nama jalan, toko, landmark).
  ///
  /// Hasil kosong bukan error: form tetap bisa diisi manual, dan jarak tetap
  /// dihitung dari koordinat yang sudah ada.
  Future<List<TitikPeta>> cariAlamat(String kueri) async {
    if (kueri.trim().length < 3) return const <TitikPeta>[];
    try {
      final Uri url = Uri.parse(_photon).replace(
        queryParameters: <String, String>{
          'q': kueri.trim(),
          'limit': '6',
          'lang': 'id',
        },
      );
      final dynamic j = jsonDecode(await _ambil(url));
      final dynamic fitur = j is Map ? j['features'] : null;
      if (fitur is! List) return const <TitikPeta>[];
      final List<TitikPeta> out = <TitikPeta>[];
      for (final dynamic f in fitur) {
        if (f is! Map) continue;
        final dynamic geom = f['geometry'];
        if (geom is! Map) continue;
        final dynamic coords = geom['coordinates'];
        if (coords is! List || coords.length < 2) continue;
        out.add(
          TitikPeta(
            lat: (coords[1] as num).toDouble(),
            lng: (coords[0] as num).toDouble(),
          ),
        );
      }
      return out;
    } catch (_) {
      return const <TitikPeta>[];
    }
  }

  // ------------------------------------------------------------------ rute

  /// Hitung rute jalan kaki dari [dari] ke [ke].
  Future<Rute> rute(TitikPeta dari, TitikPeta ke) async {
    if (!dari.valid || !ke.valid) return Rute.estimasi(0);
    try {
      final Uri url = Uri.parse(
        '$_osrm/${dari.lng},${dari.lat};${ke.lng},${ke.lat}'
        '?overview=false&alternatives=false',
      );
      final dynamic j = jsonDecode(await _ambil(url));
      final dynamic routes = j is Map ? j['routes'] : null;
      if (routes is! List || routes.isEmpty || routes.first is! Map) {
        return Rute.estimasi(jarakKm(dari, ke));
      }
      final dynamic r = routes.first as Map;
      final dynamic jarak = r['distance'];
      if (jarak is! num) return Rute.estimasi(jarakKm(dari, ke));
      final dynamic durasi = r['duration'];
      return Rute.dariServer(
        jarakKm: (jarak / 1000).toDouble(),
        durasiMenit: durasi is num ? (durasi / 60).round() : 0,
      );
    } catch (_) {
      return Rute.estimasi(jarakKm(dari, ke));
    }
  }

  Future<String> _ambil(Uri url) async {
    final HttpClientRequest req = await _http().getUrl(url);
    final HttpClientResponse res = await req.close().timeout(batas);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HttpException('HTTP ${res.statusCode}', uri: url);
    }
    return res.transform(utf8.decoder).join();
  }

  // -------------------------------------------------------------- utilitas

  /// Titik tengah dua koordinat, untuk posisi awal peta.
  static TitikPeta tengah(TitikPeta a, TitikPeta b) {
    if (!a.valid) return b;
    if (!b.valid) return a;
    return TitikPeta(
      lat: (a.lat + b.lat) / 2,
      lng: (a.lng + b.lng) / 2,
    );
  }

  /// Pusat semua titik supaya peta tidak mulai di tengah dunia.
  static TitikPeta pusat(List<TitikPeta> titik) {
    final List<TitikPeta> sah = titik.where((TitikPeta t) => t.valid).toList();
    if (sah.isEmpty) return titikKuninganBarat;
    double lat = 0;
    double lng = 0;
    for (final TitikPeta t in sah) {
      lat += t.lat;
      lng += t.lng;
    }
    return TitikPeta(lat: lat / sah.length, lng: lng / sah.length);
  }
}

/// Titik tengah wilayah Kuningan Barat, dipakai saat peta belum punya
/// koordinat apa pun.
const TitikPeta titikKuninganBarat = TitikPeta(lat: -6.2447, lng: 106.8003);

/// Daftar mitra contoh supaya form ojek punya pilihan sebelum backend nyala.
///
/// Diberi label "data contoh" di UI supaya tidak disalaharti sebagai mitra
/// sungguhan. Backend nyala -> daftar ini tidak dipakai.
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