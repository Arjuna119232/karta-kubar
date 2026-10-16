# kunbar-fix-harga

Penyebab harga selalu Rp7.000: alamat tujuan tidak pernah dapat koordinat.
- Pencarian tujuan dibatasi "1x per 4 detik", jadi kata terakhir yang diketik tidak pernah dicari -> tujuan tanpa titik -> jarak 0 -> tarif minimum.
- Alamat jemput yang diketik tidak pernah dicari koordinatnya (hanya dari GPS).

Perbaikan (`order_form_ojek.dart`):
- Pencarian alamat jemput dan tujuan memakai debounce 700 ms (dicari setelah berhenti mengetik); titik lama dibuang kalau teks berubah; hasil lama diabaikan (`_urutan`).
- Jarak = mitra->jemput + jemput->tujuan. Posisi mitra: koordinat mitra terpilih, kalau tidak ada pakai lokasi HP terakhir yang terbaca, kalau tidak ada bagian itu 0 dan rincian memberi tahu.
- Tarif tidak lagi muncul Rp7.000 palsu: sebelum jemput dan tujuan punya koordinat, tarif "-" dan tombol kirim ditolak dengan pesan jelas.
- Teks "1 jemput · 2 tujuan" diganti rincian: jarak mitra ke jemput, jemput ke tujuan, total jarak, tarif.
- Peta: garis rute jalan dari OSRM (`lokasi_service.dart`: profil `driving`, geometri GeoJSON diringkas maks ~300 titik); gagal -> garis lurus. Peta dibuat ulang saat titik berubah supaya kamera ikut pindah.
- Pencarian alamat (Photon) condong ke Jakarta Selatan agar "Pasar Minggu" tidak nyasar.
- Profil OSRM `foot` -> `driving` (berlaku juga untuk jastip; jarak motor, bukan jalan kaki).
- Tes: 13,9 km -> Rp32.000 (`test/tarif_service_test.dart`).
