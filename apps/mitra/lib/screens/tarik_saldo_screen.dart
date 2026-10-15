import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../state/app_state.dart';

const _bank = ['BCA', 'Mandiri', 'BNI', 'BRI'];
const _ewallet = ['GoPay', 'OVO', 'DANA', 'ShopeePay'];
const _fee = 2500;

/// Tarik saldo. Demo: tersimpan di perangkat dan masuk daftar permintaan;
/// kalau Supabase aktif, barisnya masuk tabel `withdrawals` untuk admin.
class TarikSaldoScreen extends StatefulWidget {
  const TarikSaldoScreen({super.key});
  @override
  State<TarikSaldoScreen> createState() => _TarikSaldoScreenState();
}

class _TarikSaldoScreenState extends State<TarikSaldoScreen> {
  final _nomor = TextEditingController();
  String _jenis = 'bank';
  String _tujuanLabel = _bank.first;
  int _nominal = 0;
  bool _kirim = false;

  @override
  void dispose() {
    _nomor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final saldo = s.saldoAktif;
    final bisa = _nominal > 0 && _nominal <= saldo && _nomor.text.trim().length >= 6;

    return Scaffold(
      appBar: AppBar(title: const Text('Tarik Saldo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF43A047)]),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saldo aktif',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9))),
                const SizedBox(height: 6),
                Text(rp(saldo),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('Nominal penarikan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in [50000, 100000, 150000, 250000])
                if (v <= saldo)
                  ChoiceChip(
                    label: Text(rp(v)),
                    selected: _nominal == v,
                    onSelected: (_) => setState(() => _nominal = v),
                  ),
              ChoiceChip(
                label: const Text('Semua'),
                selected: _nominal == saldo,
                onSelected: (_) => setState(() => _nominal = saldo),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'bank', label: Text('Transfer bank')),
              ButtonSegment(value: 'ewallet', label: Text('E-wallet')),
            ],
            selected: {_jenis},
            onSelectionChanged: (v) => setState(() {
              _jenis = v.first;
              _tujuanLabel = _jenis == 'bank' ? _bank.first : _ewallet.first;
            }),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _tujuanLabel,
            decoration: InputDecoration(
              labelText: _jenis == 'bank' ? 'Pilih bank' : 'Pilih e-wallet',
            ),
            items: [
              for (final b in (_jenis == 'bank' ? _bank : _ewallet))
                DropdownMenuItem(value: b, child: Text(b)),
            ],
            onChanged: (v) => setState(() => _tujuanLabel = v ?? _tujuanLabel),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _nomor,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: _jenis == 'bank' ? 'Nomor rekening' : 'Nomor HP terdaftar',
              hintText: _jenis == 'bank' ? 'Contoh: 1234567890' : 'Contoh: 081234567890',
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _baris('Nominal', rp(_nominal)),
                  _baris('Biaya admin', rp(_fee)),
                  const Divider(height: 18),
                  _baris('Dana diterima', rp((_nominal - _fee).clamp(0, 1 << 62)),
                      tebal: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Minimal penarikan Rp 20.000. Biaya admin Rp 2.500 dipotong dari nominal. '
            'Diproses admin lewat web panel.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: (_kirim || !bisa)
                ? null
                : () async {
                    HapticFeedback.mediumImpact();
                    setState(() => _kirim = true);
                    final s = context.read<AppState>();
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    final err = await s.mintaTarik(
                      jumlah: _nominal,
                      metode: _jenis,
                      tujuan: '$_tujuanLabel ${_nomor.text.trim()}',
                    );
                    if (!mounted) return;
                    setState(() => _kirim = false);
                    if (err != null) {
                      messenger.showSnackBar(
                          SnackBar(content: Text(err, style: const TextStyle(fontSize: 16))));
                      return;
                    }
                    await showDialog<void>(
                      context: navigator.context,
                      builder: (c) => AlertDialog(
                        title: const Text('Permintaan terkirim'),
                        content: Text(
                          'Penarikan ${rp(_nominal)} ke $_tujuanLabel sedang menunggu '
                          'diproses admin. Status bisa dilihat di Riwayat Transaksi.',
                        ),
                        actions: [
                          FilledButton(
                              onPressed: () => Navigator.pop(c),
                              child: const Text('OK')),
                        ],
                      ),
                    );
                    if (mounted) navigator.pop();
                  },
            child: _kirim
                ? const SizedBox(
                    height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3))
                : const Text('KONFIRMASI TARIK SALDO'),
          ),
        ],
      ),
    );
  }

  Widget _baris(String kunci, String nilai, {bool tebal = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(kunci)),
            Text(nilai,
                style: TextStyle(
                    fontWeight: tebal ? FontWeight.w800 : FontWeight.w600,
                    fontSize: tebal ? 17 : 14)),
          ],
        ),
      );
}