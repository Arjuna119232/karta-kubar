import 'package:any_map/any_map.dart';
import 'package:any_map_maplibre/any_map_maplibre.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/kit.dart';
import 'account_screen.dart';
import 'orders_screen.dart';
import 'earnings_screen.dart';
import 'jadwal_screen.dart';
import 'order_detail_screen.dart';
import 'order_masuk_screen.dart';
import 'widgets.dart';

/// Beranda kerja: peta penuh di belakang, semua kontrol mengambang di atasnya.
/// - Peta full screen yang gratis (MapLibre + OpenFreeMap, tanpa API key).
/// - Lokasi mitra dan order aktif tampil sebagai marker.
/// - Header kaca: sapaan, rating, jumlah order, status, tombol profil.
/// - Tombol AKTIFKAN / NONAKTIFKAN besar dengan denyut pelan.
/// - Empat aksi cepat plus kartu order aktif di atasnya.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AnyMapController? _ctrl;
  AnyLatLng? _saya;
  String? _orderDitampilkan;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pantauOrder();
  }

  @override
  void didUpdateWidget(covariant HomeScreen old) {
    super.didUpdateWidget(old);
  }

  /// Order baru langsung dibuka layar penuh, seperti aplikasi ojek pada umumnya.
  void _pantauOrder() {
    final s = context.read<AppState>();
    final o = s.incoming.isEmpty ? null : s.incoming.first;
    if (o == null) {
      _orderDitampilkan = null;
      return;
    }
    if (_orderDitampilkan == o.id) return;
    _orderDitampilkan = o.id;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderMasukScreen(order: o)),
      );
      if (mounted) setState(() => _orderDitampilkan = null);
    });
  }

  AnyLatLng _titikAwal(AppState s) {
    final o = s.active;
    if (o != null && o.pickupLat != null && o.pickupLng != null) {
      return AnyLatLng(o.pickupLat!, o.pickupLng!);
    }
    if (_saya != null) return _saya!;
    return const AnyLatLng(-6.2385, 106.8280); // Kuningan Barat
  }

  List<AnyMarker> _marker(AppState s) => [
        if (_saya != null)
          AnyMarker(
            id: 'mitra',
            position: _saya!,
            icon: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 34),
            zIndex: 9,
          ),
        if (s.active != null && s.active!.pickupLat != null)
          AnyMarker(
            id: 'aktif',
            position: AnyLatLng(s.active!.pickupLat!, s.active!.pickupLng!),
            icon: const Icon(Icons.local_shipping_rounded, color: Colors.amber, size: 32),
            zIndex: 8,
          ),
        if (s.incoming.isNotEmpty &&
            s.incoming.first.pickupLat != null)
          AnyMarker(
            id: 'baru',
            position: AnyLatLng(s.incoming.first.pickupLat!, s.incoming.first.pickupLng!),
            icon: const Icon(Icons.campaign_rounded, color: Colors.red, size: 32),
            zIndex: 8,
          ),
      ];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    _pantauOrder();

    return Scaffold(
      body: Stack(
        children: [
          // 1. PETA FULL SCREEN
          Positioned.fill(
            child: AnyMapWidget(
              adapter: MapLibreAdapter(styleUrl: 'https://tiles.openfreemap.org/styles/liberty'),
              initialCamera: AnyCameraPosition(target: _titikAwal(s), zoom: 14.5),
              markers: _marker(s),
              myLocationEnabled: true,
              onMapCreated: (c) {
                _ctrl = c;
                _posisiSaya();
              },
              onError: (e) {
                debugPrint('peta: ${e.message}');
              },
            ),
          ),

          // 2. FLOATING HEADER
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: _HeaderKaca(
              nama: s.name,
              online: s.online,
              rating: s.avgRating,
              orderSelesai: s.history.where((o) => o.isDone).length,
              onProfil: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AccountScreen())),
            ),
          ),

          // tombol zoom + lokasi di kanan peta
          Positioned(
            right: 12,
            bottom: 220,
            child: Column(
              children: [
                _TombolPeta(ikon: Icons.add_rounded, onTekan: _zoomMasuk),
                const SizedBox(height: 8),
                _TombolPeta(
                  ikon: Icons.my_location_rounded,
                  onTekan: () async {
                    await _posisiSaya();
                    final p = _saya;
                    if (p != null && _ctrl != null) {
                      _ctrl!.moveCamera(AnyCameraPosition(target: p, zoom: 16));
                    }
                  },
                ),
              ],
            ),
          ),

          // 3. TOMBOL STATUS BESAR + ORDER AKTIF + QUICK ACTION
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (s.active != null) _KartuOrderAktif(order: s.active!),
                if (s.offlineMode && s.online) const _BannerOffline(),
                TombolGradien(
                  judul: s.menyiapkanOnline
                      ? 'MENYIAPKAN...'
                      : (s.online ? 'NONAKTIFKAN' : 'AKTIFKAN'),
                  subjudul: s.online
                      ? 'sedang menerima order'
                      : 'tekan untuk mulai menerima order',
                  gradien: Gaya.hijau(s.online),
                  denyut: s.online,
                  ikon: s.online ? Icons.power_settings_new : Icons.power_off_rounded,
                  onTekan: () => _toggle(s),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: KotakAksi(
                        ikon: Icons.receipt_long_rounded,
                        warna: AppColors.primary,
                        judul: 'Order',
                        subjudul: '${s.incoming.length} masuk',
                        lencana: s.incoming.length,
                        onTekan: () => _ke(context, const OrdersScreen()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: KotakAksi(
                        ikon: Icons.payments_rounded,
                        warna: const Color(0xFF1565C0),
                        judul: 'Pendapatan',
                        subjudul: rp(s.todayEarnings),
                        onTekan: () => _ke(context, const EarningsScreen()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: KotakAksi(
                        ikon: Icons.event_note_rounded,
                        warna: const Color(0xFF6A1B9A),
                        judul: 'Jadwal',
                        subjudul: 'agenda',
                        onTekan: () => _ke(context, const JadwalScreen()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: KotakAksi(
                        ikon: Icons.settings_rounded,
                        warna: const Color(0xFF00695C),
                        judul: 'Atur',
                        subjudul: s.vehicleType,
                        onTekan: () => _ke(context, const AccountScreen()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _ke(BuildContext c, Widget w) async {
    HapticFeedback.selectionClick();
    await Navigator.push(c, MaterialPageRoute(builder: (_) => w));
    if (mounted) setState(() {});
  }

  /// Zoom in satu tingkat, posisi kamera dipertahankan.
  Future<void> _zoomMasuk() async {
    final c = _ctrl;
    if (c == null) return;
    final p = await c.getCameraPosition();
    await c.moveCamera(p.copyWith(zoom: (p.zoom + 1).clamp(2, 20)));
  }

  Future<void> _posisiSaya() async {
    try {
      final pos = await context.read<AppState>().posisiSaya();
      if (!mounted || pos == null) return;
      setState(() => _saya = AnyLatLng(pos.lat, pos.lng));
    } catch (_) {
      // Izin lokasi belum diberikan: peta tetap jalan tanpa titik biru.
    }
  }

  Future<void> _toggle(AppState s) async {
    HapticFeedback.mediumImpact();
    final berikutnya = !s.online;
    if (!berikutnya) {
      // Konfirmasi sebelum mati supaya mitra tidak kehilangan order tanpa sadar.
      final ya = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: const Text('Matikan ONLINE?'),
          content: const Text(
            'Kamu tidak akan menerima order baru.\n\n'
            'Order yang sedang berjalan tetap bisa diselesaikan.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(d, true),
              child: const Text('MATIKAN'),
            ),
          ],
        ),
      );
      if (ya != true) return;
    }
    final err = await s.setOnline(berikutnya);
    if (!mounted) return;
    if (err != null) toast(context, err);
  }
}

class _HeaderKaca extends StatelessWidget {
  const _HeaderKaca({
    required this.nama,
    required this.online,
    required this.rating,
    required this.orderSelesai,
    required this.onProfil,
  });

  final String nama;
  final bool online;
  final double rating;
  final int orderSelesai;
  final VoidCallback onProfil;

  @override
  Widget build(BuildContext context) {
    final jam = DateTime.now().hour;
    final sapaan = jam < 11
        ? 'Selamat pagi'
        : (jam < 15 ? 'Selamat siang' : (jam < 18 ? 'Selamat sore' : 'Selamat malam'));
    final awal = nama.trim().isEmpty ? 'Mitra' : nama.trim().split(' ').first;

    return Kaca(
      child: Row(
        children: [
          GestureDetector(onTap: onProfil, child: _Avatar(nama: awal)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$sapaan, $awal',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    Text(rating <= 0 ? 'baru' : rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    Text('  -  $orderSelesai order',
                        style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: online ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(online ? 'ONLINE' : 'OFFLINE',
                style: const TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 6),
          IconButton(onPressed: onProfil, icon: const Icon(Icons.person_outline_rounded)),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.nama});
  final String nama;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primary,
      child: Text(
        nama.isEmpty ? 'M' : nama[0].toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _TombolPeta extends StatelessWidget {
  const _TombolPeta({required this.ikon, required this.onTekan});
  final IconData ikon;
  final VoidCallback onTekan;

  @override
  Widget build(BuildContext context) => Kaca(
        radius: 16,
        padding: const EdgeInsets.all(10),
        onTap: onTekan,
        child: Icon(ikon, size: 24, color: AppColors.primary),
      );
}

class _KartuOrderAktif extends StatelessWidget {
  const _KartuOrderAktif({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Kaca(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order))),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primarySoft,
              child: Icon(
                order.type == 'jastip' ? Icons.shopping_bag_rounded : Icons.two_wheeler_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ORDER ${order.typeLabel} BERJALAN',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  Text('${order.statusLabel} - ${order.dropAddress}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
            Text(rp(order.fee),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _BannerOffline extends StatelessWidget {
  const _BannerOffline();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Kaca(
          radius: 14,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.wifi_off_rounded, size: 18, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text('Sinyal hilang - order mungkin terlambat masuk.',
                    style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
      );
}