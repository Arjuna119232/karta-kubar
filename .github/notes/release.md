### KUNBAR Connect v0.13.2

Tarif ojek dan jastip sekarang jujur: tidak ada lagi harga minimum yang muncul sendiri.

**Masalah yang diperbaiki**
- Alamat tujuan yang diketik tidak pernah dicari koordinatnya, jadi jarak selalu
  nol dan tarif selalu keluar Rp 7.000
- Alamat jemput hanya dari GPS; alamat yang diketik manual tidak pernah dicari
- Pencarian dibatasi satu kali tiap empat detik, jadi kata terakhir yang
  diketik selalu terlewat

**Perbaikan**
- Alamat jemput dan tujuan dicari otomatis setelah berhenti mengetik
- Titik lama otomatis dibuang kalau teksnya berubah
- Jarak dihitung dari mitra ke jemput, lalu jemput ke tujuan
- Peta menampilkan rute jalan yang sebenarnya, bukan garis lurus
- Pencarian alamat condong ke Jakarta Selatan
- Fee antar jastip memakai perbaikan yang sama

**Jujur soal tarif**
- Sebelum lokasi beli dan alamat antar sama-sama ketemu di peta, tarif
  menampilkan "-" dan tombol kirim ditolak dengan pesan yang jelas
- Angka tarif dihitung dari rute kendaraan, bukan jarak lurus

**Contoh**
- Jemput ke tujuan 13,8 km tampil Rp 32.000, bukan Rp 7.000
