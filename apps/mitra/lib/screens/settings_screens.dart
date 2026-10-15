import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../core/format.dart';
import '../models/models.dart';
import '../services/notifikasi.dart';
import '../state/app_state.dart';
import 'widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _darurat;

  @override
  void initState() {
    super.initState();
    _darurat = TextEditingController(
        text: context.read<AppState>().kontakDarurat);
  }

  @override
  void dispose() {
    _darurat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    Widget hourPicker(String label, int value, ValueChanged<int> onChanged) => Row(children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 17))),
          DropdownButton<int>(
            value: value,
            items: [for (var h = 0; h < 24; h++) DropdownMenuItem(value: h, child: Text('${h.toString().padLeft(2, '0')}:00'))],
            onChanged: (v) => onChanged(v!),
          ),
        ]);
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Radius order: ${s.radiusKm.toStringAsFixed(0)} km', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        Slider(value: s.radiusKm, min: 1, max: 15, divisions: 14, label: '${s.radiusKm.toStringAsFixed(0)} km', onChanged: s.setRadius),
        const SizedBox(height: 12),
        const Text('Jam operasional', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        hourPicker('Buka', s.openHour, (v) => s.setHours(v, s.closeHour)),
        hourPicker('Tutup', s.closeHour, (v) => s.setHours(s.openHour, v)),
        const SizedBox(height: 20),
        const SizedBox(height: 12),
        const Text('Kontak darurat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        TextField(
          controller: _darurat,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: 'Nomor HP yang bisa dihubungi'),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () {
              context.read<AppState>().setKontakDarurat(_darurat.text.trim());
              toast(context, 'Kontak darurat disimpan');
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('SIMPAN'),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Tampilan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          style: SegmentedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          segments: const [
            ButtonSegment(value: ThemeMode.system, label: Text('Otomatis')),
            ButtonSegment(value: ThemeMode.light, label: Text('Terang')),
            ButtonSegment(value: ThemeMode.dark, label: Text('Gelap')),
          ],
          selected: {s.themeMode},
          onSelectionChanged: (v) => s.setTheme(v.first),
        ),
        const SizedBox(height: 28),
        const Text('Notifikasi aplikasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text(
          '8 notifikasi PERSISTEN tidak bisa di-swipe (hilang sendiri kalau kondisinya beres). '
          '12 notifikasi biasa bisa di-swipe. Tekan "Tes" untuk lihat masing-masing.',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 8),
        _DaftarNotif(jenis: JenisNotif.daftarPersisten, label: 'PERSISTEN (tidak bisa di-swipe)'),
        _DaftarNotif(
          jenis: JenisNotif.values.where((j) => !j.persisten).toList(),
          label: 'BIASA (bisa di-swipe)',
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            await Notifikasi.instance.bersihkanSemua();
            if (context.mounted) toast(context, 'Semua notifikasi dibersihkan');
          },
          icon: const Icon(Icons.cleaning_services_outlined),
          label: const Text('BERSIHKAN SEMUA NOTIFIKASI'),
        ),
        if (Config.demo) ...[
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () {
              s.addDummyOrder();
              toast(context, 'Order dummy dikirim (aktifkan ONLINE di Beranda)');
            },
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('BUAT ORDER DUMMY'),
          ),
        ],
      ]),
    );
  }
}

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});
  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  late String _type;
  late final TextEditingController _model, _plate;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    _type = s.vehicleType;
    _model = TextEditingController(text: s.vehicleModel);
    _plate = TextEditingController(text: s.plate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kendaraan')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        DropdownButtonFormField<String>(
          initialValue: _type,
          decoration: const InputDecoration(labelText: 'Jenis'),
          items: const [
            DropdownMenuItem(value: 'Motor', child: Text('Motor')),
            DropdownMenuItem(value: 'Mobil', child: Text('Mobil')),
            DropdownMenuItem(value: 'Sepeda', child: Text('Sepeda')),
          ],
          onChanged: (v) => setState(() => _type = v!),
        ),
        const SizedBox(height: 16),
        TextField(controller: _model, decoration: const InputDecoration(labelText: 'Merek / tipe')),
        const SizedBox(height: 16),
        TextField(controller: _plate, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Plat nomor')),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () async {
            await context.read<AppState>().saveVehicle(_type, _model.text.trim(), _plate.text.trim().toUpperCase());
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('SIMPAN'),
        ),
      ]),
    );
  }
}

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppState>().repo;
    return Scaffold(
      appBar: AppBar(title: const Text('Dompet')),
      body: FutureBuilder<List<WalletTx>>(
        future: repo.wallet(),
        builder: (c, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          final tx = snap.data ?? [];
          final bal = tx.fold(0, (a, t) => a + t.amount);
          return ListView(padding: const EdgeInsets.all(16), children: [
            const Text('Saldo'),
            Text(rp(bal), style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Theme.of(c).colorScheme.primary)),
            const SizedBox(height: 8),
            const Text('Saldo bertambah otomatis setiap order selesai. Penarikan dikelola admin.'),
            const Divider(height: 32),
            for (final t in tx)
              ListTile(
                title: Text(t.note.isEmpty ? t.kind : t.note),
                subtitle: Text(jam(t.createdAt)),
                trailing: Text('${t.amount >= 0 ? '+' : ''}${rp(t.amount)}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
          ]);
        },
      ),
    );
  }
}

class RatingsScreen extends StatelessWidget {
  const RatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Rating & Ulasan')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(child: Text(s.ratings.isEmpty ? '-' : s.avgRating.toStringAsFixed(1), style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w800))),
        Center(child: Text('${s.ratings.length} ulasan')),
        const Divider(height: 32),
        for (final r in s.ratings)
          ListTile(
            title: Row(children: [for (var i = 0; i < 5; i++) Icon(i < r.stars ? Icons.star : Icons.star_border, color: Colors.amber)]),
            subtitle: Text('${r.comment}\n${jam(r.createdAt)}'),
            isThreeLine: true,
          ),
      ]),
    );
  }
}


class _DaftarNotif extends StatelessWidget {
  const _DaftarNotif({required this.jenis, required this.label});

  final List<JenisNotif> jenis;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary)),
        ),
        for (final j in jenis)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('${j.index + 1}. ${j.judul}'),
            subtitle: Text(j.alasan),
            trailing: TextButton(
              onPressed: () async {
                await Notifikasi.instance.tampilkan(
                  j,
                  judul: j.judul,
                  isi: j.alasan,
                );
                if (context.mounted) {
                  toast(context, '${j.judul} dikirim${j.persisten ? ' (persisten)' : ''}');
                }
              },
              child: const Text('Tes'),
            ),
          ),
      ],
    );
  }
}
