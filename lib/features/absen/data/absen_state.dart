import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/kehadiran.dart';
import '../../kegiatan/domain/kegiatan.dart';

/// Format payload QR absen. Dipakai untuk membuat QR dan membacanya kembali.
String absenPayload(Kegiatan a) =>
    'karta-kubar://absen/${a.date.year}${a.date.month.toString().padLeft(2, '0')}'
    '${a.date.day.toString().padLeft(2, '0')}/${Uri.encodeComponent(a.title)}';

/// Baca balik payload QR -> judul kegiatan, atau null kalau bukan QR absen.
String? parseAbsenPayload(String payload) {
  if (!payload.startsWith('karta-kubar://absen/')) return null;
  final List<String> bagian = payload.substring('karta-kubar://absen/'.length).split('/');
  if (bagian.length < 2) return null;
  return Uri.decodeComponent(bagian[1]);
}

/// Daftar kehadiran anggota. Offline: hanya hidup selama sesi aplikasi.
class AbsenNotifier extends StateNotifier<List<Kehadiran>> {
  AbsenNotifier() : super(_seed());

  static List<Kehadiran> _seed() {
    final DateTime now = DateTime.now();
    return <Kehadiran>[
      Kehadiran(
        kegiatan: 'Kerja Bakti Lingkungan',
        tanggal: now.subtract(const Duration(days: 8)),
        lokasi: 'Balai RW 05',
        status: StatusKehadiran.hadir,
      ),
      Kehadiran(
        kegiatan: 'Latihan Futsal Rutin',
        tanggal: now.subtract(const Duration(days: 15)),
        lokasi: 'GOR Kuningan',
        status: StatusKehadiran.hadir,
      ),
      Kehadiran(
        kegiatan: 'Donor Darah Bersama PMI',
        tanggal: now.subtract(const Duration(days: 23)),
        lokasi: 'Kantor Kelurahan',
        status: StatusKehadiran.izin,
      ),
      Kehadiran(
        kegiatan: 'Turnamen Badminton',
        tanggal: now.subtract(const Duration(days: 31)),
        lokasi: 'GOR Kuningan',
        status: StatusKehadiran.hadir,
      ),
    ];
  }

  bool sudahAbsen(String kegiatan, DateTime tanggal) => state.any(
        (Kehadiran k) =>
            k.kegiatan == kegiatan &&
            k.tanggal.year == tanggal.year &&
            k.tanggal.month == tanggal.month &&
            k.tanggal.day == tanggal.day,
      );

  /// Catat kehadiran. Tidak menimpa data yang sudah ada.
  bool catat(
    Kegiatan kegiatan,
    StatusKehadiran status, {
    DateTime? pada,
  }) {
    final DateTime waktu = pada ?? kegiatan.date;
    if (sudahAbsen(kegiatan.title, waktu)) return false;
    state = <Kehadiran>[
      Kehadiran(
        kegiatan: kegiatan.title,
        tanggal: waktu,
        lokasi: kegiatan.location,
        status: status,
      ),
      ...state,
    ];
    return true;
  }

  void ubahStatus(String id, StatusKehadiran status) {
    state = <Kehadiran>[
      for (final Kehadiran k in state)
        if (k.id == id)
          Kehadiran(
            kegiatan: k.kegiatan,
            tanggal: k.tanggal,
            lokasi: k.lokasi,
            status: status,
          )
        else
          k,
    ];
  }

  void hapus(String id) =>
      state = state.where((Kehadiran k) => k.id != id).toList();

  int get bulanIni =>
      state.where((Kehadiran k) => _bulanIni(k.tanggal)).length;

  int get hadirBulanIni => state
      .where((Kehadiran k) => _bulanIni(k.tanggal) && k.status == StatusKehadiran.hadir)
      .length;

  static bool _bulanIni(DateTime d) {
    final DateTime now = DateTime.now();
    return d.year == now.year && d.month == now.month;
  }
}

final StateNotifierProvider<AbsenNotifier, List<Kehadiran>> absenProvider =
    StateNotifierProvider<AbsenNotifier, List<Kehadiran>>(
  (ref) => AbsenNotifier(),
);