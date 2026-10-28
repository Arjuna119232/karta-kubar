import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_id.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stat_tile.dart';
import '../data/absen_state.dart';
import '../domain/kehadiran.dart';
import 'qr_absen_sheet.dart';
import '../../../shared/widgets/app_icon.dart';

import '../../kegiatan/domain/kegiatan.dart';
import '../../../shared/widgets/confetti.dart';
import '../../../core/utils/haptics.dart';

class AbsenScreen extends ConsumerStatefulWidget {
  const AbsenScreen({super.key});

  @override
  ConsumerState<AbsenScreen> createState() => _AbsenScreenState();
}

class _AbsenScreenState extends ConsumerState<AbsenScreen> {
  bool _modePenyelenggara = false;

  @override
  Widget build(BuildContext context) {
    final List<Kehadiran> riwayat = ref.watch(absenProvider);
    final AbsenNotifier ctrl = ref.read(absenProvider.notifier);

    final List<Kegiatan> semua =
        ref.watch(kegiatanProvider).valueOrNull ?? const <Kegiatan>[];
    final List<Kegiatan> selesai =
        semua.where((Kegiatan a) => !a.mendatang).toList();
    final List<Kegiatan> mendatang =
        semua.where((Kegiatan a) => a.mendatang).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Absen QR'),
        leading: const BackButton(),
        actions: <Widget>[
          IconButton(
            tooltip: _modePenyelenggara ? 'Mode anggota' : 'Mode penyelenggara',
            onPressed: () =>
                setState(() => _modePenyelenggara = !_modePenyelenggara),
            icon: AppIcon(_modePenyelenggara
                ? Ik.person
                : Ik.qrCode),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _modePenyelenggara
            ? _PanelPenyelenggara(kegiatan: mendatang, ctrl: ctrl)
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen, 8, AppSpacing.screen, 32),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: StatTile(
                          icon: Ik.calendarCheck,
                          value: '${ctrl.hadirBulanIni}',
                          label: 'Hadir bulan ini',
                          tint: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.gap),
                      Expanded(
                        child: StatTile(
                          icon: Ik.history,
                          value: '${riwayat.length}',
                          label: 'Total catatan',
                          tint: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.section),
                  const SectionHeader(title: 'Pindai QR Kegiatan'),
                  _ScannerCard(
                    onScan: () => _bukaScanner(ctrl),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  const SectionHeader(title: 'Riwayat Kehadiran'),
                  if (riwayat.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(
                        'Belum ada catatan kehadiran.',
                        textAlign: TextAlign.center,
                        style: context.text.bodyMedium
                            ?.copyWith(color: context.semantic.textSecondary),
                      ),
                    )
                  else
                    for (final Kehadiran k in riwayat)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.gap),
                        child: _RiwayatTile(item: k, ctrl: ctrl),
                      ),
                  if (selesai.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    const SectionHeader(title: 'Kegiatan Selesai'),
                    for (final Kegiatan a in selesai)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.gap),
                        child: _SelesaiTile(
                          kegiatan: a,
                          sudah: ctrl.sudahAbsen(
                              a.judul, a.tanggal ?? DateTime.now()),
                          onIsi: () => _catat(ctrl, a),
                        ),
                      ),
                  ],
                ],
              ),
      ),
    );
  }

  Future<void> _bukaScanner(AbsenNotifier ctrl) async {
    // Pakai context milik State (bukan parameter) supaya pemakaian setelah
    // await aman: kalau layar sudah ditutup, `mounted` false dan kita berhenti.
    final Kegiatan? target = await QrAbsenSheet.tampilkan(context);
    if (target == null || !mounted) return;
    _catat(ctrl, target);
  }

  void _catat(AbsenNotifier ctrl, Kegiatan a) {
    final bool ok = ctrl.catat(a, StatusKehadiran.hadir);
    if (ok) {
      Haptics.success();
      Confetti.tembak(context);
    } else {
      Haptics.error();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Kehadiran tercatat untuk ${a.judul}'
            : 'Kehadiran untuk ${a.judul} sudah tercatat'),
      ),
    );
  }
}

class _ScannerCard extends StatelessWidget {
  const _ScannerCard({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: context.semantic.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppIcon(Ik.qrScan,
              color: AppColors.white.withValues(alpha: 0.9), size: 34),
          const SizedBox(height: 14),
          const Text(
            'Tempelkan QR di layar',
            style: TextStyle(
                color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Pindai kode kegiatan untuk mencatat kehadiran otomatis.',
            style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.85), fontSize: 13),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () {
              Haptics.selection();
              onScan();
            },
            icon: const AppIcon(Ik.camera, size: 20),
            label: const Text('Buka Kamera Pindai'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: context.colors.primary,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiwayatTile extends StatelessWidget {
  const _RiwayatTile({required this.item, required this.ctrl});

  final Kehadiran item;
  final AbsenNotifier ctrl;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _gantiStatus(context),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.status.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: AppIcon(_ikon, color: item.status.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.kegiatan,
                    style: context.text.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  DateId.tanggal(item.tanggal),
                  style: context.text.bodySmall
                      ?.copyWith(color: context.semantic.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: item.status.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              item.status.label,
              style: context.text.labelSmall?.copyWith(color: item.status.color),
            ),
          ),
        ],
      ),
    );
  }

  Ik get _ikon => switch (item.status) {
        StatusKehadiran.hadir => Ik.check,
        StatusKehadiran.izin => Ik.mail,
        StatusKehadiran.alpha => Ik.xCircle,
      };

  void _gantiStatus(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
              child: Text('Ubah status kehadiran', style: c.text.titleMedium),
            ),
            for (final StatusKehadiran s in StatusKehadiran.values)
              ListTile(
                leading: AppIcon(Ik.dot, color: s.color, size: 14),
                title: Text(s.label),
                trailing: item.status == s
                    ? AppIcon(Ik.check, color: s.color)
                    : null,
                onTap: () {
                  ctrl.ubahStatus(item.id, s);
                  Navigator.of(context).pop();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SelesaiTile extends StatelessWidget {
  const _SelesaiTile({
    required this.kegiatan,
    required this.sudah,
    required this.onIsi,
  });

  final Kegiatan kegiatan;
  final bool sudah;
  final VoidCallback onIsi;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(kegiatan.judul, style: context.text.titleSmall),
                const SizedBox(height: 2),
                Text(
                  '${DateId.tanggal(kegiatan.tanggal)} · ${kegiatan.lokasi}',
                  style: context.text.bodySmall
                      ?.copyWith(color: context.semantic.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (sudah)
            Row(
              children: <Widget>[
                AppIcon(Ik.checkCircle,
                    color: AppColors.success, size: 18),
                const SizedBox(width: 6),
                Text('Tercatat',
                    style: context.text.labelSmall
                        ?.copyWith(color: AppColors.success)),
              ],
            )
          else
            TextButton(onPressed: onIsi, child: const Text('Catat hadir')),
        ],
      ),
    );
  }
}

/// Mode penyelenggara: menampilkan QR yang akan dipindai anggota.
class _PanelPenyelenggara extends StatelessWidget {
  const _PanelPenyelenggara({required this.kegiatan, required this.ctrl});

  final List<Kegiatan> kegiatan;
  final AbsenNotifier ctrl;

  @override
  Widget build(BuildContext context) {
    if (kegiatan.isEmpty) {
      return Center(
        child: Text('Tidak ada kegiatan mendatang.',
            style: context.text.bodyMedium),
      );
    }
    final Kegiatan a = kegiatan.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, 8, AppSpacing.screen, 32),
      children: <Widget>[
        AppCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: <Widget>[
              Text('Tampilkan di layar',
                  style: context.text.labelMedium
                      ?.copyWith(color: context.semantic.textSecondary)),
              const SizedBox(height: 4),
              Text(a.judul, style: context.text.headlineSmall),
              const SizedBox(height: 4),
              Text(
                '${DateId.hariTanggal(a.tanggal)} · ${a.lokasi}',
                textAlign: TextAlign.center,
                style: context.text.bodySmall
                    ?.copyWith(color: context.semantic.textSecondary),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.semantic.line),
                ),
                child: QrImageView(
                  data: absenPayload(a),
                  version: QrVersions.auto,
                  size: 190,
                  gapless: true,
                  backgroundColor: AppColors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppColors.primary,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Anggota memindai kode ini di menu Absen untuk mencatat kehadiran.',
                textAlign: TextAlign.center,
                style: context.text.bodySmall
                    ?.copyWith(color: context.semantic.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        const SectionHeader(title: 'Kegiatan Mendatang'),
        for (final Kegiatan k in kegiatan)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.gap),
            child: AppCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(k.judul, style: context.text.titleSmall),
                        const SizedBox(height: 2),
                        Text(
                          '${DateId.tanggal(k.tanggal)} · ${k.lokasi}',
                          style: context.text.bodySmall?.copyWith(
                              color: context.semantic.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DateId.hitungMundur(k.tanggal),
                    style: context.text.labelSmall
                        ?.copyWith(color: context.colors.primary),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}