import 'dart:async';
import 'dart:math' as math;

import 'package:any_map/any_map.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Arah manuver yang sudah disederhanakan supaya layar bisa memilih ikon.
enum ArahManuver {
  mulai,
  lurus,
  kiri,
  agakKiri,
  tajamKiri,
  kanan,
  agakKanan,
  tajamKanan,
  putarBalik,
  bundaran,
  tiba,
}

/// Satu langkah perjalanan yang sudah diterjemahkan ke bahasa Indonesia.
class LangkahNav {
  const LangkahNav({
    required this.indeks,
    required this.instruksi,
    required this.arah,
    required this.jarakMeter,
    this.namaJalan,
    this.batasKecepatanKmh,
  });

  final int indeks;
  final String instruksi;
  final ArahManuver arah;

  /// Panjang langkah ini (meter).
  final double jarakMeter;
  final String? namaJalan;
  final double? batasKecepatanKmh;

  bool get terakhir => arah == ArahManuver.tiba;
}

/// Kondisi perjalanan pada satu titik waktu — semua yang dibutuhkan layar.
class NavigasiSnapshot {
  const NavigasiSnapshot({
    required this.garis,
    required this.sisaJarakMeter,
    required this.sisaDetik,
    required this.jarakKeManuver,
    required this.kecepatanKmh,
    required this.bearing,
    required this.tiba,
    this.langkah,
    this.berikutnya,
    this.batasKecepatanKmh,
    this.lewatBatasKecepatan = false,
  });

  /// Geometri rute yang harus digambar di peta.
  final List<AnyLatLng> garis;
  final double sisaJarakMeter;
  final double sisaDetik;

  /// Jarak ke titik manuver langkah aktif (bukan ke tujuan akhir).
  final double jarakKeManuver;
  final double kecepatanKmh;

  /// Arah hadap rute (0 = utara) — dipakai kamera mode "ikuti arah".
  final double bearing;
  final bool tiba;
  final LangkahNav? langkah;
  final LangkahNav? berikutnya;
  final double? batasKecepatanKmh;
  final bool lewatBatasKecepatan;

  DateTime get perkiraanTiba =>
      DateTime.now().add(Duration(seconds: sisaDetik.round()));

  /// "1,2 km" / "350 m" — gaya yang sama dengan aplikasi ojek.
  String get sisaJarakTeks {
    if (sisaJarakMeter >= 1000) {
      return '${(sisaJarakMeter / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
    }
    return '${sisaJarakMeter.round()} m';
  }

  String get jarakManuverTeks {
    if (jarakKeManuver >= 1000) {
      return '${(jarakKeManuver / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
    }
    final m = jarakKeManuver.round();
    // Dibulatkan ke 10 m terdekat supaya angka tidak bergetar tiap detik.
    return '${(m / 10).round() * 10} m';
  }
}

/// Pembungkus TTS Indonesia. Memakai flutter_tts dan tetap diam (tanpa crash)
/// kalau perangkat tidak punya mesin suara Indonesia.
class SuaraNavigasi implements AnyVoiceGuidance {
  SuaraNavigasi();

  final FlutterTts _tts = FlutterTts();
  bool _siap = false;
  bool _aktif = true;
  String _bahasa = 'id-ID';
  double _laju = 0.52;

  @override
  bool get isEnabled => _aktif;

  @override
  set isEnabled(bool value) => _aktif = value;

  @override
  String get language => _bahasa;

  @override
  set language(String value) => _bahasa = value;

  @override
  double get speechRate => _laju;

  @override
  set speechRate(double value) => _laju = value;

  @override
  double get volume => 1;

  @override
  set volume(double value) {}

  @override
  String buildInstruction(AnyRouteStep step) => _instruksiId(step);

  @override
  String buildPreAnnouncement(AnyRouteStep step, double jarakMeter) {
    final jarak = jarakMeter >= 1000
        ? '${(jarakMeter / 1000).toStringAsFixed(1)} kilometer'
        : '${(jarakMeter / 10).round() * 10} meter';
    return 'Dalam $jarak, ${_instruksiId(step).toLowerCase()}';
  }

  @override
  String buildArrivalText() => 'Anda sudah tiba di tujuan.';

  Future<void> _siapkan() async {
    if (_siap) return;
    try {
      await _tts.setLanguage(_bahasa);
      await _tts.setSpeechRate(_laju);
      await _tts.setVolume(1);
      await _tts.setPitch(1);
      await _tts.awaitSpeakCompletion(false);
      _siap = true;
    } catch (_) {
      // Mesin TTS tidak ada / bahasa tidak didukung: diamkan saja.
      _siap = false;
    }
  }

  @override
  Future<void> speak(AnyVoiceInstruction instruction) => ucapkan(instruction.text);

  Future<void> ucapkan(String teks) async {
    if (!_aktif || teks.trim().isEmpty) return;
    await _siapkan();
    if (!_siap) return;
    try {
      await _tts.stop();
      await _tts.speak(teks);
    } catch (_) {
      // Gagal bicara tidak boleh mematikan navigasi.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  void dispose() {
    stop();
  }
}

/// Mesin navigasi belok-per-belok: rute OSRM + progres + deteksi keluar jalur
/// + suara. Semua perhitungan dilakukan di sini supaya layar tinggal menggambar.
class MesinNavigasi extends ChangeNotifier {
  MesinNavigasi({AnyRoutingProvider? provider})
      : _provider = provider ?? OsrmRoutingProvider() {
    _reroute = AnyRerouteEngine(
      provider: _provider,
      config: const AnyRerouteConfig(
        deviationThreshold: 45,
        cooldown: Duration(seconds: 12),
        maxAttempts: 3,
      ),
    )..events.listen(_saatReroute);
  }

  final AnyRoutingProvider _provider;
  late final AnyRerouteEngine _reroute;
  final SuaraNavigasi suara = SuaraNavigasi();

  AnyRoute? _rute;
  List<AnyRoute> _alternatif = const [];
  AnyRouteRequest? _permintaan;
  List<double> _kumulatif = const [];
  List<LangkahNav> _langkah = const [];
  NavigasiSnapshot? _snapshot;

  /// Awalan jarak pemberitahuan suara (meter). Nyaris sama dengan Grab.
  static const List<double> _ambang = [500, 200, 60];
  final Set<String> _sudahDiucapkan = {};

  double? _kecepatanMs;
  bool memuat = false;
  String? galat;
  bool ikutArah = true;
  bool ruteDiperbarui = false;

  AnyRoute? get rute => _rute;
  NavigasiSnapshot? get snapshot => _snapshot;
  List<AnyRoute> get alternatif => _alternatif;
  bool get aktif => _rute != null;

  bool get suaraAktif => suara.isEnabled;
  set suaraAktif(bool v) {
    suara.isEnabled = v;
    if (!v) suara.stop();
    notifyListeners();
  }

  /// Ambil rute dari posisi sekarang ke [tujuan]. [alternatif] > 0 meminta
  /// rute pembanding supaya mitra bisa memilih jalur yang lebih cepat.
  Future<bool> mulai({
    required AnyLatLng asal,
    required AnyLatLng tujuan,
    int alternatif = 2,
  }) async {
    memuat = true;
    galat = null;
    notifyListeners();

    final permintaan = AnyRouteRequest(
      origin: asal,
      destination: tujuan,
      mode: AnyTravelMode.driving,
      alternatives: alternatif > 0,
      includeSpeedLimits: true,
      includeAnnotations: true,
      language: 'id',
    );

    try {
      final hasil = await _provider.getRoute(permintaan);
      if (!hasil.isSuccess || hasil.route == null) {
        galat = 'Rute tidak ditemukan. Periksa koneksi internet.';
        memuat = false;
        notifyListeners();
        return false;
      }
      _permintaan = permintaan;
      _pasangRute(hasil.route!, hasil.alternatives);
      memuat = false;
      notifyListeners();
      return true;
    } catch (_) {
      galat = 'Gagal memuat rute. Periksa koneksi internet.';
      memuat = false;
      notifyListeners();
      return false;
    }
  }

  /// Pindah ke rute alternatif ke-[indeks] (0 = rute utama).
  void pilihAlternatif(int indeks) {
    if (indeks < 0 || indeks >= _alternatif.length) return;
    final target = _alternatif[indeks];
    final sisa = _alternatif.where((r) => !identical(r, target)).toList();
    _pasangRute(target, sisa);
    _sudahDiucapkan.clear();
    notifyListeners();
  }

  void _pasangRute(AnyRoute rute, List<AnyRoute> alternatif) {
    _rute = rute;
    _alternatif = alternatif;
    _kumulatif = _hitungKumulatif(rute);
    _langkah = List.generate(
      rute.steps.length,
      (i) => _terjemahkan(rute.steps[i], i),
    );
    _sudahDiucapkan.clear();
    if (_permintaan != null) _reroute.setRoute(rute, _permintaan!);
  }

  /// Dipanggil setiap ada posisi GPS baru.
  void perbarui(AnyLatLng posisi, {double? kecepatanMs}) {
    if (_rute == null) return;
    _kecepatanMs = kecepatanMs;

    // Biarkan library menilai apakah mitra keluar jalur.
    unawaited(_reroute.updateLocation(posisi));

    _snapshot = _hitung(posisi);
    _umumkan(_snapshot!);
    notifyListeners();
  }

  void _saatReroute(AnyRerouteEvent event) {
    _pasangRute(event.newRoute, _alternatif);
    ruteDiperbarui = true;
    unawaited(suara.ucapkan('Rute diperbarui. Ikuti petunjuk arah yang baru.'));
    notifyListeners();
  }

  void bersihkanPemberitahuanRute() {
    ruteDiperbarui = false;
    notifyListeners();
  }

  // ---------- perhitungan ----------

  List<double> _hitungKumulatif(AnyRoute rute) {
    final hasil = <double>[];
    double total = 0;
    for (final s in rute.steps) {
      total += s.distanceMeters;
      hasil.add(total);
    }
    return hasil;
  }

  NavigasiSnapshot _hitung(AnyLatLng posisi) {
    final rute = _rute!;
    final garis = rute.geometry;
    final proyeksi = _proyeksi(garis, posisi);
    final total = _kumulatif.isEmpty ? rute.distanceMeters : _kumulatif.last;
    final sudah = proyeksi.jarak.clamp(0.0, total);
    final sisa = (total - sudah).clamp(0.0, total);

    // Langkah aktif = langkah yang titik akhirnya masih di depan posisi.
    int indeks = _kumulatif.length - 1;
    for (var i = 0; i < _kumulatif.length; i++) {
      if (_kumulatif[i] > sudah) {
        indeks = i;
        break;
      }
    }
    final awal = indeks == 0 ? 0.0 : _kumulatif[indeks - 1];
    final panjang = _kumulatif.isEmpty
        ? total
        : (_kumulatif[indeks] - awal).clamp(1.0, double.infinity);
    final dalamLangkah = (sudah - awal).clamp(0.0, panjang);
    final keManuver = (panjang - dalamLangkah).clamp(0.0, panjang);

    // Sisa waktu dihitung per langkah supaya tidak melonjak saat macet.
    double sisaDetik = 0;
    if (_rute!.steps.isNotEmpty) {
      final langkahSekarang = _rute!.steps[indeks];
      sisaDetik += langkahSekarang.durationSeconds * (keManuver / panjang);
      for (var i = indeks + 1; i < _rute!.steps.length; i++) {
        sisaDetik += _rute!.steps[i].durationSeconds;
      }
    }
    // Kalau GPS menunjukkan kecepatan nyata, pakai itu saat lebih lambat dari
    // estimasi OSRM (kemacetan) — tapi jangan sampai ETA jadi tak masuk akal.
    final v = _kecepatanMs ?? 0;
    if (v > 1.0 && sisa > 30) {
      final nyata = sisa / v;
      final estimasi = sisaDetik <= 0 ? nyata : sisaDetik;
      sisaDetik = math.min(nyata, estimasi * 2.5);
    }

    final langkah = _langkah.isEmpty ? null : _langkah[indeks];
    final berikutnya =
        _langkah.length > indeks + 1 ? _langkah[indeks + 1] : null;
    final kecepatanKmh = v * 3.6;
    final batas = _rute!.steps.length > indeks
        ? _rute!.steps[indeks].speedLimit?.speedKmh
        : null;

    return NavigasiSnapshot(
      garis: garis,
      sisaJarakMeter: sisa,
      sisaDetik: math.max(0, sisaDetik),
      jarakKeManuver: keManuver,
      kecepatanKmh: kecepatanKmh,
      bearing: proyeksi.bearing,
      tiba: sisa <= 25,
      langkah: langkah,
      berikutnya: berikutnya,
      batasKecepatanKmh: batas,
      lewatBatasKecepatan: batas != null && kecepatanKmh > batas + 8,
    );
  }

  /// Proyeksi posisi ke polyline: hasilkan jarak sepanjang garis, jarak tegak
  /// lurus ke garis, dan arah segmen terdekat.
  ({double jarak, double offset, double bearing}) _proyeksi(
    List<AnyLatLng> garis,
    AnyLatLng posisi,
  ) {
    if (garis.isEmpty) return (jarak: 0, offset: 0, bearing: 0);
    if (garis.length == 1) {
      return (
        jarak: 0,
        offset: garis.first.distanceTo(posisi),
        bearing: 0,
      );
    }

    double kumulatif = 0;
    double terbaikOffset = double.infinity;
    double terbaikJarak = 0;
    double terbaikBearing = 0;

    for (var i = 0; i < garis.length - 1; i++) {
      final a = garis[i];
      final b = garis[i + 1];
      final panjang = a.distanceTo(b);
      if (panjang <= 0.01) continue;

      // Proyeksi planar lokal — cukup akurat untuk jarak di bawah 1 km.
      final lat0 = a.latitude * math.pi / 180;
      double x(AnyLatLng p) =>
          (p.longitude - a.longitude) * 111320 * math.cos(lat0);
      double y(AnyLatLng p) => (p.latitude - a.latitude) * 110540;

      final bx = x(b), by = y(b);
      final px = x(posisi), py = y(posisi);
      final panjangKuadrat = bx * bx + by * by;
      final t = panjangKuadrat == 0
          ? 0.0
          : ((px * bx + py * by) / panjangKuadrat).clamp(0.0, 1.0);
      final dx = px - bx * t;
      final dy = py - by * t;
      final offset = math.sqrt(dx * dx + dy * dy);

      if (offset < terbaikOffset) {
        terbaikOffset = offset;
        terbaikJarak = kumulatif + panjang * t;
        terbaikBearing = _bearing(a, b);
      }
      kumulatif += panjang;
    }

    return (
      jarak: terbaikJarak,
      offset: terbaikOffset,
      bearing: terbaikBearing,
    );
  }

  double _bearing(AnyLatLng a, AnyLatLng b) {
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final deg = math.atan2(y, x) * 180 / math.pi;
    return (deg + 360) % 360;
  }

  // ---------- terjemahan instruksi ----------

  LangkahNav _terjemahkan(AnyRouteStep step, int indeks) {
    final asli = step.instruction.toLowerCase();
    final jalan = step.roadName?.trim();
    final arah = _arahDari(step.maneuver, asli);

    String teks;
    switch (arah) {
      case ArahManuver.tiba:
        teks = 'Anda telah tiba di tujuan';
      case ArahManuver.mulai:
        teks = jalan == null || jalan.isEmpty
            ? 'Mulai perjalanan'
            : 'Mulai perjalanan lewat $jalan';
      case ArahManuver.lurus:
        teks = jalan == null || jalan.isEmpty
            ? 'Lurus terus'
            : 'Lurus terus di $jalan';
      case ArahManuver.putarBalik:
        teks = 'Putar balik';
      case ArahManuver.bundaran:
        teks = jalan == null || jalan.isEmpty
            ? 'Masuk bundaran, ambil jalan keluar'
            : 'Masuk bundaran, lalu ke $jalan';
      case ArahManuver.kiri:
      case ArahManuver.agakKiri:
      case ArahManuver.tajamKiri:
      case ArahManuver.kanan:
      case ArahManuver.agakKanan:
      case ArahManuver.tajamKanan:
        final kata = switch (arah) {
          ArahManuver.kiri => 'Belok kiri',
          ArahManuver.agakKiri => 'Belok agak ke kiri',
          ArahManuver.tajamKiri => 'Belok tajam ke kiri',
          ArahManuver.kanan => 'Belok kanan',
          ArahManuver.agakKanan => 'Belok agak ke kanan',
          _ => 'Belok tajam ke kanan',
        };
        teks = jalan == null || jalan.isEmpty ? kata : '$kata ke $jalan';
    }

    return LangkahNav(
      indeks: indeks,
      instruksi: teks,
      arah: arah,
      jarakMeter: step.distanceMeters,
      namaJalan: jalan,
      batasKecepatanKmh: step.speedLimit?.speedKmh,
    );
  }



  // ---------- suara ----------

  void _umumkan(NavigasiSnapshot s) {
    final langkah = s.langkah;
    if (langkah == null) return;
    if (s.tiba) {
      if (_sudahDiucapkan.add('tiba')) {
        unawaited(suara.ucapkan('Anda telah tiba di tujuan.'));
      }
      return;
    }
    // Ambang terkecil yang sudah terlewati. Dipilih begini supaya lompatan
    // GPS (mis. 600 m -> 120 m) tetap diumumkan sekali, tidak dilewati.
    double? dipakai;
    for (final ambang in _ambang) {
      if (s.jarakKeManuver <= ambang) dipakai = ambang;
    }
    if (dipakai == null) return;
    if (!_sudahDiucapkan.add('${langkah.indeks}:$dipakai')) return;
    for (final ambang in _ambang) {
      if (ambang > dipakai) _sudahDiucapkan.add('${langkah.indeks}:$ambang');
    }
    final jarak = dipakai >= 1000
        ? '${(dipakai / 1000).round()} kilometer'
        : '${dipakai.round()} meter';
    unawaited(suara.ucapkan('Dalam $jarak, ${langkah.instruksi.toLowerCase()}'));
  }

  @override
  void dispose() {
    _reroute.dispose();
    suara.dispose();
    super.dispose();
  }
}

ArahManuver _arahDari(String? manuver, String instruksi) {
  final m = (manuver ?? '').toLowerCase();
  final gabungan = '$m $instruksi';

  if (gabungan.contains('arrive') || gabungan.contains('tiba')) {
    return ArahManuver.tiba;
  }
  if (gabungan.contains('depart')) return ArahManuver.mulai;
  if (gabungan.contains('uturn') || gabungan.contains('u-turn')) {
    return ArahManuver.putarBalik;
  }
  if (gabungan.contains('roundabout') || gabungan.contains('rotary')) {
    return ArahManuver.bundaran;
  }
  // "sharp/slight left" harus diperiksa SEBELUM "left" biasa.
  if (gabungan.contains('sharp left') || gabungan.contains('tajam ke kiri')) {
    return ArahManuver.tajamKiri;
  }
  if (gabungan.contains('sharp right') ||
      gabungan.contains('tajam ke kanan')) {
    return ArahManuver.tajamKanan;
  }
  if (gabungan.contains('slight left') || gabungan.contains('keep left')) {
    return ArahManuver.agakKiri;
  }
  if (gabungan.contains('slight right') || gabungan.contains('keep right')) {
    return ArahManuver.agakKanan;
  }
  if (gabungan.contains('left')) return ArahManuver.kiri;
  if (gabungan.contains('right')) return ArahManuver.kanan;
  return ArahManuver.lurus;
}

/// Instruksi singkat Bahasa Indonesia untuk satu langkah (dipakai TTS).
String _instruksiId(AnyRouteStep step) {
  final jalan = step.roadName?.trim();
  final tanpaJalan = jalan == null || jalan.isEmpty;
  return switch (_arahDari(step.maneuver, step.instruction.toLowerCase())) {
    ArahManuver.tiba => 'Anda telah tiba di tujuan',
    ArahManuver.mulai =>
      tanpaJalan ? 'Mulai perjalanan' : 'Mulai perjalanan lewat $jalan',
    ArahManuver.lurus => tanpaJalan ? 'Lurus terus' : 'Lurus terus di $jalan',
    ArahManuver.putarBalik => 'Putar balik',
    ArahManuver.bundaran => tanpaJalan
        ? 'Masuk bundaran, ambil jalan keluar'
        : 'Masuk bundaran, lalu ke $jalan',
    ArahManuver.kiri => tanpaJalan ? 'Belok kiri' : 'Belok kiri ke $jalan',
    ArahManuver.agakKiri =>
      tanpaJalan ? 'Belok agak ke kiri' : 'Belok agak ke kiri ke $jalan',
    ArahManuver.tajamKiri =>
      tanpaJalan ? 'Belok tajam ke kiri' : 'Belok tajam ke kiri ke $jalan',
    ArahManuver.kanan => tanpaJalan ? 'Belok kanan' : 'Belok kanan ke $jalan',
    ArahManuver.agakKanan =>
      tanpaJalan ? 'Belok agak ke kanan' : 'Belok agak ke kanan ke $jalan',
    ArahManuver.tajamKanan =>
      tanpaJalan ? 'Belok tajam ke kanan' : 'Belok tajam ke kanan ke $jalan',
  };
}
