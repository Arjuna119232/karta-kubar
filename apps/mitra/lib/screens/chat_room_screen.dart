import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/chat.dart';
import '../state/app_state.dart';
import '../widgets/kit.dart';
import 'order_detail_screen.dart';
import 'peta_screen.dart';
import 'warga_profile_screen.dart';

/// Ruang chat dengan warga untuk satu order.
class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key, required this.order});
  final Order order;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  Pesan? _balas;
  String _cari = '';
  int _tampil = 30; // jumlah pesan yang dirender (load more naik ke atas)
  bool _bannerBuka = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().tandaiDibaca(widget.order.id);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _keBawah() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _kirim() async {
    final t = _input.text.trim();
    if (t.isEmpty) return;
    final s = context.read<AppState>();
    _input.clear();
    HapticFeedback.selectionClick();
    await s.repo.sendMessage(
      widget.order.id,
      t,
      balasId: _balas?.id,
      balasRingkas: _balas?.isi,
    );
    setState(() => _balas = null);
    _keBawah();
  }

  Future<void> _kirimLokasi(AppState s) async {
    final messenger = ScaffoldMessenger.of(context);
    final p = await s.posisiSaya();
    if (!mounted) return;
    if (p == null) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Lokasi belum bisa diambil. Izinkan lokasi dulu.',
              style: TextStyle(fontSize: 16))));
      return;
    }
    await s.repo.sendMessage(
      widget.order.id,
      'Lokasi saya saat ini',
      jenis: JenisPesan.lokasi,
      lat: p.lat,
      lng: p.lng,
    );
    _keBawah();
  }

  Future<void> _laporkan(BuildContext c, AppState s, Pesan p) async {
    final alasan = await showDialog<String>(
      context: c,
      builder: (d) => _DialogLaporan(pesan: p),
    );
    if (alasan == null || alasan.isEmpty || !mounted) return;
    final err = await s.laporkan(widget.order, alasan);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err ?? 'Laporan terkirim ke admin KUNBAR',
            style: const TextStyle(fontSize: 16))));
  }

  Future<void> _kirimFoto(AppState s) async {
    final path = await s.pilihFoto();
    if (!mounted || path == null) return;
    await s.repo.sendMessage(
      widget.order.id,
      'Foto',
      jenis: JenisPesan.foto,
      attachmentUrl: path,
    );
    _keBawah();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final pesan = s.pesanUntuk(widget.order.id);
    final disaring = _cari.isEmpty
        ? pesan
        : pesan.where((p) => p.isi.toLowerCase().contains(_cari.toLowerCase())).toList();
    // Tampilkan N pesan terbaru (urut kronologis); sisanya lewat "muat lebih banyak".
    final tampil = disaring.length <= _tampil
        ? disaring
        : disaring.sublist(disaring.length - _tampil);
    final online = s.aktifOrderIds.contains(widget.order.id);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => WargaProfileScreen(order: widget.order))),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primarySoft,
                    child: Text(
                      widget.order.customerName.isEmpty
                          ? 'W'
                          : widget.order.customerName[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (online)
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.order.customerName.isEmpty ? 'Warga' : widget.order.customerName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  StreamBuilder<bool>(
                    stream: s.repo.mengetik(widget.order.id),
                    builder: (_, snap) => Text(
                      snap.data == true
                          ? 'sedang menulis...'
                          : (online
                              ? 'Online'
                              : 'Terakhir dilihat ${waktuRelatif(s.pesanTerakhir(widget.order.id)?.waktu)}'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.order.customerPhone.isNotEmpty)
            IconButton(
              tooltip: 'Telepon',
              onPressed: () => launchUrl(Uri.parse('tel:${widget.order.customerPhone}')),
              icon: const Icon(Icons.call_rounded),
            ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'order') {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => OrderDetailScreen(order: widget.order)));
              } else if (v == 'peta') {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => PetaScreen(order: widget.order)));
              } else if (v == 'profil') {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => WargaProfileScreen(order: widget.order)));
              } else if (v == 'arsip') {
                s.arsipkan(widget.order.id);
                Navigator.pop(context);
              } else if (v == 'blokir') {
                s.blokirWarga(widget.order, !s.terblokir(widget.order));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(s.terblokir(widget.order)
                        ? 'Warga diblokir. Pesannya tidak muncul lagi di daftar.'
                        : 'Blokir dibuka.',
                        style: const TextStyle(fontSize: 15))));
              } else if (v == 'laporkan') {
                Navigator.pop(context);
                _laporkan(context, s, Pesan(
                  id: '-',
                  orderId: widget.order.id,
                  isi: widget.order.customerName,
                  waktu: DateTime.now(),
                  mine: false,
                ));
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'order', child: Text('Lihat order')),
              const PopupMenuItem(value: 'peta', child: Text('Lihat peta')),
              const PopupMenuItem(value: 'profil', child: Text('Profil warga')),
              const PopupMenuItem(value: 'arsip', child: Text('Arsipkan chat')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'laporkan', child: Text('Laporkan warga')),
              PopupMenuItem(
                value: 'blokir',
                child: Text(s.terblokir(widget.order)
                    ? 'Buka blokir warga'
                    : 'Blokir warga'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _BannerOrder(
            order: widget.order,
            buka: _bannerBuka,
            onUbah: () => setState(() => _bannerBuka = !_bannerBuka),
            onLihatOrder: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => OrderDetailScreen(order: widget.order))),
          ),
          _CariPesan(
            onUbah: (v) => setState(() => _cari = v),
            onTutup: () => setState(() => _cari = ''),
          ),
          Expanded(
            child: pesan.isEmpty
                ? Center(
                    child: Text(
                      _cari.isEmpty
                          ? 'Belum ada pesan.\nMulai sapa warga, biar order lancar.'
                          : 'Tidak ada pesan yang cocok.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : StreamBuilder<bool>(
                    stream: s.repo.mengetik(widget.order.id),
                    builder: (_, snap) {
                      final adaTyping = snap.data == true;
                      final baris = <Object>[];
                      String? hari;
                      for (final p in tampil) {
                        final h = kelompokTanggal(p.waktu);
                        if (h != hari) {
                          hari = h;
                          baris.add('PEMBATAS:$h');
                        }
                        baris.add(p);
                      }
                      final adaLagi = pesan.length > _tampil;
                      final geser = adaLagi ? 1 : 0;
                      return ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(12),
                        itemCount: baris.length + (adaTyping ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (adaLagi && i == 0) {
                            return Center(
                              child: TextButton.icon(
                                onPressed: () => setState(() => _tampil += 30),
                                icon: const Icon(Icons.expand_less_rounded, size: 18),
                                label: Text(
                                    'Muat ${(pesan.length - _tampil).clamp(0, 999)} pesan lama'),
                              ),
                            );
                          }
                          final idx = i - geser;
                          if (idx < 0) return const SizedBox.shrink();
                          if (idx >= baris.length) return const _Mengetik();
                          final item = baris[idx];
                          if (item is String) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Center(
                                child: Text(
                                  item.substring(9),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black45,
                                  ),
                                ),
                              ),
                            );
                          }
                          final pesanIni = item as Pesan;
                          return _Gelembung(
                            pesan: pesanIni,
                            nama: widget.order.customerName,
                            showAvatar: !pesanIni.mine,
                            onBalas: (x) => setState(() => _balas = x),
                            onTeruskan: (x) => setState(() {
                              _input.text = x.isi;
                              _balas = x;
                            }),
                            onLaporkan: () => _laporkan(context, s, pesanIni),
                            onHapus: (x) => s.hapusPesan(widget.order.id, x.id),
                          );
                        },
                      );
                    },
                  ),
          ),
          _TemplateCepat(
            onPilih: (t) => setState(() => _input.text = t),
          ),
          _AreaInput(
            controller: _input,
            balas: _balas,
            onBatalBalas: () => setState(() => _balas = null),
            onKirim: _kirim,
            onLampiran: () async {
              HapticFeedback.selectionClick();
              await showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (c) => SafeArea(
                  child: Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.photo_camera_outlined),
                        title: const Text('Kirim foto'),
                        onTap: () {
                          Navigator.pop(c);
                          _kirimFoto(s);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.my_location_rounded),
                        title: const Text('Kirim lokasi saya'),
                        onTap: () {
                          Navigator.pop(c);
                          _kirimLokasi(s);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.map_outlined),
                        title: const Text('Lihat peta rute'),
                        onTap: () {
                          Navigator.pop(c);
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => PetaScreen(order: widget.order)));
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BannerOrder extends StatelessWidget {
  const _BannerOrder({
    required this.order,
    required this.buka,
    required this.onUbah,
    required this.onLihatOrder,
  });

  final Order order;
  final bool buka;
  final VoidCallback onUbah;
  final VoidCallback onLihatOrder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Kaca(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  order.type == 'jastip'
                      ? Icons.shopping_bag_rounded
                      : Icons.two_wheeler_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Order ${order.typeLabel} - ${order.statusLabel}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                      if (buka)
                        Text(order.dropAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                if (buka) Text(rp(order.fee),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: buka ? 'Sembunyikan' : 'Tampilkan',
                  onPressed: onUbah,
                  icon: Icon(buka
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded),
                ),
              ],
            ),
            if (buka) ...[
              const SizedBox(height: 6),
              OutlinedButton(
                onPressed: onLihatOrder,
                child: const Text('LIHAT ORDER'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CariPesan extends StatefulWidget {
  const _CariPesan({required this.onUbah, required this.onTutup});
  final ValueChanged<String> onUbah;
  final VoidCallback onTutup;

  @override
  State<_CariPesan> createState() => _CariPesanState();
}

class _CariPesanState extends State<_CariPesan> {
  bool _buka = false;
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_buka) {
      return Align(
        alignment: Alignment.centerRight,
        child: IconButton(
          tooltip: 'Cari pesan',
          onPressed: () => setState(() => _buka = true),
          icon: const Icon(Icons.search_rounded),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: TextField(
        controller: _c,
        autofocus: true,
        onChanged: widget.onUbah,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Cari isi pesan...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              _c.clear();
              widget.onUbah('');
              widget.onTutup();
              setState(() => _buka = false);
            },
          ),
        ),
      ),
    );
  }
}

class _Gelembung extends StatelessWidget {
  const _Gelembung({
    required this.pesan,
    required this.nama,
    required this.onBalas,
    required this.onHapus,
    required this.showAvatar,
    required this.onTeruskan,
    required this.onLaporkan,
  });

  final Pesan pesan;
  final String nama;
  final bool showAvatar;
  final ValueChanged<Pesan> onBalas;
  final ValueChanged<Pesan> onTeruskan;
  final VoidCallback onLaporkan;
  final ValueChanged<Pesan> onHapus;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final warna = pesan.mine ? AppColors.primary : cs.surfaceContainerHighest;

    Widget isi = Column(
      crossAxisAlignment:
          pesan.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (pesan.balasRingkas != null)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(pesan.balasRingkas!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12)),
          ),
        if (pesan.jenis == JenisPesan.lokasi)
          _KartuLokasi(pesan: pesan)
        else if (pesan.jenis == JenisPesan.foto)
          _KartuFoto(pesan: pesan)
        else
          Text(pesan.isi, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${pesan.waktu.hour.toString().padLeft(2, '0')}:'
                '${pesan.waktu.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 10)),
            if (pesan.mine) ...[
              const SizedBox(width: 4),
              Icon(
                pesan.dibaca ? Icons.done_all_rounded : Icons.done_rounded,
                size: 13,
                color: pesan.dibaca ? Colors.blue : Colors.grey,
              ),
            ],
          ],
        ),
      ],
    );

    return Row(
      mainAxisAlignment:
          pesan.mine ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (showAvatar)
          Padding(
            padding: const EdgeInsets.only(right: 6, bottom: 2),
            child: CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.primarySoft,
              child: Text(nama.isEmpty ? 'W' : nama[0].toUpperCase(),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          ),
        Flexible(
          child: GestureDetector(
        onLongPress: () => _menu(context),
        child: Container(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: warna,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(pesan.mine ? 16 : 4),
              bottomRight: Radius.circular(pesan.mine ? 4 : 16),
            ),
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: pesan.mine ? Colors.white : null),
            child: isi,
          ),
        ),
        ),
        ),
      ],
    );
  }

  void _menu(BuildContext c) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: c,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply_rounded),
              title: const Text('Balas pesan ini'),
              onTap: () {
                Navigator.pop(c);
                onBalas(pesan);
              },
            ),
            ListTile(
              leading: const Icon(Icons.forward_rounded),
              title: const Text('Teruskan ke input'),
              onTap: () {
                Navigator.pop(c);
                onTeruskan(pesan);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_problem_outlined),
              title: const Text('Laporkan warga ini'),
              onTap: () {
                Navigator.pop(c);
                onLaporkan();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Salin teks'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: pesan.isi));
                Navigator.pop(c);
              },
            ),
            if (pesan.mine)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('Hapus dari perangkat', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(c);
                  onHapus(pesan);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _KartuLokasi extends StatelessWidget {
  const _KartuLokasi({required this.pesan});
  final Pesan pesan;

  @override
  Widget build(BuildContext context) {
    final lat = pesan.lat, lng = pesan.lng;
    if (lat == null || lng == null) return const Text('Lokasi dikirim');
    final url = 'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=16/$lat/$lng';
    return SizedBox(
      width: 210,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.place_rounded, size: 18),
              SizedBox(width: 6),
              Text('Lokasi saya', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text('${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
              style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          OutlinedButton(
            onPressed: () => launchUrl(Uri.parse(url),
                mode: LaunchMode.externalApplication),
            child: const Text('Lihat peta'),
          ),
        ],
      ),
    );
  }
}

class _KartuFoto extends StatelessWidget {
  const _KartuFoto({required this.pesan});
  final Pesan pesan;

  @override
  Widget build(BuildContext context) {
    final path = pesan.attachmentUrl;
    if (path == null) return const Text('Foto terkirim');
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(
        File(path),
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 200,
          height: 120,
          alignment: Alignment.center,
          color: Colors.black12,
          child: const Text('Foto tidak ditemukan', style: TextStyle(fontSize: 12)),
        ),
      ),
    );
  }
}

class _Mengetik extends StatelessWidget {
  const _Mengetik();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Warga sedang menulis...', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
}

class _TemplateCepat extends StatelessWidget {
  const _TemplateCepat({required this.onPilih});
  final ValueChanged<String> onPilih;

  @override
  Widget build(BuildContext context) {
    final daftar = daftarTemplateCepat;
    if (daftar.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final k in daftar)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(k),
                onPressed: () => onPilih(templateCepat[k] ?? k),
              ),
            ),
        ],
      ),
    );
  }
}

class _AreaInput extends StatelessWidget {
  const _AreaInput({
    required this.controller,
    required this.balas,
    required this.onBatalBalas,
    required this.onKirim,
    required this.onLampiran,
  });

  final TextEditingController controller;
  final Pesan? balas;
  final VoidCallback onBatalBalas;
  final VoidCallback onKirim;
  final VoidCallback onLampiran;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (balas != null)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.reply_rounded, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Balas: ${balas!.isi}',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: onBatalBalas,
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(onPressed: onLampiran, icon: const Icon(Icons.add_circle_outline_rounded)),
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onKirim(),
                    decoration: const InputDecoration(
                      hintText: 'Tulis pesan...',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  onPressed: onKirim,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
/// Dialog isi alasan laporan warga.
class _DialogLaporan extends StatefulWidget {
  const _DialogLaporan({required this.pesan});
  final Pesan pesan;

  @override
  State<_DialogLaporan> createState() => _DialogLaporanState();
}

class _DialogLaporanState extends State<_DialogLaporan> {
  final _teks = TextEditingController();

  @override
  void dispose() {
    _teks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Laporkan warga'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Pesan: ${widget.pesan.isi}',
              maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          TextField(
            controller: _teks,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Alasan laporan',
              hintText: 'Contoh: alamat tidak sesuai, jawaban tidak gracious',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, _teks.text.trim()),
          child: const Text('KIRIM LAPORAN'),
        ),
      ],
    );
  }
}
