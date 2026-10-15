import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';

class ChatScreen extends StatefulWidget {
  final Order order;
  const ChatScreen({super.key, required this.order});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppState>().repo;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.order.customerName)),
      body: Column(children: [
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: repo.messages(widget.order.id),
            builder: (c, snap) {
              final msgs = snap.data ?? [];
              if (msgs.isEmpty) return const Center(child: Text('Belum ada pesan'));
              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  for (final m in msgs)
                    Align(
                      alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(c).size.width * 0.75),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: m.mine ? cs.primaryContainer : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(m.body, style: const TextStyle(fontSize: 17)),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              Expanded(child: TextField(controller: _ctl, style: const TextStyle(fontSize: 17), decoration: const InputDecoration(hintText: 'Tulis pesan...'))),
              const SizedBox(width: 8),
              IconButton.filled(
                iconSize: 30,
                onPressed: () {
                  final t = _ctl.text.trim();
                  if (t.isEmpty) return;
                  _ctl.clear();
                  repo.sendMessage(widget.order.id, t);
                },
                icon: const Icon(Icons.send),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
