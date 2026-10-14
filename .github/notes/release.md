### KUNBAR Connect v0.8.0

Mulai dari tahap ini, tampilan diuji di browser dulu sebelum jadi APK.

**Yang diperbaiki**
- Tiga sampul yang kosong karena animasi tidak pernah diputar
- Teks sampul yang terdorong keluar layar
- Karakter asing yang nyasar ke komentar kode

**Struktur**
- Setiap fitur punya folder data, domain, dan presentation
- Semua data lewat satu lapisan repository, layar tidak lagi baca data langsung
- Validasi form pindah ke domain supaya bisa diuji

**Backend**
- Konfigurasi lewat file .env, tidak ada kunci API di dalam kode
- Klien Supabase tanpa paket tambahan besar
- Kartu Sumber data di halaman Profil

**Build**
- APK hanya untuk arm64, sekarang sekitar 18 MB
- AAB tetap tersedia untuk Google Play
