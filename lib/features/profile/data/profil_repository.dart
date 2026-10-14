import '../../../core/config/app_config.dart';
import '../../../core/data/hasil.dart';
import '../../../core/data/supabase_rest.dart';
import '../domain/anggota.dart';
import 'profil_lokal.dart';

/// Kontrak sumber data profil.
abstract class ProfilRepository {
  String get namaSumber;

  Future<Hasil<Anggota>> anggota();
}

/// Sumber data di perangkat.
class ProfilLokalRepository implements ProfilRepository {
  const ProfilLokalRepository();

  @override
  String get namaSumber => 'Data demo di perangkat';

  @override
  Future<Hasil<Anggota>> anggota() async =>
      Hasil<Anggota>.berhasil(ProfilLokal.anggota);
}

/// Sumber data Supabase (tabel `profiles`, satu baris per pengguna).
///
/// Baris dibaca dengan filter `id` milik sesi, jadi RLS di server tetap
/// menjadi penjaga utama; kode aplikasi cuma mencobanya.
class ProfilSupabaseRepository implements ProfilRepository {
  ProfilSupabaseRepository(this._rest);

  final SupabaseRest _rest;

  @override
  String get namaSumber => 'Supabase';

  @override
  Future<Hasil<Anggota>> anggota() async {
    final String? uid = _rest.userId;
    if (uid == null || uid.isEmpty) {
      // Belum ada sesi -> tidak ada baris profil yang boleh dibaca.
      return const Hasil<Anggota>.galat(
        GalatData('Belum masuk, jadi profil tidak bisa dimuat.', kode: 'belum_login'),
      );
    }
    final Hasil<List<Map<String, dynamic>>> r =
        await _rest.baca('profiles', filter: <String, String>{'id': uid});
    return r.peta((rows) => rows.isEmpty ? ProfilLokal.anggota : Anggota.dariBaris(rows.first));
  }
}

ProfilRepository buatProfilRepository() {
  if (AppConfig.pakaiSupabase) {
    return ProfilSupabaseRepository(SupabaseRest(env: AppConfig.env));
  }
  return const ProfilLokalRepository();
}
