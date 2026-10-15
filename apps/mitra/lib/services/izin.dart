import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Status satu izin, jujur: tidak pernah menampilkan "diizinkan" yang palsu.
enum StatusIzin { sudah, ditolak, diblokir, belum, manual, tidakTersedia }

class ItemIzin {
  const ItemIzin({
    required this.kunci,
    required this.judul,
    required this.alasan,
    required this.ikon,
    required this.izin,
    this.manual = false,
    this.petunjuk,
  });

  final String kunci;
  final String judul;

  /// Alasan singkat dalam bahasa warga, ditampilkan SEBELUM dialog Android muncul.
  final String alasan;
  final IconData ikon;
  final Permission izin;

  /// true = izin khusus yang tidak bisa lewat dialog, harus lewat Pengaturan HP.
  final bool manual;

  /// Di mana tombolnya ada di Pengaturan HP (untuk izin manual).
  final String? petunjuk;
}

/// Urutan ini juga urutan permintaan ke Android: satu per satu, bukan numpuk.
const daftarIzin = <ItemIzin>[
  ItemIzin(
    kunci: 'notifikasi',
    judul: 'Notifikasi',
    alasan: 'Order masuk berbunyi walau aplikasi tidak dibuka.',
    ikon: Icons.notifications_active_outlined,
    izin: Permission.notification,
  ),
  ItemIzin(
    kunci: 'lokasi',
    judul: 'Lokasi',
    alasan: 'Warga melihat posisimu selama order aktif.',
    ikon: Icons.my_location,
    izin: Permission.locationWhenInUse,
  ),
  ItemIzin(
    kunci: 'kamera',
    judul: 'Kamera',
    alasan: 'Foto barang dan bukti pengiriman jastip.',
    ikon: Icons.photo_camera_outlined,
    izin: Permission.camera,
  ),
  ItemIzin(
    kunci: 'mikrofon',
    judul: 'Mikrofon',
    alasan: 'Rekam catatan suara barang yang harus tepat.',
    ikon: Icons.mic_none,
    izin: Permission.microphone,
  ),
  ItemIzin(
    kunci: 'telepon',
    judul: 'Telepon',
    alasan: 'Telepon warga langsung dari layar order.',
    ikon: Icons.call_outlined,
    izin: Permission.phone,
  ),
  ItemIzin(
    kunci: 'foto',
    judul: 'Foto dan video',
    alasan: 'Pilih foto atau video dari galeri untuk dilampirkan ke order.',
    ikon: Icons.photo_library_outlined,
    izin: Permission.photos,
  ),
  ItemIzin(
    kunci: 'kontak',
    judul: 'Kontak',
    alasan: 'Simpan kontak warga agar order tidak salah kirim.',
    ikon: Icons.contacts_outlined,
    izin: Permission.contacts,
  ),
  ItemIzin(
    kunci: 'sekitar',
    judul: 'Perangkat di sekitar',
    alasan: 'Notifikasi dari perangkat sekitar seperti printer atau Bluetooth.',
    ikon: Icons.bluetooth,
    izin: Permission.bluetoothScan,
  ),
  ItemIzin(
    kunci: 'layarKunci',
    judul: 'Tampil di layar kunci',
    alasan: 'Notifikasi order bisa muncul penuh di layar kunci HP.',
    ikon: Icons.lock_clock_outlined,
    izin: Permission.notification,
    manual: true,
    petunjuk: 'Pengaturan > Aplikasi > KUNBAR Mitra > Notifikasi > '
        'Tampilkan di layar kunci',
  ),
  ItemIzin(
    kunci: 'jendelaBaru',
    judul: 'Jendela baru di latar belakang',
    alasan: 'Boleh membuka jendela kecil di atas aplikasi lain (layar konfirmasi '
        'order saat sedang menjemput).',
    ikon: Icons.picture_in_picture_alt_outlined,
    izin: Permission.systemAlertWindow,
    manual: true,
    petunjuk: 'Pengaturan > Aplikasi > KUNBAR Mitra > Akses aplikasi > '
        'Tampilkan jendela pop-up / jendela baru',
  ),
  ItemIzin(
    kunci: 'latarBelakang',
    judul: 'Berjalan di latar belakang',
    alasan: 'Supaya notifikasi ONLINE tidak dimatikan sistem saat HP hemat baterai.',
    ikon: Icons.battery_saver_outlined,
    izin: Permission.ignoreBatteryOptimizations,
    manual: true,
    petunjuk: 'Pengaturan > Aplikasi > KUNBAR Mitra > Baterai > '
        'Tanpa pembatasan',
  ),
  ItemIzin(
    kunci: 'data',
    judul: 'Akses data & file',
    alasan: 'Simpan berkas lokal: cache order, foto bukti, dan riwayat.',
    ikon: Icons.folder_outlined,
    izin: Permission.manageExternalStorage,
    manual: true,
  ),
];

Future<StatusIzin> statusIzin(Permission p) async {
  try {
    final s = await p.status;
    if (s.isGranted || s.isLimited) return StatusIzin.sudah;
    if (s.isPermanentlyDenied || s.isRestricted) return StatusIzin.diblokir;
    return StatusIzin.belum;
  } catch (_) {
    return StatusIzin.tidakTersedia;
  }
}

Future<StatusIzin> mintaIzin(Permission p) async {
  try {
    final s = await p.request();
    if (s.isGranted || s.isLimited) return StatusIzin.sudah;
    if (s.isPermanentlyDenied || s.isRestricted) return StatusIzin.diblokir;
    return StatusIzin.ditolak;
  } catch (_) {
    return StatusIzin.tidakTersedia;
  }
}

Future<bool> bukaPengaturanIzin() async {
  try {
    return await openAppSettings();
  } catch (_) {
    return false;
  }
}
