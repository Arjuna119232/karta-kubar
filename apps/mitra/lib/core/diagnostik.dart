import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Penangkap galat global + panel galat yang BISA DIBACA di HP.
///
/// Kenapa ada: kalau satu plugin gagal saat start dan tidak ada penangkap,
/// Flutter tidak menggambar apa pun -> pengguna hanya melihat layar hitam
/// tanpa petunjuk. Dengan ini penyebabnya selalu muncul di layar.
class Diagnostik {
  Diagnostik._();

  /// Galat terakhir; ditampilkan di splash supaya tidak pernah "hitam tanpa alasan".
  static final ValueNotifier<String?> terakhir = ValueNotifier<String?>(null);

  static void catat(String asal, Object e, [StackTrace? st]) {
    terakhir.value = '$asal: $e';
    debugPrint('KUNBAR-GALAT $asal: $e\n$st');
  }

  /// Dipanggil PALING AWAL di main(), sebelum kerja lain.
  static void pasang() {
    FlutterError.onError = (FlutterErrorDetails d) {
      FlutterError.presentError(d);
      terakhir.value = 'widget: ${d.exceptionAsString()}';
    };
    PlatformDispatcher.instance.onError = (Object e, StackTrace st) {
      catat('runtime', e, st);
      return true;
    };
    ErrorWidget.builder = (FlutterErrorDetails d) => PanelGalat(pesan: d.exceptionAsString());
  }
}

/// Panel galat polos: tidak memakai tema, aman dipakai sebelum MaterialApp.
class PanelGalat extends StatelessWidget {
  const PanelGalat({super.key, required this.pesan});

  final String pesan;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: const Color(0xFFFDF3F3),
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 40, color: Color(0xFFB3261E)),
              const SizedBox(height: 12),
              const Text(
                'Ada bagian yang gagal dimuat',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B1B1F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                pesan,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF44464F), height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
