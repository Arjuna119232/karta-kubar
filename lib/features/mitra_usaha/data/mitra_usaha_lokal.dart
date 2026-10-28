import '../../../shared/models/order.dart';
import '../domain/mitra_usaha.dart';

/// 34 mitra usaha di Kecamatan Mampang Prapatan.
///
/// Dua sumber koordinat, dan aplikasi menampilkan bedanya:
///
/// - `titikPerkiraan: false` = koordinat persis dari OpenStreetMap
///   (node/way amenity & shop), diambil langsung dari data OSM.
/// - `titikPerkiraan: true` = titik atau alamat masih perkiraan.
///   Alamatnya benar, titik pintunya belum. Jangan dua-duanya
///   dicampur tanpa penjelasan.
///
/// Jam buka hanya dipakai kalau sumbernya menuliskannya (tag
/// `opening_hours` di OSM). Yang tidak tertulis diberi label
/// 'Belum dikonfirmasi', BUKAN jam karangan.
///
/// No HP sama-sama hanya dari sumber (tag phone), divalidasi pola 08xx.
/// Kalau tidak ada, null dan tombol telepon disembunyikan oleh UI.
///
/// Daftar ini sengaja bukan `const`: `Kelurahan.dari(...)` memanggil
/// `firstWhere`, dan fungsi tidak boleh dipanggil dalam ekspresi const.
final List<MitraUsaha> daftarMitraUsaha = <MitraUsaha>[
  MitraUsaha(
    id: 'mu-bangka-spbu-pertamina-31-127-01',
    nama: 'SPBU Pertamina 31.127.01',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.spbu],
    alamat: 'Jl. Kemang Selatan XI, Kel. Bangka',
    kelurahan: Kelurahan.dari('Bangka'),
    fitur: 'Stasiun pengisian bahan bakar umum',
    titik: TitikPeta(lat: -6.273519, lng: 106.818816),
    jamBuka: 'Belum dikonfirmasi',
    titikPerkiraan: false,
    layanan: const <String>[],
    info: 'Dua entri OSM merek sama berjarak di bawah 35 m digabung jadi satu.',
  ),
  MitraUsaha(
    id: 'mu-bangka-indomaret',
    nama: 'Indomaret (Jl. Kemang Raya 1)',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.warungKelontong],
    alamat: 'Jl. Kemang Raya, Kel. Bangka',
    kelurahan: Kelurahan.dari('Bangka'),
    fitur: 'Minimarket rantai',
    titik: TitikPeta(lat: -6.266956, lng: 106.815656),
    jamBuka: 'Belum dikonfirmasi',
    titikPerkiraan: false,
    layanan: const <String>[],
  ),
  MitraUsaha(
    id: 'mu-bangka-indomaret-2',
    nama: 'Indomaret (Jl. Kemang Raya 2)',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.warungKelontong],
    alamat: 'Jl. Kemang Raya, Kel. Bangka',
    kelurahan: Kelurahan.dari('Bangka'),
    fitur: 'Minimarket rantai',
    titik: TitikPeta(lat: -6.272414, lng: 106.815099),
    jamBuka: 'Belum dikonfirmasi',
    titikPerkiraan: false,
    layanan: const <String>[],
  ),
  MitraUsaha(
    id: 'mu-bangka-apotek-speed-pharma',
    nama: 'Apotek Speed Pharma',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.apotek],
    alamat: 'Jl. Kemang Selatan VII, Kel. Bangka',
    kelurahan: Kelurahan.dari('Bangka'),
    fitur: 'Apotek kebutuhan obat',
    titik: TitikPeta(lat: -6.269415, lng: 106.816082),
    jamBuka: 'Belum dikonfirmasi',
    titikPerkiraan: false,
    layanan: const <String>[],
  ),
  MitraUsaha(
    id: 'mu-bangka-spbu-pertamina-kemang-raya',
    nama: 'SPBU Pertamina Kemang Raya',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.spbu],
    alamat: 'Jl. Kemang Raya, Kel. Bangka',
    kelurahan: Kelurahan.dari('Bangka'),
    fitur: 'Stasiun pengisian bahan bakar umum',
    titik: TitikPeta(lat: -6.266780, lng: 106.815678),
    jamBuka: 'Belum dikonfirmasi',
    titikPerkiraan: false,
    layanan: const <String>[],
  ),
  MitraUsaha(
    id: 'mu-bangka-hero',
    nama: 'Hero',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.warungKelontong],
    alamat: 'Jl. Kemang Club Villas, Kel. Bangka',
    kelurahan: Kelurahan.dari('Bangka'),
    fitur: 'Warung kelontong harian',
    titik: TitikPeta(lat: -6.265096, lng: 106.820759),
    jamBuka: 'Belum dikonfirmasi',
    titikPerkiraan: false,
    layanan: const <String>[],
  ),
  MitraUsaha(
    id: 'mu-bangka-lawson',
    nama: 'Lawson',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.warungKelontong],
    alamat: 'Jl. Kemang Raya, Kel. Bangka',
    kelurahan: Kelurahan.dari('Bangka'),
    fitur: 'Minimarket rantai',
    titik: TitikPeta(lat: -6.255832, lng: 106.812417),
    jamBuka: 'Belum dikonfirmasi',
    titikPerkiraan: false,
    layanan: const <String>[],
  ),
  MitraUsaha(
    id: 'mu-bangka-ranch-market-kemang',
    nama: 'Ranch Market Kemang',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.warungKelontong],
    alamat: 'Jl. Kemang VII, Kel. Bangka',
    kelurahan: Kelurahan.dari('Bangka'),
    fitur: 'Minimarket rantai',
    titik: TitikPeta(lat: -6.264019, lng: 106.815618),
    jamBuka: 'Belum dikonfirmasi',
    titikPerkiraan: false,
    layanan: const <String>[],
  ),
  MitraUsaha(
    id: 'mu-bangka-indomaret-3',
    nama: 'Indomaret (Jl. Kemang Raya 3)',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.warungKelontong],
    alamat: 'Jl. Kemang Raya, Kel. Bangka',
    kelurahan: Kelurahan.dari('Bangka'),
    fitur: 'Minimarket rantai',
    titik: TitikPeta(lat: -6.260037, lng: 106.815147),
    jamBuka: '24 jam',
    titikPerkiraan: false,
    layanan: const <String>[],
  ),
  MitraUsaha(
    id: 'mu-bangka-spbu-vivo-kemang',
    nama: 'SPBU VIVO Kemang',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.spbu],
    alamat: 'Jl. Kemang Raya, Kel. Bangka',
    kelurahan: Kelurahan.dari('Bangka'),
    fitur: 'Stasiun pengisian bahan bakar umum',
    titik: TitikPeta(lat: -6.261113, lng: 106.815332),
    jamBuka: '07:00 - 22:00',
    titikPerkiraan: false,
    layanan: const <String>['Bensin'],
  ),
  MitraUsaha(
    id: 'mu-bangka-spbu-shell-kemang-raya',
    nama: 'SPBU Shell Kemang Raya',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.spbu],
    alamat: 'Jl. Kemang Raya, Kel. Bangka',
    kelurahan: Kelurahan.dari('Bangka'),
    fitur: 'Stasiun pengisian bahan bakar umum',
    titik: TitikPeta(lat: -6.260854, lng: 106.815805),
    jamBuka: '00:00 - 23:59',
    titikPerkiraan: false,
    layanan: const <String>['Bensin'],
    info: 'Dua entri OSM merek sama berjarak di bawah 35 m digabung jadi satu.',
    noHp: '0217194429',
  ),
  MitraUsaha(
    id: 'mu-bangka-indomaret-4',
    nama: 'Indomaret (Jl. Kemang Raya 4)',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.warungKelontong],
    alamat: 'Jl. Kemang Raya, Kel. Bangka',
    kelurahan: Kelurahan.dari('Bangka'),
    fitur: 'Minimarket rantai',
    titik: TitikPeta(lat: -6.255527, lng: 106.812237),
    jamBuka: 'Belum dikonfirmasi',
    titikPerkiraan: false,
    layanan: const <String>[],
  ),
  MitraUsaha(
    id: 'mu-bangka-apotik-melawai-kemang',
    nama: 'APOTIK MELAWAI KEMANG',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.apotek],
    alamat: 'Jl. Kemang Raya, Kel. Bangka',
    kelurahan: Kelurahan.dari('Bangka'),
    fitur: 'Apotek kebutuhan obat',
    titik: TitikPeta(lat: -6.255010, lng: 106.809624),
    jamBuka: 'Belum dikonfirmasi',
    titikPerkiraan: false,
    layanan: const <String>[],
  ),
  MitraUsaha(
    id: 'mu-bangka-circle-k',
    nama: 'Circle K (Jl. Kemang Raya)',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.warungKelontong],
    alamat: 'Jl. Kemang Raya, Kel. Bangka',
    kelurahan: Kelurahan.dari('Bangka'),
    fitur: 'Minimarket rantai',
    titik: TitikPeta(lat: -6.255431, lng: 106.809265),
    jamBuka: 'Belum dikonfirmasi',
    titikPerkiraan: false,
    layanan: const <String>[],
  ),
  MitraUsaha(
    id: 'mu-pela-mampang-alfamidi-bangka-raya',
    nama: 'Alfamidi Bangka Raya',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.warungKelontong],
    alamat: 'Jl. Gang Amal IV, Kel. Pela Mampang',
    kelurahan: Kelurahan.dari('Pela Mampang'),
    fitur: 'Minimarket rantai',
    titik: TitikPeta(lat: -6.246646, lng: 106.815066),
    jamBuka: 'Belum dikonfirmasi',
    titikPerkiraan: false,
    layanan: const <String>[],
    info: 'Dua entri OSM merek sama berjarak di bawah 35 m digabung jadi satu.',
  ),
  MitraUsaha(
    id: 'mu-pela-mampang-dapur-cokelat-bangka',
    nama: 'Dapur Cokelat Bangka',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.tokoRoti],
    alamat: 'Jl. Bangka Raya, Kel. Pela Mampang',
    kelurahan: Kelurahan.dari('Pela Mampang'),
    fitur: 'Toko roti dan kue',
    titik: TitikPeta(lat: -6.253585, lng: 106.814220),
    jamBuka: 'Belum dikonfirmasi',
    titikPerkiraan: false,
    layanan: const <String>[],
  ),
  MitraUsaha(
    id: 'mu-pela-mampang-alfamart',
    nama: 'Alfamart (Jl. Bangka Raya)',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.warungKelontong],
    alamat: 'Jl. Bangka Raya, Kel. Pela Mampang',
    kelurahan: Kelurahan.dari('Pela Mampang'),
    fitur: 'Minimarket rantai',
    titik: TitikPeta(lat: -6.252755, lng: 106.814535),
    jamBuka: 'Belum dikonfirmasi',
    titikPerkiraan: false,
    layanan: const <String>[],
  ),
  MitraUsaha(
    id: 'mu-pela-mampang-indomaret',
    nama: 'Indomaret (Jl. Bangka Raya)',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.warungKelontong],
    alamat: 'Jl. Bangka Raya, Kel. Pela Mampang',
    kelurahan: Kelurahan.dari('Pela Mampang'),
    fitur: 'Minimarket rantai',
    titik: TitikPeta(lat: -6.247026, lng: 106.814935),
    jamBuka: 'Belum dikonfirmasi',
    titikPerkiraan: false,
    layanan: const <String>[],
  ),
  MitraUsaha(
    id: 'mu-bangka-pasar-warung-buncit',
    nama: 'Pasar Warung Buncit',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.pasar],
    alamat: 'Jl. Kemang Utara IX, Kel. Bangka',
    kelurahan: Kelurahan.dari('Bangka'),
    fitur: 'Pasar tradisional',
    titik: TitikPeta(lat: -6.254993, lng: 106.824623),
    jamBuka: 'Belum dikonfirmasi',
    titikPerkiraan: false,
    layanan: const <String>[],
  ),
  MitraUsaha(
    id: 'mu-tegal-parang-majestyk-bakery',
    nama: 'Majestyk Bakery',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.tokoRoti],
    alamat: 'Jl. Mampang Prapatan Raya, Kel. Tegal Parang',
    kelurahan: Kelurahan.dari('Tegal Parang'),
    fitur: 'Toko roti dan kue',
    titik: TitikPeta(lat: -6.248849, lng: 106.826678),
    jamBuka: '07:00 - 21:00',
    titikPerkiraan: false,
    layanan: const <String>[],
  ),
  MitraUsaha(
    id: 'mu-tegal-parang-spbu-pertamina-mampang-prapatan-viii',
    nama: 'SPBU Pertamina Mampang Prapatan VIII',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.spbu],
    alamat: 'Jl. Mampang Prapatan VIII, Kel. Tegal Parang',
    kelurahan: Kelurahan.dari('Tegal Parang'),
    fitur: 'Stasiun pengisian bahan bakar umum',
    titik: TitikPeta(lat: -6.247761, lng: 106.826855),
    jamBuka: 'Belum dikonfirmasi',
    titikPerkiraan: false,
    layanan: const <String>[],
  ),
  MitraUsaha(
    id: 'mu-tegal-parang-soes-roti-merdeka',
    nama: 'Soes Roti Merdeka',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.tokoRoti],
    alamat: 'Jl. Gang Haji Dahlan, Kel. Tegal Parang',
    kelurahan: Kelurahan.dari('Tegal Parang'),
    fitur: 'Toko roti dan kue',
    titik: TitikPeta(lat: -6.250392, lng: 106.826327),
    jamBuka: '07:00 - 21:00',
    titikPerkiraan: false,
    layanan: const <String>[],
  ),
  MitraUsaha(
    id: 'mu-tegal-parang-spbu-shell-mampang',
    nama: 'SPBU Shell Mampang',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.spbu],
    alamat: 'Jl. Mampang Prapatan Raya, Kel. Tegal Parang',
    kelurahan: Kelurahan.dari('Tegal Parang'),
    fitur: 'Stasiun pengisian bahan bakar umum',
    titik: TitikPeta(lat: -6.246458, lng: 106.826446),
    jamBuka: '06:00 - 23:59',
    titikPerkiraan: false,
    layanan: const <String>['Bensin'],
    noHp: '0217945592',
  ),
  MitraUsaha(
    id: 'mu-pela-mampang-alfamart-2',
    nama: 'Alfamart (Jl. Kapten Tendean)',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.warungKelontong],
    alamat: 'Jl. Kapten Tendean, Kel. Pela Mampang',
    kelurahan: Kelurahan.dari('Pela Mampang'),
    fitur: 'Minimarket rantai',
    titik: TitikPeta(lat: -6.239977, lng: 106.818991),
    jamBuka: 'Belum dikonfirmasi',
    titikPerkiraan: false,
    layanan: const <String>[],
  ),
  MitraUsaha(
    id: 'mu-kuningan-barat-spbu-shell-tendean',
    nama: 'SPBU Shell Tendean',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.spbu],
    alamat: 'Jl. Poncol Jaya Blok Prapatan, Kel. Kuningan Barat',
    kelurahan: Kelurahan.dari('Kuningan Barat'),
    fitur: 'Stasiun pengisian bahan bakar umum',
    titik: TitikPeta(lat: -6.239616, lng: 106.819408),
    jamBuka: '06:00 - 23:59',
    titikPerkiraan: false,
    layanan: const <String>['Bensin'],
    info: 'Dua entri OSM merek sama berjarak di bawah 35 m digabung jadi satu.',
    noHp: '02152922577',
  ),
  MitraUsaha(
    id: 'mu-pela-mampang-kitchen-organic',
    nama: 'Kitchen Organic',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.warungKelontong],
    alamat: 'Jl. Gang Amal IV, Kel. Pela Mampang',
    kelurahan: Kelurahan.dari('Pela Mampang'),
    fitur: 'Toko makanan organik',
    titik: TitikPeta(lat: -6.246029, lng: 106.814274),
    jamBuka: 'Belum dikonfirmasi',
    titikPerkiraan: false,
    layanan: const <String>[],
  ),
  MitraUsaha(
    id: 'mu-kuningan-barat-pasar-rengas',
    nama: 'Pasar Rengas',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.pasar],
    alamat: 'Jl. Rengas I, Kel. Kuningan Barat',
    kelurahan: Kelurahan.dari('Kuningan Barat'),
    fitur: 'Pasar tradisional',
    titik: TitikPeta(lat: -6.236747, lng: 106.818470),
    jamBuka: 'Belum dikonfirmasi',
    titikPerkiraan: false,
    layanan: const <String>[],
  ),
  MitraUsaha(
    id: 'mu-pela-mampang-pasar-bangka',
    nama: 'Pasar Bangka',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.pasar],
    alamat: 'Jl. Bangka III, Kel. Pela Mampang',
    kelurahan: Kelurahan.dari('Pela Mampang'),
    fitur: 'Pasar tradisional',
    titik: TitikPeta(lat: -6.245709, lng: 106.815304),
    jamBuka: 'Belum dikonfirmasi',
    titikPerkiraan: false,
    layanan: const <String>[],
  ),
  MitraUsaha(
    id: 'mu-pela-mampang-circle-k',
    nama: 'Circle K (Jl. Bangka Raya)',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.warungKelontong],
    alamat: 'Jl. Bangka Raya, Kel. Pela Mampang',
    kelurahan: Kelurahan.dari('Pela Mampang'),
    fitur: 'Minimarket rantai',
    titik: TitikPeta(lat: -6.246074, lng: 106.815422),
    jamBuka: 'Belum dikonfirmasi',
    titikPerkiraan: false,
    layanan: const <String>[],
  ),
  MitraUsaha(
    id: 'mu-kuningan-barat-spbu-vivo-tendean',
    nama: 'SPBU VIVO Tendean',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.spbu],
    alamat: 'Jl. Poncol Jaya, Kel. Kuningan Barat',
    kelurahan: Kelurahan.dari('Kuningan Barat'),
    fitur: 'Stasiun pengisian bahan bakar umum',
    titik: TitikPeta(lat: -6.239160, lng: 106.818748),
    jamBuka: '07:00 - 22:00',
    titikPerkiraan: false,
    layanan: const <String>['Bensin'],
  ),
  MitraUsaha(
    id: 'mu-kuningan-barat-daily-foodhall',
    nama: 'Daily Foodhall',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.warungKelontong],
    alamat: 'Jl. Kapten Tendean, Kel. Kuningan Barat',
    kelurahan: Kelurahan.dari('Kuningan Barat'),
    fitur: 'Minimarket rantai',
    titik: TitikPeta(lat: -6.239798, lng: 106.824569),
    jamBuka: 'Belum dikonfirmasi',
    titikPerkiraan: false,
    layanan: const <String>[],
  ),
  MitraUsaha(
    id: 'mu-kuningan-barat-bright',
    nama: 'Bright',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.warungKelontong],
    alamat: 'Jl. Kapten Tendean, Kel. Kuningan Barat',
    kelurahan: Kelurahan.dari('Kuningan Barat'),
    fitur: 'Minimarket rantai',
    titik: TitikPeta(lat: -6.240356, lng: 106.820718),
    jamBuka: 'Belum dikonfirmasi',
    titikPerkiraan: false,
    layanan: const <String>[],
  ),
  MitraUsaha(
    id: 'mu-kuningan-barat-spbu-pertamina-kapten-tendean',
    nama: 'SPBU Pertamina Kapten Tendean',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.spbu],
    alamat: 'Jl. Kapten Tendean, Kel. Kuningan Barat',
    kelurahan: Kelurahan.dari('Kuningan Barat'),
    fitur: 'Stasiun pengisian bahan bakar umum',
    titik: TitikPeta(lat: -6.240287, lng: 106.820462),
    jamBuka: 'Belum dikonfirmasi',
    titikPerkiraan: false,
    layanan: const <String>[],
  ),
  MitraUsaha(
    id: 'mu-mampang-prapatan-pasar-mampang',
    nama: 'Pasar Mampang',
    kategori: <KategoriMitraUsaha>[KategoriMitraUsaha.pasar],
    alamat: 'Jl. Mampang Prapatan Raya, Kel. Mampang Prapatan',
    kelurahan: Kelurahan.dari('Mampang Prapatan'),
    fitur: 'Pasar tradisional',
    titik: TitikPeta(lat: -6.240932, lng: 106.825072),
    jamBuka: 'Belum dikonfirmasi',
    titikPerkiraan: false,
    layanan: const <String>[],
  ),
];


/// Jumlah mitra per kategori (untuk chip filter).
int jumlahKategori(KategoriMitraUsaha kategori) =>
    daftarMitraUsaha.where((MitraUsaha m) => m.kategori.contains(kategori)).length;

/// Jumlah mitra per kelurahan.
int jumlahKelurahan(Kelurahan kelurahan) =>
    daftarMitraUsaha.where((MitraUsaha m) => m.kelurahan == kelurahan).length;

/// Cari mitra satu per id.
MitraUsaha? mitraUsahaById(String id) {
  for (final MitraUsaha m in daftarMitraUsaha) {
    if (m.id == id) return m;
  }
  return null;
}

/// Saring daftar mitra.
///
/// [kategori] dan [kelurahan] null berarti semua. [cari] dicocokkan ke nama,
/// alamat, kelurahan, fitur, dan kategori - cukup untuk daftar lokal dan
/// tidak memanggil server sama sekali.
List<MitraUsaha> saringMitraUsaha({
  KategoriMitraUsaha? kategori,
  Kelurahan? kelurahan,
  String cari = '',
}) {
  final String kueri = cari.trim().toLowerCase();
  return daftarMitraUsaha.where((MitraUsaha m) {
    if (kategori != null && !m.kategori.contains(kategori)) return false;
    if (kelurahan != null && m.kelurahan != kelurahan) return false;
    if (kueri.isEmpty) return true;
    return m.kataKunciLc.contains(kueri);
  }).toList(growable: false);
}

/// Lima mitra terdekat dari titik [dari], dipakai kartu di beranda.
List<MitraUsaha> mitraTerdekat(TitikPeta dari, {int batas = 5}) {
  final List<MitraUsaha> semua = List<MitraUsaha>.of(daftarMitraUsaha)
    ..sort((MitraUsaha a, MitraUsaha b) =>
        jarakKm(dari, a.titik).compareTo(jarakKm(dari, b.titik)));
  return semua.take(batas).toList(growable: false);
}

/// Barang yang lazim ada di tiap kategori.
///
/// Tanpa harga, karena harga tiap toko berbeda dan tidak ada data resmi.
/// Ditampilkan sebagai "-- jenis barang yang lazim --", bukan daftar belanja
/// milik mitra tertentu.
List<ProdukUsaha> produkUmum(KategoriMitraUsaha kategori) => switch (kategori) {
      KategoriMitraUsaha.warungKelontong => const <ProdukUsaha>[
          ProdukUsaha('Beras'),
          ProdukUsaha('Minyak goreng'),
          ProdukUsaha('Telur'),
          ProdukUsaha('Gula dan garam'),
          ProdukUsaha('Kopi dan teh'),
          ProdukUsaha('Mi instan'),
          ProdukUsaha('Pulsa dan token listrik'),
          ProdukUsaha('Rokok'),
        ],
      KategoriMitraUsaha.tokoRoti => const <ProdukUsaha>[
          ProdukUsaha('Roti tawar'),
          ProdukUsaha('Roti manis'),
          ProdukUsaha('Kue dan snack'),
          ProdukUsaha('Martabak dan roti bakar'),
          ProdukUsaha('Minuman kemasan'),
        ],
      KategoriMitraUsaha.pasar => const <ProdukUsaha>[
          ProdukUsaha('Sayurmayur'),
          ProdukUsaha('Buahbuahan'),
          ProdukUsaha('Daging sapi dan ayam'),
          ProdukUsaha('Ikan segar'),
          ProdukUsaha('Bumbu dan rempah'),
          ProdukUsaha('Sembako grosir'),
          ProdukUsaha('Jajanan pasar'),
        ],
      KategoriMitraUsaha.spbu => const <ProdukUsaha>[
          ProdukUsaha('Pertalite'),
          ProdukUsaha('Pertamax'),
          ProdukUsaha('Solar'),
          ProdukUsaha('Dexlite'),
        ],
      KategoriMitraUsaha.apotek => const <ProdukUsaha>[
          ProdukUsaha('Obat bebas'),
          ProdukUsaha('Obat resep'),
          ProdukUsaha('Vitamin dan suplemen'),
          ProdukUsaha('Alat kesehatan'),
          ProdukUsaha('Susu dan makanan bayi'),
        ],
    };
