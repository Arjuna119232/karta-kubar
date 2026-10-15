import 'package:flutter/services.dart';

/// Getaran sentuh (haptic) dengan satu titik kendali.
///
/// Kenapa dipusatkan: getaran yang terlalu sering bikin HP terasa "bergetar
/// terus" dan menguras baterai. Dengan satu berkas, gampang diaudit berapa
/// banyak getaran yang benar-benar dipakai, dan gampang dimatikan massal.
///
/// Aturan pakai:
/// - [ringan]  untuk perpindahan kecil (pilih chip, ganti tab) — PALING SERING.
/// - [sedang]  untuk aksi yang mengubah data (simpan, kirim, absen).
/// - [kuat]    hanya untuk aksi berbahaya / darurat (hapus, tombol merah).
/// - [sukses]/[gagal] untuk umpan balik hasil.
class Haptics {
  Haptics._();

  static void ringan() => HapticFeedback.selectionClick();
  static void sedang() => HapticFeedback.lightImpact();
  static void kuat() => HapticFeedback.mediumImpact();
  static void sukses() => HapticFeedback.lightImpact();
  static void gagal() => HapticFeedback.heavyImpact();

  /// Getar pola sistem — dipakai tombol darurat supaya terasa berbeda.
  static void darurat() => HapticFeedback.vibrate();
}
