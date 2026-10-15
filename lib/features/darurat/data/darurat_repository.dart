import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';
import '../../../core/data/hasil.dart';
import '../../../core/data/supabase_rest.dart';
import '../domain/darurat.dart';

abstract class DaruratRepository {
  String get namaSumber;

  Future<Hasil<List<LaporanDarurat>>> daftar();

  Future<Hasil<LaporanDarurat>> kirim(LaporanDarurat d);
}

class DaruratLokalRepository implements DaruratRepository {
  const DaruratLokalRepository();

  static const String kunci = 'kubar_darurat_v1';

  @override
  String get namaSumber => 'Tersimpan di perangkat';

  @override
  Future<Hasil<List<LaporanDarurat>>> daftar() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? json = p.getString(kunci);
      if (json == null || json.isEmpty) {
        return const Hasil<List<LaporanDarurat>>.berhasil(<LaporanDarurat>[]);
      }
      final dynamic decoded = jsonDecode(json);
      if (decoded is! List) {
        return const Hasil<List<LaporanDarurat>>.berhasil(<LaporanDarurat>[]);
      }
      return Hasil<List<LaporanDarurat>>.berhasil(
        decoded
            .whereType<Map<String, dynamic>>()
            .map(LaporanDarurat.dariBaris)
            .toList(growable: false),
      );
    } catch (e) {
      return Hasil<List<LaporanDarurat>>.galat(
        GalatData('Penyimpanan perangkat tidak bisa dibaca: $e',
            kode: 'penyimpanan_gagal'),
      );
    }
  }

  @override
  Future<Hasil<LaporanDarurat>> kirim(LaporanDarurat d) async {
    final Hasil<List<LaporanDarurat>> r = await daftar();
    if (!r.berhasil) return Hasil<LaporanDarurat>.galat(r.galat!);
    await _tulis(<LaporanDarurat>[d, ...r.data!]);
    return Hasil<LaporanDarurat>.berhasil(d);
  }

  Future<void> _tulis(List<LaporanDarurat> data) async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    await p.setString(
      kunci,
      jsonEncode(data.map((LaporanDarurat d) => d.keBaris()).toList()),
    );
  }
}

class DaruratSupabaseRepository implements DaruratRepository {
  DaruratSupabaseRepository(this._rest);

  final SupabaseRest _rest;

  @override
  String get namaSumber => 'Supabase';

  @override
  Future<Hasil<List<LaporanDarurat>>> daftar() async {
    final Hasil<List<Map<String, dynamic>>> r =
        await _rest.baca('darurat', urut: 'dibuat.desc', batas: 100);
    return r.peta((rows) => rows.map(LaporanDarurat.dariBaris).toList(growable: false));
  }

  @override
  Future<Hasil<LaporanDarurat>> kirim(LaporanDarurat d) async {
    final Map<String, dynamic> baris = d.keBaris()..remove('id');
    final Hasil<void> r = await _rest.sisip('darurat', baris);
    return r.peta((_) => d);
  }
}

DaruratRepository buatDaruratRepository() {
  if (AppConfig.pakaiSupabase) {
    return DaruratSupabaseRepository(SupabaseRest(env: AppConfig.env));
  }
  return const DaruratLokalRepository();
}

final Provider<DaruratRepository> daruratRepositoryProvider =
    Provider<DaruratRepository>((ref) => buatDaruratRepository());

/// Laporan darurat milik pengguna ini + status penanganannya.
class DaruratNotifier extends AsyncNotifier<List<LaporanDarurat>> {
  @override
  Future<List<LaporanDarurat>> build() async {
    final Hasil<List<LaporanDarurat>> h =
        await ref.watch(daruratRepositoryProvider).daftar();
    return h.berhasil ? h.data! : <LaporanDarurat>[];
  }

  Future<Hasil<LaporanDarurat>> kirim({
    required JenisDarurat jenis,
    required String lokasi,
    required String keterangan,
    required String pengirim,
  }) async {
    final LaporanDarurat d = LaporanDarurat(
      id: 'dar-${DateTime.now().millisecondsSinceEpoch}',
      jenis: jenis,
      lokasi: lokasi.trim(),
      keterangan: keterangan.trim(),
      pengirim: pengirim,
      dibuat: DateTime.now(),
    );
    final Hasil<LaporanDarurat> h =
        await ref.read(daruratRepositoryProvider).kirim(d);
    await muatUlang();
    return h;
  }

  Future<void> muatUlang() async {
    final Hasil<List<LaporanDarurat>> h =
        await ref.read(daruratRepositoryProvider).daftar();
    state = AsyncValue<List<LaporanDarurat>>.data(
      h.berhasil ? h.data! : <LaporanDarurat>[],
    );
  }
}

final AsyncNotifierProvider<DaruratNotifier, List<LaporanDarurat>>
    daruratProvider =
    AsyncNotifierProvider<DaruratNotifier, List<LaporanDarurat>>(
  DaruratNotifier.new,
);