import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/haptics.dart';
import '../../features/order/data/order_state.dart';
import '../../features/order/presentation/pilih_lokasi_peta.dart';
import '../models/order.dart';
import '../services/lokasi_service.dart';
import 'app_icon.dart';

/// Kolom alamat dengan saran otomatis dan tombol pilih di peta.
///
/// Dua cara mengisi alamat, keduanya dipakai form ojek maupun jastip:
///   1. Ketik sebagian alamat lalu pilih dari saran (Nominatim). Alamat lengkap
///      dengan nama kelurahan ikut terisi.
///   2. Tekan ikon peta, geser penanda, lalu simpan. Untuk alamat yang tidak
///      ada di basis data OpenStreetMap, misalnya alamat dalam kampung.
///
/// Tanpa ini, alamat yang diketik manual sering tidak ketemu di peta sehingga
/// tarif jatuh ke harga minimum yang salah.
class AlamatAutocomplete extends ConsumerStatefulWidget {
  const AlamatAutocomplete({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.ikon,
    required this.onUbah,
    this.validator,
    this.minTeks = 3,
    this.judulPeta,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final Ik ikon;

  /// Dipanggil setiap kali alamat berubah. [titik] null berarti alamatnya
  /// belum ketemu di peta.
  final void Function(String teks, TitikPeta? titik) onUbah;

  final String? Function(String?)? validator;

  /// Panjang minimum sebelum saran dicari.
  final int minTeks;

  /// Judul layar peta. Kalau kosong, pakai [label].
  final String? judulPeta;

  @override
  ConsumerState<AlamatAutocomplete> createState() =>
      _AlamatAutocompleteState();
}

class _AlamatAutocompleteState extends ConsumerState<AlamatAutocomplete> {
  final FocusNode _fokus = FocusNode();

  Timer? _jeda;
  List<SaranAlamat> _saran = const <SaranAlamat>[];
  bool _mencari = false;
  TitikPeta _terkunci = const TitikPeta(lat: 0, lng: 0);
  String _teksTerkunci = '';

  @override
  void dispose() {
    _jeda?.cancel();
    _fokus.dispose();
    super.dispose();
  }

  void _ubah(String teks) {
    // Teks berubah = koordinat lama tidak boleh dipakai lagi. Kalau tidak,
    // tarif dihitung dari lokasi yang bukan yang dipilih pengguna.
    if (teks != _teksTerkunci) {
      _terkunci = const TitikPeta(lat: 0, lng: 0);
      _teksTerkunci = '';
    }
    widget.onUbah(teks, null);
    _jeda?.cancel();
    if (teks.trim().length < widget.minTeks) {
      setState(() {
        _saran = const <SaranAlamat>[];
        _mencari = false;
      });
      return;
    }
    setState(() => _mencari = true);
    _jeda = Timer(const Duration(milliseconds: 700), () => _cari(teks));
  }

  Future<void> _cari(String teks) async {
    final LokasiService svc = ref.read(lokasiServiceProvider);
    final List<SaranAlamat> hasil = await svc.cariAlamatSaran(teks);
    if (!mounted || teks != widget.controller.text.trim()) return;
    setState(() {
      _mencari = false;
      _saran = hasil;
    });
  }

  void _pilihSaran(SaranAlamat s) {
    Haptics.selection();
    setState(() {
      _saran = const <SaranAlamat>[];
      _terkunci = s.titik;
      _teksTerkunci = s.teks;
    });
    widget.controller.text = s.teks.isEmpty ? s.titik.teks : s.teks;
    widget.controller.selection = TextSelection.collapsed(
      offset: widget.controller.text.length,
    );
    _fokus.unfocus();
    widget.onUbah(widget.controller.text, s.titik);
  }

  Future<void> _pilihDiPeta() async {
    Haptics.selection();
    _fokus.unfocus();
    setState(() => _saran = const <SaranAlamat>[]);
    final LokasiTerpilih? hasil =
        await context.push<LokasiTerpilih>(
      '/pilih-lokasi',
      extra: MintaLokasi(
        judul: widget.judulPeta ?? widget.label,
        awal: _terkunci.valid ? _terkunci : null,
      ),
    );
    if (!mounted || hasil == null) return;
    setState(() {
      _terkunci = hasil.titik;
      _teksTerkunci = hasil.teks;
    });
    widget.controller.text = hasil.teks;
    widget.onUbah(hasil.teks, hasil.titik);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextFormField(
          controller: widget.controller,
          focusNode: _fokus,
          onChanged: _ubah,
          validator: widget.validator,
          textInputAction: TextInputAction.search,
          inputFormatters: <TextInputFormatter>[
            LengthLimitingTextInputFormatter(160),
          ],
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: AppIcon(widget.ikon, size: 20),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (_mencari)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (widget.controller.text.isNotEmpty)
                  IconButton(
                    tooltip: 'Hapus',
                    icon: const AppIcon(Ik.close, size: 18),
                    onPressed: () {
                      widget.controller.clear();
                      _ubah('');
                    },
                  ),
                IconButton(
                  tooltip: 'Pilih di peta',
                  icon: const AppIcon(Ik.pinMitra, size: 20),
                  onPressed: _pilihDiPeta,
                ),
              ],
            ),
          ),
        ),
        if (_saran.isNotEmpty) _DaftarSaran(saran: _saran, onPilih: _pilihSaran),
      ],
    );
  }
}

/// Saran alamat di bawah kolom.
///
/// Ditampilkan di dalam flow form (bukan overlay) supaya tidak menutupi field
/// lain dan tidak perlu Overlay/Portal yang harus dibersihkan.
class _DaftarSaran extends StatelessWidget {
  const _DaftarSaran({required this.saran, required this.onPilih});

  final List<SaranAlamat> saran;
  final ValueChanged<SaranAlamat> onPilih;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: context.semantic.line),
        borderRadius: BorderRadius.circular(AppRadius.card),
        color: context.colors.surface,
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 220),
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: saran.length,
          itemBuilder: (BuildContext context, int i) {
            final SaranAlamat s = saran[i];
            return ListTile(
              dense: true,
              leading: const AppIcon(Ik.place, size: 20, color: AppColors.primary),
              title: Text(
                s.jalan,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium,
              ),
              subtitle: s.area.isEmpty
                  ? null
                  : Text(
                      s.area,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall
                          ?.copyWith(color: context.semantic.textSecondary),
                    ),
              onTap: () => onPilih(s),
            );
          },
        ),
      ),
    );
  }
}
