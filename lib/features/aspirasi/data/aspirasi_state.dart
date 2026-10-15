import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/hasil.dart';
import '../domain/aspirasi.dart';
import 'aspirasi_repository.dart';

/// Sumber data FISH yang aktif (lokal atau Supabase).
final Provider<AspirasiRepository> aspirasiRepositoryProvider =
    Provider<AspirasiRepository>((ref) => buatAspirasiRepository());

/// Daftar FISH + aksi kirim / ubah status.
///
/// Setiap perubahan SELALU memuat ulang daftar dari repository, bukan
/// menebak-nebak state di memori. Kalau optimasi lokal tanpa muat ulang,
/// layar bisa menampilkan FISH "berhasil dikirim" padahal penyimpanan
/// gagal.
class AspirasiNotifier extends AsyncNotifier<List<Aspirasi>> {
  @override
  Future<List<Aspirasi>> build() async {
    final Hasil<List<Aspirasi>> h =
        await ref.watch(aspirasiRepositoryProvider).daftar();
    return h.berhasil ? h.data! : <Aspirasi>[];
  }

  Future<Hasil<Aspirasi>> kirim({
    required String judul,
    required String isi,
    required KategoriAspirasi kategori,
    required String pengirim,
    String? rt,
    String? rw,
  }) async {
    final Aspirasi a = Aspirasi(
      id: 'fish-${DateTime.now().millisecondsSinceEpoch}',
      judul: judul.trim(),
      isi: isi.trim(),
      kategori: kategori,
      status: StatusAspirasi.baru,
      dibuat: DateTime.now(),
      pengirim: pengirim,
      rt: rt,
      rw: rw,
    );
    final Hasil<Aspirasi> h =
        await ref.read(aspirasiRepositoryProvider).kirim(a);
    await muatUlang();
    return h;
  }

  Future<Hasil<Aspirasi>> ubahStatus(
    String id,
    StatusAspirasi status, {
    String? catatan,
  }) async {
    final Hasil<Aspirasi> h = await ref
        .read(aspirasiRepositoryProvider)
        .ubahStatus(id, status, catatan: catatan);
    await muatUlang();
    return h;
  }

  Future<void> muatUlang() async {
    final Hasil<List<Aspirasi>> h =
        await ref.read(aspirasiRepositoryProvider).daftar();
    state =
        AsyncValue<List<Aspirasi>>.data(h.berhasil ? h.data! : <Aspirasi>[]);
  }
}

final AsyncNotifierProvider<AspirasiNotifier, List<Aspirasi>>aspirasiProvider =
    AsyncNotifierProvider<AspirasiNotifier, List<Aspirasi>>(
  AspirasiNotifier.new,
);

/// Ringkasan jumlah FISH per status, untuk kartu statistik.
class RekapAspirasi {
  const RekapAspirasi({
    required this.baru,
    required this.diproses,
    required this.selesai,
    required this.ditolak,
  });

  static const RekapAspirasi kosong =
      RekapAspirasi(baru: 0, diproses: 0, selesai: 0, ditolak: 0);

  factory RekapAspirasi.dari(List<Aspirasi> data) {
    int baru = 0;
    int diproses = 0;
    int selesai = 0;
    int ditolak = 0;
    for (final Aspirasi a in data) {
      switch (a.status) {
        case StatusAspirasi.baru:
          baru++;
        case StatusAspirasi.diproses:
          diproses++;
        case StatusAspirasi.selesai:
          selesai++;
        case StatusAspirasi.ditolak:
          ditolak++;
      }
    }
    return RekapAspirasi(
      baru: baru,
      diproses: diproses,
      selesai: selesai,
      ditolak: ditolak,
    );
  }

  final int baru;
  final int diproses;
  final int selesai;
  final int ditolak;

  int get total => baru + diproses + selesai + ditolak;

  /// Yang masih butuh tindakan pengurus.
  int get perluTindakan => baru + diproses;
}

/// Urutan antrean: status paling baru (belum ditangani) di atas, lalu yang
/// paling baru dibuat.
List<Aspirasi> urutPrioritas(List<Aspirasi> data) {
  final List<Aspirasi> x = List<Aspirasi>.of(data)
    ..sort((Aspirasi a, Aspirasi b) {
      final int s = a.status.prioritas.compareTo(b.status.prioritas);
      if (s != 0) return s;
      return b.dibuat.compareTo(a.dibuat);
    });
  return x;
}

/// Rekap untuk layar, ikut berubah kalau daftarnya berubah.
final Provider<RekapAspirasi> rekapAspirasiProvider =
    Provider<RekapAspirasi>((ref) {
  final List<Aspirasi> data =
      ref.watch(aspirasiProvider).valueOrNull ?? <Aspirasi>[];
  return RekapAspirasi.dari(data);
});
