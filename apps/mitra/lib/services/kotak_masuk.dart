import 'dart:convert';

import 'package:flutter/material.dart';


enum KategoriNotif { pengumuman, bonus, tips, event, peringatan, update }

extension KategoriNotifX on KategoriNotif {
  String get label => switch (this) {
        KategoriNotif.pengumuman => 'Pengumuman',
        KategoriNotif.bonus => 'Bonus',
        KategoriNotif.tips => 'Tips',
        KategoriNotif.event => 'Event',
        KategoriNotif.peringatan => 'Peringatan',
        KategoriNotif.update => 'Update',
      };

  Color get warna => switch (this) {
        KategoriNotif.pengumuman => const Color(0xFF3B82F6),
        KategoriNotif.bonus => const Color(0xFFFFC107),
        KategoriNotif.tips => const Color(0xFF22C55E),
        KategoriNotif.event => const Color(0xFFE91E63),
        KategoriNotif.peringatan => const Color(0xFFEF4444),
        KategoriNotif.update => const Color(0xFF6B7280),
      };

  IconData get ikon => switch (this) {
        KategoriNotif.pengumuman => Icons.campaign_rounded,
        KategoriNotif.bonus => Icons.payments_rounded,
        KategoriNotif.tips => Icons.lightbulb_rounded,
        KategoriNotif.event => Icons.celebration_rounded,
        KategoriNotif.peringatan => Icons.warning_amber_rounded,
        KategoriNotif.update => Icons.system_update_rounded,
      };

  static KategoriNotif dari(String? v) => KategoriNotif.values.firstWhere(
        (k) => k.name == v,
        orElse: () => KategoriNotif.pengumuman,
      );
}

enum PrioritasNotif { normal, penting, urgent }

extension PrioritasNotifX on PrioritasNotif {
  String get label => switch (this) {
        PrioritasNotif.normal => 'Normal',
        PrioritasNotif.penting => 'Penting',
        PrioritasNotif.urgent => 'Mendesak',
      };

  static PrioritasNotif dari(String? v) => PrioritasNotif.values.firstWhere(
        (p) => p.name == v,
        orElse: () => PrioritasNotif.normal,
      );
}

class NotifikasiMk {
  NotifikasiMk({
    required this.id,
    required this.kategori,
    required this.prioritas,
    required this.judul,
    required this.isi,
    required this.waktu,
    this.ctaLabel,
    this.ctaUrl,
    this.lampiranUrl,
    this.dibaca = false,
    this.diarsipkan = false,
  });

  final String id;
  final KategoriNotif kategori;
  final PrioritasNotif prioritas;
  final String judul;
  final String isi;
  final DateTime waktu;
  final String? ctaLabel;
  final String? ctaUrl;
  final String? lampiranUrl;
  final bool dibaca;
  final bool diarsipkan;
}

extension NotifikasiMkX on NotifikasiMk {
  Map<String, dynamic> toMap() => {
        'id': id,
        'kategori': kategori.name,
        'prioritas': prioritas.name,
        'judul': judul,
        'isi': isi,
        'cta_label': ctaLabel,
        'cta_url': ctaUrl,
        'lampiran_url': lampiranUrl,
        'dibaca': dibaca,
        'diarsipkan': diarsipkan,
        'created_at': waktu.toIso8601String(),
      };

  NotifikasiMk copyWith({bool? dibaca, bool? diarsipkan}) => NotifikasiMk(
        id: id,
        kategori: kategori,
        prioritas: prioritas,
        judul: judul,
        isi: isi,
        waktu: waktu,
        ctaLabel: ctaLabel,
        ctaUrl: ctaUrl,
        lampiranUrl: lampiranUrl,
        dibaca: dibaca ?? this.dibaca,
        diarsipkan: diarsipkan ?? this.diarsipkan,
      );
}

enum FilterKotak { semua, penting, belumDibaca }

extension FilterKotakX on FilterKotak {
  String get label => switch (this) {
        FilterKotak.semua => 'Semua',
        FilterKotak.penting => 'Penting',
        FilterKotak.belumDibaca => 'Belum dibaca',
      };
}

/// Sumber notifikasi. Mode demo: contoh lokal yang jujur ditandai "contoh".
/// Mode Supabase: broadcast dari admin (mitra_id NULL) + pribadi.
class NotifikasiService {
  NotifikasiService._();
  static final NotifikasiService instance = NotifikasiService._();

  static const _kunci = 'kotak_masuk_v1';

  List<NotifikasiMk> _demo = [];
  bool _siap = false;

  Future<void> init(SharedPrefHolder holder) async {
    if (_siap) return;
    _siap = true;
    final raw = holder.baca(_kunci);
    if (raw == null) {
      _demo = contoh(now: DateTime.now());
      holder.simpan(_kunci, jsonEncode(_demo.map((e) => e.toMap()).toList()));
    } else {
      try {
        _demo = (jsonDecode(raw) as List)
            .map((e) => _dariMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {
        _demo = contoh(now: DateTime.now());
      }
    }
  }

  NotifikasiMk _dariMap(Map<String, dynamic> m) => NotifikasiMk(
        id: '${m['id']}',
        kategori: KategoriNotifX.dari(m['kategori'] as String?),
        prioritas: PrioritasNotifX.dari(m['prioritas'] as String?),
        judul: (m['judul'] ?? '') as String,
        isi: (m['isi'] ?? '') as String,
        ctaLabel: m['cta_label'] as String?,
        ctaUrl: m['cta_url'] as String?,
        lampiranUrl: m['lampiran_url'] as String?,
        dibaca: (m['dibaca'] as bool?) ?? false,
        diarsipkan: (m['diarsipkan'] as bool?) ?? false,
        waktu: DateTime.tryParse('${m['created_at']}') ?? DateTime.now(),
      );

  List<NotifikasiMk> semua() => List.of(_demo);

  int belumDibaca() => _demo.where((n) => !n.dibaca && !n.diarsipkan).length;

  void tandaiDibaca(String id) => _ubah(id, (n) => n.copyWith(dibaca: true));
  void tandaiBelumDibaca(String id) => _ubah(id, (n) => n.copyWith(dibaca: false));
  void arsipkan(String id) => _ubah(id, (n) => n.copyWith(diarsipkan: true));
  void semuaDibaca() {
    _demo = _demo.map((n) => n.copyWith(dibaca: true)).toList();
  }

  void _ubah(String id, NotifikasiMk Function(NotifikasiMk) f) {
    _demo = _demo.map((n) => n.id == id ? f(n) : n).toList();
  }

  /// Seed contoh supaya layarnya tidak kosong saat mode demo.
  static List<NotifikasiMk> contoh({required DateTime now}) => [
        NotifikasiMk(
          id: 'n1',
          kategori: KategoriNotif.peringatan,
          prioritas: PrioritasNotif.urgent,
          judul: 'Tarif jastip naik mulai minggu depan',
          isi: 'Dari tanggal 20 Oktober, tarif jastip bertambah Rp 1.000 per '
              'kilometer. Tarif ojek tidak berubah. Cek lagi sebelum menerima '
              'order besar.',
          waktu: now.subtract(const Duration(hours: 2)),
        ),
        NotifikasiMk(
          id: 'n2',
          kategori: KategoriNotif.bonus,
          prioritas: PrioritasNotif.penting,
          judul: 'Bonus order jastip Rp 50.000',
          isi: 'Selesaikan 10 order jastip minggu ini dan dapat bonus tambahan '
              'Rp 50.000. Berlaku sampai akhir bulan.',
          waktu: now.subtract(const Duration(hours: 6)),
          ctaLabel: 'Lihat target',
          ctaUrl: 'https://kuninganbarat.id',
        ),
        NotifikasiMk(
          id: 'n3',
          kategori: KategoriNotif.tips,
          prioritas: PrioritasNotif.normal,
          judul: 'Tips biar rating tetap tinggi',
          isi: 'Chat warga sebelum berangkat, konfirmasi alamat lengkap, dan '
              'kirim foto barang saat diterima. Mitra dengan rating di atas 4,8 '
              'dapat order lebih sering.',
          waktu: now.subtract(const Duration(days: 1, hours: 3)),
        ),
        NotifikasiMk(
          id: 'n4',
          kategori: KategoriNotif.event,
          prioritas: PrioritasNotif.normal,
          judul: 'Gathering mitra Gratis KUNBAR',
          isi: 'Ajak semua mitra hadir Minggu, 09:00, diRQ05. Ada sarapan, '
              'diskusi, dan kejutan kecil. Daftar hadir lewat pengurusRQ05.',
          waktu: now.subtract(const Duration(days: 2)),
        ),
        NotifikasiMk(
          id: 'n5',
          kategori: KategoriNotif.pengumuman,
          prioritas: PrioritasNotif.normal,
          judul: 'Jadwal piket warga diperbarui',
          isi: 'Jadwal piket bulan ini sudah keluar di halaman warga. Mitra yang '
              'mendampingi warga bisa melihat jadwalnya langsung di aplikasi warga.',
          waktu: now.subtract(const Duration(days: 3)),
        ),
        NotifikasiMk(
          id: 'n6',
          kategori: KategoriNotif.update,
          prioritas: PrioritasNotif.normal,
          judul: 'Pembaruan aplikasi 1.8',
          isi: 'Peta di dalam aplikasi sekarang lebih ringan, dan halaman chat '
              'bisa kirim foto. Perbarui lewat Play Store atau tautan yang '
              'diberikan pengurus.',
          waktu: now.subtract(const Duration(days: 5)),
        ),
      ];
}

/// Pembungkus prefs supaya service tidak perlu tahu detail penyimpanan.
class SharedPrefHolder {
  SharedPrefHolder({required this.baca, required this.simpan});

  final String? Function(String kunci) baca;
  final void Function(String kunci, String nilai) simpan;

  static SharedPrefHolder dariPref(dynamic prefs) => SharedPrefHolder(
        baca: (k) => prefs.getString(k) as String?,
        simpan: (k, v) => prefs.setString(k, v),
      );
}

/// Helper waktu relatif: "baru saja", "5 menit", "Kemarin", tanggal.
String waktuRelatif(DateTime? w) {
  if (w == null) return '';
  final d = w.toLocal();
  final now = DateTime.now();
  final selisih = now.difference(d);
  if (selisih.inMinutes < 1) return 'baru saja';
  if (selisih.inMinutes < 60) return '${selisih.inMinutes} menit';
  if (selisih.inHours < 24 &&
      d.day == now.day &&
      d.month == now.month) {
    return '${selisih.inHours} jam';
  }
  final kemarin = DateTime(now.year, now.month, now.day)
      .subtract(const Duration(days: 1));
  if (d.year == kemarin.year && d.month == kemarin.month && d.day == kemarin.day) {
    return 'Kemarin';
  }
  return '${d.day}/${d.month}';
}

/// Kelompok tanggal untuk daftar notifikasi.
String kelompokTanggal(DateTime w) {
  final d = w.toLocal();
  final now = DateTime.now();
  final hariIni = DateTime(now.year, now.month, now.day);
  final geser = DateTime(d.year, d.month, d.day).difference(hariIni).inDays;
  if (geser == 0) return 'HARI INI';
  if (geser == -1) return 'KEMARIN';
  if (geser > -7) return 'MINGGU INI';
  return 'LEBIH LAMA';
}