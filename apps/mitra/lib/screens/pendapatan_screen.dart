import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../services/pendapatan.dart';
import '../state/app_state.dart';
import '../widgets/kit.dart';
import 'detail_transaksi_screen.dart';
import 'tarik_saldo_screen.dart';
import 'widgets.dart';

/// Halaman pendapatan: saldo, periode, grafik, breakdown, riwayat.
class PendapatanScreen extends StatefulWidget {
  const PendapatanScreen({super.key, this.dapatTombolKembali = false});
  final bool dapatTombolKembali;

  @override
  State<PendapatanScreen> createState() => _PendapatanScreenState();
}

class _PendapatanScreenState extends State<PendapatanScreen> {
  Periode _periode = Periode.hari;
  FilterTransaksi _filter = FilterTransaksi.semua;
  bool _memuat = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _muat());
  }

  Future<void> _muat() async {
    if (!mounted) return;
    setState(() => _memuat = true);
    await context.read<AppState>().refresh();
    if (!mounted) return;
    setState(() => _memuat = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final r = RekapPendapatan.hitung(s, _periode, _filter);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.dapatTombolKembali,
        title: const Text('Pendapatan'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _memuat ? null : _muat,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Cara hitungnya',
            onPressed: () => _bantuan(context),
            icon: const Icon(Icons.help_outline_rounded),
          ),
        ],
      ),
      body: _memuat
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _muat,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _KartuSaldo(saldo: s.saldoAktif),
                  const SizedBox(height: 14),
                  _TabPeriode(
                    nilai: _periode,
                    onUbah: (p) => setState(() => _periode = p),
                  ),
                  const SizedBox(height: 14),
                  _StatTiga(r: r),
                  const SizedBox(height: 14),
                  _KartuGrafik(titik: r.grafik),
                  const SizedBox(height: 14),
                  _KartuBreakdown(r: r),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Riwayat Transaksi',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      ),
                      Text('${r.riwayat.length} baris',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final f in FilterTransaksi.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(f.label),
                              selected: _filter == f,
                              onSelected: (_) => setState(() => _filter = f),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (r.riwayat.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text('Belum ada transaksi pada periode ini.\n'
                            'Selesaikan order dulu, nanti muncul di sini.',
                            textAlign: TextAlign.center),
                      ),
                    )
                  else
                    for (final b in r.riwayat)
                      _BarisRiwayat(
                        b: b,
                        onTekan: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(context, MaterialPageRoute(
                              builder: (_) => DetailTransaksiScreen(baris: b)));
                        },
                      ),
                ],
              ),
            ),
    );
  }

  void _bantuan(BuildContext c) => showModalBottomSheet<void>(
        context: c,
        showDragHandle: true,
        builder: (c) => const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dari mana angka ini?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              SizedBox(height: 10),
              Text(
                'Semua angka di halaman ini dihitung dari order yang benar-benar '
                'selesai di perangkat ini. Tidak ada estimasi, tidak ada data '
                'contoh, tidak ada iklan.\n\n'
                'Saldo Aktif = total order selesai - penarikan saldo yang sudah '
                'diproses admin.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      );
}

class _KartuSaldo extends StatelessWidget {
  const _KartuSaldo({required this.saldo});
  final int saldo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text('Saldo Aktif',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9))),
            ],
          ),
          const SizedBox(height: 8),
          Text(rp(saldo),
              style: const TextStyle(
                  color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Bisa ditarik ke rekening atau e-wallet',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
              ),
              onPressed: () async {
                HapticFeedback.selectionClick();
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TarikSaldoScreen()));
              },
              icon: const Icon(Icons.payments_rounded),
              label: const Text('TARIK SALDO'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabPeriode extends StatelessWidget {
  const _TabPeriode({required this.nilai, required this.onUbah});
  final Periode nilai;
  final ValueChanged<Periode> onUbah;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<Periode>(
      showSelectedIcon: false,
      segments: [for (final p in Periode.values) ButtonSegment(value: p, label: Text(p.label))],
      selected: {nilai},
      onSelectionChanged: (v) => onUbah(v.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
    );
  }
}

class _StatTiga extends StatelessWidget {
  const _StatTiga({required this.r});
  final RekapPendapatan r;

  @override
  Widget build(BuildContext context) {
    Widget isi(IconData ikon, String judul, String nilai, Color warna) => Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              child: Column(
                children: [
                  Icon(ikon, color: warna, size: 22),
                  const SizedBox(height: 6),
                  FittedBox(
                    child: Text(nilai,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 2),
                  Text(judul,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ),
        );

    return Row(
      children: [
        isi(Icons.savings_rounded, 'Total ${r.periode.pendek}', rp(r.total), AppColors.primary),
        const SizedBox(width: 8),
        isi(Icons.check_circle_rounded, 'Order selesai', '${r.jumlahOrder}', const Color(0xFF1565C0)),
        const SizedBox(width: 8),
        isi(Icons.stacked_line_chart_rounded, 'Rata-rata', rp(r.rataRata), const Color(0xFF6A1B9A)),
      ],
    );
  }
}

class _KartuGrafik extends StatelessWidget {
  const _KartuGrafik({required this.titik});
  final List<TitikGrafik> titik;

  @override
  Widget build(BuildContext context) {
    final maxNilai = titik.fold<int>(0, (a, t) => t.nilai > a ? t.nilai : a);
    final tinggiGrafik = maxNilai == 0 ? 1.0 : maxNilai * 1.25;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Grafik 7 hari terakhir',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            SizedBox(
              height: 170,
              child: BarChart(
                BarChartData(
                  maxY: tinggiGrafik,
                  minY: 0,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.18),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          if (i < 0 || i >= titik.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(titik[i].label, style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.primary,
                      getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                        '${rp(rod.toY)}\n${titik[group.x].jumlahOrder} order',
                        const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < titik.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: titik[i].nilai.toDouble(),
                            width: 16,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, Color(0xFF66BB6A)],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: tinggiGrafik,
                              color: Colors.grey.withValues(alpha: 0.08),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KartuBreakdown extends StatelessWidget {
  const _KartuBreakdown({required this.r});
  final RekapPendapatan r;

  @override
  Widget build(BuildContext context) {
    Widget baris(IconData ikon, String nama, int nilai, int order, double porsi, Color c) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(ikon, color: c, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(nama, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  Text('$order order',
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 100,
                    child: Text(rp(nilai),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: porsi.clamp(0, 1),
                  minHeight: 8,
                  backgroundColor: c.withValues(alpha: 0.14),
                  color: c,
                ),
              ),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Breakdown per jenis',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            baris(Icons.shopping_bag_rounded, 'Jastip', r.jastip, r.jastipOrder,
                r.porsiJastip, AppColors.primary),
            baris(Icons.two_wheeler_rounded, 'Ojek', r.ojek, r.ojekOrder,
                r.porsiOjek, const Color(0xFF1565C0)),
            Text(
              'Jastip ${(r.porsiJastip * 100).toStringAsFixed(0)}% - '
              'Ojek ${(r.porsiOjek * 100).toStringAsFixed(0)}% dari total ${r.periode.label.toLowerCase()}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarisRiwayat extends StatelessWidget {
  const _BarisRiwayat({required this.b, required this.onTekan});
  final BarisTransaksi b;
  final VoidCallback onTekan;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTekan,
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: Color(b.warna).withValues(alpha: 0.15),
          child: Icon(
            b.sWithdraw != null
                ? Icons.account_balance_rounded
                : (b.order?.type == 'jastip'
                    ? Icons.shopping_bag_rounded
                    : Icons.two_wheeler_rounded),
            color: Color(b.warna),
          ),
        ),
        title: Text(b.judul,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${b.keterangan}\n${jam(b.waktu)}',
            maxLines: 2, overflow: TextOverflow.ellipsis),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${b.masuk ? '+' : '-'}${rp(b.nominal.abs())}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: b.masuk ? Colors.green : Colors.red,
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}