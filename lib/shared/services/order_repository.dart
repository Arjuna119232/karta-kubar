import 'dart:convert';

import '../../core/data/hasil.dart';
import '../models/order.dart';
import '../models/order_jastip.dart';
import '../models/order_ojek.dart';
import '../models/order_ringkas.dart';

/// Kontrak sumber data order.
///
/// Dua implementasi: [OrderLokal] (perangkat, selalu bisa dipakai) dan
/// [OrderSupabase] (server, dipakai begitu Supabase Auth aktif). Layar hanya
/// tahu interface ini lewat repository, jadi tidak perlu tahu mana yang aktif.
abstract class OrderRepository {
  Future<Hasil<List<OrderJastip>>> daftarJastip();

  Future<Hasil<List<OrderOjek>>> daftarOjek();

  Future<Hasil<OrderJastip>> kirimJastip(OrderJastip order);

  Future<Hasil<OrderOjek>> kirimOjek(OrderOjek order);

  Future<Hasil<void>> batalJastip(String id, String alasan);

  Future<Hasil<void>> batalOjek(String id, String alasan);

  /// Order aktif untuk kartu "Order Aktif" di beranda.
  Future<Hasil<List<OrderRingkas>>> aktif();
}

// =====================================================================
//  PENYIMPANAN LOKAL (default, selalu bisa dipakai tanpa internet)
// =====================================================================

/// Simpan order sebagai JSON di SharedPreferences.
///
/// Ini yang dipakai sampai Supabase Auth benar-benar menyala, jadi fitur
/// tetap bisa dicoba warga sekarang. Formatnya sengaja memakai `keBaris()`
/// yang sama dengan kolom database, jadi migrasi ke server tidak perlu
/// menulis ulang pemetaan.
class OrderLokal implements OrderRepository {
  OrderLokal({required this.baca, required this.tulis});

  /// Membaca JSON mentah dari penyimpanan. Dipisah supaya kelas ini tidak
  /// perlu tahu soal `shared_preferences` (dan tetap bisa dipakai di web).
  final Future<String?> Function(String kunci) baca;
  final Future<void> Function(String kunci, String nilai) tulis;

  static const String kunciJastip = 'kunar_order_jastip_v1';
  static const String kunciOjek = 'kunar_order_ojek_v1';

  Future<List<Map<String, dynamic>>> _muat(String kunci) async {
    final String? mentah = await baca(kunci);
    if (mentah == null || mentah.isEmpty) return <Map<String, dynamic>>[];
    try {
      final dynamic j = jsonDecode(mentah);
      if (j is List) {
        return j
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
      }
    } catch (_) {
      // Data rusak tidak boleh membuat aplikasi crash: mulai dari kosong.
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> _simpan(String kunci, List<Map<String, dynamic>> baris) =>
      tulis(kunci, jsonEncode(baris));

  Future<Hasil<OrderJastip>> _tambahJastip(OrderJastip order) async {
    try {
      final List<Map<String, dynamic>> baris = await _muat(kunciJastip);
      final Map<String, dynamic> baru = <String, dynamic>{
        ...order.keBaris(),
        'id': order.id.isEmpty ? _idBaru() : order.id,
        'dibuat': order.dibuat.toUtc().toIso8601String(),
      };
      baris.insert(0, baru);
      await _simpan(kunciJastip, baris);
      return Hasil<OrderJastip>.berhasil(OrderJastip.dari(baru));
    } catch (e) {
      return Hasil<OrderJastip>.galat(GalatData('Gagal menyimpan order: $e'));
    }
  }

  Future<Hasil<OrderOjek>> _tambahOjek(OrderOjek order) async {
    try {
      final List<Map<String, dynamic>> baris = await _muat(kunciOjek);
      final Map<String, dynamic> baru = <String, dynamic>{
        ...order.keBaris(),
        'id': order.id.isEmpty ? _idBaru() : order.id,
        'dibuat': order.dibuat.toUtc().toIso8601String(),
      };
      baris.insert(0, baru);
      await _simpan(kunciOjek, baris);
      return Hasil<OrderOjek>.berhasil(OrderOjek.dari(baru));
    } catch (e) {
      return Hasil<OrderOjek>.galat(GalatData('Gagal menyimpan order: $e'));
    }
  }

  Future<Hasil<void>> _batal(
    String kunci,
    String id,
    String alasan,
    StatusOrder status,
  ) async {
    try {
      final List<Map<String, dynamic>> baris = await _muat(kunci);
      int ketemu = 0;
      for (final Map<String, dynamic> b in baris) {
        if (b['id'] == id) {
          b['status'] = status.name;
          b['alasan_batal'] = alasan;
          ketemu++;
        }
      }
      if (ketemu == 0) {
        return const Hasil<void>.galat(
          GalatData('Order tidak ditemukan di perangkat ini.'),
        );
      }
      await _simpan(kunci, baris);
      return Hasil<void>.berhasil(null);
    } catch (e) {
      return Hasil<void>.galat(GalatData('Gagal membatalkan order: $e'));
    }
  }

  @override
  Future<Hasil<List<OrderJastip>>> daftarJastip() async {
    final List<Map<String, dynamic>> baris = await _muat(kunciJastip);
    return Hasil<List<OrderJastip>>.berhasil(
      baris.map(OrderJastip.dari).toList(growable: false),
    );
  }

  @override
  Future<Hasil<List<OrderOjek>>> daftarOjek() async {
    final List<Map<String, dynamic>> baris = await _muat(kunciOjek);
    return Hasil<List<OrderOjek>>.berhasil(
      baris.map(OrderOjek.dari).toList(growable: false),
    );
  }

  @override
  Future<Hasil<OrderJastip>> kirimJastip(OrderJastip order) => _tambahJastip(order);

  @override
  Future<Hasil<OrderOjek>> kirimOjek(OrderOjek order) => _tambahOjek(order);

  @override
  Future<Hasil<void>> batalJastip(String id, String alasan) =>
      _batal(kunciJastip, id, alasan, StatusOrder.batal);

  @override
  Future<Hasil<void>> batalOjek(String id, String alasan) =>
      _batal(kunciOjek, id, alasan, StatusOrder.batal);

  @override
  Future<Hasil<List<OrderRingkas>>> aktif() async {
    final Hasil<List<OrderJastip>> j = await daftarJastip();
    final Hasil<List<OrderOjek>> o = await daftarOjek();
    final List<OrderRingkas> semua = <OrderRingkas>[
      ...(j.data ?? const <OrderJastip>[]).map(OrderRingkas.dariJastip),
      ...(o.data ?? const <OrderOjek>[]).map(OrderRingkas.dariOjek),
    ]..sort((OrderRingkas a, OrderRingkas b) => b.dibuat.compareTo(a.dibuat));
    return Hasil<List<OrderRingkas>>.berhasil(
      semua.where((OrderRingkas x) => x.aktif).toList(growable: false),
    );
  }
}

/// Id lokal tanpa paket uuid: cukup unik per perangkat.
String _idBaru() {
  final int ms = DateTime.now().millisecondsSinceEpoch;
  final int acak = DateTime.now().microsecondsSinceEpoch % 1000000;
  return 'local-$ms-$acak';
}

/// Bocor id dengan `warga_id` milik orang lain? Dipakai sebelum insert ke
/// server supaya order tidak pernah menimpa milik orang.
bool milikSendiri(Map<String, dynamic> baris, String wargaKunci) =>
    baris['warga_kunci'] == wargaKunci;