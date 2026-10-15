import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/format.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'chat_room_screen.dart';
import 'peta_screen.dart';
import 'widgets.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;
  final bool readOnly;
  const OrderDetailScreen({super.key, required this.order, this.readOnly = false});

  Future<void> _navigate(BuildContext c, Order o) async {
    final (lat, lng, addr) = o.navTarget;
    final q = (lat != null && lng != null) ? '$lat,$lng' : Uri.encodeComponent(addr);
    final intent = Uri.parse('google.navigation:q=$q&mode=d');
    final web = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$q&travelmode=driving');
    if (!await launchUrl(intent, mode: LaunchMode.externalApplication)) {
      if (!await launchUrl(web, mode: LaunchMode.externalApplication) && c.mounted) {
        toast(c, 'Google Maps tidak bisa dibuka');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final o = (!readOnly && s.active?.id == order.id) ? s.active! : order;
    final live = !readOnly && o.isActive;
    return Scaffold(
      appBar: AppBar(title: Text('Order ${o.typeLabel}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(rp(o.fee), style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),
          Text('${o.distanceKm.toStringAsFixed(1)} km • ${o.statusLabel}', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text(o.customerName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          OrderInfo(o),
          if (live) ...[
            const SizedBox(height: 8),
            const Row(children: [Icon(Icons.my_location, size: 18), SizedBox(width: 8), Expanded(child: Text('Lokasi Anda dibagikan ke warga selama order aktif'))]),
            const SizedBox(height: 20),
            OutlinedButton.icon(onPressed: () => _navigate(context, o), icon: const Icon(Icons.navigation, size: 28), label: const Text('NAVIGASI')),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PetaScreen(order: o))),
              icon: const Icon(Icons.map_outlined, size: 28),
              label: const Text('LIHAT PETA'),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomScreen(order: o))),
                icon: const Icon(Icons.chat),
                label: const Text('CHAT'),
              )),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse('tel:${o.customerPhone}')),
                icon: const Icon(Icons.call),
                label: const Text('TELEPON'),
              )),
            ]),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(76)),
              onPressed: () async {
                final err = await s.advance();
                if (!context.mounted) return;
                if (err != null) {
                  toast(context, err);
                } else if (s.active == null) {
                  toast(context, 'Order selesai. Penghasilan +${rp(o.fee)}');
                  Navigator.pop(context);
                }
              },
              child: Text(o.nextLabel),
            ),
          ],
        ],
      ),
    );
  }
}
