import '../models/order_tracking.dart';

/// Perhitungan tarif jastip dan ojek.
///
/// Dipisah dari UI supaya angkanya bisa diuji dan, nanti, bisa ditimpa dari
/// web admin kalau tarif berubah.
///
/// TODO backend: tarif idealnya disimpan di tabel `tarif_layanan` supaya bisa
/// diubah pengelola tanpa rilis ulang APK. Selagi ini masih konstanta.
class TarifService {
  const TarifService();

  // ---------------------------------------------------------------- ojek
  static const double tarifDasarOjek = 3000;
  static const double tarifPerKmOjek = 2500;

  /// Jarak minimum yang tetap ditagih, supaya order 200 m tidak gratis.
  static const double jarakMinOjek = 0.5;

  // -------------------------------------------------------------- jastip
  static const double tarifDasarJastip = 4000;
  static const double tarifPerKmJastip = 2000;

  /// Minimal 1,5 km: jastip selalu lintas lokasi, jarak kecil berarti salah
  /// ketik lokasi.
  static const double jarakMinJastip = 1.5;

  /// 1 pesanan = 1 fee. Jumlah barang tidak menambah fee, hanya menambah
  /// perkiraan biaya barang.
  static const double batasJauhJastip = 8.0;

  /// Tarif ojek dari jarak (km).
  double tarifOjek(double jarakKm) {
    final double dasar = jarakKm < jarakMinOjek ? jarakMinOjek : jarakKm;
    return _bulat(tarifDasarOjek + tarifPerKmOjek * dasar);
  }

  /// Fee jastip dari jarak lokasi beli -> alamat antar (km).
  double feeJastip(double jarakKm) {
    final double dasar = jarakKm < jarakMinJastip ? jarakMinJastip : jarakKm;
    double fee = tarifDasarJastip + tarifPerKmJastip * dasar;
    if (dasar > batasJauhJastip) {
      fee += (dasar - batasJauhJastip) * 1000;
    }
    return _bulat(fee);
  }

  /// Ringkasan biaya untuk ditampilkan di form (belum termasuk harga barang).
  RingkasanTarif ringkasanJastip(Rute rute) => RingkasanTarif(
        jarakKm: rute.jarakKm,
        tarif: feeJastip(rute.jarakKm),
        durasiMenit: rute.durasiMenit,
        dariServer: rute.dariServer,
      );

  RingkasanTarif ringkasanOjek(Rute rute) => RingkasanTarif(
        jarakKm: rute.jarakKm,
        tarif: tarifOjek(rute.jarakKm),
        durasiMenit: rute.durasiMenit,
        dariServer: rute.dariServer,
      );

  /// Pembulatan ke ribuan terdekat supaya uangcash rapi.
  static double _bulat(double nilai) => (nilai / 1000).round() * 1000.0;

  /// Total yang perlu menyiapkan warga: fee + perkiraan harga barang.
  static double total(double tarif, double? hargaBarang) =>
      _bulat(tarif + (hargaBarang ?? 0));
}

/// Yang tampil di form: jarak, tarif, dan apakah angkanya perkiraan.
class RingkasanTarif {
  const RingkasanTarif({
    required this.jarakKm,
    required this.tarif,
    required this.durasiMenit,
    required this.dariServer,
  });

  static const RingkasanTarif kosong = RingkasanTarif(
    jarakKm: 0,
    tarif: 0,
    durasiMenit: 0,
    dariServer: false,
  );

  final double jarakKm;
  final double tarif;
  final int durasiMenit;
  final bool dariServer;

  bool get adaJarak => jarakKm > 0;

  String get jarakTeks => jarakKm <= 0
      ? 'Belum dihitung'
      : jarakKm < 1
          ? '${(jarakKm * 1000).round()} m'
          : '${jarakKm.toStringAsFixed(1)} km';

  /// Sumber angka, jujur ditampilkan supaya warga tidak mengira pasti.
  String get sumberTeks => dariServer
      ? 'dihitung dari rute jalan kaki'
      : adaJarak
          ? 'perkiraan kasar (server rute tidak bisa dihubungi)'
          : 'menunggu lokasi';

  Rute keRute() => Rute(
        jarakKm: jarakKm,
        durasiMenit: durasiMenit,
        dariServer: dariServer,
      );
}

/// Hasil validasi form, dipakai bersama oleh form jastip dan form ojek.
class ValidasiOrder {
  const ValidasiOrder({this.pesan, this.field});

  final String? pesan;
  final String? field;

  bool get valid => pesan == null;
}

/// Validasi teks generik: wajib diisi dan tidak terlalu panjang.
ValidasiOrder wajibIsi(String nilai, {required String nama, int maks = 160}) {
  if (nilai.trim().isEmpty) {
    return ValidasiOrder(pesan: '$nama belum diisi.', field: nama);
  }
  if (nilai.trim().length > maks) {
    return ValidasiOrder(
      pesan: '$nama maksimal $maks karakter.',
      field: nama,
    );
  }
  return const ValidasiOrder();
}