# KUNBAR Connect — Cara Membuka di Acode

Versi: **0.6.1**
Kelurahan Kuningan Barat, Jakarta Selatan

## Cara buka di Acode

1. **Ekstrak** file `KUNBAR-Connect-v0.6.1-source.zip` ke folder mana saja di HP
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
    boot.dart                    menentukan halaman pertama SEBELUM runApp
    router.dart                  rute: onboarding | auth | home (tanpa rute '/')
    providers.dart               Riverpod state (tab, tema, sesi login)
    theme/                       warna, tipografi, tema terang/gelap
    utils/date_id.dart           format tanggal Bahasa Indonesia
  features/
    onboarding/                  3 slide perkenalan
    auth/                        masuk/daftar + OTP
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

## Yang sudah jadi (FASE 1–3)

- **Splash native** (logo + hijau solid, maks 1,2 dtk, oleh OS) → **Onboarding**
  (3 slide, hanya muncul sekali) → **Auth** → **5 tab**
- **Auth**: layar Masuk / Daftar (validasi nama + nomor WhatsApp, wajib centang
  Syarat & Ketentuan), lalu **OTP 6 digit** dengan kotak kode, timer kirim
  ulang, dan tombol "Jelajahi tanpa masuk". Kode demo: **123456**
- **Beranda**: sapaan sesuai waktu **dan nama kamu**, pengumuman (carousel),
  2 kartu statistik, 4 aksi cepat, agenda terdekat dengan hitung mundur,
  berita terbaru
- **Kegiatan**: filter kategori (Semua/Sosial/Olahraga/Keagamaan), dikelompokkan
  menjadi "Akan Datang" dan "Sudah Lewat", detail lewat bottom sheet
- **Keuangan**: kartu saldo, grafik batang kas 5 bulan, riwayat iuran dengan
  status lunas/belum, kartu transparansi
- **Galeri**: grid galeri kegiatan + daftar berita
- **Profil**: header, kartu anggota digital (dengan QR), poin dan kegiatan,
  menu, **pengalih tema terang/gelap/otomatis**, dan tombol **Keluar**
  (menghapus sesi, kembali ke layar auth)

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

---

# Tugas 1 - Splash pakai desain baru (prioritas utama)

Folder `aset-dari-user/` berisi desain splash dari pemilik aplikasi.

## Isi folder tersebut

| File | Isi |
|---|---|
| `kubar_splash_master.svg` | desain splash lengkap + animasi |
| `AppStore_x5f_1024.svg` | emblem berwarna untuk ikon |
| `foreground_x5f_1024.svg` | emblem transparan untuk ikon adaptif |
| `PNG-t ekstra-*.png` | emblem yang sudah diekstrak dari SVG |

## Penting: file `.svg` itu sebenarnya bukan vektor

Isinya **PNG 1024/1600 yang disembunyikan di dalam tag `<image>`** sebagai
base64, bukan gambar vektor. Jadi tidak bisa diwarnai ulang atau di-scale
dengan mulus.

Yang **benar-benar vektor** cuma isi file PNG hasil ekstrak
(`PNG-t ekstra-*.png`) — itu yang dipakai.

## Penting: animasi SMIL tidak jalan di Flutter

File SVG itu punya animasi (tag `<animate>` dan `<animateTransform>`), tetapi
Flutter **tidak bisa memutar SMIL** — baik `Image.asset` maupun `flutter_svg`
hanya menampilkan gambar diam.

**Jadi animasinya harus ditulis ulang di Dart**, bukan memuat SVG-nya.
Lapisan animasi pada desain:

| Lapisan | Gerakan | Durasi | Berulang |
|---|---|---|---|
| Grid latar | geser 0,0 → 100,100 → 0,0 | 12 detik | ya |
| Cahaya (glow) | jari-jari 430 → 470 → 430 | 4 detik | ya |
| Logo | skala 1 → 1.03 → 1 | 3 detik | ya |
| Titik loading | opasitas 0.3 → 1 → 0.3 | 1,2 detik | ya, jeda 0,2 dan 0,4 detik |

Gunakan satu `AnimationController` untuk tiap lapisan, atau satu controller
yang dipakai bersama dengan nilai berbeda.

## Warna pada desain

```
latar      #1B5E20   (hijau tua solid)
teks       #FFFFFF
teks 2     #C8E6C9
grid       #2E7D32
cahaya     #FFC107 dengan opasitas rendah
```

⚠️ **Masalah yang harus diputuskan:** tema terang aplikasi sekarang
`#F6F7F9` (abu netral). Kalau splash hijau tua, layar akan lompat warna saat
aplikasi terbuka. Pilih salah satu:

- (a) ubah tema terang jadi hijau muda lembut agar nyambung dengan splash
- (b) biarkan tema terang abu-abu, terima lompatan warna
- (c) dua versi splash, terang dan gelap, mengikuti tema perangkat

## Perhatikan juga

Teks di file SVG masih tertulis `KUBAR CONNECT`. Nama aplikasi yang benar
adalah **`KUNBAR CONNECT`** — tolong dibetulkan.