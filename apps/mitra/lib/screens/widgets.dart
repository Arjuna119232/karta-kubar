import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/format.dart';
import '../models/models.dart';
import '../state/app_state.dart';

void toast(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m, style: const TextStyle(fontSize: 16))));

Future<void> confirmSos(BuildContext c) async {
  final ok = await showDialog<bool>(
    context: c,
    builder: (d) => AlertDialog(
      title: const Text('Kirim SOS?'),
      content: const Text('Lokasi Anda dikirim ke admin KUNBAR. Jika bahaya nyata, telepon 112.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size(130, 52)),
          onPressed: () => Navigator.pop(d, true),
          child: const Text('KIRIM SOS'),
        ),
      ],
    ),
  );
  if (ok == true && c.mounted) {
    final m = await c.read<AppState>().sos();
    if (c.mounted) toast(c, m);
  }
}

/// Telepon darurat: 112 (semua layanan) dan 110 (polisi).
Future<void> teleponDarurat(BuildContext c, String nomor) async {
  final ok = await launchUrl(Uri.parse('tel:$nomor'));
  if (!ok && c.mounted) toast(c, 'Tidak bisa membuka dialer otomatis');
}

class OrderInfo extends StatelessWidget {
  final Order o;
  const OrderInfo(this.o, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget row(IconData i, String label, String v) => Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(i, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: t.bodySmall),
              Text(v, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ])),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      row(Icons.trip_origin, o.type == 'jastip' ? 'Beli / ambil di' : 'Jemput di', o.pickupAddress),
      row(Icons.place, 'Antar ke', o.dropAddress),
      if (o.note.isNotEmpty) row(Icons.sticky_note_2_outlined, 'Catatan', o.note),
    ]);
  }
}

class OrderCard extends StatelessWidget {
  final Order o;
  final VoidCallback? onTap;
  final Widget? actions;
  const OrderCard(this.o, {super.key, this.onTap, this.actions});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(8)),
                child: Text(o.typeLabel, style: TextStyle(fontWeight: FontWeight.w800, color: cs.onPrimaryContainer)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(o.customerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
              Text(rp(o.fee), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: cs.primary)),
            ]),
            const SizedBox(height: 4),
            Text('${o.distanceKm.toStringAsFixed(1)} km • ${o.statusLabel}'),
            OrderInfo(o),
            if (actions != null) ...[const SizedBox(height: 16), actions!],
          ]),
        ),
      ),
    );
  }
}
