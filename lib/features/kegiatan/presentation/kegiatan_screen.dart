import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_id.dart';
import '../../../shared/data/seed_data.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/status_views.dart';

class KegiatanScreen extends StatefulWidget {
  const KegiatanScreen({super.key});

  @override
  State<KegiatanScreen> createState() => _KegiatanScreenState();
}

class _KegiatanScreenState extends State<KegiatanScreen> {
  String _category = 'Semua';

  List<Activity> get _filtered => _category == 'Semua'
      ? SeedData.activities
      : SeedData.activities
          .where((Activity a) => a.category == _category)
          .toList();

  @override
  Widget build(BuildContext context) {
    final List<Activity> upcoming =
        _filtered.where((Activity a) => a.upcoming).toList();
    final List<Activity> past =
        _filtered.where((Activity a) => !a.upcoming).toList();

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
                  icon: const Icon(Icons.calendar_month_outlined),
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
                for (final String c in SeedData.activityCategories)
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
                    icon: Icons.event_busy_rounded,
                    title: 'Belum ada kegiatan',
                    message: 'Kegiatan pada kategori ini belum tersedia.',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 8,
                        AppSpacing.screen, 96),
                    children: <Widget>[
                      if (upcoming.isNotEmpty) ...<Widget>[
                        const _GroupLabel('Akan Datang'),
                        for (final Activity a in upcoming)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.gap),
                            child: _ActivityCard(activity: a),
                          ),
                      ],
                      if (past.isNotEmpty) ...<Widget>[
                        const _GroupLabel('Sudah Lewat'),
                        for (final Activity a in past)
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

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final Color cat = categoryColor(activity.category);
    final bool selesai = !activity.upcoming;

    return AppCard(
      onTap: () => _showDetail(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
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
            icon: Icons.event_rounded,
            text: DateId.hariTanggal(activity.date),
          ),
          const SizedBox(height: 6),
          _MetaRow(icon: Icons.place_outlined, text: activity.location),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext c) {
        final Color cat = categoryColor(activity.category);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
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
                icon: Icons.event_rounded,
                text: DateId.hariTanggal(activity.date),
              ),
              const SizedBox(height: 8),
              _MetaRow(icon: Icons.place_outlined, text: activity.location),
              const SizedBox(height: 8),
              _MetaRow(
                icon: activity.upcoming
                    ? Icons.schedule_rounded
                    : Icons.check_circle_outline_rounded,
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

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: context.semantic.textSecondary),
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
