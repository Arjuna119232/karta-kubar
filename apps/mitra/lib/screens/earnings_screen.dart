import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../state/app_state.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});
  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  int _range = 0; // 0 harian, 1 mingguan, 2 bulanan

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final from = [s.dayStart, s.weekStart, s.monthStart][_range];
    final orders = s.doneSince(from);
    final total = orders.fold(0, (a, o) => a + o.fee);
    return Scaffold(
      appBar: AppBar(title: const Text('Penghasilan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<int>(
            style: SegmentedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            segments: const [
              ButtonSegment(value: 0, label: Text('Harian')),
              ButtonSegment(value: 1, label: Text('Mingguan')),
              ButtonSegment(value: 2, label: Text('Bulanan')),
            ],
            selected: {_range},
            onSelectionChanged: (v) => setState(() => _range = v.first),
          ),
          const SizedBox(height: 24),
          Center(child: Text(rp(total), style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary))),
          Center(child: Text('${orders.length} order selesai', style: const TextStyle(fontSize: 18))),
          const SizedBox(height: 16),
          for (final o in orders)
            ListTile(
              leading: Icon(o.type == 'jastip' ? Icons.shopping_bag : Icons.two_wheeler),
              title: Text('${o.typeLabel} • ${o.customerName}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              subtitle: Text(jam(o.doneAt)),
              trailing: Text('+${rp(o.fee)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}
