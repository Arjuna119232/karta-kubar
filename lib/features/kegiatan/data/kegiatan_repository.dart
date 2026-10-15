import '../../../core/config/app_config.dart';
import '../../../core/data/hasil.dart';
import '../../../core/data/supabase_rest.dart';
import '../domain/kegiatan.dart';
import 'kegiatan_lokal.dart';

/// Kontrak sumber data kegiatan.
///
/// LAYER ATAS (layar, provider) hanya boleh bicara ke interface ini: tidak
/// pernah langsung ke Supabase dan tidak pernah langsung ke data demo. Kalau
/// nanti backend-nya ganti, cukup ganti implementasi di
/// [buatKegiatanRepository] tanpa menyentuh satu baris pun di `presentation/`.
abstract class KegiatanRepository {
  /// Nama sumber aktif, untuk ditampilkan di Pengaturan.
  String get namaSumber;

  Future<Hasil<List<Kegiatan>>> daftarKegiatan({
    String? kategori,
    bool hanyaMendatang = false,
  });

  Future<Hasil<List<Berita>>> daftarBerita();

  Future<Hasil<List<Pengumuman>>> daftarPengumuman();

  Future<Hasil<int>> totalAnggota();

  Future<Hasil<int>> kegiatanBulanIni();
}

/// Sumber data di perangkat. Selalu berhasil, tidak butuh internet.
class KegiatanLokalRepository implements KegiatanRepository {
  const KegiatanLokalRepository();

  @override
  String get namaSumber => 'Data demo di perangkat';

  @override
  Future<Hasil<List<Kegiatan>>> daftarKegiatan({
    String? kategori,
    bool hanyaMendatang = false,
  }) async {
    Iterable<Kegiatan> x = KegiatanLokal.kegiatan;
    if (kategori != null && kategori != 'Semua') {
      x = x.where((Kegiatan k) => k.kategori == kategori);
    }
    if (hanyaMendatang) x = x.where((Kegiatan k) => k.mendatang);
    return Hasil<List<Kegiatan>>.berhasil(x.toList(growable: false));
  }

  @override
  Future<Hasil<List<Berita>>> daftarBerita() async =>
      Hasil<List<Berita>>.berhasil(KegiatanLokal.berita);

  @override
  Future<Hasil<List<Pengumuman>>> daftarPengumuman() async =>
      Hasil<List<Pengumuman>>.berhasil(KegiatanLokal.pengumuman);

  @override
  Future<Hasil<int>> totalAnggota() async =>
      Hasil<int>.berhasil(KegiatanLokal.totalAnggota);

  @override
  Future<Hasil<int>> kegiatanBulanIni() async =>
      Hasil<int>.berhasil(KegiatanLokal.kegiatanBulanIni);
}

/// Sumber data Supabase (tabel `kegiatan`, `berita`, `pengumuman`).
class KegiatanSupabaseRepository implements KegiatanRepository {
  KegiatanSupabaseRepository(this._rest);

  final SupabaseRest _rest;

  @override
  String get namaSumber => 'Supabase';

  @override
  Future<Hasil<List<Kegiatan>>> daftarKegiatan({
    String? kategori,
    bool hanyaMendatang = false,
  }) async {
    final Hasil<List<Map<String, dynamic>>> r =
        await _rest.baca('kegiatan', urut: 'tanggal.asc');
    return r.peta((rows) {
      final List<Kegiatan> semua = rows
          .map(Kegiatan.dariBaris)
          .toList(growable: false);
      return semua
          .where((Kegiatan k) =>
              (kategori == null || kategori == 'Semua' || k.kategori == kategori) &&
              (!hanyaMendatang || k.mendatang))
          .toList(growable: false);
    });
  }

  @override
  Future<Hasil<List<Berita>>> daftarBerita() async {
    final Hasil<List<Map<String, dynamic>>> r =
        await _rest.baca('berita', urut: 'waktu.desc');
    return r.peta(
      (rows) => rows.map(Berita.dariBaris).toList(growable: false),
    );
  }

  @override
  Future<Hasil<List<Pengumuman>>> daftarPengumuman() async {
    final Hasil<List<Map<String, dynamic>>> r =
        await _rest.baca('pengumuman', urut: 'id.desc');
    return r.peta(
      (rows) => rows.map(Pengumuman.dariBaris).toList(growable: false),
    );
  }

  @override
  Future<Hasil<int>> totalAnggota() async =>
      // Tabel warga ada SATU: `profiles`. Semula kode ini membaca tabel
      // `anggota` yang tidak pernah dibuat di skema, jadi begitu backend
      // nyala, kartu "anggota terdaftar" selalu 0 tanpa error.
      _hitung('profiles', kolomHitung: 'id');

  @override
  Future<Hasil<int>> kegiatanBulanIni() async =>
      _hitung('kegiatan', kolomHitung: 'id');

  Future<Hasil<int>> _hitung(String tabel, {required String kolomHitung}) async {
    final Hasil<List<Map<String, dynamic>>> r =
        await _rest.baca(tabel, urut: '$kolomHitung.desc', batas: 1000);
    return r.peta((rows) => rows.length);
  }
}

/// Memilih implementasi mana yang dipakai, berdasarkan konfigurasi build.
///
/// Bawaannya `lokal` supaya aplikasi yang belum punya `.env` tetap jalan utuh.
/// Kalau `SUMBER_DATA=supabase` tapi konfigurasinya belum lengkap, fungsi
/// ini tetap memakai data lokal dan `namaSumber` mengatakannya ke pengguna.
KegiatanRepository buatKegiatanRepository() {
  if (AppConfig.pakaiSupabase) {
    return KegiatanSupabaseRepository(
      SupabaseRest(env: AppConfig.env),
    );
  }
  return const KegiatanLokalRepository();
}