import 'dart:math' as math;

import 'package:any_map/any_map.dart';
import 'package:any_map_maplibre/any_map_maplibre.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/models/order.dart';
import '../../../shared/services/peta_gaya.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/atribusi_peta.dart';
import '../../order/presentation/widgets_order.dart';
import '../data/mitra_usaha_lokal.dart';
import '../domain/mitra_usaha.dart';

/// Peta semua mitra usaha.
///
/// Warna penanda mengikuti kategori (hijau brand untuk warung, warna lain
/// hanya untuk membedakan). Tap penanda menampilkan kartu bawah; ketuk kartu
/// untuk masuk ke detail. Filter kategori berlaku langsung ke peta, jadi tidak
/// ada peta yang menampilkan semua titik lalu sebagian besar tidak terlihat.
class MitraUsahaPetaScreen extends ConsumerStatefulWidget {
  const MitraUsahaPetaScreen({super.key});

  @override
  ConsumerState<MitraUsahaPetaScreen> createState() =>
      _MitraUsahaPetaScreenState();
}

class _MitraUsahaPetaScreenState extends ConsumerState<MitraUsahaPetaScreen> {
  /// Batas zoom: 11 masih melihat seluruh kecamatan, 18 sampai tingkat
  /// pintu toko. `any_map` memakai nilai berbeda per platform, jadi batas
  /// yang sama dipakai untuk widget dan untuk tombol.
  static const double _zoomMin = 11;

  static const double _zoomMax = 19;

  KategoriMitraUsaha? _kategori;

  MitraUsaha? _terpilih;

  /// Diisi lewat `onMapCreated`. Tanpa ini tombol zoom tidak punya kendali.
  AnyMapController? _kontrol;

  List<MitraUsaha> _data() => _kategori == null
      ? daftarMitraUsaha
      : daftarMitraUsaha
          .where((MitraUsaha m) => m.kategori.contains(_kategori))
          .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final List<MitraUsaha> data = _data();
    final MitraUsaha? terpilih =
        _terpilih == null ? null : mitraUsahaById(_terpilih!.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Mitra'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Daftar mitra',
            icon: const AppIcon(Ik.shop, size: 22),
            onPressed: () => context.canPop() ? context.pop() : context.go('/mitra-usaha'),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: AnyMapWidget(
              adapter: MapLibreAdapter(styleUrl: gayaPetaGratis),
              // Kamera awal = auto-fit ke semua marker (pusat bounds + zoom
              // dari rentang titik). Kosong -> pusat Kuningan Barat.
              initialCamera: _kameraFit(data),
              onMapCreated: (AnyMapController c) => _kontrol = c,
              minZoom: _zoomMin,
              maxZoom: _zoomMax,
              markers: <AnyMarker>[
                for (final MitraUsaha m in data)
                  AnyMarker(
                    id: m.id,
                    position: AnyLatLng(m.titik.lat, m.titik.lng),
                    anchor: AnyMarkerAnchor.center,
                    icon: _Pin(
                      warna: m.kategoriUtama.warna,
                      ikon: m.kategoriUtama.ikon,
                      terpilih: terpilih?.id == m.id,
                    ),
                  ),
              ],
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              compassEnabled: true,
              onTap: (AnyLatLng p) => _petaDipilih(p, data),
            ),
          ),
          Positioned(
            left: AppSpacing.screen,
            right: AppSpacing.screen,
            top: AppSpacing.sm,
            child: _GulirKategori(
              aktif: _kategori,
              jumlah: _jumlah(),
              onPilih: (KategoriMitraUsaha? k) {
                Haptics.selection();
                setState(() {
                  _kategori = k;
                  _terpilih = null;
                });
              },
            ),
          ),
          if (terpilih != null)
            Positioned(
              left: AppSpacing.screen,
              right: AppSpacing.screen,
              bottom: AppSpacing.lg,
              child: _KartuTerpilih(item: terpilih),
            ),
          const Positioned(
            left: AppSpacing.screen,
            top: 64,
            child: AtribusiPeta(),
          ),
          // Zoom in / out di tengah kanan. `any_map` tidak menyediakan
          // tombol bawaan, jadi kamera digerakkan lewat controller.
          Positioned(
            right: AppSpacing.screen,
            top: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _TombolPeta(
                    ikon: Ik.plus,
                    label: 'Perbesar peta',
                    onTap: () => _ubahZoom(1),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _TombolPeta(
                    ikon: Ik.minus,
                    label: 'Perkecil peta',
                    onTap: () => _ubahZoom(-1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Gerakkan zoom satu tingkat. Posisi kamera dibaca dari peta saat tombol
  /// ditekan: `onCameraMove` tidak dipakai karena adapter MapLibre tidak
  /// meneruskan parameter itu ke peta aslinya.
  Future<void> _ubahZoom(double langkah) async {
    final AnyMapController? kontrol = _kontrol;
    if (kontrol == null) return;
    Haptics.selection();
    final AnyCameraPosition sekarang = await kontrol.getCameraPosition();
    double z = sekarang.zoom + langkah;
    if (z < _zoomMin) z = _zoomMin;
    if (z > _zoomMax) z = _zoomMax;
    await kontrol.animateCamera(
      AnyCameraPosition(
        target: sekarang.target,
        zoom: z,
        tilt: sekarang.tilt,
        bearing: sekarang.bearing,
      ),
      duration: const Duration(milliseconds: 280),
    );
  }

  /// `any_map` 1.0.0 tidak punya callback tap-per-marker, jadi penanda
  /// ditentukan dari titik yang ditekan: mitra terdekat dalam 60 meter yang
  /// dipilih. Kalau tidak ada yang dekat, pilihan dilepas.
  void _petaDipilih(AnyLatLng posisi, List<MitraUsaha> data) {
    Haptics.selection();
    MitraUsaha? terdekat;
    double jarakTerdekat = 0.06;
    for (final MitraUsaha m in data) {
      final double d = jarakKm(
        TitikPeta(lat: posisi.latitude, lng: posisi.longitude),
        m.titik,
      );
      if (d < jarakTerdekat) {
        jarakTerdekat = d;
        terdekat = m;
      }
    }
    setState(() {
      _terpilih = terdekat;
    });
  }

  Map<KategoriMitraUsaha, int> _jumlah() {
    final Map<KategoriMitraUsaha, int> out = <KategoriMitraUsaha, int>{};
    for (final KategoriMitraUsaha k in KategoriMitraUsaha.values) {
      out[k] = jumlahKategori(k);
    }
    return out;
  }

  /// Pusat default: Kuningan Barat (titik resmi, sama dengan `order.dart`).
  static const AnyLatLng _pusatDefault = AnyLatLng(-6.2365, 106.8219);

  /// Kamera yang memuat semua marker: pusat bounds + zoom dari rentang titik.
  static AnyCameraPosition _kameraFit(List<MitraUsaha> data) {
    if (data.isEmpty) {
      return AnyCameraPosition(target: _pusatDefault, zoom: 14);
    }
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final MitraUsaha m in data) {
      minLat = math.min(minLat, m.titik.lat);
      maxLat = math.max(maxLat, m.titik.lat);
      minLng = math.min(minLng, m.titik.lng);
      maxLng = math.max(maxLng, m.titik.lng);
    }
    final double rentang = math.max(maxLat - minLat, maxLng - minLng);
    // Satu layar ~ 360 / 2^zoom derajat; sisakan margin ~25%.
    double zoom = 14;
    if (rentang > 0) {
      final double z = math.log(360 * 0.6 / rentang) / math.ln2;
      zoom = z < 11.0 ? 11.0 : (z > 16.0 ? 16.0 : z);
    }
    return AnyCameraPosition(
      target: AnyLatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2),
      zoom: zoom,
    );
  }
}

// ------------------------------------------------------------------ bagian UI

class _GulirKategori extends StatelessWidget {
  const _GulirKategori({
    required this.aktif,
    required this.jumlah,
    required this.onPilih,
  });

  final KategoriMitraUsaha? aktif;
  final Map<KategoriMitraUsaha, int> jumlah;
  final ValueChanged<KategoriMitraUsaha?> onPilih;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          _Chip(
            label: 'Semua',
            aktif: aktif == null,
            onTap: () => onPilih(null),
          ),
          for (final KategoriMitraUsaha k in KategoriMitraUsaha.values)
            _Chip(
              label: '${k.label} ${jumlah[k] ?? 0}',
              aktif: aktif == k,
              onTap: () => onPilih(k),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.aktif, required this.onTap});

  final String label;
  final bool aktif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: aktif,
        showCheckmark: false,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _KartuTerpilih extends StatelessWidget {
  const _KartuTerpilih({required this.item});

  final MitraUsaha item;

  @override
  Widget build(BuildContext context) {
    final Color w = item.kategoriUtama.warna;
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(AppRadius.card),
      color: context.colors.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => context.push('/mitra-usaha/${item.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: w.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: AppIcon(item.kategoriUtama.ikon, size: 22, color: w),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      item.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.kelurahan.nama} - '
                      '${item.jamBukaPasti ? (item.is24Jam ? '24 jam' : item.jamBuka) : 'jam buka belum dikonfirmasi'}'
                      '${item.titikPerkiraan ? ' - titik perkiraan' : ''}',
                      style: context.text.bodySmall
                          ?.copyWith(color: context.semantic.textSecondary),
                    ),
                  ],
                ),
              ),
              const AppIcon(Ik.chevronRight, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({
    required this.warna,
    required this.ikon,
    required this.terpilih,
  });

  final Color warna;
  final Ik ikon;
  final bool terpilih;

  @override
  Widget build(BuildContext context) {
    final double d = terpilih ? 40 : 30;
    return Container(
      width: d,
      height: d,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: warna,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: terpilih ? 3 : 2),
        boxShadow: AppShadows.medium,
      ),
      child: AppIcon(ikon, size: terpilih ? 22 : 16, color: AppColors.white),
    );
  }
}

/// Tombol bulat mengambang di atas peta (zoom in / zoom out).
///
/// Ukuran 46x46, bukan 40: target sentuh minimum yang comfortable adalah
/// 44 dp, dan ini tombol yang dipakai sambil berjalan di jalan.
class _TombolPeta extends StatelessWidget {
  const _TombolPeta({
    required this.ikon,
    required this.label,
    required this.onTap,
  });

  final Ik ikon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: AppCard(
        onTap: onTap,
        radius: AppRadius.md,
        padding: EdgeInsets.zero,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Center(
            child: AppIcon(ikon, size: 22, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
