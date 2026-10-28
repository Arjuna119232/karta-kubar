import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_id.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../../../shared/widgets/status_views.dart';
import '../../../core/data/data_providers.dart';
import '../../kegiatan/domain/kegiatan.dart';
import '../../../shared/widgets/cover_pilih.dart';
import '../../../shared/widgets/animated_list_item.dart';
import '../data/galeri_state.dart';
import '../domain/media_galeri.dart';
import '../../../shared/widgets/berita_sheet.dart';

/// Galeri & berita.
///
/// Dua kelompok yang sengaja dipisah dan diberi label berbeda:
/// - "Unggahan warga": foto yang benar-benar ada di folder aplikasi, punya
///   tombol hapus.
/// - "Galeri contoh": sampul bawaan, tidak bisa dihapus, diberi label
///   "data contoh" supaya tidak disalaharti sebagai dokumentasi asli.
class GaleriScreen extends ConsumerWidget {
  const GaleriScreen({super.key});

  static const List<_MediaContoh> _contoh = <_MediaContoh>[
    _MediaContoh('Kerja Bakti', 'cover_sosial'),
    _MediaContoh('Futsal', 'cover_olahraga'),
    _MediaContoh('Pengajian', 'cover_religi'),
    _MediaContoh('Donor Darah', 'cover_donor'),
    _MediaContoh('17-an', 'cover_lomba'),
    _MediaContoh('Bakti Sosial', 'cover_umum'),
  ];

  /// Buka sheet isian, lalu jalankan pilih-foto setelah sheet ditutup.
  ///
  /// Sheet ditutup DULU supaya pemilih foto Android tidak tergambar di atas
  /// sheet (dan supaya konteks sheet tidak dipakai setelah `pop`).
  static Future<void> _bukaFormUnggah(
      BuildContext context, WidgetRef ref) async {
    Haptics.light();
    final DataUnggah? data = await AppSheet.show<DataUnggah>(
      context,
      builder: (BuildContext ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Unggah foto kegiatan', style: ctx.text.titleLarge),
          const SizedBox(height: AppSpacing.md),
          const FormUnggah(),
        ],
      ),
    );
    if (data == null) return;

    Haptics.medium();
    final HasilUnggah hasil = await ref
        .read(mediaGaleriProvider.notifier)
        .unggah(judul: data.judul, keterangan: data.keterangan);
    if (!context.mounted) return;

    final bool ok = hasil.status == StatusUnggah.selesai;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Foto disimpan di perangkat.'
            : hasil.pesan.isEmpty
                ? 'Unggah dibatalkan.'
                : hasil.pesan),
      ),
    );
  }

  static Future<void> _konfirmasiHapus(
    BuildContext context,
    WidgetRef ref,
    MediaGaleri m,
  ) async {
    Haptics.light();
    final bool ya = await AppDialog.konfirmasi(
      context,
      judul: 'Hapus foto?',
      pesan: '"${m.judul}" akan dihapus dari perangkat ini, termasuk '
          'berkasnya. Tindakan ini tidak bisa dibatalkan.',
      labelYa: 'Hapus',
      labelBatal: 'Batal',
      ikon: Ik.broom,
    );
    if (!ya) return;
    await ref.read(mediaGaleriProvider.notifier).hapus(m.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<MediaGaleri>> asyncUnggah =
        ref.watch(mediaGaleriProvider);
    final List<MediaGaleri> unggahan =
        asyncUnggah.valueOrNull ?? const <MediaGaleri>[];
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: context.colors.primary,
        backgroundColor: context.semantic.card,
        onRefresh: () async {
          Haptics.medium();
          ref.invalidate(mediaGaleriProvider);
          await Future<void>.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, 12, AppSpacing.screen, 96),
        children: <Widget>[
          Row(
            children: <Widget>[
              // Galeri dipakai dua cara: sebagai TAB (tamu/warga) dan sebagai
              // rute yang di-push dari aksi cepat beranda (anggota ke atas).
              // Saat di-push tidak ada AppBar, jadi tombol back harus dibuat
              // sendiri - kalau tidak, satu-satunya cara keluar hanya tombol
              // back perangkat.
              if (context.canPop())
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: const AppIcon(Ik.arrowBack, size: 20),
                    tooltip: 'Kembali',
                  ),
                ),
              Text('Galeri & Berita', style: context.text.headlineMedium),
              const Spacer(),
              IconButton(
                onPressed: () => _bukaFormUnggah(context, ref),
                icon: const AppIcon(Ik.addPhoto),
                tooltip: 'Unggah foto',
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SectionHeader(title: 'Unggahan warga'),
          if (asyncUnggah.isLoading && unggahan.isEmpty)
            const ShimmerListSkeleton(itemCount: 4)
          else if (unggahan.isEmpty)
            AppEmptyState(
              art: 'empty_galeri',
              title: 'Belum ada unggahan',
              message: 'Tekan ikon foto di kanan atas untuk menambahkan '
                  'dokumentasi kegiatan. Berkas disimpan di perangkat ini.',
              actionLabel: 'Unggah foto',
              onAction: () => _bukaFormUnggah(context, ref),
            )
          else
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.gap,
              mainAxisSpacing: AppSpacing.gap,
              childAspectRatio: 1.05,
              children: <Widget>[
                for (final (int i, MediaGaleri m) in unggahan.indexed)
                  AnimatedListItem(
                    index: i,
                    child: _MediaTile(
                      media: m,
                      onHapus: () => _konfirmasiHapus(context, ref, m),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.section),
          const SectionHeader(title: 'Galeri contoh'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.gap,
            mainAxisSpacing: AppSpacing.gap,
            childAspectRatio: 1.05,
            children: <Widget>[
              for (final (int i, _MediaContoh m) in _contoh.indexed)
                AnimatedListItem(index: i, child: _MediaTileContoh(media: m)),
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
      ),
    );
  }
}

class _MediaContoh {
  const _MediaContoh(this.title, this.cover);
  final String title;
  final String cover;
}

/// Data yang dikembalikan sheet isian ke pemanggilnya.
class DataUnggah {
  const DataUnggah(this.judul, this.keterangan);
  final String judul;
  final String keterangan;
}

/// Isian sebelum memilih berkas: judul kegiatan + keterangan singkat.
class FormUnggah extends StatefulWidget {
  const FormUnggah({super.key});

  @override
  State<FormUnggah> createState() => _FormUnggahState();
}

class _FormUnggahState extends State<FormUnggah> {
  final TextEditingController _judul = TextEditingController();
  final TextEditingController _keterangan = TextEditingController();

  @override
  void dispose() {
    _judul.dispose();
    _keterangan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: _judul,
          maxLength: 60,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Judul kegiatan',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _keterangan,
          maxLength: 120,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Keterangan (opsional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Foto disalin ke folder aplikasi, jadi tetap ada walau dihapus '
          'dari galeri HP. Unggahan hanya terlihat di perangkat ini sampai '
          'backend galeri aktif.',
          style: context.text.bodySmall
              ?.copyWith(color: context.semantic.textSecondary),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Lanjut pilih foto',
          icon: Ik.gallery,
          onPressed: () => Navigator.of(context).pop(
            DataUnggah(_judul.text.trim(), _keterangan.text.trim()),
          ),
        ),
      ],
    );
  }
}

/// Foto hasil unggahan warga: gambar aslinya, bukan sampul.
class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.media, required this.onHapus});

  final MediaGaleri media;
  final VoidCallback onHapus;

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
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Image.file(
                  File(media.pathBerkas),
                  fit: BoxFit.cover,
                  // Berkas bisa hilang (warga membersihkannya dari penyimpanan
                  // HP). Jangan sampai layar ikut error.
                  errorBuilder: (BuildContext c, Object e, StackTrace? s) =>
                      Container(
                    color: context.semantic.line,
                    child: Center(
                      child: AppIcon(Ik.cloudOff,
                          size: 28, color: context.semantic.textSecondary),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: _TombolHapus(onTap: onHapus),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  media.judul,
                  style: context.text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateId.tanggal(media.dibuat),
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

class _TombolHapus extends StatelessWidget {
  const _TombolHapus({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.semantic.card.withValues(alpha: 0.88),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: 'Hapus foto',
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: AppIcon(Ik.broom, size: 16),
          ),
        ),
      ),
    );
  }
}

/// Sampul bawaan. Wajib diberi label "data contoh" supaya tidak disalaharti
/// sebagai dokumentasi asli.
class _MediaTileContoh extends StatelessWidget {
  const _MediaTileContoh({required this.media});

  final _MediaContoh media;

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
                  'Data contoh',
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
      onTap: () => bukaBerita(context, item),
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
                  item.judul,
                  style: context.text.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.sumber} · ${item.waktu}',
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
