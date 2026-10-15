import 'dart:convert';

import 'package:http/http.dart' as http;

/// Rute jalan via OSRM publik (router.project-osrm.org).
/// GRATIS, tanpa API key. Server ini resmi untuk volume rendah - kalau nanti
/// dipakai sungguhan, ganti ke instance OSRM sendiri.
class RuteInfo {
  const RuteInfo({
    required this.koordinat,
    required this.jarakMeter,
    required this.durasiDetik,
  });

  /// [latitude, longitude] urut-polyline.
  final List<List<double>> koordinat;
  final double jarakMeter;
  final double durasiDetik;

  double get kilometer => jarakMeter / 1000;

  /// Menit, dibulatkan ke atas, minimal 1.
  int get etaMenit {
    final m = (durasiDetik / 60).ceil();
    return m < 1 ? 1 : m;
  }
}

class Rute {
  Rute._();

  static const _host = 'router.project-osrm.org';

  static Future<RuteInfo?> ambil(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) async {
    final uri = Uri.https(_host, '/route/v1/driving/'
        '$lng1,$lat1;$lng2,$lat2', {'overview': 'full', 'geometries': 'geojson'});
    try {
      final r = await http.get(uri, headers: const {'User-Agent': 'KUNBAR-Mitra/1'}).timeout(
            const Duration(seconds: 12),
          );
      if (r.statusCode != 200) return null;
      final body = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      if (body['code'] != 'Ok') return null;
      final routes = body['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      final r0 = routes.first as Map<String, dynamic>;
      final geometry = r0['geometry'] as Map<String, dynamic>?;
      final coords = geometry?['coordinates'] as List?;
      if (coords == null || coords.isEmpty) return null;
      return RuteInfo(
        koordinat: coords
            .map((e) => (e as List).map((v) => (v as num).toDouble()).toList())
            .toList(),
        jarakMeter: (r0['distance'] as num?)?.toDouble() ?? 0,
        durasiDetik: (r0['duration'] as num?)?.toDouble() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}
