import 'dart:async';

import 'package:any_map/any_map.dart';
import 'package:any_map_maplibre/any_map_maplibre.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/design/tokens.dart';
import '../models/models.dart';
import '../services/navigasi.dart';
import '../state/app_state.dart';

/// Navigasi belok-per-belok ala Grab: banner manuver di atas, kamera mengikuti
/// arah hadap, suara bahasa Indonesia, rute alternatif, dan tombol status order.
class NavigasiScreen extends StatefulWidget {
  const NavigasiScreen({super.key, required this.order});

  final Order order;

  @override
  State<NavigasiScreen> createState() => _NavigasiScreenState();
}

class _NavigasiScreenState extends State<NavigasiScreen> {
  static const _gaya = 'https://tiles.openfreemap.org/styles/liberty';

  final MesinNavigasi _mesin = MesinNavigasi();
  AnyMapController? _ctrl;
  StreamSubscription<Position>? _langganan;

  AnyLatLng? _asal;
  AnyLatLng? _tujuan;
  Position? _posisi;
  bool _memuat = true;
  String? _galat;
  late Order _order = widget.order;

  DateTime _kameraTerakhir = DateTime.fromMillisecondsSinceEpoch(0);
  String _idRute = 'rute';

  @override
  void initState() {
    super.initState();
    _mesin.addListener(_saatPerubahan);
    _mulai();
  }

  @override
  void dispose() {
    _langganan?.cancel();
    _mesin.removeListener(_saatPerubahan);
    _mesin.dispose();
    super.dispose();
  }

  // ---------- persiapan ----------

  Future<void> _mulai() async {
    final target = _order.navTarget;
    if (target.$1 == null || target.$2 == null) {
      setState(() {
        _memuat = false;
        _galat = 'Order ini belum punya titik koordinat tujuan.';
      });
      return;
    }
    _tujuan = AnyLatLng(target.$1!, target.$2!);

    try {
      final layanan = await Geolocator.isLocationServiceEnabled();
      if (!layanan) {
        setState(() {
          _memuat = false;
          _galat = 'GPS mati. Nyalakan lokasi lalu coba lagi.';
        });
        return;
      }
      var izin = await Geolocator.checkPermission();
      if (izin == LocationPermission.denied) {
        izin = await Geolocator.requestPermission();
      }
      if (izin == LocationPermission.denied ||
          izin == LocationPermission.deniedForever) {
        setState(() {
          _memuat = false;
          _galat = 'Izin lokasi ditolak. Navigasi butuh lokasi Anda.';
        });
        return;
      }

      final sekarang = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      _posisi = sekarang;
      _asal = AnyLatLng(sekarang.latitude, sekarang.longitude);

      final ok = await _mesin.mulai(asal: _asal!, tujuan: _tujuan!);
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _memuat = false;
          _galat = _mesin.galat;
        });
        return;
      }
      _mesin.perbarui(_asal!, kecepatanMs: sekarang.speed);
      setState(() => _memuat = false);
      _dengarkanGps();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _memuat = false;
        _galat = 'Gagal memulai navigasi. Coba lagi.';
      });
    }
  }

  void _dengarkanGps() {
    _langganan = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((p) {
      if (!mounted) return;
      _posisi = p;
      _mesin.perbarui(
        AnyLatLng(p.latitude, p.longitude),
        kecepatanMs: p.speed,
      );
    });
  }

  // ---------- reaksi tiap posisi baru ----------

  void _saatPerubahan() {
    final s = _mesin.snapshot;
    if (!mounted || s == null) return;

    // Rute berganti (reroute / pilih alternatif) -> gambar ulang garisnya.
    final idBaru = 'rute-${_mesin.rute.hashCode}';
    if (idBaru != _idRute && _ctrl != null) {
      _idRute = idBaru;
      _gambarRute(s.garis);
    }

    _geserKamera(s);
    setState(() {});
  }

  Future<void> _gambarRute(List<AnyLatLng> garis) async {
    try {
      await _ctrl?.clearPolylines();
      await _ctrl?.addPolylines([
        AnyPolyline(
          id: _idRute,
          points: garis,
          color: AppColors.primary,
          width: 7,
        ),
      ]);
    } catch (_) {}
  }

  void _geserKamera(NavigasiSnapshot s) {
    final ctrl = _ctrl;
    final pos = _posisi;
    if (ctrl == null || pos == null) return;
    final sekarang = DateTime.now();
    // Jangan kirim perintah kamera tiap frame — 1 detik sudah halus.
    if (sekarang.difference(_kameraTerakhir) < const Duration(milliseconds: 900)) {
      return;
    }
    _kameraTerakhir = sekarang;
    ctrl.moveCamera(
      AnyCameraPosition(
        target: AnyLatLng(pos.latitude, pos.longitude),
        zoom: s.tiba ? 16 : 17.2,
        tilt: _mesin.ikutArah ? 45 : 0,
        bearing: _mesin.ikutArah ? s.bearing : 0,
      ),
    );
  }

  void _recenter() {
    final p = _posisi;
    if (p == null) return;
    _kameraTerakhir = DateTime.fromMillisecondsSinceEpoch(0);
    _ctrl?.moveCamera(
      AnyCameraPosition(
        target: AnyLatLng(p.latitude, p.longitude),
        zoom: 17.2,
        tilt: _mesin.ikutArah ? 45 : 0,
        bearing: _mesin.ikutArah ? (_mesin.snapshot?.bearing ?? 0) : 0,
      ),
    );
  }

  // ---------- aksi ----------

  Future<void> _lanjutStatus() async {
    final app = context.read<AppState>();
    final pesan = await app.advance();
    if (!mounted) return;
    if (pesan != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
      return;
    }
    final aktif = app.active;
    _order = aktif ?? _order;
    if (aktif == null) {
      // Order selesai — kembali ke beranda.
      Navigator.of(context).popUntil((r) => r.isFirst);
      return;
    }
    // Status berubah (mis. sudah di jemput) -> lanjutkan ke tujuan berikut.
    final target = aktif.navTarget;
    if (target.$1 == null || target.$2 == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _memuat = true;
      _galat = null;
    });
    final posisi = _posisi;
    if (posisi == null) return;
    final ok = await _mesin.mulai(
      asal: AnyLatLng(posisi.latitude, posisi.longitude),
      tujuan: AnyLatLng(target.$1!, target.$2!),
    );
    if (!mounted) return;
    setState(() {
      _memuat = false;
      _galat = ok ? null : _mesin.galat;
    });
    if (ok) _gambarRute(_mesin.snapshot!.garis);
  }

  Future<void> _bukaGoogleMaps() async {
    final t = _order.navTarget;
    if (t.$1 == null || t.$2 == null) return;
    final q = '${t.$1},${t.$2}';
    final web = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$q&travelmode=driving',
    );
    await launchUrl(web, mode: LaunchMode.externalApplication);
  }

  void _toggleSuara() {
    setState(() => _mesin.suaraAktif = !_mesin.suaraAktif);
  }

  // ---------- tampilan ----------

  IconData _ikon(ArahManuver arah) => switch (arah) {
        ArahManuver.mulai => Icons.navigation,
        ArahManuver.lurus => Icons.straight,
        ArahManuver.kiri => Icons.turn_left,
        ArahManuver.agakKiri => Icons.turn_slight_left,
        ArahManuver.tajamKiri => Icons.turn_sharp_left,
        ArahManuver.kanan => Icons.turn_right,
        ArahManuver.agakKanan => Icons.turn_slight_right,
        ArahManuver.tajamKanan => Icons.turn_sharp_right,
        ArahManuver.putarBalik => Icons.u_turn_left,
        ArahManuver.bundaran => Icons.roundabout_left,
        ArahManuver.tiba => Icons.flag,
      };

  @override
  Widget build(BuildContext context) {
    final s = _mesin.snapshot;
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          if (_galat != null)
            _layarGalat()
          else
            AnyMapWidget(
              adapter: MapLibreAdapter(styleUrl: _gaya),
              initialCamera: AnyCameraPosition(
                target: _asal ?? _tujuan!,
                zoom: 16,
                tilt: 45,
              ),
              markers: _marker(),
              polylines: [
                if (_mesin.rute != null)
                  AnyPolyline(
                    id: 'rute-awal',
                    points: _mesin.rute!.geometry,
                    color: AppColors.primary,
                    width: 7,
                  ),
              ],
              myLocationEnabled: true,
              onMapCreated: (c) {
                _ctrl = c;
                if (_mesin.rute != null) _gambarRute(_mesin.rute!.geometry);
                if (_posisi != null) _recenter();
              },
              onError: (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Peta: ${e.message}')),
                );
              },
            ),
          if (_memuat || (_galat == null && s == null))
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 3),
            ),
          if (_galat == null && s != null) ...[
            _bannerManuver(s),
            Positioned(
              right: 12,
              bottom: 250,
              child: Column(
                children: [
                  _tombolBulat(
                    Icons.my_location,
                    _recenter,
                    'Kembali ke posisi saya',
                  ),
                  const SizedBox(height: 10),
                  _tombolBulat(
                    _mesin.ikutArah ? Icons.explore : Icons.navigation,
                    () => setState(() {
                      _mesin.ikutArah = !_mesin.ikutArah;
                      _kameraTerakhir = DateTime.fromMillisecondsSinceEpoch(0);
                      _recenter();
                    }),
                    _mesin.ikutArah ? 'Mode utara' : 'Mode ikuti arah',
                  ),
                  const SizedBox(height: 10),
                  _tombolBulat(
                    _mesin.suaraAktif ? Icons.volume_up : Icons.volume_off,
                    _toggleSuara,
                    'Suara petunjuk',
                  ),
                ],
              ),
            ),
            _hudBawah(s),
          ],
        ],
      ),
    );
  }

  List<AnyMarker> _marker() {
    final hasil = <AnyMarker>[];
    final t = _order.navTarget;
    if (t.$1 != null && t.$2 != null) {
      hasil.add(AnyMarker(
        id: 'tujuan',
        position: AnyLatLng(t.$1!, t.$2!),
      ));
    }
    if (_mesin.ikutArah == false && _posisi != null) {
      // Marker posisi hanya dipakai ketika kamera tidak mengikuti arah;
      // saat follow, myLocationEnabled sudah cukup.
      hasil.add(AnyMarker(
        id: 'saya',
        position: AnyLatLng(_posisi!.latitude, _posisi!.longitude),
      ));
    }
    return hasil;
  }

  Widget _layarGalat() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.explore_off, size: 64, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                _galat!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _memuat = true;
                    _galat = null;
                  });
                  _mulai();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                ),
                child: const Text('Coba lagi'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Kembali',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _bannerManuver(NavigasiSnapshot s) {
    final langkah = s.langkah;
    if (langkah == null) return const SizedBox.shrink();
    final ikon = _ikon(langkah.arah);
    final berikutnya = s.berikutnya;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(ikon, color: Colors.white, size: 38),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.tiba ? 'Tiba' : s.jarakManuverTeks,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      langkah.instruksi,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (berikutnya != null && !berikutnya.terakhir) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Lalu ${berikutnya.instruksi.toLowerCase()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: _toggleSuara,
                tooltip: 'Suara petunjuk',
                icon: Icon(
                  _mesin.suaraAktif ? Icons.volume_up : Icons.volume_off,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hudBawah(NavigasiSnapshot s) {
    final alternatif = _mesin.alternatif;
    final warnaBatas = s.lewatBatasKecepatan ? AppColors.error : AppColors.muted;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [
            BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_mesin.ruteDiperbarui)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.alt_route, size: 18, color: AppColors.warning),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Rute diperbarui mengikuti posisi Anda',
                            style: TextStyle(fontSize: 13, color: AppColors.warning),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: _mesin.bersihkanPemberitahuanRute,
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                s.sisaJarakTeks,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(s.sisaDetik / 60).ceil()} mnt',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tiba sekitar ${DateFormat('HH:mm').format(s.perkiraanTiba)}'
                            ' • ${_order.customerName}',
                            style: const TextStyle(fontSize: 13, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${s.kecepatanKmh.round()}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const Text(
                          'km/jam',
                          style: TextStyle(fontSize: 11, color: AppColors.muted),
                        ),
                      ],
                    ),
                    if (s.batasKecepatanKmh != null) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: warnaBatas, width: 2.5),
                        ),
                        child: Text(
                          '${s.batasKecepatanKmh!.round()}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: warnaBatas,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (alternatif.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: alternatif.length,
                      separatorBuilder: (a, b) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final r = alternatif[i];
                        final beda = (r.durationSeconds / 60).round() -
                            (s.sisaDetik / 60).round();
                        return ActionChip(
                          avatar: const Icon(Icons.alt_route, size: 16),
                          label: Text(
                            beda <= 0
                                ? 'Rute lain ${(r.durationSeconds / 60).round()} mnt'
                                : 'Rute lain +$beda mnt',
                            style: const TextStyle(fontSize: 12.5),
                          ),
                          onPressed: () => _mesin.pilihAlternatif(i),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: _lanjutStatus,
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                s.tiba ? AppColors.success : AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: Icon(s.tiba ? Icons.check_circle : Icons.flag, size: 20),
                          label: Text(
                            _order.nextLabel.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      onPressed: _bukaGoogleMaps,
                      tooltip: 'Buka di Google Maps',
                      icon: const Icon(Icons.map_outlined),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tombolBulat(IconData ikon, VoidCallback onTekan, String tip) =>
      Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 3,
        child: IconButton(
          onPressed: onTekan,
          tooltip: tip,
          icon: Icon(ikon, color: AppColors.primary, size: 22),
        ),
      );
}
