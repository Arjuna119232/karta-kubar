import 'dart:async';

import 'package:any_map/any_map.dart';
import 'package:any_map_maplibre/any_map_maplibre.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../services/rute.dart';
import '../state/app_state.dart';
import 'widgets.dart';

/// Peta gratis: MapLibre + OpenFreeMap (tanpa API key Google), rute via OSRM.
class PetaScreen extends StatefulWidget {
  const PetaScreen({super.key, required this.order});
  final Order order;

  @override
  State<PetaScreen> createState() => _PetaScreenState();
}

class _PetaScreenState extends State<PetaScreen> {
  static const _gaya = 'https://tiles.openfreemap.org/styles/liberty';
  static const _kuningan = Color(0xFF1B5E20);

  AnyMapController? _ctrl;
  RuteInfo? _rute;
  bool _memuat = true;
  String _status = 'Mengambil rute...';
  AnyLatLng? _saya;
  Timer? _timer;

  Order get order {
    final s = context.read<AppState>();
    return (s.active?.id == widget.order.id) ? s.active! : widget.order;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _muat());
    // Posisi driver disegarkan tiap 12 detik selama halaman terbuka.
    _timer = Timer.periodic(const Duration(seconds: 12), (_) => _posisiSaya());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  AnyLatLng? get _awal {
    final o = widget.order;
    if (o.pickupLat != null && o.pickupLng != null) {
      return AnyLatLng(o.pickupLat!, o.pickupLng!);
    }
    return const AnyLatLng(-6.2385, 106.8280); // Kuningan Barat
  }

  Future<void> _muat() async {
    await _posisiSaya();
    if (!mounted) return;
    final o = order;
    final asal = _awal!;
    if (o.dropLat == null || o.dropLng == null) {
      setState(() {
        _memuat = false;
        _status = 'Koordinat tujuan belum ada - peta menampilkan titik jemput.';
      });
      return;
    }
    final tujuan = AnyLatLng(o.dropLat!, o.dropLng!);
    final r = await Rute.ambil(asal.latitude, asal.longitude, tujuan.latitude, tujuan.longitude);
    if (!mounted) return;
    setState(() {
      _rute = r;
      _memuat = false;
      _status = r == null
          ? 'Rute dari server tidak terbaca - garis lurus ditampilkan.'
          : 'Rute ${r.kilometer.toStringAsFixed(1)} km - sekitar ${r.etaMenit} menit';
    });
    if (r != null) {
      _ctrl?.fitBounds(AnyLatLngBounds.fromPoints([
        asal,
        tujuan,
        ...r.koordinat.take(40).map((c) => AnyLatLng(c[1], c[0])),
      ]));
    }
  }

  Future<void> _posisiSaya() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() => _saya = AnyLatLng(p.latitude, p.longitude));
    } catch (_) {
      // Izin lokasi ditolak atau GPS mati: peta tetap jalan, hanya tanpa titik biru.
    }
  }

  List<AnyMarker> _marker() {
    final o = order;
    final out = <AnyMarker>[
      if (o.pickupLat != null && o.pickupLng != null)
        AnyMarker(
          id: 'jemput',
          position: AnyLatLng(o.pickupLat!, o.pickupLng!),
          title: 'Jemput',
          snippet: o.pickupAddress,
          icon: _pin(Icons.storefront_outlined, Colors.amber.shade800),
        ),
      if (o.dropLat != null && o.dropLng != null)
        AnyMarker(
          id: 'antar',
          position: AnyLatLng(o.dropLat!, o.dropLng!),
          title: 'Antar',
          snippet: o.dropAddress,
          icon: _pin(Icons.flag_outlined, Colors.red.shade700),
        ),
      if (_saya != null)
        AnyMarker(
          id: 'saya',
          position: _saya!,
          title: 'Posisi saya',
          zIndex: 9,
          icon: const Icon(Icons.my_location, color: _kuningan, size: 26),
        ),
    ];
    return out;
  }

  Widget _pin(IconData ikon, Color warna) =>
      Icon(ikon, color: warna, size: 30);

  List<AnyPolyline> _garis() {
    final o = order;
    if (_rute != null) {
      return [
        AnyPolyline(
          id: 'rute',
          points: _rute!.koordinat.map((c) => AnyLatLng(c[1], c[0])).toList(),
          color: _kuningan,
          width: 6,
        )
      ];
    }
    if (o.dropLat != null && o.dropLng != null && o.pickupLat != null) {
      return [
        AnyPolyline(
          id: 'garis-lurus',
          points: [AnyLatLng(o.pickupLat!, o.pickupLng!), AnyLatLng(o.dropLat!, o.dropLng!)],
          color: Colors.grey,
          width: 4,
          dashPattern: const [8, 6],
        )
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Peta ${order.typeLabel}')),
      body: Stack(
        children: [
          AnyMapWidget(
            adapter: MapLibreAdapter(styleUrl: _gaya),
            initialCamera: AnyCameraPosition(target: _awal!, zoom: 15),
            markers: _marker(),
            polylines: _garis(),
            myLocationEnabled: true,
            onMapCreated: (c) => _ctrl = c,
            onError: (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Peta: ${e.message}')),
              );
            },
          ),
          if (_memuat)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 3),
            ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.statusLabel,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(_status, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      tooltip: 'Buka navigasi',
                      onPressed: () => _bukaNavigasi(context, order),
                      icon: const Icon(Icons.navigation),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _bukaNavigasi(BuildContext c, Order o) async {
    final (_, _, alamat) = o.navTarget;
    final web = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(alamat)}');
    final ok = await launchUrl(web, mode: LaunchMode.externalApplication);
    if (!ok && c.mounted) toast(c, 'Tidak ada aplikasi peta yang bisa dibuka');
  }
}
