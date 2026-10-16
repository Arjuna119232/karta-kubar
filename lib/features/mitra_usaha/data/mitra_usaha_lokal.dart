import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/order.dart';
import '../domain/mitra_usaha.dart';

/// Data contoh mitra usaha. Koordinat dan harga PERKIRAAN, bukan hasil survei.
/// Ganti dengan sumber server setelah backend siap (di luar lingkup tahap ini).
const List<MitraUsaha> mitraUsahaContoh = <MitraUsaha>[
  MitraUsaha(
    id: 'mu-warung-madura',
    nama: 'Warung Madura',
    jenis: JenisMitraUsaha.warung,
    alamat: 'Kuningan Barat, Mampang Prapatan',
    titik: TitikPeta(lat: -6.2459, lng: 106.8021),
    deskripsi: 'Warung kelontong buka sampai larut. Sembako, rokok, pulsa, '
        'minuman dingin, dan kebutuhan harian.',
    jamBuka: '05.00 - 24.00',
    produk: <ProdukUsaha>[
      ProdukUsaha('Beras 5 kg', hargaKira: 72000),
      ProdukUsaha('Minyak goreng 1 L', hargaKira: 18000),
      ProdukUsaha('Telur 1 kg', hargaKira: 30000),
      ProdukUsaha('Mie instan', hargaKira: 3500),
      ProdukUsaha('Gula 1 kg', hargaKira: 17000),
    ],
  ),
  MitraUsaha(
    id: 'mu-pasar-poncol-jaya',
    nama: 'Pasar Poncol Jaya',
    jenis: JenisMitraUsaha.pasar,
    alamat: 'Pasar Poncol Jaya, Jakarta Selatan',
    titik: TitikPeta(lat: -6.2412, lng: 106.7968),
    deskripsi: 'Pasar tradisional: sayur, daging, ikan, bumbu dapur, dan '
        'buah segar. Paling ramai pagi hari.',
    jamBuka: '04.00 - 14.00',
    produk: <ProdukUsaha>[
      ProdukUsaha('Sayur (per ikat)'),
      ProdukUsaha('Ayam potong 1 kg', hargaKira: 38000),
      ProdukUsaha('Cabai rawit 250 g'),
      ProdukUsaha('Bawang merah 1 kg'),
      ProdukUsaha('Ikan segar 1 kg'),
    ],
  ),
  MitraUsaha(
    id: 'mu-pasar-santa',
    nama: 'Pasar Santa',
    jenis: JenisMitraUsaha.pasar,
    alamat: 'Jl. Cipaku I, Kebayoran Baru',
    titik: TitikPeta(lat: -6.2440, lng: 106.7986),
    deskripsi: 'Pasar dengan kios makanan, jajanan, kopi, dan bahan masakan. '
        'Cocok untuk titip makanan jadi.',
    jamBuka: '08.00 - 21.00',
    produk: <ProdukUsaha>[
      ProdukUsaha('Jajanan pasar'),
      ProdukUsaha('Kopi / minuman'),
      ProdukUsaha('Makanan siap santap'),
      ProdukUsaha('Bahan masakan'),
    ],
  ),
  MitraUsaha(
    id: 'mu-agen-gas',
    nama: 'Agen Gas',
    jenis: JenisMitraUsaha.agenGas,
    alamat: 'Kuningan Barat, Mampang Prapatan',
    titik: TitikPeta(lat: -6.2471, lng: 106.8040),
    deskripsi: 'Agen gas LPG. Tukar tabung kosong, antar sampai rumah lewat '
        'jastip.',
    jamBuka: '07.00 - 20.00',
    produk: <ProdukUsaha>[
      ProdukUsaha('LPG 3 kg', hargaKira: 22000),
      ProdukUsaha('LPG 5,5 kg', hargaKira: 95000),
      ProdukUsaha('LPG 12 kg', hargaKira: 200000),
    ],
  ),
  MitraUsaha(
    id: 'mu-galon-air',
    nama: 'Galon Air Minum',
    jenis: JenisMitraUsaha.galon,
    alamat: 'Kuningan Barat, Mampang Prapatan',
    titik: TitikPeta(lat: -6.2430, lng: 106.8035),
    deskripsi: 'Depot air minum isi ulang dan galon bermerek. Antar ke rumah '
        'lewat jastip.',
    jamBuka: '06.00 - 21.00',
    produk: <ProdukUsaha>[
      ProdukUsaha('Isi ulang galon 19 L', hargaKira: 6000),
      ProdukUsaha('Galon merek + isi', hargaKira: 22000),
    ],
  ),
];

final Provider<List<MitraUsaha>> mitraUsahaProvider =
    Provider<List<MitraUsaha>>((Ref ref) => mitraUsahaContoh);

MitraUsaha? cariMitraUsaha(String id) {
  for (final MitraUsaha m in mitraUsahaContoh) {
    if (m.id == id) return m;
  }
  return null;
}
