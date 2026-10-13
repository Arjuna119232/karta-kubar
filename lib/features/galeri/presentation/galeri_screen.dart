import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/data/seed_data.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';

class GaleriScreen extends StatelessWidget {
  const GaleriScreen({super.key});

  static const List<_Media> _media = <_Media>[
    _Media('Kerja Bakti', Icons.cleaning_services_rounded),
    _Media('Futsal', Icons.sports_soccer_rounded),
    _Media('Pengajian', Icons.mosque_rounded),
    _Media('Donor Darah', Icons.bloodtype_rounded),
    _Media('17-an', Icons.celebration_rounded),
    _Media('Bakti Sosial', Icons.volunteer_activism_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, 12, AppSpacing.screen, 96),
        children: <Widget>[
          Row(
            children: <Widget>[
              Text('Galeri & Berita', style: context.text.headlineMedium),
              const Spacer(),
              IconButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Unggah media segera hadir')),
                ),
                icon: const Icon(Icons.add_a_photo_outlined),
                tooltip: 'Unggah',
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SectionHeader(title: 'Galeri Kegiatan'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.gap,
            mainAxisSpacing: AppSpacing.gap,
            childAspectRatio: 1.35,
            children: <Widget>[
              for (final _Media m in _media) _MediaTile(media: m),
            ],
          ),
          const SizedBox(height: AppSpacing.section),
          const SectionHeader(title: 'Berita'),
          for (final NewsItem n in SeedData.news)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.gap),
              child: _NewsCard(item: n),
            ),
        ],
      ),
    );
  }
}

class _Media {
  const _Media(this.title, this.icon);
  final String title;
  final IconData icon;
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.media});

  final _Media media;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: context.semantic.line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(media.icon, size: 34, color: context.colors.primary),
          const SizedBox(height: 10),
          Text(media.title, style: context.text.titleSmall),
          const SizedBox(height: 2),
          Text(
            'Foto & video',
            style: context.text.bodySmall
                ?.copyWith(color: context.semantic.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item});

  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Membuka: ${item.title}')),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.image_outlined,
                color: context.colors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.semantic.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(item.tag, style: context.text.labelSmall),
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  style: context.text.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.source} · ${item.time}',
                  style: context.text.bodySmall
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
