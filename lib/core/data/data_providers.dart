import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'hasil.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/kegiatan/data/kegiatan_repository.dart';
import '../../features/kegiatan/domain/kegiatan.dart';
import '../../features/keuangan/data/keuangan_repository.dart';
import '../../features/keuangan/domain/keuangan.dart';
import '../../features/profile/data/profil_repository.dart';
import '../../features/profile/domain/anggota.dart';

/// SATU tempat untuk menentukan sumber data yang dipakai aplikasi.
///
/// Inilah gunanya lapisan repository: layar tidak pernah tahu datanya datang
/// dari perangkat atau dari Supabase. Mengganti backend cukup mengubah
/// `SUMBER_DATA` di `.env`, tanpa menyentuh `presentation/`.
final Provider<KegiatanRepository> kegiatanRepositoryProvider =
    Provider<KegiatanRepository>((ref) => buatKegiatanRepository());

final Provider<KeuanganRepository> keuanganRepositoryProvider =
    Provider<KeuanganRepository>((ref) => buatKeuanganRepository());

final Provider<ProfilRepository> profilRepositoryProvider =
    Provider<ProfilRepository>((ref) => buatProfilRepository());

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((ref) => buatAuthRepository());

/// Ringkasan backend untuk halaman Profil / Pengaturan.
class StatusBackend {
  const StatusBackend({
    required this.sumber,
    required this.supabaseSiap,
    required this.ringkasanKunci,
  });

  final String sumber;
  final bool supabaseSiap;
  final String ringkasanKunci;
}

/// Status backend sekarang, dibaca sekali.
final Provider<StatusBackend> statusBackendProvider = Provider<StatusBackend>((ref) {
  return StatusBackend(
    sumber: ref.read(authRepositoryProvider).namaSumber,
    supabaseSiap: AppConfig.pakaiSupabase,
    ringkasanKunci: AppConfig.env.ringkasanAnonKey,
  );
});

/// Pemuat data kegiatan untuk layar.
class KegiatanNotifier extends AsyncNotifier<List<Kegiatan>> {
  @override
  Future<List<Kegiatan>> build() async {
    final KegiatanRepository repo = ref.watch(kegiatanRepositoryProvider);
    final Hasil<List<Kegiatan>> h = await repo.daftarKegiatan();
    return h.berhasil ? h.data! : <Kegiatan>[];
  }

  Future<void> muatUlang() async {
    state = const AsyncValue<List<Kegiatan>>.loading();
    state = await AsyncValue.guard(
      () async => (await ref.read(kegiatanRepositoryProvider).daftarKegiatan())
          .orLempar,
    );
  }
}

final AsyncNotifierProvider<KegiatanNotifier, List<Kegiatan>>
    kegiatanProvider =
    AsyncNotifierProvider<KegiatanNotifier, List<Kegiatan>>(
  KegiatanNotifier.new,
);

/// Data keuangan untuk layar.
class KeuanganNotifier extends AsyncNotifier<List<Iuran>> {
  @override
  Future<List<Iuran>> build() async {
    final Hasil<List<Iuran>> h =
        await ref.watch(keuanganRepositoryProvider).daftarIuran();
    return h.berhasil ? h.data! : <Iuran>[];
  }

  Future<List<KasBulanan>> kas() async {
    final Hasil<List<KasBulanan>> h =
        await ref.read(keuanganRepositoryProvider).daftarKasBulanan();
    return h.berhasil ? h.data! : <KasBulanan>[];
  }
}

final AsyncNotifierProvider<KeuanganNotifier, List<Iuran>> iuranProvider =
    AsyncNotifierProvider<KeuanganNotifier, List<Iuran>>(
  KeuanganNotifier.new,
);

/// Data profil untuk layar.
class ProfilNotifier extends AsyncNotifier<Anggota> {
  @override
  Future<Anggota> build() async {
    final Hasil<Anggota> h = await ref.watch(profilRepositoryProvider).anggota();
    return h.berhasil ? h.data! : Anggota.kosong;
  }
}

final AsyncNotifierProvider<ProfilNotifier, Anggota> profilProvider =
    AsyncNotifierProvider<ProfilNotifier, Anggota>(ProfilNotifier.new);

/// Berita + pengumuman untuk beranda.
class BerandaNotifier extends AsyncNotifier<List<Berita>> {
  @override
  Future<List<Berita>> build() async {
    final KegiatanRepository repo = ref.watch(kegiatanRepositoryProvider);
    final Hasil<List<Berita>> h = await repo.daftarBerita();
    return h.berhasil ? h.data! : <Berita>[];
  }

  Future<List<Pengumuman>> pengumuman() async {
    final Hasil<List<Pengumuman>> h =
        await ref.read(kegiatanRepositoryProvider).daftarPengumuman();
    return h.berhasil ? h.data! : <Pengumuman>[];
  }
}

final AsyncNotifierProvider<BerandaNotifier, List<Berita>> beritaProvider =
    AsyncNotifierProvider<BerandaNotifier, List<Berita>>(
  BerandaNotifier.new,
);

/// Dua angka untuk kartu statistik beranda: jumlah anggota dan jumlah kegiatan
/// bulan ini. diambil dari repository, BUKAN angka yang dipatok di layar.
final FutureProvider<(int anggota, int kegiatanBulanIni)>
    ringkasanBerandaProvider = FutureProvider<(int, int)>((ref) async {
  final KegiatanRepository repo = ref.watch(kegiatanRepositoryProvider);
  final Hasil<int> a = await repo.totalAnggota();
  final Hasil<int> k = await repo.kegiatanBulanIni();
  return (a.berhasil ? a.data! : 0, k.berhasil ? k.data! : 0);
});