import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_id.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/status_views.dart';
import '../../../shared/widgets/app_icon.dart';
import '../domain/kegiatan.dart';

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
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kalender kegiatan segera hadir')),
                  ),
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
            child: _filtered.isEmpty
                ? const AppEmptyState(
                    art: 'empty_kegiatan',
                    title: 'Belum ada kegiatan',
                    message: 'Kegiatan pada kategori ini belum tersedia.',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 8,
                        AppSpacing.screen, 96),
                    children: <Widget>[
                      if (upcoming.isNotEmpty) ...<Widget>[
                        const _GroupLabel('Akan Datang'),
                        for (final Kegiatan a in upcoming)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.gap),
                            child: _ActivityCard(activity: a),
                          ),
                      ],
                      if (past.isNotEmpty) ...<Widget>[
                        const _GroupLabel('Sudah Lewat'),
                        for (final Kegiatan a in past)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.gap),
                            child: _ActivityCard(activity: a),
                          ),
                      ],
                    ],
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
        HapticFeedback.selectionClick();
        onTap();
      },
      showCheckmark: false,
      selectedColor: context.colors.primary,
      labelStyle: context.text.labelMedium?.copyWith(
        color: selected ? Colors.white : context.semantic.textSecondary,
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
    final Color cat = warnaKategori(activity.category);
    final bool selesai = !activity.upcoming;

    return AppCard(
      onTap: () => _showDetail(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: 104,
            width: double.infinity,
            child: AppCover(coverKategori(activity.category), radius: 14),
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
                  activity.category,
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
                  selesai ? 'Selesai' : DateId.hitungMundur(activity.date),
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
          Text(activity.title, style: context.text.titleMedium),
          const SizedBox(height: 10),
          _MetaRow(
            icon: Ik.calendar,
            text: DateId.hariTanggal(activity.date),
          ),
          const SizedBox(height: 6),
          _MetaRow(icon: Ik.place, text: activity.location),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext c) {
        final Color cat = warnaKategori(activity.category);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 130,
                width: double.infinity,
                child: AppCover(coverKategori(activity.category), radius: 18),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cat.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(activity.category,
                    style: c.text.labelSmall?.copyWith(color: cat)),
              ),
              const SizedBox(height: 12),
              Text(activity.title, style: c.text.headlineSmall),
              const SizedBox(height: 16),
              _MetaRow(
                icon: Ik.calendar,
                text: DateId.hariTanggal(activity.date),
              ),
              const SizedBox(height: 8),
              _MetaRow(icon: Ik.place, text: activity.location),
              const SizedBox(height: 8),
              _MetaRow(
                icon: activity.upcoming
                    ? Ik.clock
                    : Ik.checkCircle,
                text: activity.upcoming
                    ? DateId.hitungMundur(activity.date)
                    : 'Kegiatan sudah selesai',
              ),
              const SizedBox(height: 20),
              Text(
                activity.upcoming
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
