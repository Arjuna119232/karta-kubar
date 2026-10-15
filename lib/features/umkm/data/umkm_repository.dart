import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';
import '../../../core/data/hasil.dart';
import '../../../core/data/supabase_rest.dart';
import '../domain/umkm.dart';

/// Kontrak sumber data UMKM warga.
///
/// Sama seperti repository FISH: laporan yang benar-benar dikirim warga
/// DITAMPILKAN, laporan yang masih contoh diberi label, dan baris contoh
/// tidak ikut ditulis ke penyimpanan.
abstract class UmkmRepository {
  String get namaSumber;

  Future<Hasil<List<Umkm>>> daftar();

  Future<Hasil<Umkm>> ajukan(Umkm u);

  Future<Hasil<Umkm>> verifikasi(String id, bool ya);
}

class UmkmLokalRepository implements UmkmRepository {
  const UmkmLokalRepository();

  static const String kunci = 'kubar_umkm_v1';

  @override
  String get namaSumber => 'Tersimpan di perangkat';

  static List<Umkm> contoh() => <Umkm>[
        Umkm(
          id: 'contoh-1',
          nama: 'Warung Bu Imas',
          kategori: KategoriUmkm.makanan,
          deskripsi: 'Nasi campur, pecel, dan gorengan. Masak pagi sampai '
              'malam. Pesan bisa lewat WhatsApp.',
          alamat: 'Jl. Melati RT 03 / RW 05',
          noTelepon: '0812xxxx0001',
          jamBuka: '06.30 - 21.00',
          diverifikasi: true,
          contoh: true,
        ),
        Umkm(
          id: 'contoh-2',
          nama: 'Laundry Kilat KUNBAR',
          kategori: KategoriUmkm.jasa,
          deskripsi: 'Cuci satuan dan kilo, layanan antar dalam RW 05.',
          alamat: 'Jl. Kenanga RT 05 / RW 05',
          noTelepon: '0812xxxx0002',
          jamBuka: '08.00 - 19.00',
          diverifikasi: true,
          contoh: true,
        ),
        Umkm(
          id: 'contoh-3',
          nama: 'Batik Tangan Pertama',
          kategori: KategoriUmkm.kerajinan,
          deskripsi: 'Kain batik tulis warna alami, bisa pesen motif sendiri.',
          alamat: 'RT 07 / RW 05',
          diverifikasi: false,
          contoh: true,
        ),
      ];

  @override
  Future<Hasil<List<Umkm>>> daftar() async {
    final Hasil<List<Umkm>> simpan = await _baca();
    if (!simpan.berhasil) return simpan;
    return Hasil<List<Umkm>>.berhasil(<Umkm>[...contoh(), ...simpan.data!]);
  }

  @override
  Future<Hasil<Umkm>> ajukan(Umkm u) async {
    final Hasil<List<Umkm>> r = await _baca();
    if (!r.berhasil) return Hasil<Umkm>.galat(r.galat!);
    await _tulis(<Umkm>[u, ...r.data!]);
    return Hasil<Umkm>.berhasil(u);
  }

  @override
  Future<Hasil<Umkm>> verifikasi(String id, bool ya) async {
    final Hasil<List<Umkm>> r = await _baca();
    if (!r.berhasil) return Hasil<Umkm>.galat(r.galat!);
    final List<Umkm> lama = r.data!;
    final int i = lama.indexWhere((Umkm u) => u.id == id);
    if (i < 0) {
      return const Hasil<Umkm>.galat(
        GalatData('Usaha itu tidak ada di daftar.', kode: 'tidak_ditemukan'),
      );
    }
    final List<Umkm> hasil = List<Umkm>.of(lama)
      ..[i] = lama[i].denganVerifikasi(ya);
    await _tulis(hasil);
    return Hasil<Umkm>.berhasil(hasil[i]);
  }

  Future<Hasil<List<Umkm>>> _baca() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? json = p.getString(kunci);
      if (json == null || json.isEmpty) {
        return const Hasil<List<Umkm>>.berhasil(<Umkm>[]);
      }
      final dynamic decoded = jsonDecode(json);
      if (decoded is! List) {
        return const Hasil<List<Umkm>>.berhasil(<Umkm>[]);
      }
      return Hasil<List<Umkm>>.berhasil(
        decoded.whereType<Map<String, dynamic>>().map(Umkm.dariBaris).toList(),
      );
    } catch (e) {
      return Hasil<List<Umkm>>.galat(
        GalatData('Penyimpanan perangkat tidak bisa dibaca: $e',
            kode: 'penyimpanan_gagal'),
      );
    }
  }

  Future<void> _tulis(List<Umkm> data) async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    await p.setString(kunci, jsonEncode(data.map((Umkm u) => u.keBaris()).toList()));
  }
}

class UmkmSupabaseRepository implements UmkmRepository {
  UmkmSupabaseRepository(this._rest);

  final SupabaseRest _rest;

  @override
  String get namaSumber => 'Supabase';

  @override
  Future<Hasil<List<Umkm>>> daftar() async {
    final Hasil<List<Map<String, dynamic>>> r =
        await _rest.baca('umkm', urut: 'dibuat.desc', batas: 200);
    return r.peta((rows) => rows.map(Umkm.dariBaris).toList(growable: false));
  }

  @override
  Future<Hasil<Umkm>> ajukan(Umkm u) async {
    // Kolom `id` TIDAK ikut dikirim untuk usaha baru: id-nya dibuat database
    // (uuid). Yang dikirim hanya baris yang diizinkan policy.
    final Map<String, dynamic> baris = u.keBaris()..remove('id');
    final Hasil<void> r = await _rest.sisip('umkm', baris);
    return r.peta((_) => u);
  }

  @override
  Future<Hasil<Umkm>> verifikasi(String id, bool ya) async {
    final Hasil<void> r = await _rest.ubah(
      'umkm',
      <String, dynamic>{'diverifikasi': ya},
      <String, String>{'id': id},
    );
    if (!r.berhasil) return Hasil<Umkm>.galat(r.galat!);
    final Hasil<List<Map<String, dynamic>>> lagi =
        await _rest.baca('umkm', filter: <String, String>{'id': id}, batas: 1);
    if (!lagi.berhasil || lagi.data!.isEmpty) {
      return const Hasil<Umkm>.galat(
        GalatData('Status tersimpan tapi barisnya tidak terbaca lagi.',
            kode: 'baca_ulang_gagal'),
      );
    }
    return Hasil<Umkm>.berhasil(Umkm.dariBaris(lagi.data!.first));
  }
}

UmkmRepository buatUmkmRepository() {
  if (AppConfig.pakaiSupabase) {
    return UmkmSupabaseRepository(SupabaseRest(env: AppConfig.env));
  }
  return const UmkmLokalRepository();
}

final Provider<UmkmRepository> umkmRepositoryProvider =
    Provider<UmkmRepository>((ref) => buatUmkmRepository());

/// Daftar UMKM + aksi ajukan / verifikasi. Selalu muat ulang setelah
/// perubahan, sama seperti FISH.
class UmkmNotifier extends AsyncNotifier<List<Umkm>> {
  @override
  Future<List<Umkm>> build() async {
    final Hasil<List<Umkm>> h = await ref.watch(umkmRepositoryProvider).daftar();
    return h.berhasil ? h.data! : <Umkm>[];
  }

  Future<Hasil<Umkm>> ajukan({
    required String nama,
    required String deskripsi,
    required String alamat,
    required KategoriUmkm kategori,
    String? noTelepon,
    String? jamBuka,
  }) async {
    final Umkm u = Umkm(
      id: 'umkm-${DateTime.now().millisecondsSinceEpoch}',
      nama: nama.trim(),
      deskripsi: deskripsi.trim(),
      alamat: alamat.trim(),
      kategori: kategori,
      noTelepon: noTelepon,
      jamBuka: jamBuka,
    );
    final Hasil<Umkm> h = await ref.read(umkmRepositoryProvider).ajukan(u);
    await muatUlang();
    return h;
  }

  Future<void> muatUlang() async {
    final Hasil<List<Umkm>> h = await ref.read(umkmRepositoryProvider).daftar();
    state = AsyncValue<List<Umkm>>.data(h.berhasil ? h.data! : <Umkm>[]);
  }
}

final AsyncNotifierProvider<UmkmNotifier, List<Umkm>> umkmProvider =
    AsyncNotifierProvider<UmkmNotifier, List<Umkm>>(UmkmNotifier.new);