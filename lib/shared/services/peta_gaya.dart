/// Gaya peta yang dipakai SELURUH aplikasi (order, pilih lokasi, mitra).
///
/// Kenapa ubin raster OpenStreetMap, bukan vektor OpenFreeMap lagi:
/// 1. Ubin `tile.openstreetmap.de` dirender langsung dari basis data OSM
///    (pembaruan tiap menit), sedangkan planet OpenFreeMap dibangun ulang
///    berkala — jadi nama jalan/gang dan POI lokal lebih baru.
/// 2. Tampilan klasik OSM memperlihatkan nama jalan kampung, gang, warung,
///    masjid, puskesmas pada zoom 16–19. Untuk warga Kuningan Barat ini yang
///    paling berguna saat mencari alamat jemput.
///
/// PENTING: `tile.openstreetmap.org` (server utama OSM) TIDAK boleh dipakai
/// aplikasi — server membalas ubin peringatan "Access blocked, App is not
/// following the tile usage policy" (HTTP 200, jadi terlihat seperti berhasil
/// padahal isinya teks peringatan). Yang dipakai di sini server Jerman
/// `tile.openstreetmap.de` yang mengizinkan pemakaian non-komersial dengan
/// atribusi.
///
/// Kalau suatu saat server ini memblokir, cukup ganti satu konstanta di file
/// ini ke `gayaPetaCadangan` (vektor OpenFreeMap) — tiga pemanggil peta tidak
/// perlu diubah.
library;

/// Cadangan vektor: OpenFreeMap Liberty (tanpa API key, data planet OSM).
const String gayaPetaCadangan =
    'https://tiles.openfreemap.org/styles/liberty';

/// Gaya raster OpenStreetMap (server Jerman). Dipakai sebagai default.
// String HARUS diawali '{' tepat setelah kutip: MapLibre membedakan JSON vs
// URL dari karakter pertama. Spasi/baris baru di depan membuatnya dianggap
// URL lalu peta gagal dimuat.
const String gayaPetaGratis = r'''{
  "version": 8,
  "name": "KUNBAR OSM",
  "sources": {
    "osm": {
      "type": "raster",
      "tiles": [
        "https://a.tile.openstreetmap.de/{z}/{x}/{y}.png",
        "https://b.tile.openstreetmap.de/{z}/{x}/{y}.png",
        "https://c.tile.openstreetmap.de/{z}/{x}/{y}.png"
      ],
      "tileSize": 256,
      "minzoom": 0,
      "maxzoom": 19,
      "attribution": "© OpenStreetMap contributors"
    }
  },
  "layers": [
    {
      "id": "latar",
      "type": "background",
      "paint": { "background-color": "#e8e6e1" }
    },
    {
      "id": "osm",
      "type": "raster",
      "source": "osm",
      "minzoom": 0,
      "maxzoom": 20
    }
  ]
}
''';
