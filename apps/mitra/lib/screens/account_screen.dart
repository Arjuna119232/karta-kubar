import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import 'edit_profil_screen.dart';
import 'jenis_layanan_screen.dart';
import 'izin_screen.dart';
import 'kotak_masuk_screen.dart';
import 'review_screen.dart';
import 'settings_screens.dart';
import 'tentang_screen.dart';
import 'widgets.dart';

/// Profil mitra: identitas, pencapaian, lencana, ulasan, dan semua menu.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key, this.dapatTombolKembali = false});
  final bool dapatTombolKembali;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    void go(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    final awal = s.name.trim().isEmpty ? 'Mitra' : s.name.trim();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: dapatTombolKembali,
        title: const Text('Profil'),
        actions: [
          IconButton(
            tooltip: 'Pengaturan',
            onPressed: () => go(const SettingsScreen()),
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            tooltip: 'Tentang aplikasi',
            onPressed: () => go(const TentangScreen()),
            icon: const Icon(Icons.help_outline_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          _HeaderProfil(
            nama: awal,
            id: s.idMitra,
            rating: s.avgRating,
            order: s.totalOrder,
            terverifikasi: s.terverifikasi,
            level: s.level,
            onEdit: () => go(const EditProfilScreen()),
          ),
          _StatTiga(
            order: s.totalOrder,
            rating: s.avgRating,
            poin: s.poin,
          ),
          _Pencapaian(s: s),
          _LencanaStrip(s: s),
          _ApaKataWarga(s: s, onSemua: () => go(const ReviewScreen())),
          _Kelompok('AKUN', [
            _Menu(
              ikon: Icons.edit_outlined,
              judul: 'Edit Profil',
              onTekan: () => go(const EditProfilScreen()),
            ),
            _Menu(
              ikon: Icons.verified_user_outlined,
              judul: 'Verifikasi Mitra',
              sub: s.terverifikasi ? 'Sudah terverifikasi' : 'Belum diverifikasi',
              onTekan: () => go(const VerifikasiScreen()),
            ),
            _Menu(
              ikon: Icons.lock_outline_rounded,
              judul: 'Izin Aplikasi',
              sub: 'Kamera, lokasi, notifikasi',
              onTekan: () => go(const IzinScreen(saatMasuk: false)),
            ),
          ]),
          _Kelompok('PEKERJAAN', [
            _Menu(
              ikon: Icons.local_shipping_outlined,
              judul: 'Jenis Layanan',
              sub: _ringkasanLayanan(s),
              onTekan: () => go(const JenisLayananScreen()),
            ),
            _Menu(
              ikon: Icons.radar_rounded,
              judul: 'Radius & Jam Order',
              sub: '${s.radiusKm.toStringAsFixed(0)} km - ${s.openHour}:00 s/d ${s.closeHour}:00',
              onTekan: () => go(const SettingsScreen()),
            ),
            _Menu(
              ikon: Icons.two_wheeler_rounded,
              judul: 'Kendaraan',
              sub: '${s.vehicleType} ${s.plate}'.trim(),
              onTekan: () => go(const VehicleScreen()),
            ),
            _Menu(
              ikon: Icons.shield_outlined,
              judul: 'Pengaturan Keselamatan',
              sub: 'Kontak darurat ${s.kontakDarurat.isEmpty ? 'belum diisi' : s.kontakDarurat}',
              onTekan: () => go(const SettingsScreen()),
            ),
          ]),
          _Kelompok('APLIKASI', [
            _Menu(
              ikon: Icons.palette_outlined,
              judul: 'Tema Tampilan',
              sub: switch (s.themeMode) {
                ThemeMode.light => 'Terang',
                ThemeMode.dark => 'Gelap',
                ThemeMode.system => 'Otomatis',
              },
              onTekan: () => go(const SettingsScreen()),
            ),
            _Menu(
              ikon: Icons.accessibility_new_rounded,
              judul: 'Mode Lansia',
              sub: 'Teks lebih besar',
              saklar: s.modeLansia,
              onTekan: () => s.setToggle('lansia', !s.modeLansia),
            ),
            _Menu(
              ikon: Icons.vibration_rounded,
              judul: 'Getar Saat Disentuh',
              saklar: s.getarSentuh,
              onTekan: () => s.setToggle('getarSentuh', !s.getarSentuh),
            ),
            _Menu(
              ikon: Icons.notifications_active_outlined,
              judul: 'Getar Order Masuk',
              saklar: s.getarOrder,
              onTekan: () => s.setToggle('getarOrder', !s.getarOrder),
            ),
            _Menu(
              ikon: Icons.volume_up_outlined,
              judul: 'Suara Notifikasi',
              saklar: s.suaraNotifikasi,
              onTekan: () => s.setToggle('suara', !s.suaraNotifikasi),
            ),
            _Menu(
              ikon: Icons.inbox_rounded,
              judul: 'Kotak Masuk',
              sub: 'Pengumuman dan bonus admin',
              onTekan: () => go(const KotakMasukScreen()),
            ),
          ]),
          _Kelompok('BANTUAN', [
            _Menu(
              ikon: Icons.help_center_outlined,
              judul: 'FAQ',
              onTekan: () => go(const FaqScreen()),
            ),
            _Menu(
              ikon: Icons.chat_outlined,
              judul: 'Hubungi Admin',
              sub: 'via WhatsApp',
              onTekan: () => _hubungiAdmin(context, s),
            ),
            _Menu(
              ikon: Icons.info_outline_rounded,
              judul: 'Tentang Aplikasi',
              sub: 'KUNBAR Mitra',
              onTekan: () => go(const TentangScreen()),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: () => _keluar(context, s),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('KELUAR'),
            ),
          ),
        ],
      ),
    );
  }

  String _ringkasanLayanan(AppState s) {
    final aktif = <String>[
      if (s.jenisJastip) 'Jastip',
      if (s.jenisOjek) 'Ojek',
      if (s.jenisKurir) 'Kurir',
    ];
    return aktif.isEmpty ? 'Tidak ada layanan aktif' : aktif.join(' - ');
  }

  Future<void> _keluar(BuildContext context, AppState s) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
            'Kamu akan berhenti menerima order. Order yang sedang berjalan '
            'tetap bisa diselesaikan setelah masuk lagi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(d, true),
            child: const Text('KELUAR'),
          ),
        ],
      ),
    );
    if (ya == true) await s.logout();
  }

  Future<void> _hubungiAdmin(BuildContext c, AppState s) async {
    // Nomor admin disimpan di Pengaturan; kalau kosong, beri tahu langsung.
    final nomor = s.kontakDarurat;
    if (nomor.isEmpty) {
      HapticFeedback.selectionClick();
      if (!c.mounted) return;
      toast(c, 'Nomor admin belum diisi. Isi di Pengaturan > Kontak darurat.');
      return;
    }
    await launchUrl(Uri.parse('https://wa.me/$nomor'));
  }
}

class _HeaderProfil extends StatelessWidget {
  const _HeaderProfil({
    required this.nama,
    required this.id,
    required this.rating,
    required this.order,
    required this.terverifikasi,
    required this.level,
    required this.onEdit,
  });

  final String nama;
  final String id;
  final double rating;
  final int order;
  final bool terverifikasi;
  final String level;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), blurRadius: 14, offset: Offset(0, 6)),
              ],
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Text(nama[0].toUpperCase(),
                  style: const TextStyle(
                      fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ),
          ),
          const SizedBox(height: 12),
          Text(nama,
              style: const TextStyle(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(id, style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: AppColors.secondary, size: 20),
              Text(
                rating <= 0 ? 'Belum ada rating' : '${rating.toStringAsFixed(1)} - $order order',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(level,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
              ),
              if (terverifikasi) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
              ],
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
            ),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('EDIT PROFIL'),
          ),
        ],
      ),
    );
  }
}

class _StatTiga extends StatelessWidget {
  const _StatTiga({required this.order, required this.rating, required this.poin});
  final int order;
  final double rating;
  final int poin;

  @override
  Widget build(BuildContext context) {
    Widget isi(IconData ikon, String nilai, String label) => Expanded(
          child: Column(
            children: [
              Icon(ikon, color: AppColors.primary, size: 22),
              const SizedBox(height: 4),
              Text(nilai, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              Text(label, style: const TextStyle(fontSize: 11)),
            ],
          ),
        );

    return Transform.translate(
      offset: const Offset(0, -18),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              isi(Icons.check_circle_rounded, '$order', 'Order selesai'),
              isi(Icons.star_rounded,
                  rating <= 0 ? '-' : rating.toStringAsFixed(1), 'Rating'),
              isi(Icons.bolt_rounded, '$poin', 'Poin'),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pencapaian extends StatelessWidget {
  const _Pencapaian({required this.s});
  final AppState s;

  @override
  Widget build(BuildContext context) {
    Widget bar(String label, int nilai, int target, Color warna) {
      final persen = target == 0 ? 0.0 : (nilai / target).clamp(0, 1).toDouble();
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
                Text('${rp(nilai)} / ${rp(target)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: persen,
                minHeight: 10,
                backgroundColor: warna.withValues(alpha: 0.14),
                color: warna,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pencapaian',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              bar('Target hari ini', s.todayEarnings, AppState.targetHarian,
                  AppColors.primary),
              bar('Target minggu ini', s.earned(s.weekStart),
                  AppState.targetHarian * 6, const Color(0xFF1565C0)),
              Text(
                'Tingkat ${s.level} - ${s.totalOrder} dari ${s.ambangLevelBerikutnya} '
                'order menuju tingkat berikutnya.',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LencanaStrip extends StatelessWidget {
  const _LencanaStrip({required this.s});
  final AppState s;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text('Lencana',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        ),
        SizedBox(
          height: 116,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final l in s.lencana)
                Container(
                  width: 96,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: l.terbuka ? AppColors.primary : Colors.grey.shade300,
                      width: l.terbuka ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(l.ikon,
                          size: 30,
                          color: l.terbuka ? AppColors.primary : Colors.grey.shade400),
                      const SizedBox(height: 6),
                      Text(l.judul,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(l.terbuka ? '${l.jumlah}' : l.syaratTerbuka,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 9,
                              color: l.terbuka ? Colors.green : Colors.grey)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _ApaKataWarga extends StatelessWidget {
  const _ApaKataWarga({required this.s, required this.onSemua});
  final AppState s;
  final VoidCallback onSemua;

  @override
  Widget build(BuildContext context) {
    if (s.ratings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.reviews_outlined, color: Colors.grey.shade400),
                const SizedBox(width: 12),
                const Expanded(child: Text('Belum ada ulasan warga.')),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Apa Kata Warga',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                  TextButton(onPressed: onSemua, child: const Text('Lihat semua')),
                ],
              ),
              for (final r in s.ratings.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primarySoft,
                        child: const Icon(Icons.person, size: 18, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                for (var i = 0; i < 5; i++)
                                  Icon(i < r.stars ? Icons.star_rounded : Icons.star_outline_rounded,
                                      size: 14, color: Colors.amber),
                                const Spacer(),
                                Text(jam(r.createdAt), style: const TextStyle(fontSize: 10)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(r.comment),
                          ],
                        ),
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

class _Kelompok extends StatelessWidget {
  const _Kelompok(this.judul, this.menu);
  final String judul;
  final List<Widget> menu;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 6),
            child: Text(judul,
                style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade600)),
          ),
          ...menu,
        ],
      );
}

class _Menu extends StatelessWidget {
  const _Menu({
    required this.ikon,
    required this.judul,
    required this.onTekan,
    this.sub,
    this.saklar,
  });

  final IconData ikon;
  final String judul;
  final String? sub;
  final bool? saklar;
  final VoidCallback onTekan;

  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        leading: Icon(ikon, color: AppColors.primary),
        title: Text(judul),
        subtitle: sub == null ? null : Text(sub!, style: const TextStyle(fontSize: 12)),
        trailing: saklar != null
            ? Switch(value: saklar!, onChanged: (v) => onTekan())
            : const Icon(Icons.chevron_right_rounded),
        onTap: saklar != null ? null : onTekan,
      );
}