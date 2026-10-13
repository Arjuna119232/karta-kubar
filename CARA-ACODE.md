# KARTA KUBAR — Cara Membuka di Acode

Versi: **0.2.0+2 (FASE 1–2)**
Karang Taruna Kelurahan Kuningan Barat — *Satu Komando, Satu Karya*

## Cara buka di Acode

1. **Ekstrak** file `karta-kubar-v0.2.0-source.zip` ke folder mana saja di HP
   (misal `/storage/emulated/0/Acode/karta-kubar/`).
2. Buka Acode → **Open Folder** → pilih folder `karta-kubar` (folder yang
   berisi `pubspec.yaml`).
3. Tunggu Acode mengunduh **Flutter SDK** (sekali saja, sekitar 1 GB).
4. Tekan **Run ▶** di Acode.

> Folder `android/` sengaja tidak disertakan — Acode/Flutter membuatnya
> sendiri saat pertama kali Run. Folder itu juga tidak disimpan di repo
> GitHub karena selalu digenerate ulang di server.

## Struktur folder

```
lib/
  main.dart                      entry point
  core/
    router.dart                  rute: splash -> onboarding -> home
    providers.dart               Riverpod state
    theme/                       warna, tipografi, tema terang/gelap
    utils/date_id.dart           format tanggal Bahasa Indonesia
  features/
    splash/                      layar pembuka
    onboarding/                  3 slide perkenalan
    shell/                       kerangka 5 tab
    home/                        beranda
    kegiatan/                    daftar kegiatan + filter
    keuangan/                    saldo kas, grafik, riwayat iuran
    galeri/                      galeri kegiatan + berita
    profile/                     profil, kartu anggota + QR, pengaturan
  shared/
    data/seed_data.dart          data demo (offline-first)
    widgets/                     komponen UI yang dipakai berulang
assets/
  data/ fonts/ images/           (disiapkan, masih kosong)
```

## Yang sudah jadi (FASE 1–2)

- **Splash** → **Onboarding** (3 slide, hanya muncul sekali) → **5 tab**
- **Beranda**: sapaan sesuai waktu, pengumuman (carousel), 2 kartu statistik,
  4 aksi cepat, agenda terdekat dengan hitung mundur, berita terbaru
- **Kegiatan**: filter kategori (Semua/Sosial/Olahraga/Keagamaan), dikelompokkan
  menjadi "Akan Datang" dan "Sudah Lewat", detail lewat bottom sheet
- **Keuangan**: kartu saldo, grafik batang kas 5 bulan, riwayat iuran dengan
  status lunas/belum, kartu transparansi
- **Galeri**: grid galeri kegiatan + daftar berita
- **Profil**: header, kartu anggota digital (dengan QR), poin dan kegiatan,
  menu, serta **pengalih tema terang/gelap/otomatis**

## Catatan penting

- Semua data masih **offline** (dari `seed_data.dart`). Belum ada koneksi
  internet dan belum ada login sungguhan. Ini disengaja supaya aplikasinya
  tetap jalan tanpa backend.
- Menu yang belum dikerjakan menampilkan pesan "segera hadir".
- Font: Plus Jakarta Sans (judul) dan Inter (isi).

## Kalau mau lanjut sendiri

Semua layar ada di `lib/features/<nama>/presentation/`. Untuk menambah
halaman: buat folder baru, buat file `*_screen.dart`, lalu daftarkan di
`lib/features/shell/presentation/app_shell.dart`.