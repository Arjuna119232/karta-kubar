import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_icon.dart';

/// Topik FISH (aspirasi, laporan, pengaduan warga).
///
/// Ini milik DOMAIN, bukan milik Supabase: nama enum ini yang dikirim ke
/// database lewat [toDb], dan yang dibaca balik lewat [fromDb]. Kalau nanti
/// nama kolom di server berubah, hanya dua fungsi ini yang perlu diubah.
enum KategoriAspirasi { jalan, keamanan, kebersihan, layanan,kegiatan, lain }

extension KategoriAspirasiX on KategoriAspirasi {
  String get label => switch (this) {
        KategoriAspirasi.jalan => 'Jalan & PJL',
        KategoriAspirasi.keamanan => 'Keamanan',
        KategoriAspirasi.kebersihan => 'Kebersihan',
        KategoriAspirasi.layanan => 'Layanan warga',
        KategoriAspirasi.kegiatan => 'Kegiatan',
        KategoriAspirasi.lain => 'Lainnya',
      };

  Ik get ikon => switch (this) {
        KategoriAspirasi.jalan => Ik.place,
        KategoriAspirasi.keamanan => Ik.shieldCheck,
        KategoriAspirasi.kebersihan => Ik.broom,
        KategoriAspirasi.layanan => Ik.handHeart,
        KategoriAspirasi.kegiatan => Ik.calendar,
        KategoriAspirasi.lain => Ik.chat,
      };

  Color get warna => switch (this) {
        KategoriAspirasi.jalan => AppColors.accent,
        KategoriAspirasi.keamanan => AppColors.error,
        KategoriAspirasi.kebersihan => AppColors.success,
        KategoriAspirasi.layanan => AppColors.warning,
        KategoriAspirasi.kegiatan => AppColors.social,
        KategoriAspirasi.lain => AppColors.muted,
      };

  static KategoriAspirasi fromDb(String? v) => KategoriAspirasi.values.firstWhere(
        (KategoriAspirasi k) => k.name == v,
        orElse: () => KategoriAspirasi.lain,
      );
}

/// Status penanganan FISH oleh pengurus.
enum StatusAspirasi { baru, diproses, selesai, ditolak }

extension StatusAspirasiX on StatusAspirasi {
  String get label => switch (this) {
        StatusAspirasi.baru => 'Baru',
        StatusAspirasi.diproses => 'Diproses',
        StatusAspirasi.selesai => 'Selesai',
        StatusAspirasi.ditolak => 'Ditolak',
      };

  /// Urutan gravitasi: makin ke kanan, makin rendah prioritas antrean.
  int get prioritas => index;

  Color get warna => switch (this) {
        StatusAspirasi.baru => AppColors.error,
        StatusAspirasi.diproses => AppColors.warning,
        StatusAspirasi.selesai => AppColors.success,
        StatusAspirasi.ditolak => AppColors.muted,
      };

  Ik get ikon => switch (this) {
        StatusAspirasi.baru => Ik.dot,
        StatusAspirasi.diproses => Ik.clock,
        StatusAspirasi.selesai => Ik.checkCircle,
        StatusAspirasi.ditolak => Ik.xCircle,
      };

  /// Langkah status berikutnya yang boleh dipilih pengurus.
  ///
  /// Alur wajib: `baru -> diproses -> selesai`. Menolak hanya boleh dari
  /// status `baru` (laporan memang tidak relevan), tidak setelah dikerjakan
  /// — supaya warga tidak bingung dengan FISH yang "hilang".
  List<StatusAspirasi> get berikutnya => switch (this) {
        StatusAspirasi.baru => const <StatusAspirasi>[
            StatusAspirasi.diproses,
            StatusAspirasi.selesai,
            StatusAspirasi.ditolak,
          ],
        StatusAspirasi.diproses => const <StatusAspirasi>[
            StatusAspirasi.selesai,
            StatusAspirasi.baru,
          ],
        StatusAspirasi.selesai => const <StatusAspirasi>[StatusAspirasi.baru],
        StatusAspirasi.ditolak => const <StatusAspirasi>[StatusAspirasi.baru],
      };

  static StatusAspirasi fromDb(String? v) => StatusAspirasi.values.firstWhere(
        (StatusAspirasi s) => s.name == v,
        orElse: () => StatusAspirasi.baru,
      );
}

/// Satu FISH warga: aspirasi, laporan, atau pengaduan.
@immutable
class Aspirasi {
  const Aspirasi({
    required this.id,
    required this.judul,
    required this.isi,
    required this.kategori,
    required this.status,
    required this.dibuat,
    required this.pengirim,
    this.rt,
    this.rw,
    this.balasan,
    this.contoh = false,
  });

  factory Aspirasi.dariBaris(Map<String, dynamic> b) => Aspirasi(
        id: (b['id'] ?? '').toString(),
        judul: (b['judul'] ?? b['title'] ?? '').toString(),
        isi: (b['isi'] ?? b['body'] ?? '').toString(),
        kategori: KategoriAspirasiX.fromDb(b['kategori']?.toString()),
        status: StatusAspirasiX.fromDb(b['status']?.toString()),
        dibuat: DateTime.tryParse('${b['dibuat'] ?? b['created_at'] ?? ''}') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        pengirim: (b['pengirim'] ?? b['reporter'] ?? 'Warga').toString(),
        rt: b['rt']?.toString(),
        rw: b['rw']?.toString(),
        balasan: b['balasan']?.toString(),
        contoh: b['contoh'] == true,
      );

  Map<String, dynamic> keBaris() => <String, dynamic>{
        'id': id,
        'judul': judul,
        'isi': isi,
        'kategori': kategori.name,
        'status': status.name,
        'dibuat': dibuat.toIso8601String(),
        'pengirim': pengirim,
        if (rt != null) 'rt': rt,
        if (rw != null) 'rw': rw,
        if (balasan != null) 'balasan': balasan,
        'contoh': contoh,
      };

  final String id;
  final String judul;
  final String isi;
  final KategoriAspirasi kategori;
  final StatusAspirasi status;
  final DateTime dibuat;
  final String pengirim;
  final String? rt;
  final String? rw;

  /// Catatan-balasan pengurus. Null kalau belum ada.
  final String? balasan;

  /// True kalau baris ini DATA CONTOH bawaan aplikasi, bukan laporan warga
  /// sungguhan.
  ///
  /// Wajib ada: proyek ini masih berjalan di mode lokal, dan menampilkan
  /// data karangan seolah-olah hasil asli itu tidak jujur. Semua kartu contoh
  /// diberi label "contoh" di layar.
  final bool contoh;

  String get zona => (rt == null && rw == null)
      ? 'Domisili belum dicantumkan'
      : 'RT ${rt ?? '-'} / RW ${rw ?? '-'}';

  /// Umur laporan dalam bahasa manusia: "baru saja", "3 jam lalu", "5 hari lalu".
  String get umur {
    final Duration selisih = DateTime.now().difference(dibuat);
    if (selisih.inMinutes < 1) return 'baru saja';
    if (selisih.inMinutes < 60) return '${selisih.inMinutes} menit lalu';
    if (selisih.inHours < 24) return '${selisih.inHours} jam lalu';
    if (selisih.inDays < 30) return '${selisih.inDays} hari lalu';
    return '${selisih.inDays ~/ 30} bulan lalu';
  }

  Aspirasi denganStatus(StatusAspirasi baru, {String? catatan}) => Aspirasi(
        id: id,
        judul: judul,
        isi: isi,
        kategori: kategori,
        status: baru,
        dibuat: dibuat,
        pengirim: pengirim,
        rt: rt,
        rw: rw,
        balasan: catatan ?? balasan,
        contoh: contoh,
      );

  @override
  bool operator ==(Object other) =>
      other is Aspirasi && other.id == id && other.status == status &&
      other.judul == judul && other.balasan == balasan;

  @override
  int get hashCode => Object.hash(id, status, judul, balasan);

  @override
  String toString() => 'Aspirasi($id, $status, $judul)';
}
