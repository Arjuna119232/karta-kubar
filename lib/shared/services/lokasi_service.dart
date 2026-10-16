import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:geolocator/geolocator.dart';

import '../../core/data/hasil.dart';
import '../models/order.dart';
import '../models/order_tracking.dart';

/// Semua peta dan lokasi di KUNBAR lewat satu kelas ini.
///
/// Tiga sumber gratis tanpa API key:
///   1. `geolocator` -> posisi perangkat (butuh izin lokasi)
///   2. Photon       -> cari koordinat dari teks alamat (OpenStreetMap)
///   3. OSRM demo    -> rute jalan + geometri garis + jarak + ETA
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

  /// Profil `driving`: ojek dan jastip memakai kendaraan bermotor, jadi jarak
  /// harus mengikuti jalan yang bisa dilewati motor (bukan jalan kaki).
  static const String _osrm = 'https://router.project-osrm.org/route/v1/driving';

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
          // Condong ke Jakarta Selatan supaya "Pasar Minggu" tidak nyasar.
          'lat': '-6.25',
          'lon': '106.82',
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

  /// Hitung rute jalan (OSRM, profil kendaraan) dari [dari] ke [ke].
  Future<Rute> rute(TitikPeta dari, TitikPeta ke) async {
    if (!dari.valid || !ke.valid) return Rute.estimasi(0);
    try {
      final Uri url = Uri.parse(
        '$_osrm/${dari.lng},${dari.lat};${ke.lng},${ke.lat}'
        '?overview=full&geometries=geojson&alternatives=false',
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
      List<TitikPeta>? garis;
      final dynamic geom = r['geometry'];
      final dynamic koor = geom is Map ? geom['coordinates'] : null;
      if (koor is List && koor.length > 1) {
        final int langkah = koor.length > 300 ? (koor.length / 300).ceil() : 1;
        garis = <TitikPeta>[];
        for (int i = 0; i < koor.length; i += langkah) {
          final dynamic c = koor[i];
          if (c is List && c.length >= 2 && c[0] is num && c[1] is num) {
            garis.add(TitikPeta(
              lat: (c[1] as num).toDouble(),
              lng: (c[0] as num).toDouble(),
            ));
          }
        }
        garis.add(ke);
      }
      return Rute.dariServer(
        jarakKm: (jarak / 1000).toDouble(),
        durasiMenit: durasi is num ? (durasi / 60).round() : 0,
        garis: garis,
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
