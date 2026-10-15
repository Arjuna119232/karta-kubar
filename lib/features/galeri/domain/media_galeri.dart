import 'package:flutter/foundation.dart';

/// Satu media yang diunggah warga ke galeri.
///
/// Bedanya dengan [_Media] statis di layar: ini punya berkas asli di dalam
/// folder aplikasi, jadi foto yang sudah diunggah tetap ada setelah aplikasi
/// ditutup dan setelah perangkat dimatikan.
@immutable
class MediaGaleri {
  const MediaGaleri({
    required this.id,
    required this.judul,
    required this.pathBerkas,
    required this.dibuat,
    this.keterangan = '',
  });

  /// Id pendek dari waktuUngil +_acak, supaya unik walau dua warga mengunggah
  /// pada detik yang sama.
  final String id;
  final String judul;

  /// Lokasi absolut berkas di dalam folder dokumen aplikasi.
  ///
  /// Disalin saat unggah, BUKAN path asli dari galeri Android: Android sering
  /// memindahkan berkas hasil kamera, jadi path asli bisa basi dalam hitungan
  /// hari dan fotonya ikut hilang dari daftar.
  final String pathBerkas;
  final DateTime dibuat;
  final String keterangan;

  factory MediaGaleri.dariBaris(Map<String, dynamic> b) => MediaGaleri(
        id: (b['id'] ?? '').toString(),
        judul: (b['judul'] ?? '').toString(),
        pathBerkas: (b['path'] ?? '').toString(),
        dibuat: DateTime.tryParse('${b['dibuat'] ?? ''}') ?? DateTime.now(),
        keterangan: (b['keterangan'] ?? '').toString(),
      );

  Map<String, dynamic> keBaris() => <String, dynamic>{
        'id': id,
        'judul': judul,
        'path': pathBerkas,
        'dibuat': dibuat.toIso8601String(),
        'keterangan': keterangan,
      };

  @override
  bool operator ==(Object other) =>
      other is MediaGaleri && other.id == id && other.pathBerkas == pathBerkas;

  @override
  int get hashCode => Object.hash(id, pathBerkas);
}
