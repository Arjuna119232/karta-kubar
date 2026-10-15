import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
/// Status kehadiran anggota pada satu kegiatan.
enum StatusKehadiran { hadir, izin, alpha }

extension StatusKehadiranX on StatusKehadiran {
  String get label => switch (this) {
        StatusKehadiran.hadir => 'Hadir',
        StatusKehadiran.izin => 'Izin',
        StatusKehadiran.alpha => 'Alpha',
      };

  Color get color => switch (this) {
        StatusKehadiran.hadir => AppColors.success,
        StatusKehadiran.izin => AppColors.warning,
        StatusKehadiran.alpha => AppColors.error,
      };
}

/// Satu catatan kehadiran.
@immutable
class Kehadiran {
  const Kehadiran({
    required this.kegiatan,
    required this.tanggal,
    required this.lokasi,
    required this.status,
  });

  final String kegiatan;
  final DateTime tanggal;
  final String lokasi;
  final StatusKehadiran status;

  String get id =>
      '$kegiatan-${tanggal.year}${tanggal.month}${tanggal.day}';
}