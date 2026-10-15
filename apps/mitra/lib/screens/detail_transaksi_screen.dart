import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../services/pendapatan.dart';
import '../state/app_state.dart';
import 'widgets.dart';

/// Detail satu baris transaksi (order selesai atau penarikan saldo).
class DetailTransaksiScreen extends StatelessWidget {
  const DetailTransaksiScreen({super.key, required this.baris});
  final BarisTransaksi baris;

  @override
  Widget build(BuildContext context) {
    final o = baris.order;
    final w = baris.sWithdraw;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Transaksi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusBar(baris: baris),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: baris.masuk
                    ? const [AppColors.primary, Color(0xFF43A047)]
                    : const [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
              ),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(baris.masuk ? 'Dana masuk' : 'Dana keluar',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9))),
                const SizedBox(height: 6),
                Text(
                  '${baris.masuk ? '+' : '-'}${rp(baris.nominal.abs())}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (w != null) ...[
                    _baris('Nomor permintaan', w.id),
                    _baris('Metode', w.metodeLabel),
                    _baris('Tujuan', w.tujuan),
                    _baris('Status', w.statusLabel),
                    _baris('Waktu', jam(w.createdAt)),
                  ] else if (o != null) ...[
                    _baris('Order ID', o.id),
                    _baris('Jenis', o.typeLabel),
                    _baris('Customer', o.customerName.isEmpty ? 'Warga' : o.customerName),
                    _baris('Pickup', o.pickupAddress.isEmpty ? '-' : o.pickupAddress),
                    _baris('Dropoff', o.dropAddress.isEmpty ? '-' : o.dropAddress),
                    _baris('Jarak', '${o.distanceKm.toStringAsFixed(1)} km'),
                    _baris('Fee aplikasi', '15%'),
                    _baris('Pembayaran', 'Cash / QRIS'),
                    _baris('Waktu', jam(baris.waktu)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (o != null && o.customerPhone.isNotEmpty)
            FilledButton.icon(
              onPressed: () => launchUrl(Uri.parse('tel:${o.customerPhone}')),
              icon: const Icon(Icons.call_rounded),
              label: const Text('HUBUNGI CUSTOMER'),
            ),
          if (w != null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Permintaan tarik saldo diproses admin di web panel. Status berubah '
                'otomatis setelah diproses.',
                style: TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _baris(String kunci, String nilai) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 118, child: Text(kunci, style: const TextStyle(fontSize: 13))),
            Expanded(
              child: Text(nilai,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.baris});
  final BarisTransaksi baris;

  @override
  Widget build(BuildContext context) {
    final o = baris.order;
    final w = baris.sWithdraw;
    final selesai = o == null || o.isDone;
    final warna = selesai ? Colors.green : Colors.orange;
    final teks = w != null
        ? w.statusLabel
        : (o == null ? 'Transaksi' : o.statusLabel);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: warna.withValues(alpha: 0.15),
              child: Icon(
                w != null
                    ? Icons.account_balance_rounded
                    : (selesai ? Icons.check_rounded : Icons.hourglass_top_rounded),
                color: warna,
              ),
            ),
            const SizedBox(width: 12),
            Text(teks, style: TextStyle(fontWeight: FontWeight.w800, color: warna, fontSize: 17)),
          ],
        ),
      ),
    );
  }
}