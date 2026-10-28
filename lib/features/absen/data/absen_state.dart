import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/kehadiran.dart';
import '../../kegiatan/domain/kegiatan.dart';

/// Format payload QR absen. Dipakai untuk membuat QR dan membacanya kembali.
///
/// Kegiatan tanpa tanggal (baris dari server yang tanggalnya kosong) memakai
/// ruas tanggal kosong — bukan `!` — supaya pembuatan QR tidak pernah crash.
String absenPayload(Kegiatan a) {
  final DateTime? t = a.tanggal;
  final String tanggal = t == null
      ? ''
      : '${t.year}${t.month.toString().padLeft(2, '0')}'
          '${t.day.toString().padLeft(2, '0')}';
  return 'karta-kubar://absen/$tanggal/${Uri.encodeComponent(a.judul)}';
}

/// Isi QR absen yang berhasil dibaca kamera.
///
/// `tanggal` boleh null: QR dari penyelenggara bisa saja tidak memuat tanggal
/// yang sah, dan menolak seluruh QR hanya karena tanggalnya rusak akan membuat
/// absensi gagal di lapangan.
class AbsenKode {
  const AbsenKode({required this.judul, this.tanggal});

  final String judul;
  final DateTime? tanggal;

  @override
  String toString() => 'AbsenKode($judul, $tanggal)';
}

/// Baca payload QR absen -> judul + tanggal, atau null kalau bukan QR absen.
AbsenKode? bacaAbsenKode(String payload) {
  const String awalan = 'karta-kubar://absen/';
  final String teks = payload.trim();
  if (!teks.startsWith(awalan)) return null;
  final List<String> bagian = teks.substring(awalan.length).split('/');
  if (bagian.length < 2) return null;
  final String judul = Uri.decodeComponent(bagian[1]).trim();
  if (judul.isEmpty) return null;
  return AbsenKode(judul: judul, tanggal: _bacaTanggal(bagian[0]));
}

/// `YYYYMMDD` -> DateTime, atau null kalau bukan tanggal yang benar-benar ada.
///
/// `DateTime(2026, 2, 31)` TIDAK error — dia bergulir jadi 3 Maret. Karena itu
/// hasilnya dibandingkan balik dengan angka aslinya.
DateTime? _bacaTanggal(String teks) {
  if (teks.length != 8) return null;
  final int? tahun = int.tryParse(teks.substring(0, 4));
  final int? bulan = int.tryParse(teks.substring(4, 6));
  final int? hari = int.tryParse(teks.substring(6, 8));
  if (tahun == null || bulan == null || hari == null) return null;
  final DateTime hasil = DateTime(tahun, bulan, hari);
  if (hasil.year != tahun || hasil.month != bulan || hasil.day != hari) {
    return null;
  }
  return hasil;
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
    final DateTime waktu = pada ?? kegiatan.tanggal ?? DateTime.now();
    if (sudahAbsen(kegiatan.judul, waktu)) return false;
    state = <Kehadiran>[
      Kehadiran(
        kegiatan: kegiatan.judul,
        tanggal: waktu,
        lokasi: kegiatan.lokasi,
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