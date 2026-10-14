import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../core/data/data_providers.dart';
import '../../kegiatan/domain/kegiatan.dart';

class GaleriScreen extends ConsumerWidget {
  const GaleriScreen({super.key});

  static const List<_Media> _media = <_Media>[
    _Media('Kerja Bakti', 'cover_sosial'),
    _Media('Futsal', 'cover_olahraga'),
    _Media('Pengajian', 'cover_religi'),
    _Media('Donor Darah', 'cover_donor'),
    _Media('17-an', 'cover_lomba'),
    _Media('Bakti Sosial', 'cover_umum'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                icon: const AppIcon(Ik.addPhoto),
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
            childAspectRatio: 1.05,
            children: <Widget>[
              for (final _Media m in _media) _MediaTile(media: m),
            ],
          ),
          const SizedBox(height: AppSpacing.section),
          const SectionHeader(title: 'Berita'),
          for (final Berita n in
              ref.watch(beritaProvider).valueOrNull ?? const <Berita>[])
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
  const _Media(this.title, this.cover);
  final String title;
  final String cover;
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.media});

  final _Media media;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.semantic.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: context.semantic.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(child: AppCover(media.cover, radius: 0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(media.title,
                    style: context.text.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                  'Foto & video',
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

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item});

  final Berita item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Membuka: ${item.title}')),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppCover(coverBerita(item.tag), width: 68, height: 68),
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
