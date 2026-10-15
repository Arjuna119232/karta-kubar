import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../services/layanan.dart';
import '../state/app_state.dart';

/// Detail + pengaturan satu layanan.
class DetailLayananScreen extends StatefulWidget {
  const DetailLayananScreen({super.key, required this.kode});
  final KodeLayanan kode;

  @override
  State<DetailLayananScreen> createState() => _DetailLayananScreenState();
}

class _DetailLayananScreenState extends State<DetailLayananScreen> {
  late PengaturanLayanan _p;
  late final TextEditingController _fee;

  @override
  void initState() {
    super.initState();
    _p = context.read<AppState>().pengaturan(widget.kode);
    _fee = TextEditingController(text: '${_p.feeMinimum}');
  }

  @override
  void dispose() {
    _fee.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final k = widget.kode;
    final stat = s.statistikLayanan(k);

    return Scaffold(
      appBar: AppBar(title: Text(k.nama)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: k.warna.withValues(alpha: 0.14),
                    child: Icon(k.ikon, color: k.warna, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(k.nama,
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                        Text(k.deskripsi, style: const TextStyle(fontSize: 13)),
                        Text('Contoh: ${k.contoh}',
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _p.aktif,
                    onChanged: (v) => setState(() => _p = _p.salin(aktif: v)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _Judul('Pengaturan'),
          Text('Radius maksimal: ${_p.radiusKm} km'),
          Slider(
            value: _p.radiusKm.toDouble(),
            min: 1,
            max: k.radiusMaks.toDouble(),
            divisions: k.radiusMaks - 1,
            label: '${_p.radiusKm} km',
            onChanged: (v) => setState(() => _p = _p.salin(radiusKm: v.round())),
          ),
          Row(
            children: [
              Expanded(
                child: _Jam(
                  label: 'Mulai',
                  jam: _p.jamMulai,
                  onUbah: (v) => setState(() => _p = _p.salin(jamMulai: v)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Jam(
                  label: 'Selesai',
                  jam: _p.jamSelesai,
                  onUbah: (v) => setState(() => _p = _p.salin(jamSelesai: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _fee,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Fee minimum (Rp)',
              helperText: 'Order di bawah nominal ini tidak diterima',
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _p.autoTerima,
            onChanged: (v) => setState(() => _p = _p.salin(autoTerima: v)),
            title: const Text('Terima order otomatis'),
            subtitle: const Text(
                'Berisiko: order langsung diterima tanpa kamu pilih.'),
          ),
          const SizedBox(height: 8),
          const _Judul('Prioritas'),
          SegmentedButton<PrioritasLayanan>(
            showSelectedIcon: false,
            segments: [
              for (final p in PrioritasLayanan.values)
                ButtonSegment(value: p, label: Text(p.label)),
            ],
            selected: {_p.prioritas},
            onSelectionChanged: (v) => setState(() => _p = _p.salin(prioritas: v.first)),
          ),
          const SizedBox(height: 20),
          const _Judul('Statistik'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _stat('Order', '${stat.totalOrder}'),
                  _stat('Pendapatan', rp(stat.totalPendapatan)),
                  _stat('Rata fee', rp(stat.rataFee)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Statistik dihitung dari order yang benar-benar selesai di perangkat ini.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 20),
          const _Judul('Info'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estimasi ${k.estimasi}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const Divider(height: 20),
                  const Text('Tips', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(k.tips, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              final fee = int.tryParse(_fee.text.trim());
              s.simpanPengaturanLayanan(
                _p.salin(feeMinimum: (fee == null || fee < 0) ? _p.feeMinimum : fee),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pengaturan tersimpan')));
              Navigator.pop(context);
            },
            child: const Text('SIMPAN PENGATURAN'),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String nilai) => Expanded(
        child: Column(
          children: [
            Text(nilai,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      );
}

class _Judul extends StatelessWidget {
  const _Judul(this.teks);
  final String teks;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
        child: Text(teks,
            style: const TextStyle(
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
                color: AppColors.primary)),
      );
}

class _Jam extends StatelessWidget {
  const _Jam({required this.label, required this.jam, required this.onUbah});
  final String label;
  final int jam;
  final ValueChanged<int> onUbah;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        icon: const Icon(Icons.schedule_rounded, size: 18),
        label: Text('$label ${jam.toString().padLeft(2, '0')}:00'),
        onPressed: () async {
          final v = await showTimePicker(
            context: context,
            initialTime: TimeOfDay(hour: jam, minute: 0),
          );
          if (v != null) onUbah(v.hour);
        },
      );
}
