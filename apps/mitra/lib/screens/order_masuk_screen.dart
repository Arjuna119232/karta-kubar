import 'package:any_map/any_map.dart';
import 'package:any_map_maplibre/any_map_maplibre.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/rute.dart';
import '../state/app_state.dart';
import '../widgets/kit.dart';
import 'peta_screen.dart';

/// Order masuk full screen ala Grab - tapi lebih bersih: tanpa iklan,
/// preview rute langsung, dan countdown yang jujur.
class OrderMasukScreen extends StatefulWidget {
  const OrderMasukScreen({super.key, required this.order});
  final Order order;

  @override
  State<OrderMasukScreen> createState() => _OrderMasukScreenState();
}

class _OrderMasukScreenState extends State<OrderMasukScreen> {
  RuteInfo? _rute;
  bool _ambil = false;

  Order get o => widget.order;
  bool get jastip => o.type == 'jastip';

  @override
  void initState() {
    super.initState();
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();
    WidgetsBinding.instance.addPostFrameCallback((_) => _rute_());
  }

  Future<void> _rute_() async {
    if (o.pickupLat == null || o.dropLat == null) return;
    final r = await Rute.ambil(
      o.pickupLat!, o.pickupLng!, o.dropLat!, o.dropLng!,
    );
    if (mounted) setState(() => _rute = r);
  }

  List<AnyMarker> _marker() => [
        if (o.pickupLat != null && o.pickupLng != null)
          AnyMarker(
            id: 'a',
            position: AnyLatLng(o.pickupLat!, o.pickupLng!),
            icon: const Icon(Icons.storefront_rounded, color: Colors.green, size: 30),
          ),
        if (o.dropLat != null && o.dropLng != null)
          AnyMarker(
            id: 'b',
            position: AnyLatLng(o.dropLat!, o.dropLng!),
            icon: const Icon(Icons.flag_rounded, color: Colors.red, size: 30),
          ),
      ];

  List<AnyPolyline> _garis() {
    if (_rute != null) {
      return [
        AnyPolyline(
          id: 'r',
          points: _rute!.koordinat.map((c) => AnyLatLng(c[1], c[0])).toList(),
          color: AppColors.primary,
          width: 6,
        )
      ];
    }
    if (o.pickupLat != null && o.dropLat != null) {
      return [
        AnyPolyline(
          id: 'r',
          points: [AnyLatLng(o.pickupLat!, o.pickupLng!), AnyLatLng(o.dropLat!, o.dropLng!)],
          color: Colors.grey,
          width: 4,
          dashPattern: const [8, 6],
        )
      ];
    }
    return [];
  }

  Future<void> _terima() async {
    setState(() => _ambil = true);
    HapticFeedback.mediumImpact();
    final err = await context.read<AppState>().accept(o);
    if (!mounted) return;
    if (err != null) {
      setState(() => _ambil = false);
      toastOrder(err);
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _tolak() async {
    HapticFeedback.lightImpact();
    context.read<AppState>().reject(o);
    Navigator.of(context).pop();
  }

  void toastOrder(String m) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m, style: const TextStyle(fontSize: 16))),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final sisa = s.sisaTolak(o);
    return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // --- Top bar: judul + countdown ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _tolak,
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Tolak',
                    ),
                    Expanded(
                      child: Text(jastip ? 'ORDER JASTIP' : 'ORDER OJEK',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sisa <= 10 ? Colors.red : Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${sisa}s',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  children: [
                    _Header(jastip: jastip),
                    const SizedBox(height: 14),
                    _Pendapatan(o: o, rute: _rute),
                    const SizedBox(height: 14),
                    _PetaRute(
                      awal: o.pickupLat != null
                          ? AnyLatLng(o.pickupLat!, o.pickupLng!)
                          : const AnyLatLng(-6.2385, 106.8280),
                      markers: _marker(),
                      garis: _garis(),
                      rute: _rute,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => PetaScreen(order: o))),
                    ),
                    const SizedBox(height: 16),
                    _Titimah(jastip: jastip, o: o, rute: _rute),
                    const SizedBox(height: 16),
                    _KartuWarga(o: o),
                  ],
                ),
              ),
              // --- Aksi ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  children: [
                    TombolGradien(
                      judul: 'TERIMA ORDER',
                      subjudul: sisa > 0 ? 'otomatis ditolak dalam ${sisa}s' : 'tersisa 0s',
                      gradien: Gaya.hijau(false),
                      denyut: true,
                      ikon: Icons.check_circle_rounded,
                      onTekan: _ambil ? () {} : _terima,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _ambil ? null : _tolak,
                      icon: const Icon(Icons.close_rounded, color: Colors.red),
                      label: const Text('Tolak Order',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.jastip});
  final bool jastip;

  @override
  Widget build(BuildContext context) {
    final warna = jastip ? AppColors.primary : const Color(0xFF1565C0);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [warna.withValues(alpha: 0.95), warna.withValues(alpha: 0.65)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Icon(jastip ? Icons.shopping_bag_rounded : Icons.two_wheeler_rounded,
              size: 46, color: Colors.white),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              jastip ? 'JASTIP BARU' : 'OJEK BARU',
              style: const TextStyle(
                  color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pendapatan extends StatelessWidget {
  const _Pendapatan({required this.o, required this.rute});
  final Order o;
  final RuteInfo? rute;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF43A047)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pendapatan bersih',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
          const SizedBox(height: 4),
          Text(rp(o.fee),
              style: const TextStyle(
                  color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag('Cash / QRIS'),
              _Tag('Fee 15% masuk aplikasi'),
              if (rute != null)
                _Tag('${rute!.kilometer.toStringAsFixed(1)} km - ${rute!.etaMenit} menit'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _Tag(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(t,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}

class _PetaRute extends StatelessWidget {
  const _PetaRute({
    required this.awal,
    required this.markers,
    required this.garis,
    required this.rute,
    required this.onTap,
  });

  final AnyLatLng awal;
  final List<AnyMarker> markers;
  final List<AnyPolyline> garis;
  final RuteInfo? rute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Stack(
          children: [
            AnyMapWidget(
              adapter: MapLibreAdapter(styleUrl: 'https://tiles.openfreemap.org/styles/liberty'),
              initialCamera: AnyCameraPosition(target: awal, zoom: 14),
              markers: markers,
              polylines: garis,
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: FilledButton.tonalIcon(
                onPressed: onTap,
                icon: const Icon(Icons.fullscreen_rounded, size: 18),
                label: const Text('Peta penuh'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Titimah extends StatelessWidget {
  const _Titimah({required this.jastip, required this.o, required this.rute});
  final bool jastip;
  final Order o;
  final RuteInfo? rute;

  @override
  Widget build(BuildContext context) {
    Widget titik(Color c, String label, String judul, String isi, String jarak) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Text(label,
                    style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(judul, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  Text(isi, style: const TextStyle(fontSize: 14)),
                  Text(jarak, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titik(
          Colors.green,
          jastip ? 'BELI / AMBIL DI' : 'JEMPUT DI',
          o.pickupAddress.isEmpty ? 'Lokasi jemput' : o.pickupAddress.split(',').first,
          o.pickupAddress,
          '${o.distanceKm.toStringAsFixed(1)} km dari Anda',
        ),
        Container(
          margin: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
          width: 2,
          height: 26,
          color: Colors.grey.shade400,
        ),
        titik(
          Colors.red,
          'ANTAR KE',
          o.dropAddress.isEmpty ? 'Tujuan' : o.dropAddress.split(',').first,
          o.dropAddress,
          rute == null
              ? 'jarak belum dihitung'
              : 'total ${rute!.kilometer.toStringAsFixed(1)} km',
        ),
      ],
    );
  }
}

class _KartuWarga extends StatelessWidget {
  const _KartuWarga({required this.o});
  final Order o;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 24, child: Icon(Icons.person, size: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.customerName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const Row(
                        children: [
                          Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          Text('4.9 - warga KUNBAR', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Telepon warga',
                  onPressed: o.customerPhone.isEmpty
                      ? null
                      : () => launchUrl(Uri.parse('tel:${o.customerPhone}')),
                  icon: const Icon(Icons.call),
                ),
              ],
            ),
            if (o.note.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Catatan: ${o.note}',
                    style: const TextStyle(fontSize: 14)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}