import '../../core/data/hasil.dart';
import '../models/mitra_jasa.dart';
import '../models/order.dart';
import '../models/order_ojek.dart';
import '../models/order_ringkas.dart';
import '../models/order_tracking.dart';
import 'order_repository.dart';
import 'order_service_base.dart';
import 'tarif_service.dart';

/// Semua yang dibutuhkan layar order OJEK (ojek komunitas).
///
/// Sama seperti [JastipService], kelas ini tidak menyentuh widget supaya bisa
/// dipakai APK Mitra dan Web Admin tanpa perubahan.
class OjekService extends OrderServiceDasar {
  OjekService({
    required OrderRepository repo,
    Duration polling = const Duration(seconds: 8),
  }) : super(
          repo: repo,
          jenis: JenisOrder.ojek,
          detikPolling: polling,
        );

  static const JenisOrder jenisOrder = JenisOrder.ojek;

  /// Semua order (jastip + ojek). Dideklarasikan ulang supaya kontraknya
  /// terlihat jelas di kelas ini, bukan hanya di kelas induk.
  @override
  Future<Hasil<List<OrderRingkas>>> orderSaya() => super.orderSaya();

  /// Satu order berdasarkan id.
  @override
  Future<Hasil<OrderRingkas>> orderById(String id) => super.orderById(id);

  /// Order yang sedang berjalan.
  @override
  Future<Hasil<List<OrderRingkas>>> orderAktif() => super.orderAktif();

  /// Batalkan order warga sendiri.
  @override
  Future<Hasil<void>> batal(String id, String alasan) => super.batal(id, alasan);

  /// Buat order ojek baru.
  ///
  /// [mitra] boleh null: tanpa memilih driver, sistem yang menugaskan mitra
  /// terdekat. Statusnya tetap `menunggu`.
  Future<Hasil<OrderRingkas>> createOrder({
    required String kunciWarga,
    required String wargaNama,
    required String wargaNomor,
    required String lokasiJemput,
    required TitikPeta titikJemput,
    required String lokasiTujuan,
    required TitikPeta titikTujuan,
    required RingkasanTarif ringkasan,
    MitraJasa? mitra,
    String catatan = '',
    MetodeBayar metodeBayar = MetodeBayar.cash,
  }) async {
    final ValidasiOrder v = validasi(
      lokasiJemput: lokasiJemput,
      lokasiTujuan: lokasiTujuan,
    );
    if (!v.valid) {
      return Hasil<OrderRingkas>.galat(GalatData(v.pesan!, kode: v.field));
    }
    final DateTime sekarang = DateTime.now();
    final OrderOjek order = OrderOjek(
      id: '',
      kode: kodeOrder(JenisOrder.ojek, sekarang),
      wargaKunci: kunciWarga,
      wargaNama: wargaNama,
      wargaNomor: wargaNomor,
      mitraId: mitra?.id,
      lokasiJemput: lokasiJemput.trim(),
      latJemput: titikJemput.lat,
      lngJemput: titikJemput.lng,
      lokasiTujuan: lokasiTujuan.trim(),
      latTujuan: titikTujuan.lat,
      lngTujuan: titikTujuan.lng,
      jarakKm: ringkasan.jarakKm,
      durasiMenit: ringkasan.durasiMenit,
      tarif: ringkasan.tarif,
      catatan: catatan.trim(),
      metodeBayar: metodeBayar,
      status: StatusOrder.menunggu,
      dibuat: sekarang,
    );
    final Hasil<OrderOjek> h = await repo.kirimOjek(order);
    if (!h.berhasil) {
      return Hasil<OrderRingkas>.galat(h.galat ?? GalatData('Gagal mengirim.'));
    }
    return Hasil<OrderRingkas>.berhasil(OrderRingkas.dariOjek(h.data!));
  }

  /// Cek isi form sebelum submit.
  static ValidasiOrder validasi({
    required String lokasiJemput,
    required String lokasiTujuan,
  }) {
    if (lokasiJemput.trim().length < 3) {
      return const ValidasiOrder(
        pesan: 'Lokasi jemput belum jelas. Isi manual atau tekan ikon lokasi.',
        field: 'lokasiJemput',
      );
    }
    if (lokasiTujuan.trim().length < 3) {
      return const ValidasiOrder(
        pesan: 'Lokasi tujuan belum diisi.',
        field: 'lokasiTujuan',
      );
    }
    if (lokasiJemput.trim().toLowerCase() ==
        lokasiTujuan.trim().toLowerCase()) {
      return const ValidasiOrder(
        pesan: 'Lokasi jemput dan tujuan sama. Cek lagi alamatnya.',
        field: 'lokasiTujuan',
      );
    }
    return const ValidasiOrder();
  }

  /// Hitung tarif ojek dari rute.
  static RingkasanTarif hitungTarif(Rute rute) =>
      const TarifService().ringkasanOjek(rute);
}

/// Daftar mitra yang bisa dipilih di form ojek.
///
/// Backend belum nyala, jadi layar memakai [mitraContoh] yang sudah diberi
/// label "data contoh". Begitu backend hidup,repository mengembalikan baris
/// nyata dan daftar contoh otomatis tidak dipakai.
abstract class MitraRepository {
  /// Mitra yang sedang online dan bisa menerima order [jenis].
  Future<Hasil<List<MitraJasa>>> tersedia(JenisOrder jenis);

  Future<Hasil<MitraJasa>> byId(String id);

  /// Posisi terakhir mitra (dipakai peta tracking).
  Stream<MitraJasa?> pantauLokasi(String id, {Duration? interval});
}

/// Sumber mitra saat backend belum nyala.
class MitraRepositoryContoh implements MitraRepository {
  const MitraRepositoryContoh();

  @override
  Future<Hasil<List<MitraJasa>>> tersedia(JenisOrder jenis) async {
    final List<MitraJasa> hasil = mitraContoh
        .where((MitraJasa m) => m.aktif && m.online && m.bisa(jenis))
        .toList(growable: false);
    return Hasil<List<MitraJasa>>.berhasil(hasil);
  }

  @override
  Future<Hasil<MitraJasa>> byId(String id) async {
    for (final MitraJasa m in mitraContoh) {
      if (m.id == id) return Hasil<MitraJasa>.berhasil(m);
    }
    return const Hasil<MitraJasa>.galat(
      GalatData('Mitra tidak ditemukan.', kode: 'mitra_hilang'),
    );
  }

  @override
  Stream<MitraJasa?> pantauLokasi(String id, {Duration? interval}) async* {
    // Data contoh tidak bergerak. Layar tracking menampilkan catatan jujur
    // bahwa posisi belum dikirim, bukan marker yang diam di tengah peta.
    final Duration jeda = interval ?? const Duration(seconds: 10);
    MitraJasa? terakhir = await byId(id).then((Hasil<MitraJasa> h) =>
        h.berhasil ? h.data : null);
    yield terakhir;
    for (int i = 0; i < 600; i++) {
      await Future<void>.delayed(jeda);
      if (terakhir != null && terakhir.id != id) return;
      yield terakhir;
    }
  }
}