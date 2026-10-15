import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/data/hasil.dart';
import '../domain/media_galeri.dart';
import 'galeri_repository.dart';

/// Repository galeri. Satu titik, supaya layar tidak tahu soal penyimpanan.
final Provider<GaleriRepository> galeriRepositoryProvider =
    Provider<GaleriRepository>((ref) => const GaleriLokalRepository());

/// Status proses unggah yang sedang berjalan.
enum StatusUnggah { pilih, menyalin, menyimpan, selesai, gagal }

/// Hasil satu kali unggah, dipakai layar untuk menampilkan status jujur.
class HasilUnggah {
  const HasilUnggah({required this.status, this.pesan = '', this.media});

  final StatusUnggah status;
  final String pesan;
  final MediaGaleri? media;
}

/// Daftar media yang sudah diunggah, plus proses mengunggah.
///
/// Pakai `AsyncNotifier` supaya daftar di layar selalu sama dengan isi
/// penyimpanan - bukan state lokal yang bisa berbeda dari yang tersimpan.
class GaleriNotifier extends AsyncNotifier<List<MediaGaleri>> {
  @override
  Future<List<MediaGaleri>> build() async {
    final Hasil<List<MediaGaleri>> h =
        await ref.watch(galeriRepositoryProvider).daftar();
    return h.berhasil ? h.data! : const <MediaGaleri>[];
  }

  /// Pilih satu foto dari galeri Android, salin ke folder aplikasi, lalu
  /// simpan HANYA metadata-nya.
  ///
  /// [ImageSource.gallery] di Android 13+ membuka Photo Picker bawaan sistem,
  /// jadi TIDAK butuh izin penyimpanan sama sekali.
  Future<HasilUnggah> unggah({
    required String judul,
    String keterangan = '',
  }) async {
    try {
      final XFile? pilih = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        // Batasi ukuran supaya tidak ada foto 12 MB tersimpan di perangkat
        // warga yang HP-nya_room kecil.
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (pilih == null) {
        return const HasilUnggah(status: StatusUnggah.gagal, pesan: 'Tidak ada foto dipilih.');
      }

      final String stempel = DateTime.now().toIso8601String().replaceAll(RegExp(r'[^0-9]'), '');
      final String ekstensi = pilih.name.contains('.') ? pilih.name.split('.').last.toLowerCase() : 'jpg';
      final String pathBaru =
          await PenyimpanMedia.salin(pilih.path, 'media-$stempel.$ekstensi');

      final MediaGaleri m = MediaGaleri(
        id: 'm$stempel',
        judul: judul.trim().isEmpty ? pilih.name : judul.trim(),
        pathBerkas: pathBaru,
        dibuat: DateTime.now(),
        keterangan: keterangan.trim(),
      );

      final Hasil<MediaGaleri> simpan =
          await ref.read(galeriRepositoryProvider).tambah(m);
      if (!simpan.berhasil) {
        return HasilUnggah(
          status: StatusUnggah.gagal,
          pesan: simpan.galat?.pesan ?? 'Gagal menyimpan.',
        );
      }
      await muatUlang();
      return HasilUnggah(status: StatusUnggah.selesai, media: m);
    } on FileSystemException catch (e) {
      return HasilUnggah(
        status: StatusUnggah.gagal,
        pesan: 'Gagal menyimpan berkas: ${e.message}',
      );
    } catch (e) {
      return HasilUnggah(status: StatusUnggah.gagal, pesan: 'Unggah gagal: $e');
    }
  }

  Future<void> hapus(String id) async {
    final Hasil<void> h = await ref.read(galeriRepositoryProvider).hapus(id);
    if (!h.berhasil) return;
    await muatUlang();
  }

  Future<void> muatUlang() async {
    state = const AsyncValue<List<MediaGaleri>>.loading();
    state = await AsyncValue.guard(
      () async => (await ref.read(galeriRepositoryProvider).daftar()).orLempar,
    );
  }
}

final AsyncNotifierProvider<GaleriNotifier, List<MediaGaleri>> mediaGaleriProvider =
    AsyncNotifierProvider<GaleriNotifier, List<MediaGaleri>>(
  GaleriNotifier.new,
);
