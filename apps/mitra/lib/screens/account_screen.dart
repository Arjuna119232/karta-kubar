import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'izin_screen.dart';
import 'kotak_masuk_screen.dart';
import 'settings_screens.dart';
import 'widgets.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    void go(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    return Scaffold(
      appBar: AppBar(title: const Text('Akun')),
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(radius: 28, child: Icon(Icons.person, size: 32)),
            title: Text(s.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            subtitle: Text('${s.vehicleType} ${s.plate}'.trim()),
          ),
          const Divider(),
          ListTile(leading: const Icon(Icons.two_wheeler), title: const Text('Kendaraan'), onTap: () => go(const VehicleScreen())),
          ListTile(leading: const Icon(Icons.account_balance_wallet), title: const Text('Dompet'), onTap: () => go(const WalletScreen())),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Rating & Ulasan'),
            subtitle: Text(s.ratings.isEmpty ? 'Belum ada' : '${s.avgRating.toStringAsFixed(1)} dari ${s.ratings.length} ulasan'),
            onTap: () => go(const RatingsScreen()),
          ),
          ListTile(leading: const Icon(Icons.settings), title: const Text('Pengaturan'), onTap: () => go(const SettingsScreen())),
          ListTile(
            leading: const Icon(Icons.inbox_rounded),
            title: const Text('Kotak Masuk'),
            subtitle: const Text('Pengumuman, bonus, tips dari admin'),
            onTap: () => go(const KotakMasukScreen()),
          ),
          ListTile(leading: const Icon(Icons.lock_outline), title: const Text('Izin Aplikasi'), subtitle: const Text('Kamera, lokasi, notifikasi, dll'), onTap: () => go(const IzinScreen(saatMasuk: false))),
          ListTile(
            leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            title: const Text('SOS Darurat', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
            subtitle: const Text('Kirim lokasi ke admin + appear notifikasi'),
            onTap: () => confirmSos(context),
          ),
          ListTile(
            leading: const Icon(Icons.local_phone_outlined, color: Colors.red),
            title: const Text('Telepon 112 (Darurat)'),
            subtitle: const Text('112 = ambulans, polisi, pemadam'),
            onTap: () => teleponDarurat(context, '112'),
          ),
          ListTile(
            leading: const Icon(Icons.local_police_outlined, color: Colors.red),
            title: const Text('Telepon 110 (Polisi)'),
            onTap: () => teleponDarurat(context, '110'),
          ),
          const Divider(),
          ListTile(leading: const Icon(Icons.logout), title: const Text('Keluar'), onTap: s.logout),
        ],
      ),
    );
  }
}
