import 'package:any_map/any_map.dart';
import 'package:any_map_maplibre/any_map_maplibre.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/kotak_masuk.dart';
import '../state/app_state.dart';
import '../widgets/kit.dart';
import 'account_screen.dart';
import 'kotak_masuk_screen.dart';
import 'order_detail_screen.dart';
import 'order_masuk_screen.dart';
import 'orders_screen.dart';
import 'pendapatan_screen.dart';
import 'widgets.dart';

/// Beranda kerja: peta penuh di belakang, semua kontrol mengambang di atasnya.
///
/// - Peta full screen gratis (MapLibre + OpenFreeMap, tanpa API key).
/// - Lokasi mitra dan order aktif tampil sebagai marker.
/// - Header kaca: sapaan, rating, ringkasan hari ini, status, kotak masuk.
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

  /// Order baru langsung dibuka layar penuh, seperti aplikasi ojek umumnya.
  ///
  /// [_orderDitampilkan] sengaja TIDAK direset setelah layar ditutup: kalau
  /// order masih ada di `incoming` (ditolak tapi belum hilang, atau gagal
  /// terkirim), membuka ulang layarnya hanya membuat mitra terjebak lingkar.
  /// Reset terjadi sendiri ketika order itu benar-benar lenyap dari `incoming`.
  void _pantauOrder() {
    final s = context.read<AppState>();
    final o = s.incoming.isEmpty ? null : s.incoming.first;
    if (o == null) {
      _orderDitampilkan = null;
      return;
    }
    if (_orderDitampilkan == o.id) return;
    _orderDitampilkan = o.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderMasukScreen(order: o)),
      );
    });
  }

  /// Koordinat lengkap = lat DAN lng terisi; kalau salah satu null, marker
  /// tidak digambar (menghindari `null!` yang mematikan layar beranda).
  static AnyLatLng? _titikOrder(double? lat, double? lng) =>
      (lat == null || lng == null) ? null : AnyLatLng(lat, lng);

  AnyLatLng _titikAwal(AppState s) {
    final o = s.active;
    final t = o == null ? null : _titikOrder(o.pickupLat, o.pickupLng);
    if (t != null) return t;
    if (_saya != null) return _saya!;
    return const AnyLatLng(-6.2385, 106.8280); // Kuningan Barat
  }

  List<AnyMarker> _marker(AppState s) {
    final aktif = s.active == null
        ? null
        : _titikOrder(s.active!.pickupLat, s.active!.pickupLng);
    final baru = s.incoming.isEmpty
        ? null
        : _titikOrder(s.incoming.first.pickupLat, s.incoming.first.pickupLng);
    return [
      if (_saya != null)
        AnyMarker(
          id: 'mitra',
          position: _saya!,
          icon: const Icon(Icons.two_wheeler_rounded,
              color: Colors.white, size: 34),
          zIndex: 9,
        ),
      if (aktif != null)
        AnyMarker(
          id: 'aktif',
          position: aktif,
          icon: const Icon(Icons.local_shipping_rounded,
              color: Colors.amber, size: 32),
          zIndex: 8,
        ),
      if (baru != null)
        AnyMarker(
          id: 'baru',
          position: baru,
          icon: const Icon(Icons.campaign_rounded, color: Colors.red, size: 32),
          zIndex: 8,
        ),
    ];
  }

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
              adapter: MapLibreAdapter(
                styleUrl: 'https://tiles.openfreemap.org/styles/liberty',
              ),
              initialCamera: AnyCameraPosition(target: _titikAwal(s), zoom: 14.5),
              markers: _marker(s),
              myLocationEnabled: true,
              onMapCreated: (c) {
                _ctrl = c;
                _posisiSaya();
              },
              onError: (e) => debugPrint('peta: ${e.message}'),
            ),
          ),

          // 2. HEADER KACA
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: _HeaderBeranda(
              nama: s.name,
              online: s.online,
              rating: s.avgRating,
              orderHariIni: s.history.where((o) => o.isDone).length,
              pendapatan: s.todayEarnings,
              onProfil: () => _ke(context, const AccountScreen(dapatTombolKembali: true)),
              onKotakMasuk: () => _ke(context, const KotakMasukScreen()),
            ),
          ),

          // 3. TOMBOL PETA (kanan)
          Positioned(
            right: 12,
            bottom: 232,
            child: Column(
              children: [
                _TombolPeta(ikon: Icons.add_rounded, onTekan: _zoomMasuk),
                const SizedBox(height: 8),
                _TombolPeta(ikon: Icons.my_location_rounded, onTekan: _keSaya),
              ],
            ),
          ),

          // 4. TOMBOL STATUS + ORDER AKTIF + AKSI CEPAT
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
                      ? 'sedang menerima order di sekitar'
                      : 'tekan untuk mulai menerima order',
                  gradien: Gaya.hijau(s.online),
                  denyut: s.online,
                  menyala: !s.menyiapkanOnline,
                  ikon: s.online
                      ? Icons.power_settings_new_rounded
                      : Icons.power_off_rounded,
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
                        warna: AppColors.info,
                        judul: 'Pendapatan',
                        subjudul: rp(s.todayEarnings),
                        onTekan: () => _ke(
                            context, const PendapatanScreen(dapatTombolKembali: true)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: KotakAksi(
                        ikon: Icons.inbox_rounded,
                        warna: AppColors.violet,
                        judul: 'Kotak',
                        subjudul: 'info admin',
                        onTekan: () => _ke(context, const KotakMasukScreen()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: KotakAksi(
                        ikon: Icons.person_rounded,
                        warna: AppColors.teal,
                        judul: 'Profil',
                        subjudul: s.vehicleType,
                        onTekan: () =>
                            _ke(context, const AccountScreen(dapatTombolKembali: true)),
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
    final z = p.zoom + 1;
    // clamp() mengembalikan `num`, bukan `double` - tulis eksplisit.
    await c.moveCamera(p.copyWith(zoom: z < 2 ? 2 : (z > 20 ? 20 : z)));
  }

  Future<void> _keSaya() async {
    await _posisiSaya();
    final p = _saya;
    if (p != null && _ctrl != null) {
      await _ctrl!.moveCamera(AnyCameraPosition(target: p, zoom: 16));
    } else {
      await _posisiSaya();
    }
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
            TextButton(
                onPressed: () => Navigator.pop(d, false),
                child: const Text('Batal')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
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

/// Header: identitas, status, dan ringkasan hari ini dalam satu kartu kaca.
class _HeaderBeranda extends StatelessWidget {
  const _HeaderBeranda({
    required this.nama,
    required this.online,
    required this.rating,
    required this.orderHariIni,
    required this.pendapatan,
    required this.onProfil,
    required this.onKotakMasuk,
  });

  final String nama;
  final bool online;
  final double rating;
  final int orderHariIni;
  final int pendapatan;
  final VoidCallback onProfil;
  final VoidCallback onKotakMasuk;

  @override
  Widget build(BuildContext context) {
    final p = Palet.of(context);
    final jam = DateTime.now().hour;
    final sapaan = jam < 11
        ? 'Selamat pagi'
        : (jam < 15
            ? 'Selamat siang'
            : (jam < 18 ? 'Selamat sore' : 'Selamat malam'));
    final awal = nama.trim().isEmpty ? 'Mitra' : nama.trim().split(' ').first;

    return Kaca(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              GestureDetector(onTap: onProfil, child: _Avatar(nama: awal)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$sapaan, $awal',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Teks.judul.copyWith(color: p.teks, fontSize: 17),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.gold, size: 15),
                        const SizedBox(width: 3),
                        Text(
                          rating <= 0 ? 'Mitra baru' : rating.toStringAsFixed(1),
                          style: Teks.ket.copyWith(
                            color: p.teks2,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '  -  $orderHariIni order',
                          style: Teks.ket.copyWith(color: p.teks2, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _PilStatus(online: online),
              _IkonKotakMasuk(onTap: onKotakMasuk),
            ],
          ),
          Divider(height: 22, color: p.garis),
          Row(
            children: [
              Expanded(
                child: _AngkaRingkas(
                  label: 'PENDAPATAN',
                  nilai: rp(pendapatan),
                  warna: p.teks,
                ),
              ),
              Container(width: 1, height: 30, color: p.garis),
              Expanded(
                child: _AngkaRingkas(
                  label: 'ORDER',
                  nilai: '$orderHariIni',
                  warna: p.teks,
                ),
              ),
              Container(width: 1, height: 30, color: p.garis),
              Expanded(
                child: _AngkaRingkas(
                  label: 'RATING',
                  nilai: rating <= 0 ? '-' : rating.toStringAsFixed(1),
                  warna: p.teks,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AngkaRingkas extends StatelessWidget {
  const _AngkaRingkas({
    required this.label,
    required this.nilai,
    required this.warna,
  });

  final String label;
  final String nilai;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    final p = Palet.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Teks.label.copyWith(
            color: p.teks2,
            fontSize: 9.5,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          nilai,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Teks.judul.copyWith(color: warna, fontSize: 15),
        ),
      ],
    );
  }
}

class _PilStatus extends StatelessWidget {
  const _PilStatus({required this.online});
  final bool online;

  @override
  Widget build(BuildContext context) {
    final p = Palet.of(context);
    final w = online ? AppColors.primaryBright : AppColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: p.lembut(w, 0.16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: w, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            online ? 'ONLINE' : 'OFFLINE',
            style: Teks.label.copyWith(
              color: online
                  ? (p.gelap ? AppColors.primaryOnDark : AppColors.primary)
                  : AppColors.muted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _IkonKotakMasuk extends StatelessWidget {
  const _IkonKotakMasuk({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palet.of(context);
    final belum = NotifikasiService.instance.belumDibaca();
    return IconButton(
      tooltip: 'Kotak Masuk',
      onPressed: onTap,
      icon: Badge(
        isLabelVisible: belum > 0,
        label: Text('$belum'),
        backgroundColor: AppColors.error,
        child: Icon(Icons.notifications_none_rounded, color: p.teks),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.nama});
  final String nama;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(
        gradient: Gaya.hijau(false),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        nama.isEmpty ? 'M' : nama[0].toUpperCase(),
        style: const TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
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
        radius: AppRadius.field,
        padding: const EdgeInsets.all(10),
        onTap: onTekan,
        child: Icon(ikon, size: 24, color: Palet.of(context).brand),
      );
}

class _KartuOrderAktif extends StatelessWidget {
  const _KartuOrderAktif({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final p = Palet.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Kaca(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order))),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                order.type == 'jastip'
                    ? Icons.shopping_bag_rounded
                    : Icons.two_wheeler_rounded,
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
                      style: Teks.label.copyWith(
                          color: AppColors.primary, fontSize: 10.5)),
                  const SizedBox(height: 2),
                  Text('${order.statusLabel} - ${order.dropAddress}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Teks.isi.copyWith(color: p.teks, fontSize: 14.5)),
                ],
              ),
            ),
            Text(rp(order.fee),
                style: Teks.judul.copyWith(color: p.teks, fontSize: 16)),
            Icon(Icons.chevron_right_rounded, color: p.teks2),
          ],
        ),
      ),
    );
  }
}

class _BannerOffline extends StatelessWidget {
  const _BannerOffline();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Kaca(
          radius: AppRadius.field,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 18, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sinyal hilang - order mungkin terlambat masuk.',
                  style: Teks.ket.copyWith(fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
      );
}
