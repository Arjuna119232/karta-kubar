import 'package:any_map/any_map.dart';
import 'package:any_map_maplibre/any_map_maplibre.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/hasil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/models/order.dart';
import '../../../shared/services/lokasi_service.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/primary_button.dart';
import 'widgets_order.dart';

/// Hasil pilihan peta: koordinat + alamat nama jalan.
@immutable
class LokasiTerpilih {
  const LokasiTerpilih({required this.titik, required this.alamat});

  final TitikPeta titik;

  /// Nama jalan dari Nominatim. Kosong kalau server tidak bisa dibaca.
  final String alamat;

  /// Alamat siap tempel ke kolom isian. Kalau alamat kosong, pakai koordinat
  /// supaya kolom tidak terasa kosong dan tidak menampilkan "null".
  String get teks => alamat.isNotEmpty ? alamat : titik.teks;
}

/// Permintaan buka peta dari satu kolom form.
///
/// `judul` dipakai sebagai judul layar peta supaya pengguna tahu sedang memilih
/// jemput, tujuan, lokasi beli, atau alamat antar.
@immutable
class MintaLokasi {
  const MintaLokasi({this.judul = 'Pilih lokasi', this.awal});

  final String judul;

  /// Titik yang dipakai sebagai titik awal peta.
  final TitikPeta? awal;
}

/// Pilih titik dengan menggeser peta.
///
/// Penanda ditahan di tengah layar: begitu peta berhenti digeser, koordinat di
/// tengah itu yang dipakai. Setelah tombol simpan, nama jalannya dibaca balik
/// dari koordinat (Nominatim reverse) supaya kolom isian terisi alamat asli,
/// bukan angka koordinat.
///
/// Balikan: `context.pop(LokasiTerpilih)` atau `context.pop(null)` kalau batal.
class PilihLokasiPetaScreen extends StatefulWidget {
  const PilihLokasiPetaScreen({
    super.key,
    this.judul = 'Pilih lokasi',
    this.awal,
  });

  final String judul;

  /// Titik awal. Kalau tidak diisi, pakai lokasi perangkat; kalau lokasi tidak
  /// bisa dibaca, pakai pusat Kuningan Barat.
  final TitikPeta? awal;

  @override
  State<PilihLokasiPetaScreen> createState() => _PilihLokasiPetaScreenState();
}

class _PilihLokasiPetaScreenState extends State<PilihLokasiPetaScreen> {
  final LokasiService _svc = LokasiService();

  TitikPeta _tengah = titikKuninganBarat;
  AnyCameraPosition _kamera = AnyCameraPosition(
    target: AnyLatLng(-6.2365, 106.8219),
    zoom: 16,
  );
  String _alamatTeks = '';
  bool _sibuk = false;
  bool _sudahTebak = false;

  @override
  void dispose() {
    _svc.buang();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.judul),
        actions: <Widget>[
          if (_sibuk)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: PrimaryButton(
            label: 'Simpan lokasi ini',
            icon: Ik.check,
            onPressed: _simpan,
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: AnyMapWidget(
              adapter: MapLibreAdapter(styleUrl: gayaPetaGratis),
              initialCamera: _kamera,
              onMapCreated: (_) => _tebakAwal(),
              onCameraMove: (AnyCameraPosition c) => _kamera = c,
              onCameraIdle: _kameraSelesai,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              compassEnabled: true,
            ),
          ),
          // Penanda tengah: tidak bisa digeser, peta digeser untuk memindahkannya.
          const Center(
            child: IgnorePointer(
              child: _PinTengah(),
            ),
          ),
          Positioned(
            left: AppSpacing.screen,
            right: AppSpacing.screen,
            bottom: AppSpacing.md,
            child: _KartuAlamat(
              teks: _alamatTeks,
              koordinat:
                  '${_tengah.lat.toStringAsFixed(5)}, ${_tengah.lng.toStringAsFixed(5)}',
            ),
          ),
        ],
      ),
    );
  }

  /// Coba lokasi perangkat satu kali saja, jangan diulang tiap kali widget
  /// peta dibangun ulang.
  Future<void> _tebakAwal() async {
    if (_sudahTebak) return;
    _sudahTebak = true;
    if (widget.awal != null && widget.awal!.valid) {
      setState(() => _tengah = widget.awal!);
      return;
    }
    final TitikPeta? saya = await _svc.posisiSaya().then((Hasil<TitikPeta> h) {
      return h.berhasil ? h.data : null;
    });
    if (!mounted || saya == null || !saya.valid) return;
    setState(() {
      _tengah = saya;
      _kamera = AnyCameraPosition(target: AnyLatLng(saya.lat, saya.lng), zoom: 16);
    });
  }

  /// Peta berhenti digeser: koordinat tengah layar = titik yang dipilih.
  void _kameraSelesai() {
    final AnyLatLng t = _kamera.target;
    if (!t.latitude.isFinite || !t.longitude.isFinite) return;
    setState(() => _tengah = TitikPeta(lat: t.latitude, lng: t.longitude));
    _bacaAlamat();
  }

  Future<void> _bacaAlamat() async {
    setState(() => _sibuk = true);
    final String teks = await _svc.reverseAlamat(_tengah);
    if (!mounted) return;
    setState(() {
      _sibuk = false;
      if (teks.isNotEmpty) _alamatTeks = teks;
    });
  }

  Future<void> _simpan() async {
    if (!_tengah.valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Peta belum selesai dimuat.')),
      );
      return;
    }
    Haptics.success();
    context.pop(
      LokasiTerpilih(titik: _tengah, alamat: _alamatTeks),
    );
  }
}

/// Penanda tengah: bulat tengah + titik, gaya Google Maps.
class _PinTengah extends StatelessWidget {
  const _PinTengah();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 3),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        Container(width: 2, height: 18, color: AppColors.primary),
      ],
    );
  }
}

/// Alamat di bawah peta: nama jalan dari server, plus koordinat sebagai
/// cadangan supaya pengguna tahu pasti mana yang dipilih.
class _KartuAlamat extends StatelessWidget {
  const _KartuAlamat({required this.teks, required this.koordinat});

  final String teks;
  final String koordinat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AppIcon(Ik.pinMitra, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  teks.isEmpty ? 'Alamat belum terbaca' : teks,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  koordinat,
                  style: context.text.labelSmall
                      ?.copyWith(color: context.semantic.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
