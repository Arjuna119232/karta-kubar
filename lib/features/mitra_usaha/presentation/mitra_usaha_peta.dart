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
import '../../../shared/widgets/app_icon.dart';
import '../../order/presentation/widgets_order.dart';
import '../data/mitra_usaha_lokal.dart';
import '../domain/mitra_usaha.dart';

/// Peta semua mitra usaha.
///
/// Warna penanda mengikuti kategori (hijau brand untuk warung, warna lain
/// hanya untuk membedakan). Tap penanda menampilkan kartu bawah; ketuk kartu
/// untuk masuk ke detail. Filter kategori berlaku langsung ke peta, jadi tidak
/// ada peta yang menampilkan 47 titik lalu 40 di antaranya tidak terlihat.
class MitraUsahaPetaScreen extends ConsumerStatefulWidget {
  const MitraUsahaPetaScreen({super.key});

  @override
  ConsumerState<MitraUsahaPetaScreen> createState() =>
      _MitraUsahaPetaScreenState();
}

class _MitraUsahaPetaScreenState extends ConsumerState<MitraUsahaPetaScreen> {
  KategoriMitraUsaha? _kategori;

  MitraUsaha? _terpilih;

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
              initialCamera: AnyCameraPosition(
                target: _pusat(data),
                zoom: 13,
              ),
              markers: <AnyMarker>[
                for (final MitraUsaha m in data)
                  AnyMarker(
                    id: m.id,
                    position: AnyLatLng(m.titik.lat, m.titik.lng),
                    anchor: AnyMarkerAnchor.center,
                    icon: _Pin(
                      warna: m.kategoriUtama.warna,
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
        ],
      ),
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

  static AnyLatLng _pusat(List<MitraUsaha> data) {
    if (data.isEmpty) return const AnyLatLng(-6.2365, 106.8219);
    double lat = 0;
    double lng = 0;
    for (final MitraUsaha m in data) {
      lat += m.titik.lat;
      lng += m.titik.lng;
    }
    final double n = data.length.toDouble();
    return AnyLatLng(lat / n, lng / n);
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
                      '${item.is24Jam ? '24 jam' : item.jamBuka}',
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
  const _Pin({required this.warna, required this.terpilih});

  final Color warna;
  final bool terpilih;

  @override
  Widget build(BuildContext context) {
    final double d = terpilih ? 38 : 22;
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        color: warna,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: terpilih ? 3 : 2),
        boxShadow: AppShadows.medium,
      ),
    );
  }
}
