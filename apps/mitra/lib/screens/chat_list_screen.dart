import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import 'chat_screen.dart';

/// Daftar percakapan dengan warga (satu baris per order).
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final daftar = <MapEntry<String, String>>[];
    if (s.active != null) {
      daftar.add(MapEntry(s.active!.id, s.active!.customerName));
    }
    for (final o in s.history.take(30)) {
      if (!daftar.any((e) => e.key == o.id)) {
        daftar.add(MapEntry(o.id, o.customerName));
      }
    }
    for (final o in s.incoming) {
      if (!daftar.any((e) => e.key == o.id)) {
        daftar.add(MapEntry(o.id, o.customerName));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chat Warga')),
      body: daftar.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Belum ada percakapan.\n\nChat muncul setelah kamu menerima order.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              itemCount: daftar.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final id = daftar[i].key;
                Order orderOf() => s.active?.id == id
                    ? s.active!
                    : (s.history.firstWhere((o) => o.id == id,
                        orElse: () => s.incoming.firstWhere((o) => o.id == id)));
                final o = orderOf();
                return ListTile(
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      (daftar[i].value.isEmpty ? 'W' : daftar[i].value[0]).toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  title: Text(daftar[i].value.isEmpty ? 'Warga' : daftar[i].value,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${o.typeLabel} - ${o.statusLabel} - ${o.distanceKm.toStringAsFixed(1)} km'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ChatScreen(order: o))),
                );
              },
            ),
    );
  }
}
