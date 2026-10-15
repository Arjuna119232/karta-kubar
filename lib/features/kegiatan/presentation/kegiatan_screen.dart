import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_id.dart';
import '../../../shared/widgets/animated_list_item.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../../../shared/widgets/status_views.dart';
import '../../../shared/widgets/app_icon.dart';
import '../domain/kegiatan.dart';
import '../../../shared/widgets/cover_pilih.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/widgets/app_dialogs.dart';
import 'kalender_kegiatan.dart';

/// Layar kegiatan. Data lewat repository (`kegiatanProvider`), bukan data demo.
class KegiatanScreen extends ConsumerStatefulWidget {
  const KegiatanScreen({super.key});

  @override
  ConsumerState<KegiatanScreen> createState() => _KegiatanScreenState();
}

class _KegiatanScreenState extends ConsumerState<KegiatanScreen> {
  String _category = 'Semua';

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Kegiatan>> async = ref.watch(kegiatanProvider);
    final List<Kegiatan> semua = async.valueOrNull ?? const <Kegiatan>[];
    final List<Kegiatan> _filtered = _category == 'Semua'
        ? semua
        : semua.where((Kegiatan a) => a.kategori == _category).toList();
    final List<Kegiatan> upcoming =
        _filtered.where((Kegiatan a) => a.mendatang).toList();
    final List<Kegiatan> past =
        _filtered.where((Kegiatan a) => !a.mendatang).toList();

    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 12,
                AppSpacing.screen, 0),
            child: Row(
              children: <Widget>[
                Text('Kegiatan', style: context.text.headlineMedium),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    Haptics.light();
                    AppSheet.show<void>(
                      context,
                      builder: (BuildContext ctx) => Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Kalender kegiatan',
                              style: ctx.text.titleLarge),
                          const SizedBox(height: 4),
                          Text(
                            'Pilih tanggal untuk lihat kegiatan',
                            style: ctx.text.bodySmall
                                ?.copyWith(color: ctx.semantic.textSecondary),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          KalenderKegiatan(
                            kegiatan: semua,
                            accent: ctx.colors.primary,
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const AppIcon(Ik.calendar),
                  tooltip: 'Kalender',
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              children: <Widget>[
                for (final String c in const <String>[
                  'Semua',
                  'Sosial',
                  'Olahraga',
                  'Keagamaan',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _CategoryChip(
                      label: c,
                      selected: c == _category,
                      onTap: () => setState(() => _category = c),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: async.when(
              loading: () => const SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                child: ShimmerListSkeleton(itemCount: 5, itemHeight: 96),
              ),
              error: (Object e, StackTrace st) => AppErrorState(
                onRetry: () => ref.invalidate(kegiatanProvider),
              ),
              data: (_) => _filtered.isEmpty
                  ? const AppEmptyState(
                      art: 'empty_kegiatan',
                      title: 'Belum ada kegiatan',
                      message: 'Kegiatan pada kategori ini belum tersedia.',
                    )
                  : RefreshIndicator(
                      color: context.colors.primary,
                      onRefresh: () async {
                        ref.invalidate(kegiatanProvider);
                        await Future<void>.delayed(
                            const Duration(milliseconds: 600));
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screen, 8, AppSpacing.screen, 96),
                        children: <Widget>[
                          if (_terdekat(upcoming) != null)
                            AnimatedListItem(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.lg),
                                child: _HitungMundur(
                                    kegiatan: _terdekat(upcoming)!),
                              ),
                            ),
                          if (upcoming.isNotEmpty) ...<Widget>[
                            const _GroupLabel('Akan Datang'),
                            for (final (int i, Kegiatan a) in upcoming.indexed)
                              AnimatedListItem(
                                index: i,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: AppSpacing.gap),
                                  child: _ActivityCard(activity: a),
                                ),
                              ),
                          ],
                          if (past.isNotEmpty) ...<Widget>[
                            const _GroupLabel('Sudah Lewat'),
                            for (final (int i, Kegiatan a) in past.indexed)
                              AnimatedListItem(
                                index: i,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: AppSpacing.gap),
                                  child: _ActivityCard(activity: a),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kegiatan mendatang dengan tanggal paling dekat dari sekarang.
Kegiatan? _terdekat(List<Kegiatan> daftar) {
  final DateTime sekarang = DateTime.now();
  Kegiatan? hasil;
  for (final Kegiatan k in daftar) {
    final DateTime? t = k.tanggal;
    if (t == null || t.isBefore(DateTime(sekarang.year, sekarang.month, sekarang.day))) {
      continue;
    }
    if (hasil == null || t.isBefore(hasil.tanggal!)) hasil = k;
  }
  return hasil;
}

/// Kartu hitung mundur untuk kegiatan terdekat.
class _HitungMundur extends StatelessWidget {
  const _HitungMundur({required this.kegiatan});

  final Kegiatan kegiatan;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime hariIni = DateTime(now.year, now.month, now.day);
    final DateTime t = kegiatan.tanggal!;
    final int selisih = DateTime(t.year, t.month, t.day).difference(hariIni).inDays;
    final String angka = selisih <= 0 ? 'Hari ini' : selisih == 1 ? 'Besok' : '$selisih hari lagi';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppShadows.colored(AppColors.primary),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'KEGIATAN TERDEKAT',
                  style: context.text.labelSmall
                      ?.copyWith(color: AppColors.heroSubtext),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  kegiatan.judul,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleMedium
                      ?.copyWith(color: AppColors.white),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(
              angka,
              style: context.text.titleSmall?.copyWith(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Text(
        text.toUpperCase(),
        style: context.text.labelSmall
            ?.copyWith(color: context.semantic.textSecondary),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        Haptics.selection();
        onTap();
      },
      showCheckmark: false,
      selectedColor: context.colors.primary,
      labelStyle: context.text.labelMedium?.copyWith(
        color: selected ? AppColors.white : context.semantic.textSecondary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        side: BorderSide(
            color: selected ? context.colors.primary : context.semantic.line),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  final Kegiatan activity;

  @override
  Widget build(BuildContext context) {
    final Color cat = warnaKategori(activity.kategori);
    final bool selesai = !activity.mendatang;

    return AppCard(
      onTap: () => _showDetail(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: 104,
            width: double.infinity,
            child: AppCover(coverKategori(activity.kategori), radius: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cat.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  activity.kategori,
                  style: context.text.labelSmall?.copyWith(color: cat),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: selesai
                      ? context.semantic.line
                      : context.colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  selesai ? 'Selesai' : DateId.hitungMundur(activity.tanggal),
                  style: context.text.labelSmall?.copyWith(
                    color: selesai
                        ? context.semantic.textSecondary
                        : context.colors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(activity.judul, style: context.text.titleMedium),
          const SizedBox(height: 10),
          _MetaRow(
            icon: Ik.calendar,
            text: DateId.hariTanggal(activity.tanggal),
          ),
          const SizedBox(height: 6),
          _MetaRow(icon: Ik.place, text: activity.lokasi),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext c) {
        final Color cat = warnaKategori(activity.kategori);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 130,
                width: double.infinity,
                child: AppCover(coverKategori(activity.kategori), radius: 18),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cat.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(activity.kategori,
                    style: c.text.labelSmall?.copyWith(color: cat)),
              ),
              const SizedBox(height: 12),
              Text(activity.judul, style: c.text.headlineSmall),
              const SizedBox(height: 16),
              _MetaRow(
                icon: Ik.calendar,
                text: DateId.hariTanggal(activity.tanggal),
              ),
              const SizedBox(height: 8),
              _MetaRow(icon: Ik.place, text: activity.lokasi),
              const SizedBox(height: 8),
              _MetaRow(
                icon: activity.mendatang
                    ? Ik.clock
                    : Ik.checkCircle,
                text: activity.mendatang
                    ? DateId.hitungMundur(activity.tanggal)
                    : 'Kegiatan sudah selesai',
              ),
              const SizedBox(height: 20),
              Text(
                activity.mendatang
                    ? 'Tandai kehadiran kamu lewat menu Absen di Beranda saat kegiatan berlangsung.'
                    : 'Terima kasih untuk partisipasi kamu pada kegiatan ini.',
                style: c.text.bodyMedium
                    ?.copyWith(color: c.semantic.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final Ik icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        AppIcon(icon, size: 16, color: context.semantic.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: context.text.bodySmall
                ?.copyWith(color: context.semantic.textSecondary),
          ),
        ),
      ],
    );
  }
}
