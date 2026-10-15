import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/izin.dart';
import '../state/app_state.dart';
import 'widgets.dart';

/// Halaman izin aplikasi.
/// [saatMasuk] = true -> tampil otomatis sekali setelah login (bisa dilewati).
/// [saatMasuk] = false -> dibuka manual dari menu Akun.
class IzinScreen extends StatefulWidget {
  const IzinScreen({super.key, this.saatMasuk = true});
  final bool saatMasuk;

  @override
  State<IzinScreen> createState() => _IzinScreenState();
}

class _IzinScreenState extends State<IzinScreen> {
  final Map<String, StatusIzin> _status = {};
  String? _sibuk;

  @override
  void initState() {
    super.initState();
    _muatSemua();
  }

  Future<void> _muatSemua() async {
    for (final it in daftarIzin) {
      final s = it.manual ? StatusIzin.manual : await statusIzin(it.izin);
      if (!mounted) return;
      setState(() => _status[it.kunci] = s);
    }
  }

  Future<void> _minta(ItemIzin it) async {
    setState(() => _sibuk = it.kunci);
    final s = it.manual ? StatusIzin.manual : await mintaIzin(it.izin);
    if (!mounted) return;
    setState(() {
      _sibuk = null;
      _status[it.kunci] = s;
    });
    if (s == StatusIzin.diblokir) {
      toast(context, '${it.judul} diblokir Android. Buka lewat Pengaturan HP.');
    }
  }

  void _tutup() {
    final s = context.read<AppState>();
    if (widget.saatMasuk) {
      s.tandaiIzinDitinjau();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final keluar = widget.saatMasuk;
    return Scaffold(
      appBar: keluar
          ? null
          : AppBar(title: const Text('Izin Aplikasi')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Izin Aplikasi',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text(
                    'Android akan meminta izin satu per satu. Menolak tidak membuat '
                    'aplikasi rusak - hanya fitur yang butuh izin itu yang tidak bisa jalan. '
                    'Izin bisa diubah kapan saja di menu Akun.',
                  ),
                  const SizedBox(height: 16),
                  for (final it in daftarIzin)
                    _KartuIzin(
                      item: it,
                      status: _status[it.kunci],
                      sibuk: _sibuk == it.kunci,
                      onMinta: () => _minta(it),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Izin "Akses data & file" dibuka lewat Pengaturan HP karena jenisnya '
                    'spesial (sistem memilih folder yang boleh dibuka aplikasi).',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _tutup,
                  child: Text(keluar ? 'NANTI SAJA, LANJUT' : 'SELESAI'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KartuIzin extends StatelessWidget {
  const _KartuIzin({
    required this.item,
    required this.status,
    required this.sibuk,
    required this.onMinta,
  });

  final ItemIzin item;
  final StatusIzin? status;
  final bool sibuk;
  final VoidCallback onMinta;

  @override
  Widget build(BuildContext context) {
    final s = status ?? StatusIzin.belum;
    final (label, warna) = switch (s) {
      StatusIzin.sudah => ('Sudah diizinkan', Colors.green),
      StatusIzin.ditolak => ('Ditolak', Colors.orange),
      StatusIzin.diblokir => ('Diblokir Android', Colors.red),
      StatusIzin.manual => ('lewat Pengaturan HP', Colors.blue),
      StatusIzin.tidakTersedia => ('tidak tersedia di HP ini', Colors.grey),
      StatusIzin.belum => ('belum diizinkan', Colors.grey),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(item.ikon, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.judul,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(item.alasan),
                  const SizedBox(height: 6),
                  Text(label,
                      style: TextStyle(color: warna, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (s != StatusIzin.sudah)
                    OutlinedButton.icon(
                      onPressed: sibuk ? null : onMinta,
                      icon: sibuk
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.lock_open_outlined),
                      label: Text(s == StatusIzin.manual
                          ? 'Buka Pengaturan HP'
                          : 'Izinkan'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
