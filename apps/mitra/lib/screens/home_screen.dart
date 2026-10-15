import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../state/app_state.dart';
import 'order_detail_screen.dart';
import 'widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Halo, ${s.name}'),
        actions: [
          IconButton(
            tooltip: 'SOS',
            iconSize: 34,
            color: Colors.red,
            icon: const Icon(Icons.warning_amber_rounded),
            onPressed: () => confirmSos(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: s.refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (s.offlineMode)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Text('Tidak ada sinyal. Menampilkan data tersimpan.'),
              ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(96),
                backgroundColor: s.online ? cs.primary : Colors.grey.shade700,
                textStyle: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              icon: Icon(s.online ? Icons.power_settings_new : Icons.power_off, size: 34),
              label: Text(s.online ? 'ONLINE' : 'OFFLINE'),
              onPressed: () async {
                final err = await s.setOnline(!s.online);
                if (err != null && context.mounted) toast(context, err);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(s.online ? 'Ketuk untuk berhenti terima order' : 'Ketuk untuk mulai terima order', textAlign: TextAlign.center),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Penghasilan hari ini'),
                    Text(rp(s.todayEarnings), style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: cs.primary)),
                  ])),
                  Column(children: [
                    Text('${s.todayCount}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                    const Text('order'),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            if (s.active != null) ...[
              Text('ORDER AKTIF', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              OrderCard(
                s.active!,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: s.active!))),
                actions: FilledButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: s.active!))),
                  child: const Text('BUKA ORDER'),
                ),
              ),
            ],
            if (s.online && s.active == null) ...[
              Text('ORDER MASUK (${s.incoming.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (s.incoming.isEmpty)
                const Padding(padding: EdgeInsets.all(32), child: Text('Menunggu order...', textAlign: TextAlign.center, style: TextStyle(fontSize: 18))),
              for (final o in s.incoming)
                OrderCard(
                  o,
                  actions: Row(children: [
                    Expanded(child: OutlinedButton(onPressed: () => s.reject(o), child: const Text('TOLAK'))),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () async {
                          final err = await s.accept(o);
                          if (!context.mounted) return;
                          if (err != null) {
                            toast(context, err);
                          } else if (s.active != null) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: s.active!)));
                          }
                        },
                        child: const Text('TERIMA'),
                      ),
                    ),
                  ]),
                ),
            ],
            if (!s.online && s.active == null)
              const Padding(padding: EdgeInsets.all(32), child: Text('Anda offline. Aktifkan ONLINE untuk menerima order.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18))),
          ],
        ),
      ),
    );
  }
}
