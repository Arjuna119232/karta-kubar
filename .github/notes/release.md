### KUNBAR Connect v0.10.0

Warga bisa mengirim FISH, pengurus punya panel kendali.

**Papan Aspirasi & Laporan**
- Tombol Aspirasi di beranda sekarang membuka papan FISH, bukan "segera hadir"
- Form kirim: topik, judul, dan cerita detail, divalidasi sebelum disimpan
- Laporan yang terkirim benar-benar tersimpan di perangkat dan tetap ada saat aplikasi ditutup
- Filter status: Baru, Diproses, Selesai, Ditolak

**Panel Pengurus**
- Menu Panel Pengurus di halaman Profil, terbuka untuk pengurus, RT, RW, dan admin
- Antrean FISH yang perlu tindakan, diurutkan dari yang paling baru
- Tandai Diproses, Selesai, atau Ditolak, dengan catatan untuk warga
- Pintasan ke sesi absensi dan agenda

**Yang diperbaiki**
- Tombol Iuran dan Galeri di beranda sekarang menuju tab yang benar untuk semua level akses
- Angka anggota dan kegiatan di beranda diambil dari data, bukan angka yang ditulis mati
- Tiga baris FISH bawaan diberi label "data contoh" supaya tidak disangka laporan asli
- Pemeriksa kode: method `peta` dan `indeksTab` sempat salah dibaca sehingga melaporkan compile error palsu

**Catatan**
- Panel pengurus masih memakai data di perangkat. Supabase butuh proyek nyata dan aturan RLS.
- Baris "data contoh" tidak ikut tersimpan, jadi begitu warga mengirim laporan asli, yang terlihat hanya laporan asli.
