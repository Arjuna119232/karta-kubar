import 'package:flutter/material.dart';

/// Status kehadiran anggota pada satu kegiatan.
enum StatusKehadiran { hadir, izin, alpha }

extension StatusKehadiranX on StatusKehadiran {
  String get label => switch (this) {
        StatusKehadiran.hadir => 'Hadir',
        StatusKehadiran.izin => 'Izin',
        StatusKehadiran.alpha => 'Alpha',
      };

  Color get color => switch (this) {
        StatusKehadiran.hadir => const Color(0xFF1B7A43),
        StatusKehadiran.izin => const Color(0xFFB26A00),
        StatusKehadiran.alpha => const Color(0xFFD32F2F),
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