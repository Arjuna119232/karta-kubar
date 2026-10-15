import '../../core/data/hasil.dart';
import '../models/order.dart';
import '../models/order_tracking.dart';

/// Sumber titik perjalanan untuk satu order.
///
/// Kenapa abstrak: APK warga hanya butuh "ambil 10 titik terbaru", APK mitra
/// butuh "kirim titik baru", web admin butuh keduanya. Semuanya lewat kontrak
/// ini supaya tidak ada kode yang menulis query sendiri.
///
/// CATATAN JUJUR SOAL REAL-TIME: sampai Supabase Auth menyala dan kredensial
/// masuk ke APK, jadi ada sesi, sehingga tidak ada WebSocket push yang aman.
/// Implementasi saat ini [TrackingPolling] mengambil ulang tiap
/// [interval] detik lewat penyimpanan yang sedang aktif. Begitu Auth aktif,
/// tinggal tulis [TrackingRealtime] (Phoenix/WS) tanpa layar yang berubah
/// satu baris pun.
abstract class TrackingService {
  Future<Hasil<List<OrderTracking>>> titikOrder(
    String orderId,
    JenisOrder jenis,
  );

  Future<Hasil<void>> kirimTitik({
    required String orderId,
    required JenisOrder jenis,
    required StatusOrder status,
    required TitikPeta lokasi,
    String catatan = '',
  });
}

/// Ambil ulang titik terbaru secara berkala.
///
/// Ini yang dipakai warga sekarang. Aman dipakai di widget apa pun karena
/// [detak] bisa dimatikan dengan `ref.onDispose`.
class TrackingPolling implements TrackingService {
  TrackingPolling({
    required this.ambil,
    this.interval = const Duration(seconds: 10),
    this.ambilLangsung,
  });

  /// Fungsi pembacaan titik (dipisah dari class supaya file ini tidak
  /// bergantung pada repository tertentu).
  final Future<Hasil<List<OrderTracking>>> Function(String orderId, JenisOrder jenis)
      ambil;

  /// Pembricaan sekali tanpa jeda — dipakai saat layar baru dibuka supaya
  /// tidak menunggu satu tick penuh.
  final Future<Hasil<List<OrderTracking>>> Function(String orderId, JenisOrder jenis)?
      ambilLangsung;

  final Duration interval;

  Stream<List<OrderTracking>> stream(String orderId, JenisOrder jenis) async* {
    if (ambilLangsung != null) {
      final Hasil<List<OrderTracking>> awal = await ambilLangsung(orderId, jenis);
      if (awal.berhasil) yield awal.data ?? const <OrderTracking>[];
    }
    while (true) {
      await Future<void>.delayed(interval);
      final Hasil<List<OrderTracking>> h = await ambil(orderId, jenis);
      if (h.berhasil) yield h.data ?? const <OrderTracking>[];
    }
  }

  @override
  Future<Hasil<List<OrderTracking>>> titikOrder(
    String orderId,
    JenisOrder jenis,
  ) =>
      ambil(orderId, jenis);

  @override
  Future<Hasil<void>> kirimTitik({
    required String orderId,
    required JenisOrder jenis,
    required StatusOrder status,
    required TitikPeta lokasi,
    String catatan = '',
  }) async {
    // Warga TIDAK boleh menambah titik: itu hak mitra (kendaraan yang
    // bergerak). Method ini ada supaya kontrak sama untuk tiga aplikasi.
    return const Hasil<void>.galat(
      GalatData('Hanya mitra yang boleh mengirim titik perjalanan.'),
    );
  }
}

/// Riwayat tracking untuk satu order, siap dipakai di timeline.
class JejakStatus {
  const JejakStatus({
    required this.status,
    required this.selesai,
    required this.catatan,
    required this.waktu,
  });

  factory JejakStatus.dari(OrderTracking t) => JejakStatus(
        status: StatusOrder.dari(t.status),
        selesai: true,
        catatan: t.catatan,
        waktu: t.dibuat,
      );

  final StatusOrder status;
  final bool selesai;
  final String catatan;
  final DateTime? waktu;

  String get jam => waktu == null
      ? '-'
      : '${waktu!.hour.toString().padLeft(2, '0')}:'
          '${waktu!.minute.toString().padLeft(2, '0')}';
}

/// Tahapan yang ditampilkan sebagai timeline, sesuai jenis order.
///
/// Tahap "diproses" punya arti sedikit berbeda untuk jastip (mitra belanja
/// barang) dan ojek (mitra menuju lokasi jemput), jadi labelnya dibuat per
/// jenis supaya warga tidak salah paham.
const List<StatusOrder> tahapanUmum = <StatusOrder>[
  StatusOrder.menunggu,
  StatusOrder.diterima,
  StatusOrder.diproses,
  StatusOrder.dalamPerjalanan,
  StatusOrder.selesai,
];

/// Tahapan sampai posisi sekarang, ditambah satu tahap berikutnya.
List<StatusOrder> alurStatus(StatusOrder status) {
  if (!status.aktif) {
    return <StatusOrder>[
      status == StatusOrder.batal ? StatusOrder.batal : StatusOrder.dibatalkan,
    ];
  }
  final int sudah = tahapanUmum.indexOf(status);
  final int sampai = (sudah < 0 ? 1 : sudah + 2).clamp(1, tahapanUmum.length);
  return tahapanUmum.take(sampai).toList(growable: false);
}

/// LabelFriendly untuk satu tahap.
String labelTahap(StatusOrder s, JenisOrder jenis) {
  if (s != StatusOrder.diproses) return s.label;
  return jenis == JenisOrder.jastip
      ? 'Mitra belanja barang'
      : 'Mitra menuju lokasi jemput';
}
