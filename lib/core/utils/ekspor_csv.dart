import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Utilitas ekspor laporan: ubah data jadi CSV, lalu simpan ke berkas dan
/// buka sheet berbagi Android supaya pengguna bisa menyimpan ke Files, Drive,
/// atau mengirim ke WhatsApp.
///
/// Kenapa tidak langsung menulis ke folder Downloads? Android 10+ memakai
/// scoped storage: aplikasi tidak boleh menulis ke /storage/emulated/0 tanpa
/// izin khusus. Sheet berbagi adalah jalur yang resmi, tidak butuh izin, dan
/// hasilnya sama saja - file-nya benar-benar ada di perangkat.
abstract final class EksporBerkas {
  /// Bungkus satu nilai CSV sesuai aturan RFC 4180.
  ///
  /// WAJIB: nilai berisi koma, tanda kutip, atau baris baru harus diapit
  /// kutip dan kutip di dalamnya jadi dua kutip. Tanpa ini, satu catatan
  /// beranda bisa membuat seluruh baris CSV bergeser saat dibuka di Excel.
  static String sel(Object? nilai) {
    final String s = '${nilai ?? ''}';
    if (!s.contains(RegExp('[,"\n\r]'))) return s;
    return '"${s.replaceAll('"', '""')}"';
  }

  /// Satu baris CSV dari beberapa kolom.
  static String baris(List<Object?> kolom) => kolom.map(sel).join(',');

  /// Tulis [isi] ke berkas sementara lalu buka sheet berbagi.
  ///
  /// Mengembalikan lokasi berkas supaya layar bisa menampilkannya di snackbar.
  /// Melempar [FileSystemException] kalau direktori aplikasi tidak bisa ditulis;
  /// pemanggil yang memutuskan cara menampilkan gagalnya.
  static Future<String> bagikan({
    required String isi,
    required String namaBerkas,
    String? subyek,
    String? catatan,
  }) async {
    final Directory dir = await getTemporaryDirectory();
    final File f = File('${dir.path}/$namaBerkas');
    await f.writeAsString(isi, flush: true);
    await Share.shareXFiles(
      <XFile>[XFile(f.path, mimeType: 'text/csv', name: namaBerkas)],
      subject: subyek,
      text: catatan,
    );
    return f.path;
  }

  /// Nama berkas aman untuk tanggal hari ini, mis.
  /// `laporan-kas-2026-10-15.csv`.
  static String namaBerkasTanggal(String prefiks, DateTime waktu) {
    final String d = waktu.toIso8601String().substring(0, 10);
    return '$prefiks-$d.csv';
  }
}
