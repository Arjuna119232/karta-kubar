import 'package:flutter/foundation.dart';

/// Hasil operasi data: berhasil atau gagal **dengan alasan yang bisa dibaca**.
///
/// Kenapa tidak pakai `throw`? Karena kegagalan koneksi itu HAL NORMAL (HP
/// tanpa sinyal, server Supabase down, RLS menolak). Kalau dibiarkan dilempar,
/// satu `await` yang gagal mematikan seluruh layar tanpa pesan - persis bug
/// yang pernah terjadi di aplikasi ini.
///
/// Pakai begitu:
///
/// ```dart
/// final Hasil<List<Kegiatan>> hasil = await repo.daftar();
/// if (!hasil.berhasil) {
///   tampilPesan(hasil.galat!.pesan);
///   return;
/// }
/// tampil(hasil.data!);
/// ```
@immutable
class Hasil<T> {
  const Hasil.berhasil(this.data) : galat = null;
  const Hasil.gagal(this.galat) : data = null;

  /// Alias Bahasa Indonesia supaya panggilan di lapisan fitur enak dibaca.
  const Hasil.galat(GalatData e) : this.gagal(e);

  /// Data bila berhasil, `null` bila gagal.
  final T? data;

  /// Alasan bila gagal, `null` bila berhasil.
  final GalatData? galat;

  bool get berhasil => galat == null;

  /// Ubah isi kalau berhasil; kalau gagal, [GalatData]-nya diteruskan.
  ///
  /// ```dart
  /// return hasil.peta((rows) => rows.map(_keKegiatan).toList());
  /// ```
  Hasil<R> peta<R>(R Function(T nilai) ubah) {
    final T? v = data;
    final GalatData? e = galat;
    if (v == null || e != null) return Hasil<R>.gagal(e!);
    return Hasil<R>.berhasil(ubah(v));
  }

  /// Nilai kalau berhasil, kalau gagal lempar [GalatData] sebagai exception
  /// (dipakai di lapisan atas yang memang harus tahu gagal).
  T get atauLempar {
    final T? v = data;
    if (v != null) return v;
    throw (galat ?? const GalatData('Gagal tanpa alasan'));
  }

  /// Alias Bahasa Indonesia dari [atauLempar].
  T get orLempar => atauLempar;

  @override
  String toString() => berhasil ? 'Hasil.berhasil($data)' : 'Hasil.gagal($galat)';
}

/// Alasan kegagalan. field ini diterjemahkan ke teks yang tampil ke pengguna.
@immutable
class GalatData implements Exception {
  const GalatData(this.pesan, {this.kode, this.asli});

  /// Pesan dalam bahasa manusia, siap ditampilkan.
  final String pesan;

  /// Kode mesin, mis. `invalid_grant` atau `42501` (RLS).
  final String? kode;

  /// Balisan server apa adanya, untuk saat debugging saja.
  final String? asli;

  @override
  String toString() => 'GalatData(${kode ?? '-'}, $pesan)';
}