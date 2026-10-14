import 'package:flutter/foundation.dart';

/// Satu bulan iuran warga.
@immutable
class Iuran {
  const Iuran({required this.periode, required this.nominal, required this.lunas});

  /// Contoh: "Oktober 2026".
  final String periode;
  final int nominal;
  final bool lunas;

  factory Iuran.dariBaris(Map<String, dynamic> b) => Iuran(
        periode: (b['periode'] ?? '').toString(),
        nominal: _keInt(b['nominal']),
        lunas: (b['lunas'] ?? false) == true,
      );

  Map<String, dynamic> keBaris() => <String, dynamic>{
        'periode': periode,
        'nominal': nominal,
        'lunas': lunas,
      };
}

/// Titik data kas satu bulan untuk grafik.
@immutable
class KasBulanan {
  const KasBulanan({required this.label, required this.juta});

  /// Singkatan bulan, mis. "Okt".
  final String label;
  final double juta;

  factory KasBulanan.dariBaris(Map<String, dynamic> b) => KasBulanan(
        label: (b['label'] ?? '').toString(),
        juta: _keDouble(b['juta']),
      );

  Map<String, dynamic> keBaris() => <String, dynamic>{'label': label, 'juta': juta};
}

int _keInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

double _keDouble(Object? v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}
