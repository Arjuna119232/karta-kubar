import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/session.dart';
import '../../../core/auth/user_role.dart';
import '../../../core/data/hasil.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stat_tile.dart';
import '../../../shared/widgets/status_views.dart';
import '../../aspirasi/data/aspirasi_state.dart';
import '../../aspirasi/domain/aspirasi.dart';
import '../../aspirasi/presentation/aspirasi_screen.dart';
import '../../shell/data/app_tabs.dart';

/// Panel kendali untuk pengurus / RT / RW / kelurahan.
///
/// Ini layar yang membuat aplikasi jadi alat kerja, bukan sekadar papan
/// baca. Dari sini pengurus bisa melihat antrean FISH dan menandainya.
class PengurusScreen extends ConsumerWidget {
  const PengurusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Session session = ref.watch(sessionProvider);
    final AsyncValue<List<Aspirasi>> state = ref.watch(aspirasiProvider);
    final RekapAspirasi rekap = ref.watch(rekapAspirasiProvider);
    final List<Aspirasi> antrean =
        urutPrioritas(state.valueOrNull ?? <Aspirasi>[]);
    final List<Aspirasi> perluTindakan = antrean
        .where((Aspirasi a) =>
            a.status == StatusAspirasi.baru ||
            a.status == StatusAspirasi.diproses)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Pengurus'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: () => ref.read(aspirasiProvider.notifier).muatUlang(),
            icon: const AppIcon(Ik.refresh),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(aspirasiProvider.notifier).muatUlang(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen, 8, AppSpacing.screen, 96),
            children: <Widget>[
              FadeSlideIn(index: 0, child: _Sapaan(session: session)),
              const SizedBox(height: 18),
              if (state.isLoading)
                const AppSkeleton(height: 104, radius: 20)
              else
                FadeSlideIn(index: 1, child: _Angka(rekap: rekap)),
              const SizedBox(height: 18),
              FadeSlideIn(index: 2, child: const _Pintasan()),
              const SizedBox(height: 22),
              SectionHeader(
                title: 'Antrean FISH',
                actionLabel: 'Papan warga',
                onAction: () => context.go('/aspirasi'),
              ),
              if (perluTindakan.isEmpty)
                const AppEmptyState(
                  title: 'Antrean bersih',
                  message: 'Tidak ada FISH yang menunggu tindakan. Kerja bagus.',
                )
              else
                for (final (int i, Aspirasi a) in perluTindakan.indexed)
                  FadeSlideIn(
                    index: 3 + i,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.gap),
                      child: AspirasiCard(
                        item: a,
                        onUbahStatus: (StatusAspirasi baru) =>
                            _ubahStatus(context, ref, a, baru),
                      ),
                    ),
                  ),
              if (antrean.length > perluTindakan.length) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  '${antrean.length - perluTindakan.length} FISH lain sudah selesai atau ditolak.',
                  style: context.text.bodySmall
                      ?.copyWith(color: context.semantic.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _ubahStatus(
    BuildContext context,
    WidgetRef ref,
    Aspirasi a,
    StatusAspirasi baru,
  ) async {
    final bool butuhCatatan = baru == StatusAspirasi.selesai ||
        baru == StatusAspirasi.ditolak;

    String? catatan;
    if (butuhCatatan) {
      catatan = await _mintaCatatan(context, a, baru);
      if (catatan == null) return; // dibatalkan
    }


    HapticFeedback.mediumImpact();
    final Hasil<Aspirasi> h = await ref
        .read(aspirasiProvider.notifier)
        .ubahStatus(a.id, baru, catatan: catatan);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(h.berhasil
            ? '"${a.judul}" -> ${baru.label}'
            : 'Gagal: ${h.galat?.pesan ?? 'tidak diketahui'}'),
      ),
    );
  }

  Future<String?> _mintaCatatan(
    BuildContext context,
    Aspirasi a,
    StatusAspirasi baru,
  ) {
    final TextEditingController c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text('Tandai ${baru.label}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '"${a.judul}"',
              style: Theme.of(dialogContext).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: c,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              maxLength: 240,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Catatan untuk warga (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final String isi = c.text.trim();
              Navigator.of(dialogContext).pop(isi);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    ).whenComplete(c.dispose);
  }
}

class _Sapaan extends StatelessWidget {
  const _Sapaan({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: session.efektif.warna.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: AppIcon(session.efektif.ikon,
                color: session.efektif.warna, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(session.user?.name ?? 'Pengurus',
                    style: context.text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  session.efektif.deskripsi,
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

class _Angka extends StatelessWidget {
  const _Angka({required this.rekap});

  final RekapAspirasi rekap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: StatTile(
                icon: Ik.chat,
                value: '${rekap.perluTindakan}',
                label: 'Perlu tindakan',
                tint: StatusAspirasi.baru.warna,
              ),
            ),
            const SizedBox(width: AppSpacing.gap),
            Expanded(
              child: StatTile(
                icon: Ik.checkCircle,
                value: '${rekap.selesai}',
                label: 'Selesai',
                tint: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gap),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: <Widget>[
              _MiniAngka(
                label: 'Baru',
                nilai: '${rekap.baru}',
                warna: StatusAspirasi.baru.warna,
              ),
              _MiniAngka(
                label: 'Diproses',
                nilai: '${rekap.diproses}',
                warna: StatusAspirasi.diproses.warna,
              ),
              _MiniAngka(
                label: 'Ditolak',
                nilai: '${rekap.ditolak}',
                warna: StatusAspirasi.ditolak.warna,
              ),
              _MiniAngka(
                label: 'Total',
                nilai: '${rekap.total}',
                warna: context.colors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniAngka extends StatelessWidget {
  const _MiniAngka({
    required this.label,
    required this.nilai,
    required this.warna,
  });

  final String label;
  final String nilai;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            nilai,
            style: context.text.titleMedium?.copyWith(color: warna),
          ),
          const SizedBox(height: 2),
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

class _Pintasan extends ConsumerWidget {
  const _Pintasan();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Session session = ref.watch(sessionProvider);

    return Row(
      children: <Widget>[
        Expanded(
          child: _KartuPintasan(
            icon: Ik.qrScan,
            judul: 'Sesi absensi',
            ket: 'Tampilkan QR di layar',
            onTap: () => context.go('/absen'),
          ),
        ),
        const SizedBox(width: AppSpacing.gap),
        Expanded(
          child: _KartuPintasan(
            icon: Ik.calendarCheck,
            judul: 'Agenda',
            ket: 'Kelola kegiatan',
            onTap: () {
              // Angka 1 salah: untuk role pengurus urutan tabnya
              // (Beranda / Absen / Kegiatan / Kas / Profil), jadi indeks 1
              // membuka tab "Absen", bukan Agenda.
              final UserRole role = ref.read(sessionProvider).efektif;
              ref.read(navigationIndexProvider.notifier).state =
                  indeksTab(role, 'Agenda');
              context.go('/home');
            },
          ),
        ),
        if (session.efektif.bisa(UserRole.admin)) ...<Widget>[
          const SizedBox(width: AppSpacing.gap),
          Expanded(
            child: _KartuPintasan(
              icon: Ik.megaphone,
              judul: 'Umum',
              ket: 'Kelola broadcast',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Broadcast butuh kanal resmi - belum siap.'),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _KartuPintasan extends StatelessWidget {
  const _KartuPintasan({
    required this.icon,
    required this.judul,
    required this.ket,
    required this.onTap,
  });

  final Ik icon;
  final String judul;
  final String ket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: <Widget>[
          AppIcon(icon, size: 24, color: context.colors.primary),
          const SizedBox(height: 8),
          Text(
            judul,
            style: context.text.labelLarge,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            ket,
            style: context.text.labelSmall
                ?.copyWith(color: context.semantic.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
