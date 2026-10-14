import '../../../core/config/app_config.dart';
import '../../../core/data/hasil.dart';
import '../../../core/data/supabase_rest.dart';
import '../domain/keuangan.dart';
import 'keuangan_lokal.dart';

/// Kontrak sumber data keuangan.
abstract class KeuanganRepository {
  String get namaSumber;

  Future<Hasil<List<Iuran>>> daftarIuran();

  Future<Hasil<List<KasBulanan>>> daftarKasBulanan();
}

/// Sumber data di perangkat.
class KeuanganLokalRepository implements KeuanganRepository {
  const KeuanganLokalRepository();

  @override
  String get namaSumber => 'Data demo di perangkat';

  @override
  Future<Hasil<List<Iuran>>> daftarIuran() async =>
      Hasil<List<Iuran>>.berhasil(KeuanganLokal.iuran);

  @override
  Future<Hasil<List<KasBulanan>>> daftarKasBulanan() async =>
      Hasil<List<KasBulanan>>.berhasil(KeuanganLokal.kasBulanan);
}

/// Sumber data Supabase (tabel `iuran`, `kas_bulanan`).
class KeuanganSupabaseRepository implements KeuanganRepository {
  KeuanganSupabaseRepository(this._rest);

  final SupabaseRest _rest;

  @override
  String get namaSumber => 'Supabase';

  @override
  Future<Hasil<List<Iuran>>> daftarIuran() async {
    final Hasil<List<Map<String, dynamic>>> r =
        await _rest.baca('iuran', urut: 'periode.desc');
    return r.peta(
      (rows) => rows.map(Iuran.dariBaris).toList(growable: false),
    );
  }

  @override
  Future<Hasil<List<KasBulanan>>> daftarKasBulanan() async {
    final Hasil<List<Map<String, dynamic>>> r =
        await _rest.baca('kas_bulanan', urut: 'label.asc');
    return r.peta(
      (rows) => rows.map(KasBulanan.dariBaris).toList(growable: false),
    );
  }
}

KeuanganRepository buatKeuanganRepository() {
  if (AppConfig.pakaiSupabase) {
    return KeuanganSupabaseRepository(SupabaseRest(env: AppConfig.env));
  }
  return const KeuanganLokalRepository();
}
