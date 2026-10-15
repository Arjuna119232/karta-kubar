import 'package:flutter/foundation.dart';

import 'order.dart';

/// Rating + komentar warga untuk mitra setelah order selesai.
@immutable
class ReviewOrder {
  const ReviewOrder({
    required this.id,
    required this.orderId,
    required this.jenis,
    required this.reviewerKunci,
    required this.rating,
    required this.komentar,
    required this.dibuat,
    this.reviewerId,
    this.mitraId,
    this.fotoUrl,
  });

  factory ReviewOrder.dari(Map<String, dynamic> j) => ReviewOrder(
        id: bacaTeks(j['id']),
        orderId: bacaTeks(j['order_id']),
        jenis: JenisOrder.dari(bacaTeks(j['order_jenis'])),
        reviewerId: j['reviewer_id']?.toString(),
        reviewerKunci: bacaTeks(j['reviewer_kunci']),
        mitraId: j['mitra_id']?.toString(),
        rating: bacaBulat(j['rating']).clamp(1, 5),
        komentar: bacaTeks(j['komentar']),
        fotoUrl: j['foto_url']?.toString(),
        dibuat: bacaWaktu(j['dibuat']),
      );

  final String id;
  final String orderId;
  final JenisOrder jenis;
  final String? reviewerId;
  final String reviewerKunci;
  final String? mitraId;
  final int rating;
  final String komentar;
  final String? fotoUrl;
  final DateTime dibuat;

  bool get tanpaKomentar => komentar.trim().isEmpty;

  Map<String, dynamic> keBaris() => <String, dynamic>{
        if (id.isNotEmpty) 'id': id,
        'order_id': orderId,
        'order_jenis': jenis.name,
        'reviewer_kunci': reviewerKunci,
        if (mitraId != null && mitraId!.isNotEmpty) 'mitra_id': mitraId,
        'rating': rating,
        'komentar': komentar,
        if (fotoUrl != null && fotoUrl!.isNotEmpty) 'foto_url': fotoUrl,
      };

  @override
  bool operator ==(Object lain) =>
      lain is ReviewOrder && lain.id == id && lain.orderId == orderId;

  @override
  int get hashCode => Object.hash(id, orderId);
}

/// Ringkasan rating sebuah mitra: dipakai kartu driver di form order.
@immutable
class RingkasanRating {
  const RingkasanRating({
    required this.jumlah,
    required this.rata,
    this.terbaru = const <ReviewOrder>[],
  });

  static const RingkasanRating kosong = RingkasanRating(jumlah: 0, rata: 0);

  final int jumlah;
  final double rata;
  final List<ReviewOrder> terbaru;

  String get labelTeks => jumlah == 0 ? 'Belum ada penilaian' : '$rata (${jumlah.toStringAsFixed(1)})';

  factory RingkasanRating.dari(List<ReviewOrder> list) {
    if (list.isEmpty) return RingkasanRating.kosong;
    final int total = list.fold<int>(0, (int s, ReviewOrder r) => s + r.rating);
    return RingkasanRating(
      jumlah: list.length,
      rata: total / list.length,
      terbaru: list.take(3).toList(growable: false),
    );
  }
}