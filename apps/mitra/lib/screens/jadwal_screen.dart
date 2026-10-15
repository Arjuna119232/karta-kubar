import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../state/app_state.dart';

/// Jadwal kerja mitra: jam operasional, target harian, dan jam istirahat.
/// Datanya dihitung dari order yang benar-benar selesai - tidak dikarang.
class JadwalScreen extends StatelessWidget {
  const JadwalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final target = s.targetHarian;
    final tercapai = s.todayEarnings;

    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Kartu(
            judul: 'Target hari ini',
            isi: '${rp(tercapai)} / ${rp(target)}',
            persen: target == 0 ? 0 : (tercapai / target).clamp(0, 1).toDouble(),
            warna: AppColors.primary,
          ),
          const SizedBox(height: 14),
          _Kartu(
            judul: 'Target minggu ini',
            isi: '${rp(s.earned(s.weekStart))} dari ${rp(target * 6)}',
            persen: (s.earned(s.weekStart) / (target * 6)).clamp(0, 1).toDouble(),
            warna: const Color(0xFF1565C0),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Jam operasional',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    '${s.openHour.toString().padLeft(2, '0')}:00 - '
                    '${s.closeHour.toString().padLeft(2, '0')}:00',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text('Ubah di Pengaturan. Di luar jam ini tombol AKTIFKAN tidak aktif.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rekap 7 hari terakhir',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  for (var d = 6; d >= 0; d--) _BarisHari(s, d),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Semua angka dihitung dari order yang benar-benar selesai. Tidak ada '
            'estimasi atau data contoh di halaman ini.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Kartu extends StatelessWidget {
  const _Kartu({
    required this.judul,
    required this.isi,
    required this.persen,
    required this.warna,
  });

  final String judul;
  final String isi;
  final double persen;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(judul, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 4),
            Text(isi, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: persen,
                minHeight: 10,
                backgroundColor: warna.withValues(alpha: 0.15),
                color: warna,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarisHari extends StatelessWidget {
  const _BarisHari(this.s, this.hariLalu);
  final AppState s;
  final int hariLalu;

  @override
  Widget build(BuildContext context) {
    final n = DateTime.now().subtract(Duration(days: hariLalu));
    final mulai = DateTime(n.year, n.month, n.day);
    final order = s.doneSince(mulai).where((o) {
      final d = o.doneAt.toLocal();
      return d.year == n.year && d.month == n.month && d.day == n.day;
    }).toList();
    final total = order.fold(0, (a, o) => a + o.fee);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(_namaHari(n.weekday), style: const TextStyle(fontSize: 13))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (order.length / 5).clamp(0, 1).toDouble(),
                minHeight: 8,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 96,
            child: Text('${order.length} order - ${rp(total)}',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  String _namaHari(int w) => const ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'][w - 1];
}