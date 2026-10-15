import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// GPS HANYA menyala saat ada order aktif (hemat baterai).
class LocationService {
  StreamSubscription<Position>? _sub;
  bool get running => _sub != null;

  Future<bool> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  }

  Future<void> start(void Function(Position) onPos) async {
    if (running) return;
    if (!await ensurePermission()) return;
    _sub = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 30,
        intervalDuration: const Duration(seconds: 10),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'KUNBAR Mitra',
          notificationText: 'Lokasi dibagikan ke warga selama order aktif',
        ),
      ),
    ).listen(onPos, onError: (_) {});
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
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
