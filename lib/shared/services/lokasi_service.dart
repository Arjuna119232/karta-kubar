import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/data/hasil.dart';
import '../models/order.dart';
import '../models/order_tracking.dart';

/// Satu saran alamat dari Nominatim: teks siap tampil + koordinat.
///
/// Dipisah dari [LokasiService] supaya bisa dipakai juga di widget yang tidak
/// punya akses ke service.

@immutable
class SaranAlamat {
  const SaranAlamat({
    required this.teks,
    required this.titik,
    this.kelurahan,
    this.shortName = '',
    this.type = '',
  });

  /// Alamat satu baris, mis. "Jl. Poncol Jaya, Kuningan Barat, Jakarta".
  /// Alias: `displayName`.
  final String teks;

  final TitikPeta titik;

  /// Kelurahan/kecamatan hasil baca detail alamat.
  final String? kelurahan;

  /// Nama pendek (nama jalan/tempat) untuk baris utama saran.
  final String shortName;

  /// Jenis tempat (mis. `residential`, `shop`, `street`). Boleh kosong.
  final String type;

  String get displayName => teks;
  double get lat => titik.lat;
  double get lng => titik.lng;

  /// Nama jalan/kawasan saja, untuk baris kecil di bawah alamat.
  String get jalan =>
      shortName.isNotEmpty ? shortName : teks.split(',').first.trim();

  /// Nama kedua yang tampil di bawah nama jalan: kelurahan kalau ada,
  /// kalau tidak pakai bagian kedua alamat.
  String get area {
    if (kelurahan != null && kelurahan!.isNotEmpty) return kelurahan!;
    return teks.split(',').length > 1 ? teks.split(',')[1].trim() : '';
  }
}

/// Ambil nama Frida dari peta detail Nominatim.
///
/// Urutannya sengaja: `village` (desa atau kelurahan) lebih persis dari
/// `suburb` (kelurahan viewbox) dan `city_district`.
String _ketikAlamat(Map<String, dynamic> alamat) {
  for (final String kunci in const <String>[
    'village',
    'suburb',
    'city_district',
    'town',
    'city',
  ]) {
    final Object? v = alamat[kunci];
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  return '';
}

/// Semua peta dan lokasi di KUNBAR lewat satu kelas ini.
///
/// Tiga sumber gratis tanpa API key:
///   1. `geolocator` -> posisi perangkat (butuh izin lokasi)
///   2. Nominatim    -> saran alamat lengkap + koordinat (OpenStreetMap)
///   3. Photon       -> cadangan pencarian alamat, cepat tapi tanpa teks
///   4. OSRM demo    -> rute jalan + geometri garis + jarak + ETA
///
/// Kalau jaringan gagal, hasil tetap dikembalikan dari haversine dan ditandai
/// `dariServer: false`, supaya UI bisa jujur membedakan "rute asli" dari
/// "perkiraan kasar".
class LokasiService {
  LokasiService();

  /// Batas waktu satu panggilan jaringan. Peta harus terasa cepat; lebih dari
  /// 6 detik dianggap gagal agar layar tidak menggantung.
  static const Duration batas = Duration(seconds: 6);

  static const String _photon = 'https://photon.komoot.io/api/';

  /// OpenStreetMap Nominatim. Rules penggunaan mereka mewajibkan User-Agent
  /// yang bisa dihubungi dan maksimal 1 permintaan per detik, jadi [_jeda]
  /// dipakai di semua panggilan.
  static const String _nominatim = 'https://nominatim.openstreetmap.org';

  /// Waktu panggilan terakhir ke tiap server (rate limit 1 permintaan/detik).
  DateTime _terakhir = DateTime.fromMillisecondsSinceEpoch(0);

  /// Cache alamat supaya mengetik ulang kata yang sama tidak memanggil server
  /// lagi.dibatasi 40 entri terakhir, cukup untuk satu sesi form.
  final Map<String, List<SaranAlamat>> _cacheSaran =
      <String, List<SaranAlamat>>{};

  /// Profil `driving`: ojek dan jastip memakai kendaraan bermotor, jadi jarak
  /// harus mengikuti jalan yang bisa dilewati motor (bukan jalan kaki).
  static const String _osrm = 'https://router.project-osrm.org/route/v1/driving';

  HttpClient? _klien;

  HttpClient _http() {
    _klien ??= HttpClient()
      ..connectionTimeout = const Duration(seconds: 5)
      ..userAgent = 'KUNBARConnect/1.0';
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

  /// Sama seperti [posisiSaya], tapi koordinatnya juga diberi nama jalan dari
  /// server (reverse geocode).
  ///
  /// Dipakai form pemesanan supaya tombol "lokasi HP" mengisi kolom alamat
  /// dengan nama jalan, bukan angka koordinat mentah. Kalau server tidak bisa
  /// dibaca, hasil tetap koordinat tanpa nama — pemesanan tidak boleh gagal
  /// hanya karena nama jalannya tidak ketemu.
  Future<Hasil<TitikPeta>> posisiSayaBeralamat() async {
    final Hasil<TitikPeta> hasil = await posisiSaya();
    if (!hasil.berhasil) return hasil;
    final TitikPeta titik = hasil.data!;
    final String nama = await reverseAlamat(titik);
    return Hasil<TitikPeta>.berhasil(
      TitikPeta(lat: titik.lat, lng: titik.lng, alamat: nama),
    );
  }

  // -------------------------------------------------------------- geocoding

  /// Pusat pencarian (Kuningan Barat). Hasil dekat titik ini diutamakan.
  static const String _biasLat = '-6.2365';
  static const String _biasLon = '106.8219';

  /// Rate limit 1 permintaan/detik: tunggu sisa waktu sejak panggilan terakhir.
  ///
  /// (Versi lama menghitung selisih dari epoch 1970 sehingga panggilan
  /// pertama menunggu puluhan tahun -> pencarian "loading terus".)
  Future<void> _jeda() async {
    final Duration lewat = DateTime.now().difference(_terakhir);
    const Duration minimal = Duration(seconds: 1);
    if (lewat < minimal) {
      await Future<void>.delayed(minimal - lewat);
    }
    _terakhir = DateTime.now();
  }

  /// Cari koordinat dari teks alamat. Hasil kosong bukan error.
  Future<List<TitikPeta>> cariAlamat(String kueri) async {
    final List<SaranAlamat> s = await cariAlamatSaran(kueri);
    return s.map((SaranAlamat e) => e.titik).toList(growable: false);
  }

  /// Saran alamat dari teks yang diketik pengguna.
  ///
  /// Urutan: cache -> Photon (utama) -> Nominatim (cadangan). Tidak pernah
  /// melempar error dan tidak pernah menggantung lebih dari beberapa detik.
  Future<List<SaranAlamat>> cariAlamatSaran(String kueri) async {
    final String k = kueri.trim().toLowerCase();
    if (k.length < 3) return const <SaranAlamat>[];
    final List<SaranAlamat>? ada = _cacheSaran[k];
    if (ada != null) return ada;

    List<SaranAlamat> hasil = await _saranPhoton(kueri.trim());
    if (hasil.isEmpty) hasil = await _saranNominatim(kueri.trim());
    if (hasil.isNotEmpty) {
      _cacheSaran[k] = hasil;
      if (_cacheSaran.length > 40) _cacheSaran.remove(_cacheSaran.keys.first);
    }
    return hasil;
  }

  Future<List<SaranAlamat>> _saranPhoton(String kueri) async {
    Future<String> panggil(bool denganLang) async {
      await _jeda();
      return _ambil(
        Uri.parse(_photon).replace(
          queryParameters: <String, String>{
            'q': kueri,
            'limit': '5',
            if (denganLang) 'lang': 'id',
            'lat': _biasLat,
            'lon': _biasLon,
          },
        ),
      );
    }

    try {
      String isi;
      try {
        isi = await panggil(true);
      } on HttpException {
        // Photon menolak `lang` yang tidak didukung (HTTP 400): ulangi tanpa.
        isi = await panggil(false);
      }
      final dynamic j = jsonDecode(isi);
      final dynamic fitur = j is Map ? j['features'] : null;
      if (fitur is! List) return const <SaranAlamat>[];
      final List<SaranAlamat> out = <SaranAlamat>[];
      for (final dynamic f in fitur) {
        if (f is! Map) continue;
        final dynamic geom = f['geometry'];
        final dynamic coords = geom is Map ? geom['coordinates'] : null;
        if (coords is! List ||
            coords.length < 2 ||
            coords[0] is! num ||
            coords[1] is! num) {
          continue;
        }
        final Map<String, dynamic> p = f['properties'] is Map
            ? (f['properties'] as Map).cast<String, dynamic>()
            : <String, dynamic>{};
        String t(String key) {
          final Object? v = p[key];
          return v is String ? v.trim() : '';
        }

        final String jalan = t('street');
        final String nomor = t('housenumber');
        String pendek = t('name');
        if (pendek.isEmpty) {
          pendek = jalan.isEmpty || nomor.isEmpty ? jalan : '$jalan $nomor';
        }
        final String kel = t('suburb').isNotEmpty ? t('suburb') : t('district');
        final List<String> bagian = <String>[
          pendek,
          if (jalan.isNotEmpty && jalan != pendek) jalan,
          kel,
          t('city').isNotEmpty ? t('city') : t('county'),
          t('state'),
        ].where((String e) => e.isNotEmpty).toList();
        if (bagian.isEmpty) continue;
        out.add(
          SaranAlamat(
            teks: bagian.toSet().join(', '),
            shortName: pendek.isEmpty ? bagian.first : pendek,
            type: t('osm_value').isNotEmpty ? t('osm_value') : t('type'),
            kelurahan: kel,
            titik: TitikPeta(
              lat: (coords[1] as num).toDouble(),
              lng: (coords[0] as num).toDouble(),
            ),
          ),
        );
      }
      return out;
    } catch (e) {
      debugPrint('[LokasiService] Photon gagal: $e');
      return const <SaranAlamat>[];
    }
  }

  Future<List<SaranAlamat>> _saranNominatim(String kueri) async {
    try {
      await _jeda();
      final Uri url = Uri.parse('$_nominatim/search').replace(
        queryParameters: <String, String>{
          'q': kueri,
          'format': 'jsonv2',
          'addressdetails': '1',
          'limit': '5',
          'countrycodes': 'id',
          'accept-language': 'id',
          'viewbox': '106.70,-6.15,106.95,-6.35',
        },
      );
      final dynamic j = jsonDecode(await _ambil(url));
      if (j is! List) return const <SaranAlamat>[];
      final List<SaranAlamat> out = <SaranAlamat>[];
      for (final dynamic e in j) {
        if (e is! Map) continue;
        final dynamic nama = e['display_name'];
        final double? la = double.tryParse('${e['lat']}');
        final double? lo = double.tryParse('${e['lon']}');
        if (nama is! String || nama.trim().isEmpty || la == null || lo == null) {
          continue;
        }
        final Map<String, dynamic> alamat = e['address'] is Map
            ? (e['address'] as Map).cast<String, dynamic>()
            : <String, dynamic>{};
        final dynamic n = e['name'];
        out.add(
          SaranAlamat(
            teks: nama,
            shortName: n is String && n.trim().isNotEmpty
                ? n.trim()
                : nama.split(',').first.trim(),
            type: '${e['type'] ?? ''}',
            titik: TitikPeta(lat: la, lng: lo),
            kelurahan: _ketikAlamat(alamat),
          ),
        );
      }
      return out;
    } catch (e) {
      debugPrint('[LokasiService] Nominatim gagal: $e');
      return const <SaranAlamat>[];
    }
  }

  /// Alamat dari titik (balik dari koordinat ke nama jalan).
  Future<String> reverseAlamat(TitikPeta titik) async {
    if (!titik.valid) return '';
    try {
      await _jeda();
      final Uri url = Uri.parse('$_nominatim/reverse').replace(
        queryParameters: <String, String>{
          'lat': '${titik.lat}',
          'lon': '${titik.lng}',
          'format': 'jsonv2',
          'zoom': '18',
          'accept-language': 'id',
        },
      );
      final dynamic j = jsonDecode(await _ambil(url));
      if (j is! Map) return '';
      return bacaTeks(j['display_name']);
    } catch (_) {
      return '';
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
