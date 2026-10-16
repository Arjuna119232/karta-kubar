import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/widgets/animated_list_item.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/status_views.dart';
import '../data/mitra_usaha_lokal.dart';
import '../domain/mitra_usaha.dart';

/// Daftar mitra usaha: filter jenis, kartu dengan jarak dan jam buka.
class MitraUsahaScreen extends ConsumerStatefulWidget {
  const MitraUsahaScreen({super.key});

  @override
  ConsumerState<MitraUsahaScreen> createState() => _MitraUsahaScreenState();
}

class _MitraUsahaScreenState extends ConsumerState<MitraUsahaScreen> {
  /// null = semua jenis.
  JenisMitraUsaha? _filter;

  @override
  Widget build(BuildContext context) {
    final List<MitraUsaha> semua = ref.watch(mitraUsahaProvider);
    final List<MitraUsaha> data = _filter == null
        ? semua
        : semua
            .where((MitraUsaha m) => m.jenis == _filter)
            .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Mitra Usaha')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen, 8, AppSpacing.screen, 40),
          children: <Widget>[
            const _Catatan(),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  _Pilihan(
                    label: 'Semua',
                    aktif: _filter == null,
                    onTap: () => _pilih(null),
                  ),
                  for (final JenisMitraUsaha j in JenisMitraUsaha.values)
                    _Pilihan(
                      label: j.label,
                      aktif: _filter == j,
                      onTap: () => _pilih(j),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (data.isEmpty)
              const AppEmptyState(
                title: 'Belum ada mitra',
                message: 'Mitra usaha untuk jenis ini belum terdaftar.',
              )
            else
              for (final (int i, MitraUsaha m) in data.indexed)
                AnimatedListItem(
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.gap),
                    child: _KartuMitra(item: m),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  void _pilih(JenisMitraUsaha? j) {
    Haptics.selection();
    setState(() => _filter = j);
  }
}

class _Catatan extends StatelessWidget {
  const _Catatan();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppIcon(Ik.handHeart, size: 22, color: context.colors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Titip belanja ke warung, pasar, agen gas, atau depot galon '
              'lewat Jastip. Data masih contoh: lokasi dan harga perkiraan.',
              style: context.text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pilihan extends StatelessWidget {
  const _Pilihan({
    required this.label,
    required this.aktif,
    required this.onTap,
  });

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

class _KartuMitra extends StatelessWidget {
  const _KartuMitra({required this.item});

  final MitraUsaha item;

  @override
  Widget build(BuildContext context) {
    final Color w = item.jenis.warna;
    final double km = item.jarakDariPusatKm;
    final String jarak =
        km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';
    return AppCard(
      onTap: () => context.push('/mitra-usaha/${item.id}'),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: w.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Center(child: AppIcon(item.jenis.ikon, size: 26, color: w)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.nama, style: context.text.titleSmall),
                const SizedBox(height: 2),
                Text(
                  '${item.jenis.label} - buka ${item.jamBuka}',
                  style: context.text.bodySmall
                      ?.copyWith(color: context.semantic.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  '$jarak dari pusat kelurahan',
                  style: context.text.labelSmall
                      ?.copyWith(color: context.semantic.textSecondary),
                ),
              ],
            ),
          ),
          const AppIcon(Ik.chevronRight, size: 20),
        ],
      ),
    );
  }
}
