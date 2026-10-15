import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// GPS + notifikasi foreground.
///
/// Selama mitra ONLINE, service ini hidup terus dan notifikasinya
/// `setOngoing: true` -> tidak bisa di-swipe, baru hilang saat OFFLINE.
class LocationService {
  StreamSubscription<Position>? _sub;
  bool get running => _sub != null;
  bool _aktifOrder = false;
  String? _orderId;

  /// true = GPS di HP sedang menyala (bukan soal izin).
  Future<bool> lokasiNyala() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }

  Future<bool> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  }

  /// Nyalakan GPS + notifikasi "Sedang ONLINE".
  /// [aktifOrder] = ada order yang sedang jalan -> sampling rapat.
  /// Mengembalikan false kalau izin lokasi ditolak (panggil pakai fallback).
  Future<bool> startOnline({
    required bool aktifOrder,
    String? orderId,
    void Function(Position)? onPos,
  }) async {
    if (running) {
      // Sudah hidup: set ulang hanya kalau mode atau order-nya berubah.
      if (_aktifOrder == aktifOrder && _orderId == orderId) return true;
      await stop();
    }
    if (!await ensurePermission()) return false;
    _aktifOrder = aktifOrder;
    _orderId = orderId;
    _sub = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: aktifOrder ? LocationAccuracy.medium : LocationAccuracy.low,
        distanceFilter: aktifOrder ? 30 : 100,
        intervalDuration: Duration(seconds: aktifOrder ? 10 : 30),
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: 'KUNBAR Mitra • Sedang ONLINE',
          notificationText: aktifOrder
              ? 'Order aktif. Lokasi Anda dikirim ke warga.'
              : 'Menunggu order di sekitar Anda. Buka aplikasi lalu tekan OFFLINE untuk berhenti.',
          notificationChannelName: 'Status ONLINE',
          setOngoing: true, // tidak bisa di-swipe pengguna
          enableWakeLock: aktifOrder,
        ),
      ),
    ).listen(onPos ?? (_) {}, onError: (_) {});
    return true;
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _aktifOrder = false;
    _orderId = null;
  }

  /// Titik posisi sekarang untuk marker peta. Null kalau izin lokasi belum ada.
  Future<({double lat, double lng})?> posisiSekarang() async {
    try {
      final p = await current();
      if (p == null) return null;
      return (lat: p.latitude, lng: p.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<Position?> current() async {
    try {
      if (!await ensurePermission()) return null;
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }
}