import 'dart:convert';

import '../../core/data/hasil.dart';
import '../models/order.dart';
import '../models/order_jastip.dart';
import '../models/order_ojek.dart';
import '../models/order_tracking.dart';
import '../models/review_order.dart';
import 'tracking_service.dart';

/// Penyimpanan rating + komentar warga.
///
/// Terpisah dari order karena satu order hanya boleh dinilai SEKALI (dijaga
/// unique constraint di database) tapi review punya riwayat panjang per mitra.
abstract class ReviewRepository {
  Future<Hasil<List<ReviewOrder>>> untukMitra(String mitraId);

  Future<Hasil<List<ReviewOrder>>> untukOrder(String orderId, JenisOrder jenis);

  Future<Hasil<ReviewOrder>> kirim(ReviewOrder review);

  Future<Hasil<void>> hapus(String id);
}

/// Sumber review sebelum backend nyala: disimpan di perangkat.
class ReviewLokal implements ReviewRepository {
  ReviewLokal({required this.baca, required this.tulis});

  final Future<String?> Function(String kunci) baca;
  final Future<void> Function(String kunci, String nilai) tulis;

  static const String kunci = 'kunar_review_order_v1';

  Future<List<Map<String, dynamic>>> _muat() async {
    final String? mentah = await baca(kunci);
    if (mentah == null || mentah.isEmpty) return <Map<String, dynamic>>[];
    try {
      final dynamic j = _decode(mentah);
      if (j is List) return j.whereType<Map<String, dynamic>>().toList(growable: false);
    } catch (_) {
      // Data rusak tidak boleh crash: mulai dari kosong.
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> _simpan(List<Map<String, dynamic>> baris) =>
      tulis(kunci, _encode(baris));

  @override
  Future<Hasil<List<ReviewOrder>>> untukMitra(String mitraId) async {
    final List<Map<String, dynamic>> baris = await _muat();
    return Hasil<List<ReviewOrder>>.berhasil(
      baris
          .where((Map<String, dynamic> b) => b['mitra_id'] == mitraId)
          .map(ReviewOrder.dari)
          .toList(growable: false),
    );
  }

  @override
  Future<Hasil<List<ReviewOrder>>> untukOrder(
    String orderId,
    JenisOrder jenis,
  ) async {
    final List<Map<String, dynamic>> baris = await _muat();
    return Hasil<List<ReviewOrder>>.berhasil(
      baris
          .where((Map<String, dynamic> b) =>
              b['order_id'] == orderId && b['order_jenis'] == jenis.name)
          .map(ReviewOrder.dari)
          .toList(growable: false),
    );
  }

  @override
  Future<Hasil<ReviewOrder>> kirim(ReviewOrder review) async {
    try {
      final List<Map<String, dynamic>> baris = await _muat();
      // Satu order hanya boleh dinilai sekali: kembalikan yang lama, bukan
      // membuat duplikat yang-delete tidak bisa dibersihkan.
      final int sudah = baris.indexWhere((Map<String, dynamic> b) =>
          b['order_id'] == review.orderId &&
          b['order_jenis'] == review.jenis.name);
      final Map<String, dynamic> baru = <String, dynamic>{
        ...review.keBaris(),
        'id': review.id.isNotEmpty ? review.id : 'lokal-${DateTime.now().microsecondsSinceEpoch}',
        'dibuat': DateTime.now().toUtc().toIso8601String(),
      };
      if (sudah >= 0) {
        baris[sudah] = baru;
      } else {
        baris.insert(0, baru);
      }
      await _simpan(baris);
      return Hasil<ReviewOrder>.berhasil(ReviewOrder.dari(baru));
    } catch (e) {
      return Hasil<ReviewOrder>.galat(GalatData('Gagal menyimpan penilaian: $e'));
    }
  }

  @override
  Future<Hasil<void>> hapus(String id) async {
    final List<Map<String, dynamic>> baris = await _muat();
    baris.removeWhere((Map<String, dynamic> b) => b['id'] == id);
    await _simpan(baris);
    return Hasil<void>.berhasil(null);
  }
}

/// Rating + komentar untuk satu mitra.
class ReviewService {
  const ReviewService(this.repo);

  final ReviewRepository repo;

  /// Ringkasan rating untuk kartu mitra di form / detail order.
  Future<RingkasanRating> ringkasan(String mitraId) async {
    if (mitraId.isEmpty) return RingkasanRating.kosong;
    final Hasil<List<ReviewOrder>> h = await repo.untukMitra(mitraId);
    if (!h.berhasil) return RingkasanRating.kosong;
    return RingkasanRating.dari(h.data ?? const <ReviewOrder>[]);
  }

  Future<Hasil<List<ReviewOrder>>> untukOrder(String orderId, JenisOrder jenis) =>
      repo.untukOrder(orderId, jenis);

  /// Kirim penilaian. Menolak rating di luar 1..5 dan order yang belum selesai.
  Future<Hasil<ReviewOrder>> kirim({
    required String orderId,
    required JenisOrder jenis,
    required String reviewerKunci,
    required String? mitraId,
    required int rating,
    String komentar = '',
    String? fotoUrl,
  }) async {
    if (rating < 1 || rating > 5) {
      return const Hasil<ReviewOrder>.galat(
        GalatData('Rating harus 1 sampai 5 bintang.', kode: 'rating_ngawur'),
      );
    }
    if (komentar.length > 400) {
      return const Hasil<ReviewOrder>.galat(
        GalatData('Komentar maksimal 400 karakter.', kode: 'komentar_panjang'),
      );
    }
    return repo.kirim(
      ReviewOrder(
        id: '',
        orderId: orderId,
        jenis: jenis,
        reviewerKunci: reviewerKunci,
        mitraId: mitraId,
        rating: rating,
        komentar: komentar.trim(),
        fotoUrl: fotoUrl,
        dibuat: DateTime.now(),
      ),
    );
  }
}

/// Penyimpanan titik tracking (lokal, sampai backend siap).
class TrackingLokal implements TrackingService {
  TrackingLokal({required this.baca, required this.tulis});

  final Future<String?> Function(String kunci) baca;
  final Future<void> Function(String kunci, String nilai) tulis;

  static const String kunci = 'kunar_order_tracking_v1';

  Future<List<Map<String, dynamic>>> _muat() async {
    final String? mentah = await baca(kunci);
    if (mentah == null || mentah.isEmpty) return <Map<String, dynamic>>[];
    try {
      final dynamic j = _decode(mentah);
      if (j is List) return j.whereType<Map<String, dynamic>>().toList(growable: false);
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
    return <Map<String, dynamic>>[];
  }

  /// Titik untuk satu order, terbaru dulu.
  Future<List<OrderTracking>> untuk(String orderId) async {
    final List<Map<String, dynamic>> baris = await _muat();
    final List<OrderTracking> out = baris
        .where((Map<String, dynamic> b) => b['order_id'] == orderId)
        .map(OrderTracking.dari)
        .toList(growable: false)
      ..sort((OrderTracking a, OrderTracking b) => b.dibuat.compareTo(a.dibuat));
    return out;
  }

  @override
  Future<Hasil<List<OrderTracking>>> titikOrder(
    String orderId,
    JenisOrder jenis,
  ) async =>
      Hasil<List<OrderTracking>>.berhasil(await untuk(orderId));

  @override
  Future<Hasil<void>> kirimTitik({
    required String orderId,
    required JenisOrder jenis,
    required StatusOrder status,
    required TitikPeta lokasi,
    String catatan = '',
  }) async {
    try {
      await tambah(
        OrderTracking(
          id: DateTime.now().millisecondsSinceEpoch,
          orderId: orderId,
          jenis: jenis,
          status: status.name,
          lokasi: lokasi,
          catatan: catatan,
          dibuat: DateTime.now(),
        ),
      );
      return Hasil<void>.berhasil(null);
    } catch (e) {
      return Hasil<void>.galat(GalatData('Gagal menyimpan titik: $e'));
    }
  }

  Future<void> tambah(OrderTracking t) async {
    final List<Map<String, dynamic>> baris = await _muat();
    baris.add(<String, dynamic>{
      ...t.keBaris(),
      'dibuat': t.dibuat.toUtc().toIso8601String(),
    });
    await tulis(kunci, _encode(baris));
  }
}

/// Titik tracking untuk order jastip ATAU ojek, dengan jenisnya ikut dibawa
/// supaya layar tracking cukup punya satu pembaca.
Future<List<OrderTracking>> titikUntuk(
  TrackingLokal store,
  String orderId,
  JenisOrder jenis,
) async {
  final List<OrderTracking> semua = await store.untuk(orderId);
  return semua.where((OrderTracking t) => t.jenis == jenis).toList(growable: false);
}

/// Bantu ubah list model jadi baris JSON (dipakai storage lokal).
List<Map<String, dynamic>> barisJastip(List<OrderJastip> list) =>
    list.map((OrderJastip o) => o.keBaris()).toList(growable: false);

List<Map<String, dynamic>> barisOjek(List<OrderOjek> list) =>
    list.map((OrderOjek o) => o.keBaris()).toList(growable: false);
String _encode(List<Map<String, dynamic>> baris) => jsonEncode(baris);

dynamic _decode(String mentah) => jsonDecode(mentah);
