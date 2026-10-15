import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
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
          const _TransparansiCard(),
        ],
      ),
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
  const _TransparansiCard();

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
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unduh laporan segera hadir')),
            ),
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
