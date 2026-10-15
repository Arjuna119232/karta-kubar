import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../services/kotak_masuk.dart';
import 'detail_notifikasi_screen.dart';
import '../state/app_state.dart';

/// Kotak Masuk: pengumuman, bonus, tips, event, peringatan, update dari admin.
class KotakMasukScreen extends StatefulWidget {
  const KotakMasukScreen({super.key, this.dapatTombolKembali = true});
  final bool dapatTombolKembali;

  @override
  State<KotakMasukScreen> createState() => _KotakMasukScreenState();
}

class _KotakMasukScreenState extends State<KotakMasukScreen> {
  final _cari = TextEditingController();
  FilterKotak _filter = FilterKotak.semua;
  KategoriNotif? _kategori;
  bool _tampilArsip = false;

  @override
  void dispose() {
    _cari.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final svc = NotifikasiService.instance;
    final semua = svc.semua();
    final kata = _cari.text.trim().toLowerCase();

    var daftar = semua.where((n) {
      if (_tampilArsip) {
        if (!n.diarsipkan) return false;
      } else if (n.diarsipkan) {
        return false;
      }
      if (kata.isNotEmpty && !n.judul.toLowerCase().contains(kata) && !n.isi.toLowerCase().contains(kata)) {
        return false;
      }
      if (_kategori != null && n.kategori != _kategori) return false;
      switch (_filter) {
        case FilterKotak.semua:
          return true;
        case FilterKotak.penting:
          return n.prioritas != PrioritasNotif.normal;
        case FilterKotak.belumDibaca:
          return !n.dibaca;
      }
    }).toList();

    // Penting & mendesak selalu di atas, lalu berdasarkan waktu.
    daftar.sort((a, b) {
      final pa = a.prioritas.index, pb = b.prioritas.index;
      if (pa != pb) return pb.compareTo(pa);
      return b.waktu.compareTo(a.waktu);
    });

    // Group per tanggal (yang dipakai = tanggal papier pertama per kelompok).
    final List<Object> isi = [];
    String? kelompok;
    for (final n in daftar) {
      final k = kelompokTanggal(n.waktu);
      if (k != kelompok) {
        kelompok = k;
        isi.add(k);
      }
      isi.add(n);
    }

    final belum = svc.belumDibaca();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.dapatTombolKembali,
        title: const Text('Kotak Masuk'),
        actions: [
          IconButton(
            tooltip: 'Tandai semua dibaca',
            onPressed: belum == 0
                ? null
                : () => setState(() {
                      svc.semuaDibaca();
                      s.sentuh();
                    }),
            icon: Badge(
              isLabelVisible: belum > 0,
              label: Text('$belum'),
              child: const Icon(Icons.done_all_rounded),
            ),
          ),
          IconButton(
            tooltip: _tampilArsip ? 'Kembali ke Kotak Masuk' : 'Lihat arsip',
            onPressed: () => setState(() => _tampilArsip = !_tampilArsip),
            icon: Icon(_tampilArsip
                ? Icons.inbox_rounded
                : Icons.inventory_2_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              controller: _cari,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari notifikasi...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _cari.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _cari.clear();
                          setState(() {});
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final f in FilterKotak.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f == FilterKotak.belumDibaca && belum > 0
                          ? '${f.label} ($belum)'
                          : f.label),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ChoiceChip(
                  label: const Text('Semua kategori'),
                  selected: _kategori == null,
                  onSelected: (_) => setState(() => _kategori = null),
                ),
                for (final k in KategoriNotif.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(k.ikon, size: 16, color: k.warna),
                      label: Text(k.label),
                      selected: _kategori == k,
                      onSelected: (_) => setState(() => _kategori = k),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: isi.isEmpty
                ? _Kosong(arsip: _tampilArsip)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: isi.length,
                    itemBuilder: (_, i) {
                      final item = isi[i];
                      if (item is String) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
                          child: Text(item,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary)),
                        );
                      }
                      final n = item as NotifikasiMk;
                      return Dismissible(
                        key: ValueKey(n.id),
                        background: _latar(n.dibaca
                            ? Icons.mark_email_unread_rounded
                            : Icons.archive_rounded,
                            n.dibaca ? Colors.blueGrey : Colors.teal),
                        onDismissed: (_) => setState(() {
                          if (n.dibaca) {
                            svc.tandaiBelumDibaca(n.id);
                          } else {
                            svc.tandaiDibaca(n.id);
                          }
                          s.sentuh();
                        }),
                        child: _BarisNotif(
                          n: n,
                          onTekan: () {
                            setState(() {
                              svc.tandaiDibaca(n.id);
                              s.sentuh();
                            });
                            Navigator.push(context, MaterialPageRoute(
                                builder: (_) => DetailNotifikasiScreen(n: n)));
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _latar(IconData ikon, Color warna) => Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: warna,
        child: Icon(ikon, color: Colors.white),
      );
}

class _BarisNotif extends StatelessWidget {
  const _BarisNotif({required this.n, required this.onTekan});
  final NotifikasiMk n;
  final VoidCallback onTekan;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTekan,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: n.kategori.warna.withValues(alpha: 0.16),
                child: Icon(n.kategori.ikon, color: n.kategori.warna),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!n.dibaca)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: const BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle),
                          ),
                        Expanded(
                          child: Text(n.judul,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: n.dibaca ? FontWeight.w600 : FontWeight.w800,
                                fontSize: 15,
                              )),
                        ),
                        Text(waktuRelatif(n.waktu), style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(n.isi,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13,
                            color: n.dibaca ? Colors.black54 : Colors.black87)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: n.kategori.warna.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(n.kategori.label,
                              style: TextStyle(
                                  fontSize: 11, color: n.kategori.warna, fontWeight: FontWeight.w700)),
                        ),
                        if (n.prioritas != PrioritasNotif.normal) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(n.prioritas.label,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Kosong extends StatelessWidget {
  const _Kosong({required this.arsip});
  final bool arsip;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_rounded,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)),
              const SizedBox(height: 14),
              Text(arsip ? 'Arsip kosong' : 'Belum ada notifikasi',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                arsip
                    ? 'Notifikasi yang diarsipkan akan muncul di sini.'
                    : 'Notifikasi dari admin akan muncul di sini.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}