import '../../core/data/hasil.dart';
import 'order_repository.dart';
import '../models/order.dart';
import '../models/order_jastip.dart';
import '../models/order_ojek.dart';
import '../models/order_ringkas.dart';

/// Kontrak yang dipakai facade Jastip dan Ojek.
///
/// Kenapa tidak dua kelas yang masing-masing penuh: aturan bentuk
/// order (wajib ada koordinat tujuan, kode order, urutan tanggal) sama untuk
/// keduanya. Satu kontrak = satu tempat aturan, jadi tidak bisa berbeda
/// antara jastip dan ojek tanpa ketahuan saat review kode.
abstract class OrderServiceBase {
  /// Order milik warga, terbaru dulu.
  Future<Hasil<List<OrderRingkas>>> orderSaya();

  /// Satu order berdasarkan id. Gagal dikembalikan sebagai [Hasil.galat],
  /// bukan exception, supaya layar tidak pernah crash diam-diam.
  Future<Hasil<OrderRingkas>> orderById(String id);

  /// Order yang sedang berjalan (untuk kartu "Order Aktif").
  Future<Hasil<List<OrderRingkas>>> orderAktif();

  /// Batalkan order warga sendiri. Gagal kalau statusnya sudah tidak
  /// boleh dibatalkan (mis. sudah selesai).
  Future<Hasil<void>> batal(String id, String alasan);

  /// Order dari satu jenis saja.
  Future<Hasil<List<OrderRingkas>>> orderJenis(JenisOrder jenis);

  /// Satu order, sudah di-poll. Ini yang dipakai layar tracking.
  Stream<OrderRingkas?> pantau(String id, {Duration interval});
}

/// Bangun kode order yang enak dibaca manusia.
///
/// `KST-2501A2B3C4`: KUNBAR-Service-Tip, tanggalYYMM, lalu 6 karakter acak.
/// Panjang dan pola dibuat tetap supaya Mitra dan Web bisa parses sama.
String kodeOrder(JenisOrder jenis, DateTime waktu) {
  final String awalan = jenis == JenisOrder.jastip ? 'KST' : 'KOD';
  final String bulan =
      '${waktu.year.toString().substring(2)}${waktu.month.toString().padLeft(2, '0')}';
  return '$awalan-$bulan-${_acak(6)}';
}

String _acak(int panjang) {
  const String abjad = '0123456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  final DateTime now = DateTime.now();
  int seed = now.microsecondsSinceEpoch;
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < panjang; i++) {
    seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
    out.write(abjad[seed % abjad.length]);
  }
  return out.toString();
}
// =====================================================================
//  IMPLEMENTASI DASAR (dipakai JastipService dan OjekService)
// =====================================================================

/// Semua operasi order yang tidak membedakan jenis.
///
/// [OrderRepository] yang benar-benar bicara ke penyimpanan; kelas ini
/// hanya menerjemahkan baris database jadi [OrderRingkas] dan menjaga aturan
/// yang sama untuk jastip maupun ojek.
class OrderServiceDasar implements OrderServiceBase {
  OrderServiceDasar({
    required this.repo,
    required this.jenis,
    required this.detikPolling,
  });

  final OrderRepository repo;
  final JenisOrder jenis;

  /// Jeda antar pembacaan status di layar tracking.
  final Duration detikPolling;

  static OrderServiceDasar untuk(
    OrderRepository repo,
    JenisOrder jenis, {
    Duration detikPolling = const Duration(seconds: 10),
  }) =>
      OrderServiceDasar(repo: repo, jenis: jenis, detikPolling: detikPolling);

  Future<List<OrderRingkas>> _semua() async {
    final Hasil<List<OrderJastip>> j = await repo.daftarJastip();
    final Hasil<List<OrderOjek>> k = await repo.daftarOjek();
    if (!j.berhasil && !k.berhasil) {
      return const <OrderRingkas>[];
    }
    final List<OrderRingkas> semua = <OrderRingkas>[
      ...(j.data ?? const <OrderJastip>[]).map(OrderRingkas.dariJastip),
      ...(k.data ?? const <OrderOjek>[]).map(OrderRingkas.dariOjek),
    ]..sort((OrderRingkas a, OrderRingkas b) => b.dibuat.compareTo(a.dibuat));
    return semua;
  }

  @override
  Future<Hasil<List<OrderRingkas>>> orderSaya() async =>
      Hasil<List<OrderRingkas>>.berhasil(await _semua());

  @override
  Future<Hasil<List<OrderRingkas>>> orderJenis(JenisOrder j) async {
    final List<OrderRingkas> semua = await _semua();
    return Hasil<List<OrderRingkas>>.berhasil(
      semua.where((OrderRingkas o) => o.jenis == j).toList(growable: false),
    );
  }

  @override
  Future<Hasil<List<OrderRingkas>>> orderAktif() async {
    final List<OrderRingkas> semua = await _semua();
    return Hasil<List<OrderRingkas>>.berhasil(
      semua.where((OrderRingkas o) => o.aktif).toList(growable: false),
    );
  }

  @override
  Future<Hasil<OrderRingkas>> orderById(String id) async {
    for (final OrderRingkas o in await _semua()) {
      if (o.id == id) return Hasil<OrderRingkas>.berhasil(o);
    }
    return Hasil<OrderRingkas>.galat(
      GalatData('Order $id tidak ditemukan di perangkat ini.', kode: 'order_hilang'),
    );
  }

  @override
  Future<Hasil<void>> batal(String id, String alasan) async {
    final Hasil<OrderRingkas> h = await orderById(id);
    if (!h.berhasil) {
      return Hasil<void>.galat(h.galat ?? GalatData('Order tidak ditemukan.'));
    }
    final OrderRingkas o = h.data!;
    if (!o.status.bisaDibatalWarga) {
      return Hasil<void>.galat(
        GalatData(
          'Order sudah berstatus "${o.status.label}", jadi tidak bisa dibatalkan lagi.',
          kode: 'batal_ditolak',
        ),
      );
    }
    return jenis == JenisOrder.ojek
        ? repo.batalOjek(id, alasan)
        : repo.batalJastip(id, alasan);
  }

  @override
  Stream<OrderRingkas?> pantau(String id, {Duration? interval}) async* {
    final Duration jeda = interval ?? detikPolling;
    while (true) {
      final Hasil<OrderRingkas> h = await orderById(id);
      yield h.berhasil ? h.data : null;
      if (!h.berhasil) return;
      await Future<void>.delayed(jeda);
    }
  }
}
