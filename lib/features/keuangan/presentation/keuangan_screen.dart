import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ekspor_csv.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/haptics.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/status_views.dart';
import '../domain/keuangan.dart';

/// Layar keuangan. Data SELALU lewat repository (`iuranProvider`), bukan
/// membaca data demo langsung, supaya sumber data bisa diganti tanpa mengubah
/// satu baris pun di sini.
class KeuanganScreen extends ConsumerWidget {
  const KeuanganScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Iuran>> iuran = ref.watch(iuranProvider);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, 12, AppSpacing.screen, 96),
        children: <Widget>[
          Text('Keuangan', style: context.text.headlineMedium),
          const SizedBox(height: 16),
          const _SaldoCard(),
          const SizedBox(height: AppSpacing.section),
          const SectionHeader(title: 'Kas 5 Bulan Terakhir'),
          const AppCard(child: _KasChart()),
          const SizedBox(height: AppSpacing.section),
          const SectionHeader(title: 'Iuran Saya'),
          _IuranCard(iuran: iuran),
          const SizedBox(height: AppSpacing.section),
          const SectionHeader(title: 'Transparansi'),
          _TransparansiCard(
            onUnduh: () => _unduhLaporan(context, ref),
          ),
        ],
      ),
    );
  }

  /// Susun CSV dari data yang sedang tampil, lalu buka pratinjau.
  ///
  /// Data dibaca dari provider yang SAMA dengan layar ini, jadi berkas yang
  /// diunduh selalu sama dengan angka yang dibaca anggota.
  static Future<void> _unduhLaporan(BuildContext context, WidgetRef ref) async {
    Haptics.ringan();
    final List<Iuran> iuran =
        ref.read(iuranProvider).valueOrNull ?? const <Iuran>[];
    // `kas()` sudah mengembalikan list kosong saat gagal (bukan Hasil), jadi
    // tidak ada penanganan galat yang perlu ditulis ulang di sini.
    final List<KasBulanan> dataKas =
        await ref.read(iuranProvider.notifier).kas();

    if (!context.mounted) return;
    final String csv = _csvLaporan(iuran, dataKas);
    await AppSheet.tampilkan<void>(
      context,
      judul: 'Laporan kas',
      subjudul: 'CSV siap dibuka di Excel atau Google Sheets',
      isi: _PratinjauCsv(csv: csv),
    );
  }

  /// CSV: satu blok iuran, satu blok rekap kas.
  static String _csvLaporan(List<Iuran> iuran, List<KasBulanan> kas) {
    final StringBuffer b = StringBuffer()
      ..writeln(EksporBerkas.baris(<Object?>['IURAN WARGA']))
      ..writeln(EksporBerkas.baris(<Object?>['Periode', 'Nominal', 'Status']));
    for (final Iuran i in iuran) {
      b.writeln(EksporBerkas.baris(
        <Object?>[i.periode, i.nominal, i.lunas ? 'Lunas' : 'Belum'],
      ));
    }
    final int sudah = iuran.where((Iuran i) => i.lunas).length;
    final int total = iuran.fold<int>(0, (int s, Iuran i) => s + i.nominal);
    b
      ..writeln()
      ..writeln(EksporBerkas.baris(<Object?>['RINGKASAN']))
      ..writeln(EksporBerkas.baris(<Object?>['Jumlah bulan', sudah]))
      ..writeln(EksporBerkas.baris(<Object?>['Belum lunas', iuran.length - sudah]))
      ..writeln(EksporBerkas.baris(<Object?>['Total iuran', total]))
      ..writeln()
      ..writeln(EksporBerkas.baris(<Object?>['REKAP KAS BULANAN']))
      ..writeln(EksporBerkas.baris(<Object?>['Bulan', 'Juta']));
    for (final KasBulanan k in kas) {
      b.writeln(EksporBerkas.baris(<Object?>[k.label, k.juta]));
    }
    return b.toString();
  }
}

/// Pratinjau isi CSV + dua jalan keluarnya: salin ke clipboard, atau tulis
/// berkas lalu buka sheet berbagi Android.
class _PratinjauCsv extends StatefulWidget {
  const _PratinjauCsv({required this.csv});

  final String csv;

  @override
  State<_PratinjauCsv> createState() => _PratinjauCsvState();
}

class _PratinjauCsvState extends State<_PratinjauCsv> {
  bool _sibuk = false;

  Future<void> _salin() async {
    Haptics.ringan();
    await Clipboard.setData(ClipboardData(text: widget.csv));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV disalin ke clipboard.')),
    );
  }

  Future<void> _bagikan() async {
    Haptics.sedang();
    setState(() => _sibuk = true);
    try {
      await EksporBerkas.bagikan(
        isi: widget.csv,
        namaBerkas: EksporBerkas.namaBerkasTanggal('laporan-kas', DateTime.now()),
        subyek: 'Laporan kas KARANG TARUNA',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyiapkan berkas: $e')),
      );
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int baris = '\n'.allMatches(widget.csv).length + 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '$baris baris - siap diunduh atau disalin.',
          style: context.text.bodySmall
              ?.copyWith(color: context.semantic.textSecondary),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 220),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.semantic.card,
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(color: context.semantic.line),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              widget.csv,
              style: context.text.bodySmall?.copyWith(
                fontFamily: 'monospace',
                height: 1.45,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: _sibuk ? null : _salin,
                // Tanpa ikon: enum `Ik` tidak punya ikon salin, dan memakai
                // ikon yang maknanya beda lebih buruk daripada tanpa ikon.
                child: const Text('Salin'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                onPressed: _sibuk ? null : _bagikan,
                loading: _sibuk,
                icon: Ik.download,
                label: 'Unduh',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SaldoCard extends StatelessWidget {
  const _SaldoCard();

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
          Text(
            'Saldo Kas Karang Taruna',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Rp 12.450.000',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _MiniStat(
                  label: 'Masuk (Okt)',
                  value: 'Rp 2.4 jt',
                  icon: Ik.southWest,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                  label: 'Keluar (Okt)',
                  value: 'Rp 850 rb',
                  icon: Ik.northEast,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final Ik icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          AppIcon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KasChart extends ConsumerWidget {
  const _KasChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Grafik kas diambil lewat repository yang sama dengan iuran.
    final Future<List<KasBulanan>> kas =
        ref.read(iuranProvider.notifier).kas();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 160,
          child: FutureBuilder<List<KasBulanan>>(
            future: kas,
            builder: (BuildContext context,
                AsyncSnapshot<List<KasBulanan>> snap) {
              final List<KasBulanan> data = snap.data ?? const <KasBulanan>[];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  for (int i = 0; i < data.length; i++)
                    Expanded(
                      child: _Bar(
                        label: data[i].label,
                        value: data[i].juta,
                        max: 14,
                        isLast: i == data.length - 1,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            AppIcon(Ik.trendingUp,
                size: 18, color: context.colors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Kas naik 8,4% dibanding bulan lalu.',
                style: context.text.bodySmall
                    ?.copyWith(color: context.semantic.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.value,
    required this.max,
    required this.isLast,
  });

  final String label;
  final double value;
  final double max;

  /// Bar bulan terakhir diberi warna penuh, yang lain redup.
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final double ratio = (value / max).clamp(0.05, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Text(
            value.toStringAsFixed(1),
            style: context.text.labelSmall
                ?.copyWith(color: context.semantic.textSecondary),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 108,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: ratio,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isLast
                        ? context.colors.primary
                        : context.colors.primary.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: context.text.labelSmall),
        ],
      ),
    );
  }
}

class _IuranCard extends StatelessWidget {
  const _IuranCard({required this.iuran});

  final AsyncValue<List<Iuran>> iuran;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: iuran.when(
        loading: () => const _IuranSkeleton(),
        error: (Object e, StackTrace st) => Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Iuran belum bisa dimuat: $e',
              style: context.text.bodyMedium
                  ?.copyWith(color: context.colors.error)),
        ),
        data: (List<Iuran> rows) {
          if (rows.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Belum ada riwayat iuran.'),
            );
          }
          return Column(
            children: <Widget>[
              for (int i = 0; i < rows.length; i++) ...<Widget>[
                _IuranRow(
                  label: rows[i].periode,
                  amount: rows[i].nominal,
                  paid: rows[i].lunas,
                ),
                if (i != rows.length - 1)
                  Divider(height: 1, color: context.semantic.line),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _IuranRow extends StatelessWidget {
  const _IuranRow({
    required this.label,
    required this.amount,
    required this.paid,
  });

  final String label;
  final int amount;
  final bool paid;

  @override
  Widget build(BuildContext context) {
    final Color tone = paid ? AppColors.success : AppColors.warning;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppIcon(
              paid ? Ik.check : Ik.clock,
              color: tone,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: context.text.titleSmall),
                const SizedBox(height: 2),
                Text(
                  'Rp ${_format(amount)}',
                  style: context.text.bodySmall
                      ?.copyWith(color: context.semantic.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              paid ? 'Lunas' : 'Belum bayar',
              style: context.text.labelSmall?.copyWith(color: tone),
            ),
          ),
        ],
      ),
    );
  }

  static String _format(int v) {
    final String s = v.toString();
    final StringBuffer b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }
}

class _TransparansiCard extends StatelessWidget {
  const _TransparansiCard({required this.onUnduh});

  final VoidCallback onUnduh;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppIcon(Ik.shieldCheck,
                  color: context.colors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Laporan terbuka untuk semua anggota',
                    style: context.text.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Setiap pemasukan dan pengeluaran dicatat bendahara dan bisa diaudit anggota. '
            'Pembayaran iuran online (QRIS) akan hadir setelah integrasi backend.',
            style: context.text.bodyMedium
                ?.copyWith(color: context.semantic.textSecondary),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onUnduh,
            icon: const AppIcon(Ik.download, size: 18),
            label: const Text('Unduh laporan'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


/// Kerangka baris iuran saat data masih dimuat — bentuknya meniru baris asli
/// (lingkaran status + dua baris teks) supaya tidak ada lompatan tata letak
/// ketika data benar-benar tiba.
class _IuranSkeleton extends StatelessWidget {
  const _IuranSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            for (int i = 0; i < 3; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  const AppSkeleton(height: 36, width: 36, radius: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const <Widget>[
                        AppSkeleton(height: 12, width: 128, radius: 6),
                        SizedBox(height: AppSpacing.xs),
                        AppSkeleton(height: 10, radius: 5),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
