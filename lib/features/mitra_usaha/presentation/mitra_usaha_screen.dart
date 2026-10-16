import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/models/order.dart';
import '../../../shared/widgets/animated_list_item.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/status_views.dart';
import '../data/mitra_usaha_lokal.dart';
import '../domain/mitra_usaha.dart';

/// Daftar mitra usaha: cari, filter kategori, filter kelurahan, peta.
///
/// Semua data lokal, jadi halaman ini tidak pernah menunggu server. Pencarian
/// cukup mencocokkan nama, alamat, kelurahan, dan kategori.
class MitraUsahaScreen extends ConsumerStatefulWidget {
  const MitraUsahaScreen({super.key});

  @override
  ConsumerState<MitraUsahaScreen> createState() => _MitraUsahaScreenState();
}

class _MitraUsahaScreenState extends ConsumerState<MitraUsahaScreen> {
  final TextEditingController _cari = TextEditingController();

  /// null = semua kategori.
  KategoriMitraUsaha? _kategori;

  /// null = semua kelurahan.
  Kelurahan? _kelurahan;

  @override
  void dispose() {
    _cari.dispose();
    super.dispose();
  }

  List<MitraUsaha> _saring(List<MitraUsaha> semua) {
    return saringMitraUsaha(
      kategori: _kategori,
      kelurahan: _kelurahan,
      cari: _cari.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<MitraUsaha> semua = daftarMitraUsaha;
    final List<MitraUsaha> data = _saring(semua);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mitra Usaha'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Lihat peta',
            icon: const AppIcon(Ik.place, size: 22),
            onPressed: () {
              Haptics.selection();
              context.push('/mitra-usaha/peta');
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen, 8, AppSpacing.screen, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _KolomCari(
                    controller: _cari,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _Ringkasan(data: data, semua: semua),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
            _GulirChip(
              items: <_ChipData>[
                _ChipData(
                  label: 'Semua',
                  jumlah: semua.length,
                  aktif: _kategori == null && _kelurahan == null,
                  onTap: () => _pilih(null, null),
                ),
                for (final KategoriMitraUsaha k in KategoriMitraUsaha.values)
                  _ChipData(
                    label: k.label,
                    jumlah: jumlahKategori(k),
                    aktif: _kategori == k,
                    onTap: () =>
                        _pilih(_kategori == k ? null : k, _kelurahan),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _GulirChip(
              items: <_ChipData>[
                for (final Kelurahan k in Kelurahan.semua)
                  _ChipData(
                    label: k.nama,
                    jumlah: jumlahKelurahan(k),
                    aktif: _kelurahan == k,
                    onTap: () => _pilih(
                      _kategori,
                      _kelurahan == k ? null : k,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: data.isEmpty
                  ? AppEmptyState(
                      title: 'Tidak ada mitra yang cocok',
                      message: 'Ubah kata kunci atau kosongkan filternya.',
                      actionLabel: 'Bersihkan filter',
                      onAction: _bersihkan,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screen, 0, AppSpacing.screen, 40),
                      itemCount: data.length,
                      itemBuilder: (BuildContext context, int i) =>
                          AnimatedListItem(
                        index: i,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.gap),
                          child: _KartuMitra(item: data[i]),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _pilih(KategoriMitraUsaha? k, Kelurahan? kel) {
    Haptics.selection();
    setState(() {
      _kategori = k;
      _kelurahan = kel;
    });
  }

  void _bersihkan() {
    Haptics.selection();
    setState(() {
      _kategori = null;
      _kelurahan = null;
      _cari.clear();
    });
  }
}

/// Isi filter sedang aktif, supaya pengguna tahu kenapa daftar mengecil.
class _Ringkasan extends StatelessWidget {
  const _Ringkasan({required this.data, required this.semua});

  final List<MitraUsaha> data;
  final List<MitraUsaha> semua;

  @override
  Widget build(BuildContext context) {
    final int buka = data
        .where((MitraUsaha m) => m.jamBukaPasti && m.isOpen)
        .length;
    final int semantics = data.where((MitraUsaha m) => m.is24Jam).length;
    return Row(
      children: <Widget>[
        _Angka(
          nilai: '${data.length}',
          label: data.length == semua.length ? 'mitra' : 'dari ${semua.length}',
        ),
        _Angka(nilai: '$buka', label: 'buka sekarang'),
        _Angka(nilai: '$semantics', label: 'buka 24 jam'),
      ],
    );
  }
}

class _Angka extends StatelessWidget {
  const _Angka({required this.nilai, required this.label});

  final String nilai;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(nilai, style: context.text.headlineSmall),
          Text(
            label,
            style: context.text.labelSmall
                ?.copyWith(color: context.semantic.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _KolomCari extends StatelessWidget {
  const _KolomCari({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Cari warung, pasar, galon, gas...',
        prefixIcon: const AppIcon(Ik.search, size: 20),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Hapus',
                icon: const AppIcon(Ik.close, size: 18),
                onPressed: () {
                  Haptics.selection();
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
    );
  }
}

class _ChipData {
  const _ChipData({
    required this.label,
    required this.jumlah,
    required this.aktif,
    required this.onTap,
  });

  final String label;
  final int jumlah;
  final bool aktif;
  final VoidCallback onTap;
}

class _GulirChip extends StatelessWidget {
  const _GulirChip({required this.items});

  final List<_ChipData> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        children: <Widget>[
          for (final _ChipData d in items)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text('${d.label} ${d.jumlah}'),
                selected: d.aktif,
                showCheckmark: false,
                onSelected: (_) => d.onTap(),
              ),
            ),
        ],
      ),
    );
  }
}

class _KartuMitra extends StatelessWidget {
  const _KartuMitra({required this.item});

  final MitraUsaha item;

  @override
  Widget build(BuildContext context) {
    final KategoriMitraUsaha k = item.kategoriUtama;
    final Color w = k.warna;
    return AppCard(
      onTap: () => context.push('/mitra-usaha/${item.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: w.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Center(child: AppIcon(k.ikon, size: 26, color: w)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.nama, style: context.text.titleSmall),
                const SizedBox(height: 3),
                Text(
                  item.alamat,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall
                      ?.copyWith(color: context.semantic.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: 4,
                  children: <Widget>[
                    _Lencana(
                      teks: item.jamBukaPasti
                          ? (item.is24Jam ? '24 jam' : item.jamBuka)
                          : 'jam buka belum dikonfirmasi',
                      warna: !item.jamBukaPasti
                          ? context.semantic.textSecondary
                          : (item.isOpen
                              ? AppColors.success
                              : AppColors.warning),
                    ),
                    _Lencana(teks: k.label, warna: w),
                    _Lencana(
                      teks: jarakPendek(item.jarakDariPusatKm),
                      warna: context.semantic.textSecondary,
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
}

class _Lencana extends StatelessWidget {
  const _Lencana({required this.teks, required this.warna});

  final String teks;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        teks,
        style: context.text.labelSmall?.copyWith(color: warna),
      ),
    );
  }
}
