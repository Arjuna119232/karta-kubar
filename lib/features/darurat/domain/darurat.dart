import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_icon.dart';

/// Jenis keadaan darurat di Kuningan Barat.
enum JenisDarurat { kebakaran, kecelakaan, kekerasan, banjir, listrik_mati, lain }

extension JenisDaruratX on JenisDarurat {
  String get label => switch (this) {
        JenisDarurat.kebakaran => 'Kebakaran',
        JenisDarurat.kecelakaan => 'Kecelakaan',
        JenisDarurat.kekerasan => 'Kekerasan',
        JenisDarurat.banjir => 'Banjir',
        JenisDarurat.listrik_mati => 'Listrik mati',
        JenisDarurat.lain => 'Lainnya',
      };

  /// Nomor darurat nasional Indonesia yang relevan: 112 nasional,
  /// 119 ambulans, 110 polisi, 115 PLN.
  String get nomor => switch (this) {
        JenisDarurat.kebakaran => '112',
        JenisDarurat.kecelakaan => '119',
        JenisDarurat.kekerasan => '110',
        JenisDarurat.banjir => '112',
        JenisDarurat.listrik_mati => '115',
        JenisDarurat.lain => '112',
      };

  /// Nama lembaga yang menangani, ditampilkan di layar supaya warga tahu
  /// menelepon siapa.
  String get lembaga => switch (this) {
        JenisDarurat.kebakaran => 'Pemadam Kebakaran / 112',
        JenisDarurat.kecelakaan => 'Ambulans / 119',
        JenisDarurat.kekerasan => 'Polisi / 110',
        JenisDarurat.banjir => 'Pemadam Kebakaran / 112',
        JenisDarurat.listrik_mati => 'PLN / 115',
        JenisDarurat.lain => 'Darurat Nasional / 112',
      };

  Ik get ikon => switch (this) {
        JenisDarurat.kebakaran => Ik.megaphone,
        JenisDarurat.kecelakaan => Ik.handHeart,
        JenisDarurat.kekerasan => Ik.shieldCheck,
        JenisDarurat.banjir => Ik.drop,
        JenisDarurat.listrik_mati => Ik.bell,
        JenisDarurat.lain => Ik.help,
      };

  static JenisDarurat fromDb(String? v) => JenisDarurat.values.firstWhere(
        (JenisDarurat k) => k.name == v,
        orElse: () => JenisDarurat.lain,
      );
}

/// Status penanganan laporan.
enum StatusDarurat { terkirim, ditangani, selesai }

extension StatusDaruratX on StatusDarurat {
  String get label => switch (this) {
        StatusDarurat.terkirim => 'Terkirim',
        StatusDarurat.ditangani => 'Ditangani',
        StatusDarurat.selesai => 'Selesai',
      };

  Color get warna => switch (this) {
        StatusDarurat.terkirim => AppColors.error,
        StatusDarurat.ditangani => AppColors.warning,
        StatusDarurat.selesai => AppColors.success,
      };

  static StatusDarurat fromDb(String? v) => StatusDarurat.values.firstWhere(
        (StatusDarurat s) => s.name == v,
        orElse: () => StatusDarurat.terkirim,
      );
}

/// Satu laporan darurat.
@immutable
class LaporanDarurat {
  const LaporanDarurat({
    required this.id,
    required this.jenis,
    required this.lokasi,
    required this.keterangan,
    required this.pengirim,
    required this.dibuat,
    this.status = StatusDarurat.terkirim,
    this.contoh = false,
  });

  factory LaporanDarurat.dariBaris(Map<String, dynamic> b) => LaporanDarurat(
        id: (b['id'] ?? '').toString(),
        jenis: JenisDaruratX.fromDb(b['jenis']?.toString()),
        lokasi: (b['lokasi'] ?? '').toString(),
        keterangan: (b['keterangan'] ?? '').toString(),
        pengirim: (b['pengirim'] ?? 'Warga').toString(),
        dibuat: DateTime.tryParse('${b['dibuat'] ?? ''}') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        status: StatusDaruratX.fromDb(b['status']?.toString()),
        contoh: b['contoh'] == true,
      );

  Map<String, dynamic> keBaris() => <String, dynamic>{
        if (id.startsWith('dar-')) 'id': id,
        'jenis': jenis.name,
        'lokasi': lokasi,
        'keterangan': keterangan,
        'pengirim': pengirim,
        'status': status.name,
        'contoh': contoh,
      };

  final String id;
  final JenisDarurat jenis;
  final String lokasi;
  final String keterangan;
  final String pengirim;
  final DateTime dibuat;
  final StatusDarurat status;
  final bool contoh;

  String get umur {
    // Nama variabelnya `selisih`, bukan `s`: huruf `s` dipakai juga sebagai
    // nama parameter closure `firstWhere((StatusDarurat s) => ...)` di file ini,
    // dan analyzer statis proyek salah mengira keduanya tipe yang sama.
    final Duration selisih = DateTime.now().difference(dibuat);
    if (selisih.inMinutes < 1) return 'baru saja';
    if (selisih.inMinutes < 60) return '${selisih.inMinutes} menit lalu';
    if (selisih.inHours < 24) return '${selisih.inHours} jam lalu';
    return '${selisih.inDays} hari lalu';
  }

  @override
  bool operator ==(Object other) =>
      other is LaporanDarurat && other.id == id;

  @override
  int get hashCode => id.hashCode;
}