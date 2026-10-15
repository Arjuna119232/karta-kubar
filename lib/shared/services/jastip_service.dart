import '../../core/data/hasil.dart';
import '../models/order.dart';
import '../models/order_jastip.dart';
import '../models/order_ringkas.dart';
import 'order_repository.dart';
import 'order_service_base.dart';
import 'tarif_service.dart';

/// Semua yang dibutuhkan layar order JASTIP (jasa titip).
///
/// Dipakai oleh APK Warga (form, riwayat, detail, tracking) dan nanti oleh
/// APK Mitra (daftar order masuk) serta Web Admin. Karena itu kelas ini tidak
/// boleh menyentuh widget apa pun.
class JastipService extends OrderServiceDasar {
  JastipService({
    required OrderRepository repo,
    Duration polling = const Duration(seconds: 10),
  }) : super(
          repo: repo,
          jenis: JenisOrder.jastip,
          detikPolling: polling,
        );

  static const JenisOrder jenisOrder = JenisOrder.jastip;

  /// Buat order jastip baru.
  ///
  /// Fee TIDUK dihitung di sini: pemanggil sudah punya [RingkasanTarif] dari
  /// form (yang punya akses ke lokasi & rute). Parameter [kunciWarga] dipakai
  /// sebagai penanda baris milik siapa, supaya tidak pernah tertukar dengan
  /// order orang lain.
  Future<Hasil<OrderRingkas>> createOrder({
    required String kunciWarga,
    required String wargaNama,
    required String wargaNomor,
    required String barang,
    required int qty,
    required String lokasiBeli,
    required TitikPeta titikBeli,
    required String alamatAntar,
    required TitikPeta titikAntar,
    required RingkasanTarif ringkasan,
    String catatan = '',
    String? fotoReferensi,
    double? estimasiBiayaBarang,
    MetodeBayar metodeBayar = MetodeBayar.cash,
  }) async {
    final ValidasiOrder v = validasi(
      barang: barang,
      qty: qty,
      lokasiBeli: lokasiBeli,
      alamatAntar: alamatAntar,
    );
    if (!v.valid) {
      return Hasil<OrderRingkas>.galat(GalatData(v.pesan!, kode: v.field));
    }
    final DateTime sekarang = DateTime.now();
    final OrderJastip order = OrderJastip(
      id: '',
      kode: kodeOrder(JenisOrder.jastip, sekarang),
      wargaKunci: kunciWarga,
      wargaNama: wargaNama,
      wargaNomor: wargaNomor,
      barang: barang.trim(),
      qty: qty,
      lokasiBeli: lokasiBeli.trim(),
      latBeli: titikBeli.lat,
      lngBeli: titikBeli.lng,
      alamatAntar: alamatAntar.trim(),
      latAntar: titikAntar.lat,
      lngAntar: titikAntar.lng,
      catatan: catatan.trim(),
      fotoReferensi: fotoReferensi,
      jarakKm: ringkasan.jarakKm,
      tarif: ringkasan.tarif,
      estimasiBiayaBarang: estimasiBiayaBarang,
      metodeBayar: metodeBayar,
      status: StatusOrder.menunggu,
      dibuat: sekarang,
    );
    final Hasil<OrderJastip> h = await repo.kirimJastip(order);
    if (!h.berhasil) {
      return Hasil<OrderRingkas>.galat(h.galat ?? GalatData('Gagal mengirim.'));
    }
    return Hasil<OrderRingkas>.berhasil(OrderRingkas.dariJastip(h.data!));
  }

  /// Cek isi form sebelum submit. Dipisah supaya aturan ini bisa dipakai
  /// Mitra/Admin juga dan tidak hanya ada di UI.
  static ValidasiOrder validasi({
    required String barang,
    required int qty,
    required String lokasiBeli,
    required String alamatAntar,
  }) {
    if (barang.trim().isEmpty) {
      return const ValidasiOrder(pesan: 'Nama barang belum diisi.', field: 'barang');
    }
    if (barang.trim().length > 120) {
      return const ValidasiOrder(
        pesan: 'Nama barang maksimal 120 karakter.',
        field: 'barang',
      );
    }
    if (qty < 1 || qty > 99) {
      return const ValidasiOrder(
        pesan: 'Jumlah barang antara 1 sampai 99.',
        field: 'qty',
      );
    }
    if (lokasiBeli.trim().length < 3) {
      return const ValidasiOrder(
        pesan: 'Lokasi beli terlalu singkat. Sebutkan nama toko atau jalan.',
        field: 'lokasiBeli',
      );
    }
    if (alamatAntar.trim().length < 5) {
      return const ValidasiOrder(
        pesan: 'Alamat antar terlalu singkat agar mitra tidak nyasar.',
        field: 'alamatAntar',
      );
    }
    return const ValidasiOrder();
  }

  /// Hitung fee jastip dari rute, tanpa perlu tahu UI-nya.
  static RingkasanTarif hitungFee(TitikPeta beli, TitikPeta antar, double jarakKm) {
    const TarifService tarif = TarifService();
    return RingkasanTarif(
      jarakKm: jarakKm,
      tarif: tarif.feeJastip(jarakKm),
      durasiMenit: jarakKm <= 0 ? 0 : (jarakKm / 4.2 * 60).round(),
      dariServer: false,
    );
  }
}