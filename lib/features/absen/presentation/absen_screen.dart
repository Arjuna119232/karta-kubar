import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../shared/widgets/app_icon.dart';

import '../../kegiatan/domain/kegiatan.dart';

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
                    onScan: () => _bukaScanner(context, ctrl),
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
                          onIsi: () => _catat(context, ctrl, a),
                        ),
                      ),
                  ],
                ],
              ),
      ),
    );
  }

  void _bukaScanner(BuildContext context, AbsenNotifier ctrl) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext c) => _ScannerSheet(ctrl: ctrl),
    );
  }

  void _catat(
      BuildContext context, AbsenNotifier ctrl, Kegiatan a) {
    final bool ok = ctrl.catat(a, StatusKehadiran.hadir);
    HapticFeedback.mediumImpact();
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
              color: Colors.white.withValues(alpha: 0.9), size: 34),
          const SizedBox(height: 14),
          const Text(
            'Tempelkan QR di layar',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Pindai kode kegiatan untuk mencatat kehadiran otomatis.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () {
              HapticFeedback.selectionClick();
              onScan();
            },
            icon: const AppIcon(Ik.camera, size: 20),
            label: const Text('Buka Kamera Pindai'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
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

/// Simulasi viewfinder kamera: membaca payload QR kegiatan pertama yang tersedia.
/// Butuh Consumer karena `_cocok` membaca daftar kegiatan dari repository,
/// bukan dari data demo.
class _ScannerSheet extends ConsumerStatefulWidget {
  const _ScannerSheet({required this.ctrl});

  final AbsenNotifier ctrl;

  @override
  ConsumerState<_ScannerSheet> createState() => _ScannerSheetState();
}

class _ScannerSheetState extends ConsumerState<_ScannerSheet> {
  bool _memindai = false;
  String? _hasil;

  @override
  Widget build(BuildContext context) {
    final String? judul = _hasil;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (judul == null) ...<Widget>[
            _Viewfinder(busy: _memindai),
            const SizedBox(height: 18),
            Text('Memindai kode QR...',
                textAlign: TextAlign.center,
                style: context.text.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Demo: kamera tidak diaktifkan. Payload QR yang terbaca ditampilkan di bawah.',
              textAlign: TextAlign.center,
              style: context.text.bodySmall
                  ?.copyWith(color: context.semantic.textSecondary),
            ),
          ] else ...<Widget>[
            _HasilCard(judul: judul, ctrl: widget.ctrl),
          ],
          const SizedBox(height: 20),
          if (judul == null)
            OutlinedButton(
              onPressed: _memindai ? null : _mulai,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button)),
              ),
              child: const Text('Pindai sekarang'),
            )
          else
            FilledButton.icon(
              onPressed: () {
                widget.ctrl.catat(
                  _cocok(judul!),
                  StatusKehadiran.hadir,
                  pada: DateTime.now(),
                );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Kehadiran tercatat: $judul')),
                );
              },
              icon: const AppIcon(Ik.check, size: 20),
              label: const Text('Ya, saya hadir'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button)),
              ),
            ),
        ],
      ),
    );
  }

  /// Cari kegiatan dari daftar yang sudah dimuat repository.
  /// Kalau tidak ketemu (mis. judul kegiatan dihapus admin), pakai yang
  /// pertama - lebih baik daripada `.first` yang bisa melempar.
  Kegiatan _cocok(String judul) {
    final List<Kegiatan> semua =
        ref.watch(kegiatanProvider).valueOrNull ?? const <Kegiatan>[];
    if (semua.isEmpty) return Kegiatan.cadangan;
    for (final Kegiatan a in semua) {
      if (a.judul == judul) return a;
    }
    return semua.first;
  }

  Future<void> _mulai() async {
    setState(() => _memindai = true);
    HapticFeedback.selectionClick();
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    final List<Kegiatan> semua =
        ref.watch(kegiatanProvider).valueOrNull ?? const <Kegiatan>[];
    if (semua.isEmpty) {
      setState(() => _memindai = false);
      return;
    }
    final Kegiatan target = semua.firstWhere(
      (Kegiatan a) => !a.mendatang,
      orElse: () => semua.first,
    );
    final String? parsed = parseAbsenPayload(absenPayload(target));
    HapticFeedback.mediumImpact();
    setState(() {
      _memindai = false;
      _hasil = parsed ?? target.judul;
    });
  }
}

class _Viewfinder extends StatelessWidget {
  const _Viewfinder({required this.busy});

  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.semantic.line),
      ),
      child: Center(
        child: busy
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 14),
                  Text('Mendekode...', style: context.text.bodyMedium),
                ],
              )
            : AppIcon(Ik.qrCode,
                size: 92, color: context.colors.primary.withValues(alpha: 0.35)),
      ),
    );
  }
}

class _HasilCard extends StatelessWidget {
  const _HasilCard({required this.judul, required this.ctrl});

  final String judul;
  final AbsenNotifier ctrl;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppIcon(Ik.checkCircle,
                  color: AppColors.success, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text('QR terbaca', style: context.text.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(judul, style: context.text.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Kegiatan teridentifikasi dari kode QR.',
            style: context.text.bodySmall
                ?.copyWith(color: context.semantic.textSecondary),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.semantic.line),
                ),
                child: QrImageView(
                  data: absenPayload(a),
                  version: QrVersions.auto,
                  size: 190,
                  gapless: true,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF1B5E20),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF1A1A1A),
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