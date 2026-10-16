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
  /// Batas atas jarak (km, inklusif) -> tarif. Di atas baris terakhir:
  /// [tarifOjekDasarLanjut] + (km - [batasOjekLanjut]) x [tarifOjekPerKmLanjut].
  static const List<(double, double)> tabelOjek = <(double, double)>[
    (2, 7000),
    (4, 10000),
    (6, 14000),
    (8, 18000),
    (10, 22000),
    (12, 26000),
    (15, 32000),
  ];
  static const double batasOjekLanjut = 15;
  static const double tarifOjekDasarLanjut = 32000;
  static const double tarifOjekPerKmLanjut = 2500;

  // -------------------------------------------------------------- jastip
  /// Biaya ANTAR saja (lokasi beli -> alamat antar), bukan jarak mitra ke toko.
  static const List<(double, double)> tabelJastip = <(double, double)>[
    (1, 3000),
    (2, 5000),
    (3, 7000),
    (4, 9000),
    (5, 11000),
    (7, 15000),
    (10, 20000),
  ];
  static const double batasJastipLanjut = 10;
  static const double tarifJastipDasarLanjut = 20000;
  static const double tarifJastipPerKmLanjut = 2500;

  /// Tarif ojek dari TOTAL jarak (km) = mitra->jemput + jemput->tujuan.
  double tarifOjek(double jarakKm) => _hitung(
        jarakKm,
        tabelOjek,
        batasOjekLanjut,
        tarifOjekDasarLanjut,
        tarifOjekPerKmLanjut,
      );

  /// Fee antar jastip dari jarak lokasi beli -> alamat antar (km).
  double feeJastip(double jarakKm) => _hitung(
        jarakKm,
        tabelJastip,
        batasJastipLanjut,
        tarifJastipDasarLanjut,
        tarifJastipPerKmLanjut,
      );

  static double _hitung(
    double km,
    List<(double, double)> tabel,
    double batas,
    double dasar,
    double perKm,
  ) {
    final double jarak = km < 0 ? 0 : km;
    for (final (double maks, double tarif) in tabel) {
      if (jarak <= maks) return tarif;
    }
    return _bulat(dasar + (jarak - batas) * perKm);
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

  /// Pembulatan ke Rp500 terdekat (tarif >15 km / >10 km kelipatan 2.500).
  static double _bulat(double nilai) => (nilai / 500).round() * 500.0;

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
      ? 'dihitung dari rute jalan (OSRM)'
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