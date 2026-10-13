import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_id.dart';
import '../../../shared/data/seed_data.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stat_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Activity> upcoming =
        SeedData.activities.where((Activity a) => a.upcoming).toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, 12, AppSpacing.screen, 96),
        children: <Widget>[
          const _Greeting(),
          const SizedBox(height: 18),
          const _AnnouncementCarousel(),
          const SizedBox(height: 18),
          const Row(
            children: <Widget>[
              Expanded(
                child: StatTile(
                  icon: Icons.groups_rounded,
                  value: '128',
                  label: 'Anggota aktif',
                  tint: AppColors.primary,
                ),
              ),
              SizedBox(width: AppSpacing.gap),
              Expanded(
                child: StatTile(
                  icon: Icons.event_available_rounded,
                  value: '12',
                  label: 'Kegiatan bulan ini',
                  tint: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Aksi Cepat'),
          const _QuickActions(),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'Agenda Terdekat',
            actionLabel: 'Lihat semua',
            onAction: () =>
                ref.read(navigationIndexProvider.notifier).state = 1,
          ),
          for (final Activity a in upcoming)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.gap),
              child: _AgendaTile(activity: a),
            ),
          const SizedBox(height: 10),
          const SectionHeader(title: 'Berita Terbaru'),
          for (final NewsItem n in SeedData.news)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.gap),
              child: _NewsTile(item: n),
            ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${DateId.greeting()},',
                style: context.text.bodyMedium
                    ?.copyWith(color: context.semantic.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(SeedData.memberName, style: context.text.headlineMedium),
            ],
          ),
        ),
        _IconBadge(
          icon: Icons.notifications_none_rounded,
          showDot: true,
          onTap: () {
            HapticFeedback.selectionClick();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Belum ada notifikasi baru')),
            );
          },
        ),
        const SizedBox(width: 10),
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[Color(0xFF1B5E20), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'SK',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, this.showDot = false, this.onTap});

  final IconData icon;
  final bool showDot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Material(
          color: context.semantic.card,
          shape: CircleBorder(side: BorderSide(color: context.semantic.line)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const SizedBox(
              width: 46,
              height: 46,
              child: Icon(Icons.notifications_none_rounded, size: 22),
            ),
          ),
        ),
        if (showDot)
          Positioned(
            right: 11,
            top: 11,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: context.colors.error,
                shape: BoxShape.circle,
                border: Border.all(color: context.semantic.card, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

class _AnnouncementCarousel extends StatefulWidget {
  const _AnnouncementCarousel();

  @override
  State<_AnnouncementCarousel> createState() => _AnnouncementCarouselState();
}

class _AnnouncementCarouselState extends State<_AnnouncementCarousel> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const List<Announcement> items = SeedData.announcements;
    return Column(
      children: <Widget>[
        SizedBox(
          height: 158,
          child: PageView.builder(
            controller: _controller,
            itemCount: items.length,
            onPageChanged: (int i) => setState(() => _page = i),
            itemBuilder: (BuildContext context, int i) {
              final Announcement a = items[i];
              return _AnnouncementCard(item: a);
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(items.length, (int i) {
            final bool active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: active
                    ? context.colors.primary
                    : context.semantic.line,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.item});

  final Announcement item;

  @override
  Widget build(BuildContext context) {
    final List<Color> grad = context.semantic.heroGradient;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: grad,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              item.tag,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.body,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Row(
            children: <Widget>[
              Icon(Icons.campaign_rounded,
                  color: Colors.white.withValues(alpha: 0.9), size: 16),
              const SizedBox(width: 6),
              Text(
                'Pengumuman',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<_QuickItem> items = <_QuickItem>[
      _QuickItem(Icons.qr_code_scanner_rounded, 'Absen', AppColors.primary,
          () => _soon(context, 'Absen QR')),
      _QuickItem(Icons.account_balance_wallet_rounded, 'Iuran',
          AppColors.accent, () => ref.read(navigationIndexProvider.notifier).state = 2),
      _QuickItem(Icons.forum_rounded, 'Aspirasi',
          AppColors.warning, () => _soon(context, 'Aspirasi')),
      _QuickItem(Icons.photo_library_rounded, 'Galeri',
          AppColors.success, () => ref.read(navigationIndexProvider.notifier).state = 3),
    ];

    return Row(
      children: <Widget>[
        for (final _QuickItem it in items)
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                HapticFeedback.selectionClick();
                it.onTap();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: <Widget>[
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: it.tint.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(it.icon, color: it.tint, size: 26),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      it.label,
                      style: context.text.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _soon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label segera hadir')),
    );
  }
}

class _QuickItem {
  _QuickItem(this.icon, this.label, this.tint, this.onTap);
  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback onTap;
}

class _AgendaTile extends StatelessWidget {
  const _AgendaTile({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final bool selesai = !activity.upcoming;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  '${activity.date.day}',
                  style: context.text.titleLarge
                      ?.copyWith(color: context.colors.primary, height: 1),
                ),
                Text(
                  DateId.bulanSingkat(activity.date),
                  style: context.text.labelSmall
                      ?.copyWith(color: context.colors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  activity.title,
                  style: context.text.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    Icon(Icons.place_outlined,
                        size: 14, color: context.semantic.textSecondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${activity.location} · ${DateId.tanggal(activity.date)}',
                        style: context.text.bodySmall
                            ?.copyWith(color: context.semantic.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
    );
  }
}

class _NewsTile extends StatelessWidget {
  const _NewsTile({required this.item});

  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Membuka: ${item.title}')),
        );
      },
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.article_outlined,
                color: context.colors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.title,
                  style: context.text.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.source} · ${item.time}',
                  style: context.text.bodySmall
                      ?.copyWith(color: context.semantic.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded,
              color: context.semantic.textSecondary),
        ],
      ),
    );
  }
}
