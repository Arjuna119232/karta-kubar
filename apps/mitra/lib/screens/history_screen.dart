import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'order_detail_screen.dart';
import 'widgets.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Order')),
      body: s.history.isEmpty
          ? const Center(child: Text('Belum ada riwayat', style: TextStyle(fontSize: 18)))
          : RefreshIndicator(
              onRefresh: s.refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final o in s.history)
                    OrderCard(o,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: o, readOnly: true)))),
                ],
              ),
            ),
    );
  }
}
