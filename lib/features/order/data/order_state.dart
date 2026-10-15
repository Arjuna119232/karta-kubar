import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/hasil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/models/mitra_jasa.dart';
import '../../../shared/models/order.dart';
import '../../../shared/models/order_ringkas.dart';
import '../../../shared/models/review_order.dart';
import '../../../shared/services/jastip_service.dart';
import '../../../shared/services/lokasi_service.dart';
import '../../../shared/services/ojek_service.dart';
import '../../../shared/services/order_repository.dart';
import '../../../shared/services/order_service_base.dart';
import '../../../shared/services/review_service.dart';
import '../../../shared/services/tarif_service.dart';

/// Kunci stabil per perangkat untuk menandai order milik siapa.
///
/// Dipakai karena login APK belum memakai Supabase Auth: `auth.uid()` belum
/// ada, jadi baris order tidak bisa selalu dikaitkan ke `profiles`. Kunci ini
/// disimpan sekali dan tidak pernah berubah, jadi order lama tetap milik orang
/// yang sama setelah aplikasi diperbarui.
class KunciWarga {
  const KunciWarga(this.nilai);

  final String nilai;

  static const String _kunciSimpan = 'kunar_warga_kunci_v1';

  /// Dibaca sekali lalu disimpan. Nilai kosong hanya terjadi kalau penyimpanan
  /// gagal, dan itu ditangani dengan id sementara per sesi.
  static Future<KunciWarga> muat() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? lama = p.getString(_kunciSimpan);
      if (lama != null && lama.isNotEmpty) return KunciWarga(lama);
      final String baru =
          'warga-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
      await p.setString(_kunciSimpan, baru);
      return KunciWarga(baru);
    } catch (_) {
      return KunciWarga('warga-sesi-${DateTime.now().millisecondsSinceEpoch}');
    }
  }
}

/// Penyimpanan order + review di perangkat.
final Provider<OrderRepository> orderRepositoryProvider =
    Provider<OrderRepository>((ref) {
  return OrderLokal(
    baca: _bacaKunci,
    tulis: _tulisKunci,
  );
});

final Provider<ReviewRepository> reviewRepositoryProvider =
    Provider<ReviewRepository>((ref) {
  return ReviewLokal(baca: _bacaKunci, tulis: _tulisKunci);
});

Future<String?> _bacaKunci(String kunci) async {
  final SharedPreferences p = await SharedPreferences.getInstance();
  return p.getString(kunci);
}

Future<void> _tulisKunci(String kunci, String nilai) async {
  final SharedPreferences p = await SharedPreferences.getInstance();
  await p.setString(kunci, nilai);
}

final Provider<JastipService> jastipServiceProvider = Provider<JastipService>(
  (ref) => JastipService(repo: ref.watch(orderRepositoryProvider)),
);

final Provider<OjekService> ojekServiceProvider = Provider<OjekService>(
  (ref) => OjekService(repo: ref.watch(orderRepositoryProvider)),
);

final Provider<ReviewService> reviewServiceProvider = Provider<ReviewService>(
  (ref) => ReviewService(ref.watch(reviewRepositoryProvider)),
);

final Provider<MitraRepository> mitraRepositoryProvider =
    Provider<MitraRepository>((ref) => const MitraRepositoryContoh());

final Provider<LokasiService> lokasiServiceProvider =
    Provider<LokasiService>((ref) {
  final LokasiService s = LokasiService();
  ref.onDispose(s.buang);
  return s;
});

final Provider<TarifService> tarifServiceProvider =
    Provider<TarifService>((ref) => const TarifService());

final Provider<KunciWarga> kunciWargaProvider = FutureProvider<KunciWarga>(
  (ref) => KunciWarga.muat(),
);

/// Penyimpanan titik tracking di perangkat.
final Provider<TrackingLokal> trackingLokalProvider =
    Provider<TrackingLokal>((ref) {
  return TrackingLokal(baca: _bacaKunci, tulis: _tulisKunci);
});

// =====================================================================
//  Daftar order (dipakai beranda, riwayat, dan daftar semua)
// =====================================================================

/// Semua order warga, terbaru dulu. Satu sumber untuk semua layar.
final AsyncNotifierProvider<OrderNotifier, List<OrderRingkas>> orderProvider =
    AsyncNotifierProvider<OrderNotifier, List<OrderRingkas>>(OrderNotifier.new);

class OrderNotifier extends AsyncNotifier<List<OrderRingkas>> {
  @override
  Future<List<OrderRingkas>> build() async {
    final JastipService j = ref.watch(jastipServiceProvider);
    final OjekService o = ref.watch(ojekServiceProvider);
    final List<OrderRingkas> a =
        (await j.orderSaya()).data ?? const <OrderRingkas>[];
    final List<OrderRingkas> b =
        (await o.orderSaya()).data ?? const <OrderRingkas>[];
    final List<OrderRingkas> semua = <OrderRingkas>[...a, ...b]
      ..sort((OrderRingkas x, OrderRingkas y) => y.dibuat.compareTo(x.dibuat));
    return semua;
  }

  Future<void> muatUlang() async {
    state = await AsyncValue<List<OrderRingkas>>.guard(build);
  }

  /// Dipanggil setelah form berhasil submit supaya daftar langsung terlihat.
  Future<void> tambah(OrderRingkas baru) async {
    final List<OrderRingkas> sekarang = state.valueOrNull ?? const <OrderRingkas>[];
    state = AsyncValue<List<OrderRingkas>>.data(<OrderRingkas>[
      baru,
      ...sekarang.where((OrderRingkas o) => o.id != baru.id),
    ]);
    await muatUlang();
  }
}

/// Order yang masih berjalan, untuk kartu "Order Aktif" di beranda.
final Provider<List<OrderRingkas>> orderAktifProvider =
    Provider<List<OrderRingkas>>((ref) {
  final List<OrderRingkas> semua = ref.watch(orderProvider).valueOrNull ??
      const <OrderRingkas>[];
  return semua.where((OrderRingkas o) => o.aktif).toList(growable: false);
});

// =====================================================================
//  Satu order + pantauan status
// =====================================================================

/// Satu order, di-poll supaya layar tracking selalu segar.
///
/// [id] dibawa sebagai `"<jenis>:<uuid>"` (contoh `jastip:local-123`) supaya
/// satu provider melayani jastip dan ojek tanpa parameter kedua.
final StreamProvider.autoDispose.family<OrderRingkas?, String>
    orderPantauProvider =
    StreamProvider.autoDispose.family<OrderRingkas?, String>((ref, kunci) {
  final int pisah = kunci.indexOf(':');
  final String jenis =
      pisah > 0 ? kunci.substring(0, pisah) : JenisOrder.jastip.name;
  final String idAsli = pisah > 0 ? kunci.substring(pisah + 1) : kunci;
  final OrderServiceDasar svc = jenis == JenisOrder.ojek.name
      ? ref.watch(ojekServiceProvider)
      : ref.watch(jastipServiceProvider);
  return _pantau(svc, idAsli);
});

Future<OrderRingkas?> _pantau(OrderServiceDasar svc, String id) async* {
  while (true) {
    final Hasil<List<OrderRingkas>> semua = await svc.orderSaya();
    OrderRingkas? ketemu;
    for (final OrderRingkas o in semua.data ?? const <OrderRingkas>[]) {
      if (o.id == id) {
        ketemu = o;
        break;
      }
    }
    yield ketemu;
    await Future<void>.delayed(svc.detikPolling);
  }
}

/// Titik perjalanan untuk satu order, dipakai peta dan timeline.
final StreamProvider.autoDispose.family<List<TitikPeta>, String>
    trackingTitikProvider =
    StreamProvider.autoDispose.family<List<TitikPeta>, String>((ref, kunci) {
  final int pisah = kunci.indexOf(':');
  final String jenis =
      pisah > 0 ? kunci.substring(0, pisah) : JenisOrder.jastip.name;
  final String idAsli = pisah > 0 ? kunci.substring(pisah + 1) : kunci;
  final TrackingLokal store = ref.watch(trackingLokalProvider);
  return titikUntuk(store, idAsli, JenisOrder.dari(jenis));
});

;
// =====================================================================
//  Mitra
// =====================================================================

/// Mitra yang sedang online dan bisa menerima order [jenis].
final FutureProvider.family<List<MitraJasa>, JenisOrder>
    mitraTersediaProvider =
    FutureProvider.family<List<MitraJasa>, JenisOrder>((ref, jenis) async {
  final MitraRepository repo = ref.watch(mitraRepositoryProvider);
  return (await repo.tersedia(jenis)).data ?? const <MitraJasa>[];
});

/// Rating mitra untuk kartu di form ojek dan kartu detail.
final FutureProvider.family<RingkasanRating, String> ringkasanRatingProvider =
    FutureProvider.family<RingkasanRating, String>((ref, mitraId) async {
  if (mitraId.isEmpty) return RingkasanRating.kosong;
  return ref.watch(reviewServiceProvider).ringkasan(mitraId);
});

/// Ulasan untuk satu mitra (kartu detail order).
final FutureProvider.family<List<ReviewOrder>, String> ulasanMitraProvider =
    FutureProvider.family<List<ReviewOrder>, String>((ref, mitraId) async {
  if (mitraId.isEmpty) return const <ReviewOrder>[];
  final Hasil<List<ReviewOrder>> h =
      await ref.watch(reviewRepositoryProvider).untukMitra(mitraId);
  return h.data ?? const <ReviewOrder>[];
});
