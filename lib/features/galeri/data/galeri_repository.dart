import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/hasil.dart';
import '../domain/media_galeri.dart';

/// Kontrak sumber data galeri.
///
/// Yang disimpan di sini hanya metadata (judul + lokasi berkas). Berkas
/// gambarnya sendiri ada di folder dokumen aplikasi - lihat [PenyimpanMedia].
///
/// Menyimpan foto sebagai base64 di SharedPreferences akan membuat penyimpanan
/// melonjak tanpa batas, jadi TIDAK dilakukan: berkasnya tetap sebagai file.
abstract class GaleriRepository {
  String get namaSumber;

  Future<Hasil<List<MediaGaleri>>> daftar();

  Future<Hasil<MediaGaleri>> tambah(MediaGaleri m);

  Future<Hasil<void>> hapus(String id);
}

/// Sumber data di perangkat: daftar JSON di SharedPreferences.
class GaleriLokalRepository implements GaleriRepository {
  const GaleriLokalRepository();

  /// Satu kunci = satu daftar. Jangan tulis ulang string ini di tempat lain.
  static const String kunci = 'kubar_galeri_v1';

  @override
  String get namaSumber => 'Tersimpan di perangkat';

  @override
  Future<Hasil<List<MediaGaleri>>> daftar() => _baca();

  @override
  Future<Hasil<MediaGaleri>> tambah(MediaGaleri m) async {
    final Hasil<List<MediaGaleri>> lama = await _baca();
    if (!lama.berhasil) return Hasil<MediaGaleri>.gagal(lama.galat!);
    final bool ok = await _tulis(<MediaGaleri>[m, ...lama.data!]);
    if (!ok) return Hasil<MediaGaleri>.gagal(const GalatData('Gagal menyimpan galeri.'));
    return Hasil<MediaGaleri>.berhasil(m);
  }

  @override
  Future<Hasil<void>> hapus(String id) async {
    final Hasil<List<MediaGaleri>> lama = await _baca();
    if (!lama.berhasil) return Hasil<void>.gagal(lama.galat!);

    // `firstOrNull` butuh package:collection; project ini sengaja tidak
    // menambah dependensi untuk satu baris, jadi cari manual.
    MediaGaleri? target;
    for (final MediaGaleri m in lama.data!) {
      if (m.id == id) {
        target = m;
        break;
      }
    }
    final List<MediaGaleri> sisa =
        lama.data!.where((MediaGaleri m) => m.id != id).toList(growable: false);

    // Berkas ikut dihapus supaya folder aplikasi tidak menumpuk berkas yatim
    // yang tidak pernah tampil lagi.
    if (target != null) await _hapusBerkas(target.pathBerkas);
    final bool ok = await _tulis(sisa);
    if (!ok) return Hasil<void>.gagal(const GalatData('Gagal menyimpan galeri.'));
    return const Hasil<void>.berhasil(null);
  }

  Future<bool> _tulis(List<MediaGaleri> data) async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString(
        kunci,
        jsonEncode(data.map((MediaGaleri m) => m.keBaris()).toList()),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Hasil<List<MediaGaleri>>> _baca() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? mentah = p.getString(kunci);
      if (mentah == null || mentah.isEmpty) {
        return Hasil<List<MediaGaleri>>.berhasil(const <MediaGaleri>[]);
      }
      final Object? decode = jsonDecode(mentah);
      if (decode is! List) {
        return const Hasil<List<MediaGaleri>>.berhasil(<MediaGaleri>[]);
      }
      return Hasil<List<MediaGaleri>>.berhasil(
        decode
            .whereType<Map<String, dynamic>>()
            .map(MediaGaleri.dariBaris)
            .toList(growable: false),
      );
    } catch (e) {
      return Hasil<List<MediaGaleri>>.gagal(GalatData('Gagal membaca galeri: $e'));
    }
  }

  /// Gagal menghapus berkas tidak boleh membatalkan penghapusan daftar: item
  /// yang rusak lebih RECE daripada membekakanya seluruh layar.
  Future<void> _hapusBerkas(String path) async {
    try {
      final File f = File(path);
      if (await f.exists()) await f.delete();
    } on FileSystemException {
      // Berkas sudah hilang atau tidak bisa dihapus. Daftar tetap diperbarui.
    }
  }
}

/// Folder tempat berkas media salinan disimpan.
///
/// Terpisah dari repository supaya layer data tidak selalu ikut membawa
/// `path_provider` dan supaya pemindahan berkas bisa diuji sendiri.
abstract final class PenyimpanMedia {
  static Future<Directory> folderMedia() async {
    final Directory dok = await getApplicationDocumentsDirectory();
    final Directory f = Directory('${dok.path}/media');
    if (!await f.exists()) await f.create(recursive: true);
    return f;
  }

  /// Salin berkas hasil pilih galeri ke dalam folder aplikasi.
  ///
  /// Mengembalikan lokasi barunya. Sengaja memakai `copy`, bukan `rename`:
  /// berkas asal milik pengguna harus tetap utuh.
  static Future<String> salin(String sumber, String namaTujuan) async {
    final Directory f = await folderMedia();
    final File tujuan = File('${f.path}/$namaTujuan');
    await File(sumber).copy(tujuan.path);
    return tujuan.path;
  }
}
