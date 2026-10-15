import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/session.dart';
import '../../../core/data/hasil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_views.dart';
import '../data/darurat_repository.dart';
import '../domain/darurat.dart';

/// Lapor darurat. Layar ini sengaja dibuat satu tombol besar di atas:
/// saat panik, tidak ada yang membaca form panjang.
class DaruratScreen extends ConsumerWidget {
  const DaruratScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Session session = ref.watch(sessionProvider);
    final AsyncValue<List<LaporanDarurat>> state = ref.watch(daruratProvider);
    final List<LaporanDarurat> riwayat = state.valueOrNull ?? <LaporanDarurat>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Lapor Darurat')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen, 12, AppSpacing.screen, 96),
          children: <Widget>[
            _TombolDarurat(
              onTap: () => _bukaForm(context, session),
            ),
            const SizedBox(height: 14),
            _KartuNomorDarurat(),
            const SizedBox(height: 22),
            const SectionHeader(title: 'Laporan saya'),
            if (riwayat.isEmpty)
              const AppEmptyState(
                title: 'Belum ada laporan',
                message: 'Laporan yang kamu kirim akan muncul di sini beserta '
                    'status penanganannya.',
              )
            else
              for (final (int i, LaporanDarurat d) in riwayat.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.gap),
                  child: _KartuLaporan(item: d, urutan: i),
                ),
          ],
        ),
      ),
    );
  }

  void _bukaForm(BuildContext context, Session session) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext _) => FormDarurat(pengirim: session.user?.name ?? 'Warga'),
    );
  }
}

/// Tombol merah besar. Satu-satunya aksi utama di layar ini.
class _TombolDarurat extends StatelessWidget {
  const _TombolDarurat({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.error,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 132,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AppIcon(Ik.megaphone, size: 40, color: Colors.white),
              SizedBox(height: 10),
              Text(
                'LAPOR DARURAT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Ketuk untuk melapor ke pengurus RW',
                style: TextStyle(color: Color(0xFFFFD9D9), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nomor darurat resmi. Ditaruh di layar ini supaya warga tidak perlu
/// menunggu server aplikasi saat keadaan nyata.
class _KartuNomorDarurat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppIcon(Ik.phone, size: 18, color: context.colors.error),
              const SizedBox(width: 8),
              Text('Nomor darurat resmi',
                  style: context.text.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          for (final (String nomor, String nama) in <(String, String)>[
            ('112', 'Darurat nasional'),
            ('119', 'Ambulans'),
            ('110', 'Polisi'),
            ('115', 'PLN'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 58,
                    child: Text(
                      nomor,
                      style: context.text.titleMedium
                          ?.copyWith(color: context.colors.error),
                    ),
                  ),
                  Expanded(
                      child: Text(nama,
                          style: context.text.bodyMedium)),
                  IconButton(
                    tooltip: 'Telepon $nomor',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      launchUrl(Uri(scheme: 'tel', path: nomor));
                    },
                    icon: AppIcon(Ik.phone,
                        size: 18, color: context.colors.primary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _KartuLaporan extends StatelessWidget {
  const _KartuLaporan({required this.item, required this.urutan});

  final LaporanDarurat item;
  final int urutan;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: AppIcon(item.jenis.ikon, size: 20, color: AppColors.error),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(item.jenis.label, style: context.text.titleSmall),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.status.warna.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.status.label,
                        style: context.text.labelSmall?.copyWith(
                          color: item.status.warna,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.lokasi.isEmpty ? 'Lokasi belum diisi' : item.lokasi,
                  style: context.text.bodySmall
                      ?.copyWith(color: context.semantic.textSecondary),
                ),
                if (item.keterangan.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(item.keterangan, style: context.text.bodyMedium),
                ],
                const SizedBox(height: 8),
                Text(
                  '${item.pengirim} - ${item.umur}',
                  style: context.text.labelSmall
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

/// Form laporan darurat.
class FormDarurat extends ConsumerStatefulWidget {
  const FormDarurat({super.key, required this.pengirim});

  final String pengirim;

  @override
  ConsumerState<FormDarurat> createState() => _FormDaruratState();
}

class _FormDaruratState extends ConsumerState<FormDarurat> {
  final TextEditingController _lokasi = TextEditingController();
  final TextEditingController _keterangan = TextEditingController();
  JenisDarurat _jenis = JenisDarurat.kebakaran;
  bool _kirim = false;
  String? _galat;

  @override
  void dispose() {
    _lokasi.dispose();
    _keterangan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double bawah = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.screen, 0, AppSpacing.screen, bawah + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SectionHeader(title: 'Apa yang terjadi?'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final JenisDarurat j in JenisDarurat.values)
                  ChoiceChip(
                    label: Text(j.label),
                    avatar: AppIcon(j.ikon, size: 16),
                    selected: _jenis == j,
                    selectedColor: AppColors.error.withValues(alpha: 0.14),
                    side: BorderSide(
                      color: _jenis == j ? AppColors.error : context.semantic.line,
                    ),
                    onSelected: (bool v) {
                      if (!v) return;
                      HapticFeedback.selectionClick();
                      setState(() => _jenis = j);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lokasi,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Lokasi kejadian',
                hintText: 'Contoh: Depan Pasar RT 03, sisi kali',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _keterangan,
              textCapitalization: TextCapitalization.sentences,
              minLines: 3,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Keterangan',
                hintText: 'Ada orang terluka? Ada api? Berapa banyak?',
                border: OutlineInputBorder(),
              ),
            ),
            if (_galat != null)
              Text(
                _galat!,
                style:
                    context.text.bodySmall?.copyWith(color: AppColors.error),
              ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _kirim ? null : _submit,
              icon: const AppIcon(Ik.megaphone, size: 20),
              label: const Text('Kirim laporan darurat'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_lokasi.text.trim().isEmpty) {
      setState(() => _galat = 'Lokasi wajib diisi supaya pengurus tahu ke mana.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _kirim = true;
      _galat = null;
    });

    final Hasil<LaporanDarurat> h = await ref.read(daruratProvider.notifier).kirim(
          jenis: _jenis,
          lokasi: _lokasi.text,
          keterangan: _keterangan.text,
          pengirim: widget.pengirim,
        );

    if (!mounted) return;
    if (h.berhasil) {
      final ScaffoldMessengerState snack = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      snack.showSnackBar(
        const SnackBar(content: Text('Laporan terkirim ke pengurus RW.')),
      );
    } else {
      setState(() {
        _kirim = false;
        _galat = h.galat?.pesan ?? 'Tidak diketahui kenapa gagal.';
      });
    }
  }
}