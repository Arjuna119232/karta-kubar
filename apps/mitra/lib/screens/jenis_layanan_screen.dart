import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../services/layanan.dart';
import '../state/app_state.dart';
import '../widgets/kit.dart';
import 'detail_layanan_screen.dart';

/// Halaman Jenis Layanan: hanya 3 layanan inti, grouped per status.
class JenisLayananScreen extends StatefulWidget {
  const JenisLayananScreen({super.key});
  @override
  State<JenisLayananScreen> createState() => _JenisLayananScreenState();
}

class _JenisLayananScreenState extends State<JenisLayananScreen> {
  bool _banner = true;
  bool _adaPerubahan = false;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final semua = s.daftarPengaturanLayanan;
    final aktif = semua.where((e) => e.aktif).toList();
    final nonaktif = semua.where((e) => !e.aktif).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jenis Layanan'),
        actions: [
          IconButton(
            tooltip: 'Bantuan',
            onPressed: () => _bantuan(context),
            icon: const Icon(Icons.help_outline_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                if (_banner) _Banner(dismiss: () => setState(() => _banner = false)),
                if (aktif.isNotEmpty) ...[
                  _Header('AKTIF', '${aktif.length} layanan'),
                  for (final p in aktif) ...[
                    _Kartu(
                      p: p,
                      aktif: true,
                      onToggle: () => _konfirmasiNonaktif(context, s, p),
                      onDetail: () => _detail(context, p),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
                if (nonaktif.isNotEmpty) ...[
                  _Header('TERSEDIA', '${nonaktif.length} layanan belum aktif'),
                  for (final p in nonaktif) ...[
                    _Kartu(
                      p: p,
                      aktif: false,
                      onToggle: () => _konfirmasiAktif(context, s, p),
                      onDetail: () => _detail(context, p),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
                const SizedBox(height: 10),
                const Text(
                  'Hanya ada tiga layanan di KUNBAR karena tiga itu yang benar-benar '
                  'dipakai warga. Tidak ada layanan yang tidak relevan.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          // tombol simpan menempel di bawah
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: Opacity(
                  opacity: _adaPerubahan ? 1 : 0.55,
                  child: TombolGradien(
                    judul: 'SIMPAN PENGATURAN',
                    subjudul: _adaPerubahan ? 'Ada perubahan belum disimpan' : 'Semua tersimpan',
                    gradien: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF43A047)]),
                    ikon: Icons.save_rounded,
                    onTekan: _adaPerubahan ? () => _simpan(context, s) : () {},
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _detail(BuildContext c, PengaturanLayanan p) async {
    await Navigator.push(c,
        MaterialPageRoute(builder: (_) => DetailLayananScreen(kode: p.kode)));
    if (mounted) setState(() => _adaPerubahan = true);
  }

  Future<void> _konfirmasiAktif(BuildContext c, AppState s, PengaturanLayanan p) async {
    HapticFeedback.mediumImpact();
    final ya = await showDialog<bool>(
      context: c,
      builder: (d) => _DialogLayanan(
        kode: p.kode,
        aktif: true,
        pengaturan: p,
      ),
    );
    if (ya != true || !mounted) return;
    setState(() => _adaPerubahan = true);
    HapticFeedback.mediumImpact();
    s.setAktifLayanan(p.kode, true);
  }

  Future<void> _konfirmasiNonaktif(
      BuildContext c, AppState s, PengaturanLayanan p) async {
    HapticFeedback.mediumImpact();
    final ya = await showDialog<bool>(
      context: c,
      builder: (d) => _DialogLayanan(
        kode: p.kode,
        aktif: false,
        pengaturan: p,
        adaOrderAktif: s.active?.type == p.kode.name,
      ),
    );
    if (ya != true || !mounted) return;
    setState(() => _adaPerubahan = true);
    HapticFeedback.mediumImpact();
    s.setAktifLayanan(p.kode, false);
  }

  Future<void> _simpan(BuildContext c, AppState s) async {
    HapticFeedback.mediumImpact();
    final ya = await showDialog<bool>(
      context: c,
      builder: (d) => AlertDialog(
        title: const Text('Simpan pengaturan?'),
        content: const Text(
            'Pengaturan layanan langsung berlaku. Order yang sedang berjalan tidak berubah.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('SIMPAN')),
        ],
      ),
    );
    if (ya != true || !mounted) return;
    setState(() => _adaPerubahan = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pengaturan layanan disimpan',
            style: TextStyle(fontSize: 16))));
  }

  void _bantuan(BuildContext c) => showModalBottomSheet<void>(
        context: c,
        showDragHandle: true,
        builder: (c) => const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kenapa cuma tiga layanan?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              SizedBox(height: 10),
              Text(
                'KUNBAR hanya melayani jastip, ojek komunitas, dan antar barang. '
                'Tidak ada layanan yang remeh dan tidak dipakai warga, jadi tidak '
                'menggantungkan mitra.\n\n'
                'Matikan layanan yang memang tidak kamu kerjakan supaya tidak ada '
                'order yang tidak bisa diterima.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      );
}

class _Banner extends StatelessWidget {
  const _Banner({required this.dismiss});
  final VoidCallback dismiss;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Kaca(
          radius: 16,
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Aktifkan layanan yang ingin kamu terima. Nonaktifkan yang tidak kamu sanggup.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              IconButton(
                tooltip: 'Tutup',
                onPressed: dismiss,
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
            ],
          ),
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header(this.judul, this.keterangan);
  final String judul;
  final String keterangan;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
        child: Row(
          children: [
            Text(judul,
                style: const TextStyle(
                    fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(keterangan, style: const TextStyle(fontSize: 11)),
            ),
          ],
        ),
      );
}

class _Kartu extends StatelessWidget {
  const _Kartu({
    required this.p,
    required this.aktif,
    required this.onToggle,
    required this.onDetail,
  });

  final PengaturanLayanan p;
  final bool aktif;
  final VoidCallback onToggle;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final k = p.kode;
    final warna = aktif ? k.warna : Colors.grey;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
          color: aktif ? k.warna : Colors.grey.withValues(alpha: 0.3),
          width: aktif ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onDetail,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: warna.withValues(alpha: 0.14),
                child: Icon(k.ikon, color: warna, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(k.nama,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    Text(k.deskripsi, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      '${p.radiusKm} km - ${p.jamMulai}:00 s/d ${p.jamSelesai}:00 - min ${rp(p.feeMinimum)}',
                      style: TextStyle(
                          fontSize: 12,
                          color: aktif ? Colors.green : Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Switch(value: aktif, onChanged: (_) => onToggle()),
              IconButton(
                tooltip: 'Pengaturan',
                onPressed: onDetail,
                icon: Icon(Icons.chevron_right_rounded,
                    color: aktif ? k.warna : Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog konfirmasi kustom (bukan AlertDialog polos): bulat 20dp + icon.
class _DialogLayanan extends StatelessWidget {
  const _DialogLayanan({
    required this.kode,
    required this.aktif,
    required this.pengaturan,
    this.adaOrderAktif = false,
  });

  final KodeLayanan kode;
  final bool aktif;
  final PengaturanLayanan pengaturan;
  final bool adaOrderAktif;

  @override
  Widget build(BuildContext context) {
    final warna = aktif ? kode.warna : Colors.red;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: warna.withValues(alpha: 0.15),
              child: Icon(aktif ? kode.ikon : Icons.warning_amber_rounded,
                  color: warna, size: 30),
            ),
            const SizedBox(height: 14),
            Text(
              aktif ? 'Aktifkan ${kode.nama}?' : 'Nonaktifkan ${kode.nama}?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              aktif
                  ? 'Kamu akan menerima order ${kode.namaPendek.toLowerCase()}. '
                      'Pastikan kamu siap dan online.'
                  : 'Kamu tidak akan menerima order ${kode.namaPendek.toLowerCase()} '
                      'lagi sampai diaktifkan kembali.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _baris('Tarif rata-rata', kode.tarif),
                  _baris('Radius', '${pengaturan.radiusKm} km'),
                  _baris('Jam', '${pengaturan.jamMulai}:00 - ${pengaturan.jamSelesai}:00'),
                ],
              ),
            ),
            if (!aktif && adaOrderAktif) ...[
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(Icons.info_rounded, size: 16, color: Colors.orange),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text('Ada order aktif. Selesaikan dulu sebelum mematikan layanan.',
                        style: TextStyle(fontSize: 12, color: Colors.orange)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('BATAL'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: warna),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(aktif ? 'AKTIFKAN' : 'NONAKTIFKAN'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _baris(String kunci, String nilai) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(child: Text(kunci, style: const TextStyle(fontSize: 13))),
            Text(nilai,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          ],
        ),
      );
}