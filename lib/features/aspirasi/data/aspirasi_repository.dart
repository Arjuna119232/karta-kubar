import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';
import '../../../core/data/hasil.dart';
import '../../../core/data/supabase_rest.dart';
import '../domain/aspirasi.dart';

/// Kontrak sumber data FISH warga.
///
/// Layar hanya bicara ke interface ini. Mode lokal benar-benar MENYIMPAN
/// laporan yang dikirim warga di perangkat (SharedPreferences), jadi laporan
/// yang sudah dikirim tidak hilang saat aplikasi ditutup - itu beda dari
/// data demo kegiatan/berita yang hanya contoh statis.
abstract class AspirasiRepository {
  String get namaSumber;

  Future<Hasil<List<Aspirasi>>> daftar();

  /// Simpan FISH baru. Mengembalikan FISH yang benar-benar tersimpan.
  Future<Hasil<Aspirasi>> kirim(Aspirasi a);

  /// Ubah status satu FISH oleh pengurus. [catatan] opsional jadi balasan.
  Future<Hasil<Aspirasi>> ubahStatus(
    String id,
    StatusAspirasi status, {
    String? catatan,
  });
}

/// Sumber data di perangkat: SharedPreferences + 3 baris contoh bawaan.
class AspirasiLokalRepository implements AspirasiRepository {
  const AspirasiLokalRepository();

  /// Satu kunci = satu daftar. Jangan tulis ulang string ini di tempat lain.
  static const String kunci = 'kubar_aspirasi_v1';

  @override
  String get namaSumber => 'Tersimpan di perangkat';

  /// 3 FISH contoh supaya layarnya tidak kosong pertama kali dibuka.
  ///
  /// Semuanya ditandai `contoh: true`, dan layar wajib menampilkan label
  /// "contoh" pada kartu itu. Baris contoh TIDAK ikut ditulis ke
  /// SharedPreferences, jadi begitu warga mengirim laporan sungguhan, yang
  /// tampil hanya laporan asli.
  static List<Aspirasi> contoh() {
    final DateTime now = DateTime.now();
    return <Aspirasi>[
      Aspirasi(
        id: 'contoh-1',
        judul: 'Lampu jalan mati depan pos ronda',
        isi:
            'Lampu di jalan RT 03 menuju pos ronda mati sejak tiga malam. '
            'Warga yang lewat jadi gelap dan berisiko celaka.',
        kategori: KategoriAspirasi.jalan,
        status: StatusAspirasi.baru,
        dibuat: now.subtract(const Duration(hours: 6)),
        pengirim: 'Warga RT 03',
        rt: '03',
        rw: '05',
        contoh: true,
      ),
      Aspirasi(
        id: 'contoh-2',
        judul: 'Sampah menumpuk di sisi kali',
        isi:
            'Penampung sampah di sisi kali sudah penuh dua hari. '
            'Mohon jadwal angkut yang jelas dan diberitahukan ke warga.',
        kategori: KategoriAspirasi.kebersihan,
        status: StatusAspirasi.diproses,
        dibuat: now.subtract(const Duration(days: 2)),
        pengirim: 'Warga RT 07',
        rt: '07',
        rw: '05',
        contoh: true,
      ),
      Aspirasi(
        id: 'contoh-3',
        judul: 'Jam layanan balai RW belum jelas',
        isi:
            'Saran agar jam layanan balai RW ditempel di papan depan '
            'supaya warga tidak datang saat kantor tutup.',
        kategori: KategoriAspirasi.layanan,
        status: StatusAspirasi.selesai,
        dibuat: now.subtract(const Duration(days: 9)),
        pengirim: 'Warga RT 01',
        rt: '01',
        rw: '05',
        balasan: 'Jam layanan sudah ditempel di papan depan balai.',
        contoh: true,
      ),
    ];
  }

  @override
  Future<Hasil<List<Aspirasi>>> daftar() async {
    final Hasil<List<Aspirasi>> tersimpan = await _baca();
    if (!tersimpan.berhasil) return tersimpan;
    // Baris contoh selalu di depan, laporan asli menyusul.
    return Hasil<List<Aspirasi>>.berhasil(<Aspirasi>[
      ...contoh(),
      ...tersimpan.data!,
    ]);
  }

  @override
  Future<Hasil<Aspirasi>> kirim(Aspirasi a) async {
    final Hasil<List<Aspirasi>> r = await _baca();
    if (!r.berhasil) return Hasil<Aspirasi>.galat(r.galat!);
    await _tulis(<Aspirasi>[a, ...r.data!]);
    return Hasil<Aspirasi>.berhasil(a);
  }

  @override
  Future<Hasil<Aspirasi>> ubahStatus(
    String id,
    StatusAspirasi status, {
    String? catatan,
  }) async {
    final Hasil<List<Aspirasi>> r = await _baca();
    if (!r.berhasil) return Hasil<Aspirasi>.galat(r.galat!);
    final List<Aspirasi> lama = r.data!;
    final int i = lama.indexWhere((Aspirasi a) => a.id == id);
    if (i < 0) {
      return const Hasil<Aspirasi>.galat(
        GalatData('Laporan itu tidak ada di daftar.', kode: 'tidak_ditemukan'),
      );
    }
    final Aspirasi baru = lama[i].denganStatus(status, catatan: catatan);
    final List<Aspirasi> hasil = List<Aspirasi>.of(lama)..[i] = baru;
    await _tulis(hasil);
    return Hasil<Aspirasi>.berhasil(baru);
  }

  Future<Hasil<List<Aspirasi>>> _baca() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? json = p.getString(kunci);
      if (json == null || json.isEmpty) {
        return const Hasil<List<Aspirasi>>.berhasil(<Aspirasi>[]);
      }
      final dynamic decoded = jsonDecode(json);
      if (decoded is! List) {
        return const Hasil<List<Aspirasi>>.berhasil(<Aspirasi>[]);
      }
      return Hasil<List<Aspirasi>>.berhasil(
        decoded
            .whereType<Map<String, dynamic>>()
            .map(Aspirasi.dariBaris)
            .toList(growable: false),
      );
    } catch (e) {
      return Hasil<List<Aspirasi>>.galat(
        GalatData('Penyimpanan perangkat tidak bisa dibaca: $e',
            kode: 'penyimpanan_gagal'),
      );
    }
  }

  Future<void> _tulis(List<Aspirasi> data) async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    await p.setString(
      kunci,
      jsonEncode(data.map((Aspirasi a) => a.keBaris()).toList()),
    );
  }
}

/// Sumber data Supabase (tabel `aspirasi`).
class AspirasiSupabaseRepository implements AspirasiRepository {
  AspirasiSupabaseRepository(this._rest);

  final SupabaseRest _rest;

  @override
  String get namaSumber => 'Supabase';

  @override
  Future<Hasil<List<Aspirasi>>> daftar() async {
    final Hasil<List<Map<String, dynamic>>> r =
        await _rest.baca('aspirasi', urut: 'dibuat.desc', batas: 200);
    return r.peta((rows) => rows.map(Aspirasi.dariBaris).toList(growable: false));
  }

  @override
  Future<Hasil<Aspirasi>> kirim(Aspirasi a) async {
    final Hasil<void> r = await _rest.sisip('aspirasi', a.keBaris());
    return r.peta((_) => a);
  }

  @override
  Future<Hasil<Aspirasi>> ubahStatus(
    String id,
    StatusAspirasi status, {
    String? catatan,
  }) async {
    final Hasil<void> r = await _rest.ubah(
      'aspirasi',
      <String, dynamic>{
        'status': status.name,
        if (catatan != null && catatan.isNotEmpty) 'balasan': catatan,
      },
      <String, String>{'id': id},
    );
    if (!r.berhasil) return Hasil<Aspirasi>.galat(r.galat!);
    // Baris yang baru diubah dibaca lagi supaya isi kartu di layar sama
    // persis dengan yang tersimpan di server (bukan objek tiruan yang
    // judulnya kosong).
    final Hasil<List<Map<String, dynamic>>> lagi =
        await _rest.baca('aspirasi', filter: <String, String>{'id': id});
    if (!lagi.berhasil || lagi.data!.isEmpty) {
      return Hasil<Aspirasi>.galat(
        r.galat ??
            const GalatData('Status tersimpan, tapi barisnya tidak terbaca lagi.',
                kode: 'baca_ulang_gagal'),
      );
    }
    return Hasil<Aspirasi>.berhasil(Aspirasi.dariBaris(lagi.data!.first));
  }
}

AspirasiRepository buatAspirasiRepository() {
  if (AppConfig.pakaiSupabase) {
    return AspirasiSupabaseRepository(SupabaseRest(env: AppConfig.env));
  }
  return const AspirasiLokalRepository();
}
