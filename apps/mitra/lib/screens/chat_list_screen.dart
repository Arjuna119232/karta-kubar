import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../services/chat.dart';
import '../state/app_state.dart';
import 'chat_room_screen.dart';

/// Daftar percakapan per order. Search, filter, arsip, unread.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _cari = TextEditingController();
  FilterChat _filter = FilterChat.semua;
  String _kata = '';

  @override
  void dispose() {
    _cari.dispose();
    super.dispose();
  }

  List<Order> _daftar(AppState s) {
    final semua = <Order>[
      if (s.active != null) s.active!,
      ...s.incoming,
      ...s.history,
    ];
    return semua;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final semua = _daftar(s);
    final kata = _kata.trim().toLowerCase();

    final tampil = semua.where((o) {
      if (kata.isNotEmpty && !o.customerName.toLowerCase().contains(kata)) return false;
      final arsip = s.arsip.contains(o.id);
      switch (_filter) {
        case FilterChat.semua:
          return !arsip;
        case FilterChat.belumDibaca:
          return !arsip && s.pesanBelumDibaca(o.id) > 0;
        case FilterChat.orderAktif:
          return !arsip && s.aktifOrderIds.contains(o.id);
        case FilterChat.selesai:
          return !arsip && o.isDone;
      }
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final totalBelum = s.jumlahBelumDibaca;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Warga'),
        actions: [
          IconButton(
            tooltip: 'Tandai semua dibaca',
            onPressed: totalBelum == 0 ? null : () => s.tandaiSemuaDibaca(semua),
            icon: Badge(
              isLabelVisible: totalBelum > 0,
              label: Text('$totalBelum'),
              child: const Icon(Icons.done_all_rounded),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _cari,
              onChanged: (v) => setState(() => _kata = v),
              decoration: InputDecoration(
                hintText: 'Cari nama warga...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _kata.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _cari.clear();
                          setState(() => _kata = '');
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final f in FilterChat.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f.label),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: tampil.isEmpty
                ? _Kosong(filter: _filter, adaSemua: semua.isNotEmpty)
                : ListView.builder(
                    itemCount: tampil.length,
                    itemBuilder: (_, i) {
                      final o = tampil[i];
                      return Dismissible(
                        key: ValueKey(o.id),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.blueGrey,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('ARSIP', style: TextStyle(color: Colors.white)),
                              SizedBox(width: 8),
                              Icon(Icons.archive_rounded, color: Colors.white),
                            ],
                          ),
                        ),
                        onDismissed: (_) {
                          s.arsipkan(o.id);
                          HapticFeedback.selectionClick();
                        },
                        child: _BarisChat(order: o),
                      );
                    },
                  ),
          ),
          if (s.arsip.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextButton.icon(
                onPressed: () => s.bukaArsip(),
                icon: const Icon(Icons.inventory_2_outlined, size: 18),
                label: Text('Lihat arsip (${s.arsip.length})'),
              ),
            ),
        ],
      ),
    );
  }
}

class _BarisChat extends StatelessWidget {
  const _BarisChat({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final belum = s.pesanBelumDibaca(order.id);
    final terakhir = s.pesanTerakhir(order.id);
    final online = s.aktifOrderIds.contains(order.id);

    return ListTile(
      onTap: () {
        HapticFeedback.selectionClick();
        s.tandaiDibaca(order.id);
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => ChatRoomScreen(order: order)));
      },
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primarySoft,
            child: Text(
              order.customerName.isEmpty ? 'W' : order.customerName[0].toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
            ),
          ),
          if (online)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).cardTheme.color ?? Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(order.customerName.isEmpty ? 'Warga' : order.customerName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        terakhir == null
            ? 'Belum ada pesan'
            : (terakhir.mine ? 'Kamu: ${terakhir.isi}' : terakhir.isi),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(waktuRelatif(terakhir?.waktu), style: const TextStyle(fontSize: 11)),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                order.type == 'jastip' ? Icons.shopping_bag_rounded : Icons.two_wheeler_rounded,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 6),
              if (belum > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$belum',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Kosong extends StatelessWidget {
  const _Kosong({required this.filter, required this.adaSemua});
  final FilterChat filter;
  final bool adaSemua;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined,
                size: 72, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)),
            const SizedBox(height: 14),
            Text(
              adaSemua ? 'Tidak ada di filter ini' : 'Belum ada percakapan',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              adaSemua
                  ? 'Coba pilih filter lain atau kosongkan pencarian.'
                  : 'Chat muncul setelah kamu menerima order dari warga.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}