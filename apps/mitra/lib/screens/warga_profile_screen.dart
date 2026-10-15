import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'chat_room_screen.dart';
import 'order_detail_screen.dart';

/// Profil warga, dibuka dari avatar di ruang chat.
class WargaProfileScreen extends StatelessWidget {
  const WargaProfileScreen({super.key, required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final bersama = s.history.where((o) => o.customerName == order.customerName).toList();
    final nama = order.customerName.isEmpty ? 'Warga KUNBAR' : order.customerName;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Warga')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 46,
                backgroundColor: AppColors.primarySoft,
                child: Text(nama[0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ),
              const SizedBox(height: 12),
              Text(nama, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                  Text('Rating 4.9 - warga KUNBAR', style: TextStyle(fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _baris('Alamat', order.pickupAddress.isEmpty ? '-' : order.pickupAddress),
                  _baris('Total order bersama kamu', '${bersama.length}'),
                  _baris('Bergabung', 'Warga KUNBAR'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    final baru = Navigator.of(context);
                    Navigator.pop(context);
                    baru.push(MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(order: order)));
                  },
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text('CHAT'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: order.customerPhone.isEmpty
                      ? null
                      : () => launchUrl(Uri.parse('tel:${order.customerPhone}')),
                  icon: const Icon(Icons.call_rounded),
                  label: const Text('TELEPON'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order))),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('LIHAT ORDER TERKAIT'),
          ),
          const SizedBox(height: 20),
          const Text('Riwayat order dengan warga ini',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (bersama.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Belum ada order sebelumnya dengan warga ini')),
            )
          else
            for (final o in bersama)
              ListTile(
                title: Text('${o.typeLabel} - ${o.statusLabel}'),
                subtitle: Text(jam(o.doneAt)),
                trailing: Text(rp(o.fee),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
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
            SizedBox(width: 150, child: Text(kunci, style: const TextStyle(fontSize: 13))),
            Expanded(
                child: Text(nilai,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
          ],
        ),
      );
}
