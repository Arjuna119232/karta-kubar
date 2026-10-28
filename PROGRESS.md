# PROGRESS — KUNBAR Connect

Berkas ini supaya sesi baru bisa melanjutkan tanpa membaca ulang semua riwayat.

**Terakhir diperbarui:** 16 Okt 2026
**Versi aplikasi:** 0.13.0+25 (build 20 = 0.7.0 sudah DIRUSAK, jangan dipakai sebagai acuan)

---

## Ringkasan

Aplikasi warga Kuningan Barat, satu codebase Flutter untuk Android + iOS.
Splash dan 3 sampul sudah selesai. Lapisan data + backend Supabase sudah
disiapkan. Yang tersisa: konfigurasi `.env` asli dan verifikasi di perangkat.

---

## Tahap per fitur

| # | Tahap | Status | Commit |
|---|---|---|---|
| 11 | UMKM warga + Lapor darurat | ✅ | (commit ini) |
| 0 | Fondasi: tema M3, ikon, router, build CI | ✅ | `c3d6bb3`, `1440406` |
| 1 | ~~`SplashScreen` + `onFinished`~~ (diganti splash native 15 Okt) | ✅ | `f512dca` |
| 2 | `OnbArt` (aspirasi, komunitas, terhubung) untuk 3 sampul | ✅ | `f512dca` |
| 3 | `.env` → `--dart-define` → `AppEnv`, tanpa API key di kode | ✅ | `8a4a2eb` |
| 4 | Lapisan repository + klien Supabase + role warga/admin | ✅ | `8a4a2eb` |
| 5 | Struktur `{data,domain,presentation}` per fitur | ✅ | `0580097` |
| 5a | Pembersihan karakter non-Latin + alat cek repo-wide | ✅ | `8ba3a2d` |
| 6 | Build APK arm64 (~18 MB) + AAB + dokumen signing | ✅ | `9f0e8e3` |
| 7 | README + PROGRESS.md | ✅ | `0580097` |
| 8 | Splash native Android 12+ + iOS `UILaunchScreen` (logo + warna solid, tanpa frame putih) | ✅ | `c100e61` |
| 9 | Nama lengkap "KUNBAR CONNECT" + kredit "from Katar KunBar" seragam di Android & iOS | ✅ | `09cb8df`, `a41e283`, `3c12216` |
| 10 | FISH warga (kirim + pantau status) + Pengurus (antrean + aksi status) | ✅ | `bc3f88e` |
| 11 | UMKM warga + Lapor darurat | ✅ | `04e81e6` |
| 12 | Overhaul tampilan v6 (satu bahasa visual untuk semua layar) | ✅ | (commit ini) |
| 13 | Empat tombol kosong jadi fitur nyata: kalender, unduh CSV, unggah galeri, edit profil | ✅ | `fc97844` |
| 14 | Order Jastip & Ojek: schema, model, service, 7 layar, peta gratis | ✅ | (commit ini) |

### Status 15 fitur APK (dicek dari kode, bukan dari daftar)

| # | Fitur | Status | Kenyataan |
|---|---|---|---|
| 1 | Berita & pengumuman | ✅ | Pengumuman di beranda, berita di Galeri |
| 2 | Agenda kegiatan | ✅ | Layar Kegiatan + filter kategori |
| 3 | Galeri | ✅ | Berita + sampul |
| 4 | UMKM warga | ✅ | Katalog + filter kategori + form pengajuan (v0.11.0) |
| 5 | Peta wilayah | ❌ | Butuh tile OpenStreetMap (gratis, tanpa API key) |
| 6 | Aspirasi & pengaduan | ✅ | Papan FISH + filter status + form kirim |
| 7 | Lapor darurat | ✅ | Tombol merah + nomor 112/119/110/115 + riwayat status (v0.11.0) |
| 8 | Forum warga | ❌ | Skema `forum_topik` + `forum_balasan` sudah ada |
| 9 | Booking fasilitas | ❌ | Skema `fasilitas` + `booking` sudah ada |
| 10 | Donasi | ❌ | Skema ada. **Butuh Midtrans** (akun merchant) untuk uang sungguhan |
| 11 | Absensi kegiatan | ✅ | QR + riwayat, khusus anggota |
| 12 | Kartu anggota digital | ⚠ | Kartu sudah ada, **QR-nya masih gambar tiruan** (belum bisa discan) |
| 13 | Chat | ❌ | Skema `pesan` ada. Butuh login Supabase Auth + Realtime |
| 14 | Profil | ✅ | Kartu anggota, hak akses, menu |
| 15 | Pengaturan | ✅ | Tema, mode Lansia, status backend, edit profil, notifikasi, bantuan |

**Angka: 11 jadi, 1 setengah, 3 belum.** Tidak ada fitur yang ditandai selesai
padahal baru kerangka.

### 16 fitur Panel Pengurus (web)

Belum ada. Semuanya masuk ke satu web console berbasis Node tanpa dependency,
sumber data sama dengan APK (Supabase).

Prioritasnya: verifikasi warga, moderasi FISH, broadcast pengumuman, rekap
kas, laporan, kelola role, audit log, export CSV/PDF.

### Yang TIDAK bisa dibuat tanpa akun/kredensial lain

| Fitur | Yang dibutuhkan |
|---|---|
| Donasi sungguhan | Akun merchant Midtrans + kunci API |
| Push notification | Project Firebase (FCM) |
| Broadcast WhatsApp | Akun WhatsApp Business + template disetujui |
| Verifikasi NIK otomatis | **Tidak ada API publik.** Cuma verifikasi manual + OCR KTP |
| Peta | OpenStreetMap (gratis, tanpa kunci) — sudah jadi pilihan |

### Fitur yang sudah ada dan jalan

- Splash **native** (Android `Theme.SplashScreen` + iOS `UILaunchScreen`) →
  onboarding / beranda / login, maks 1,2 dtk, tanpa frame putih
- Onboarding 3 slide beranimasi, bisa digeser
- Masuk / daftar (mode demo, OTP `123456`)
- Beranda: greeting, pengumuman, berita, agenda, aksi cepat
- Kegiatan: filter kategori, kalender bulanan bertanda hari ada acara, tinggi
  ilustrasi dihitung dari lebar layar
- Absen: scan QR tiruan, riwayat, ubah status
- Keuangan: saldo, grafik kas 5 bulan, riwayat iuran, unduh laporan kas CSV
  (salin ke clipboard atau bagikan lewat sheet Android)
- Galeri: berita + sampul + unggahan foto warga (tersimpan di perangkat)
- Aspirasi & Laporan: kirim FISH, filter status, tersimpan di perangkat
- Panel Pengurus: antrean FISH, tandai Diproses/Selesai/Ditolak + catatan
- Profil: kartu anggota, level akses 5 tingkat, **kartu "Sumber data"**
- Mode terang/gelap + mode Lansia
- Edit profil, Notifikasi, dan Bantuan sebagai layar penuh


### Bentuk layar setelah overhaul v6

Semua layar sekarang memakai satu set komponen bersama di
`lib/shared/widgets/`: `app_card`, `app_dialogs` (dialog + bottom sheet),
`primary_button`, `section_header`, `status_views` (skeleton, state kosong,
state galat), `shimmer_box`, `loading_dots`, `animated_list_item`,
`fade_slide_in`, `animated_fab`, `flip_card`, `confetti`. Efek dan ikon
dipusatkan di `lib/core/theme/` (`app_colors`, `app_spacing`, `app_shadows`,
`app_typography`, `app_assets`) dan getaran di `lib/core/utils/haptics.dart`.

### Komponen yang disimpan tapi belum dipakai

`AppSurface`, `AppSheet`, `AppDialog`, `GlassCard`, `ModernCard`,
`AnimatedButton`, dan `Haptics` (versi lama) **TIDAK dihapus**. User: jangan
ada yang dipangkas, ukuran APK tidak jadi pertimbangan. Semuanya dikembalikan
dan diperbaiki supaya tetap bisa dikompilasi, lalu didaftarkan di
`tool/keep_unused.txt` supaya `tool/check_dart.py` menandai mereka sebagai
CATATAN, bukan MASALAH.

Daftar lengkap ada di `tool/keep_unused.txt`. Kalau nanti salah satu dipakai,
hapus barisnya supaya daftarnya tetap jujur.

### APK universal

Default build sekarang **universal** (arm64-v8a + armeabi-v7a + x86_64):
satu berkas bisa dipasang di HP mana pun, emulator, dan Chromebook. Pilih
`arm64` hanya kalau sedang mengejar APK paling kecil.

### Belum dikerjakan (sengaja)

- Backend Supabase **sungguhan** — baru lapisan kodenya, belum ada proyek
  Supabase terisi.
- Verifikasi identitas warga (NIK). Tidak ada API publik untuk itu.
- Iuran QRIS / Midtrans, FCM, WhatsApp Business, peta.
- Build iOS — sudah disiapkan (`tool/patch_ios.py`, `build-ios.yml`), tidak
  dijalankan sampai Android pas.

---

## Cara menjalankan

### Melihat perubahan tampilan (TANPA build APK)

Pratinjau splash + 3 sampul dengan animasi CSS, angka salinan Dart:
- `design/browser/splash-native.html` — splash native 2026 + handoff + cek aturan
- `design/browser/index.html` — 3 sampul onboarding

```bash
cd ~/karta-kubar
python3 -m http.server 8484 --bind 127.0.0.1 &
am start -a android.intent.action.VIEW \
  -d "http://127.0.0.1:8484/design/browser/index.html"
```

> Ini wajib dipakai setiap kali mengubah tampilan. Satu build APK ≈ 5-6
> menit; satu edit HTML ≈ 3 detik.

### Pratinjau statis (PNG)

```bash
python3 design/preview_baru.py     # -> design/pratinjau-*.png
```

### Build APK

Build selalu lewat GitHub Actions (Flutter tidak bisa di Termux):

```bash
git push origin main
gh run watch
gh release download <tag> -D /tmp/x
```

Hasil: APK ~18 MB (arm64 saja) + AAB untuk Play Store.

---

## Sebelum commit

```bash
python3 tool/check_dart.py       # WAJIB — blocking di CI
python3 tool/check_nonlatin.py   # WAJIB — blocking di CI
flutter analyze                  # kalau Flutter terpasang
```

Dan selalu:

```bash
grep -rn "Lokal\." lib/features/*/presentation/   # harus kosong
```

---

## Jebakan yang sudah pernah kejadian (jangan diulang)

1. **Build hijau ≠ aplikasi jalan.** Flutter hanya mengompilasi file yang
   terjangkau dari `lib/main.dart`. File yatim dengan `undefined name` lolos
   4 rilis. `tool/check_dart.py` yang menangkapnya.
2. **`AnimationController` yang hanya dibaca `.value` di `build` tanpa
   listener** → widget tidak pernah dibangun ulang → opacity 0 → layar
   kosong. Dua `AnimatedBuilder` bersarang.
3. **`Column` + `Spacer(flex:)` bukan centering.** Pakai `Stack` + `Center` +
   `Positioned(bottom:)`.
4. **`Padding(right:)` di item terakhir `Row` yang di-center** → seluruh
   kelompok bergeser setengah jarak.
5. **Ganti-string massal menyisakan prefiks.** `SeedData.activities` →
   `KegiatanLokal.kegiatan`, tapi `SeedData.activityCategories` menjadi
   `SeedData.KegiatanLokal.kategori`. Setelah refactor massal, selalu `grep`
   nama kelas lama.
6. **Satuan campur di pratinjau.** `tinggi = fs * SCALE` (px) lalu dipakai
   sebagai dp → semua teks di bawahnya bergeser. Satu daftar tinggi harus
   satu satuan.
7. **Huruf Mandarin dari IME** pernah nyasar ke komentar `.py` dan `.dart`.
   `tool/check_nonlatin.py` sekarang menjaga seluruh repo.
8. **Indeks tab tidak boleh dipatok.** Jumlah tab berbeda per role, jadi
   `navigationIndexProvider = 3` mendarat di tab yang salah untuk role lain.
   Pakai `indeksTab(role, 'label')` dari `features/shell/data/app_tabs.dart`.
9. **Angka statistik tidak boleh ditulis mati di layar** (`value: '128'`).
   Ambil dari repository lewat `ringkasanBerandaProvider`.
10. **Pakai `ScaffoldMessenger` yang diambil SEBELUM `Navigator.pop()`.**
    Setelah sheet ditutup, `context` sudah tidak terpasang.
11. **`required this.x` tanpa `final bool x;` = compile error.** Nimanya ketahuan
    hanya saat CI compile (v0.10.0 build pertama gagal 4 baris error).
    `tool/check_dart.py` punya cek `FIELD-HILANG` untuk itu.

---

## Kalau sesi baru mulai

Baca berurutan:

1. `PROGRESS.md` (berkas ini)
2. `README.md` — cara build, signing, backend, iOS
3. `AGENTS.md` di `~/.config/zyvo/` — keputusan & jebakan per tahap
4. `git log --oneline -15` — urutan perubahan

Lalu cek cepat:

```bash
cd ~/karta-kubar && git status --short && python3 tool/check_dart.py | tail -3
```
## v6.0.0+22 — Rombak UI/UX (design system v6)
- Design system: `app_spacing`, `app_shadows`, `app_assets`, gradient preset, tema (transisi Cupertino, dialog/sheet/snackbar/FAB/chip), mode lansia 1,3x + tombol 64dp + kontras tinggi.
- Widget baru: `AnimatedButton`, `GlassCard`, `Shimmer*`, `AnimatedListItem`, `EmptyState`, `ErrorState`, `ModernCard`, `AnimatedFab`, `LoadingDots`, `FlipCard`, `Confetti`, `AppDialog`/`AppSheet`, `Haptics`.
- Spinner polos, AlertDialog, dan warna hardcode sudah diganti token.
- Catatan: build number sengaja 22 (bukan 6) supaya bisa menimpa v0.11.0+21 di HP.


---

## Order Jastip & Ojek (0.13.0, 16 Okt 2026)

### Yang sudah jadi

- **Schema** (`supabase/schema.sql` bagian 12-14): `mitra_jasa`,
  `order_jastip`, `order_ojek`, `order_tracking`, `review_order` + RLS +
  realtime publication. Semua memakai `warga_id` nullable FK ke `public.profiles`
  plus `warga_kunci` stabil per perangkat, karena login APK belum Supabase Auth.
- **Model** (`lib/shared/models/`): `order`, `order_jastip`, `order_ojek`,
  `mitra_jasa`, `order_tracking`, `review_order`, `order_ringkas`. Plain Dart
  tanpa codegen.
- **Service** (`lib/shared/services/`): `lokasi_service` (geolocator + Photon +
  OSRM, semua keyless), `tarif_service`, `tracking_service`,
  `order_repository` (lokal), `order_service_base`, `jastip_service`,
  `ojek_service`, `review_service`.
- **Layar** (`lib/features/order/presentation/`): form jastip, form ojek,
  tracking, riwayat, daftar semua, detail, rating, `widgets_order` (peta,
  kartu order, timeline status, bintang, pilihan bayar).
- **Beranda**: dua menu besar Jastip dan Ojek, bagian "Order Berjalan", dua
  aksi cepat baru.
- **8 rute**: `/jastip/form`, `/ojek/form`, `/jastip/history`,
  `/ojek/history`, `/order/list`, `/order/tracking/:jenis/:id`,
  `/order/detail/:jenis/:id`, `/order/rating/:jenis/:id`.

### Yang SENGAJA belum ada (disebut apa adanya di UI)

| Fitur | Kenyataan |
|---|---|
| Order masuk ke server | Baru tersimpan di perangkat. Kirim otomatis begitu Supabase Auth menyala; RLS-nya sudah ditulis sekarang |
| Posisi mitra bergerak | Peta baru menampilkan titik yang dikirim aplikasi Mitra. формы tracking menihilkan ini di UI |
| Nomor mitra | Belum ada di backend, jadi tombol "Hubungi mitra" hanya memberi tahu, bukan membuka telepon |
| Pilih driver otomatis | Mitra masih data contoh; begitu backend nyala, repository mengembalikannya |
| QRIS | Terlihat di form tapi tidak bisa dipilih (butuh akun merchant) |
| Notifikasi push | Butuh FCM |

### Peta gratis

`any_map` + `any_map_maplibre` (MapLibre) + OpenFreeMap. Style yang benar:
`https://tiles.openfreemap.org/styles/liberty` (URL `openfreemap.org/style.json`
yang biasa muncul di tutorial mengembalikan 404). Pencarian alamat dari Photon,
rute jalan kaki dari OSRM, cadangan haversine kalau jaringan gagal.

Paket `maplibre_gl` yang dibawa `any_map_maplibre` WAJIB Java 21 di CI.
`geolocator` dikunci di 12.x (13.x mengganti `getCurrentPosition` ke
`locationSettings`).

### Cek build

`flutter analyze` sudah 0 error 0 warning. Lint mekanis dibersihkan otomatis
di CI oleh `dart fix --apply`. `tool/check_dart.py` tetap blocking.

## v0.14.2 — paket "full fix" dari AI lain (AUDIT, sebagian kecil diambil)

Paket `kunbar-full-fix.zip` (438 entri) **bukan** patch di atas v0.14.1, tapi
*cabang penuh* dari state lama. 10 berkas berbeda + 3 berkas baru, hampir
semuanya regresi:

| Isi paket | Putuskan | Alasan |
| --- | --- | --- |
| `core/services/location_service.dart` (baru) | TOLAK | duplikat geocoder kedua (dua sumber kebenaran), bias coords `-6.2500/106.8230` = **salah ~1,3 km** (pusat resmi Nominatim `-6.2365/106.8219`) |
| `shared/widgets/address_autocomplete.dart` (baru) | TOLAK | duplikat `alamat_autocomplete.dart` |
| `ojek/presentation/map_picker_screen.dart` (baru) | TOLAK | duplikat `pilih_lokasi_peta.dart` + ganti peta ke `flutter_map` |
| `mitra_usaha_lokal.dart` (lat ~-6.248) | TOLAK | koordinat dihitung ulang per jalan dari basis salah; merusak sebaran *golden angle* yang sudah diverifikasi |
| `mitra_usaha.dart` | TOLAK | `Color(0xFF1B5E20)` mentah + `Icons.*` Material (larangan design system) |
| `order.dart`, `pilih_lokasi_peta.dart` | TOLAK | `titikKuninganBarat` di-*reset* ke `-6.2500/106.8230` |
| `mitra_usaha_peta.dart` (`flutter_map`) | TOLAK | ganti lib peta; kartu terpilih + auto-fit + pin ikon sudah ada di HEAD |
| `order_form_ojek.dart` | TOLAK | hanya rewiring ke widget duplikat |
| `pubspec.yaml` (`flutter_map`, `latlong2`, `geolocator ^13.0.1`) | TOLAK | `geolocator` 13.0.1 sudah terbukti merusak build (12.0.0 yang dipakai) |
| `build.yml`, `test/tarif_service_test.dart` | IDENTIK | tidak ada yang perlu diambil |
| **GPS menampilkan nama jalan** | **DIAMBIL** | satu perbaikan nyata (lihat bawah) |

**Perbaikan yang diambil:** tombol "lokasi HP" mengisi kolom alamat dengan
`-6.23649, 106.82187` (angka mentah). Sekarang diisi nama jalan dari
reverse geocode. `TitikPeta` dapat field `alamat` (opsional, default kosong,
`teks` memprioritaskan alamat), `LokasiService.posisiSayaBeralamat()` =
`posisiSaya()` + `reverseAlamat()`, dipakai form ojek **dan** jastip.
Kalau server tidak terbaca, koordinat tetap dipakai — pemesanan tidak boleh
gagal hanya karena nama jalannya tidak ketemu.

## v0.14.3 — reverse geocode cepat (Photon utama + cache + status gagal)

Brief dari user menyebut `LocationService.reverseGeocode()` dan
`MapPickerScreen` — **dua nama itu tidak ada di repo ini**, keduanya berasal
dari cabang `kunbar-full-fix.zip` yang ditolak (lihat v0.14.2). Implementasi
sesuai kode asli: `LokasiService.reverseAlamat()` dan
`PilihLokasiPetaScreen` (`pilih_lokasi_peta.dart`).

- **Photon jadi API utama** `GET https://photon.komoot.io/reverse?lat&lon&lang=id`,
  batas 4 detik. Balasan `/reverse` tidak punya `display_name`, jadi
  `_bacaPhoton()` merangkai `name/street/houseNumber/district/city/county/
  state/postcode/country`, membuang bagian kosong dan duplikat, maksimal 4
  bagian. Nominatim tetap cadangan dengan batas 6 detik, `format=jsonv2`,
  `zoom=18`, `accept-language=id`, User-Agent `KUNBARConnect/1.0` (sudah
  dipasang di `HttpClient.userAgent`).
- **Cache balik alamat** `_cacheReverse` (static, kunci koordinat 4 desimal
  ~11 m, maksimum 60 entri). Geser balik ke titik yang sama = instan.
  Hanya hasil **yang tidak kosong** yang disimpan, supaya jaringan yang
  pulih lalu tombol "Coba Lagi" tetap bisa berhasil.
- **Debounce 400 ms** di peta. Sebelumnya tiap `onCameraIdle` langsung
  memanggil server, jadi drag sedikit sudah menembak API.
- **Statusnya jujur, tidak menggantung:** saat nunggu tampil koordinat +
  "Mencari alamat..." + spinner kecil; sukses = alamat penuh + ikon pin;
  gagal = koordinat + "Alamat tidak tersedia" + tombol **Coba Lagi**.
  `AnimatedSwitcher` 220 ms supaya tidak terlihat melompat.
- Hasil basi dibuang: kalau titik tengah sudah berubah selama menunggu,
  jawabannya tidak dipakai.
- Ikon pakai `Ik.error` / `Ik.refresh` / `Ik.pinMitra` (setStandar proyek),
  bukan emoji.

## v0.14.4 — 59 mitra usaha dengan koordinat asli warga (16 Okt 2026)

Warga mengirim daftar warung, pasar, agen gas, dan depot air (4 pesan
WhatsApp, 47 baris) dariAI lain. Datanya **jauh lebih akurat** dari 47
mitra sebelumnya, yang koordinatnya adalah perkiraan per jalan + offset
golden angle. Contoh kesalahan lama: Toko Buyung pk di `-6.2600` padahal
Jl. Bangka IX ada di `-6.2451` (1,6 km meleset).

### Yang berubah

| | lama | baru |
|---|---|---|
| jumlah mitra | 47 | **59** |
| koordinat asli warga | 0 | **40** |
| titik ditandai perkiraan | semua diam-diam | **19** (tampil di UI) |
| jam buka terkonfirmasi | 0 (semua karangan) | **22** |
| jam buka "belum dikonfirmasi" | - | **37** |

- **13 mitra baru** (8 warung kelontong/sembako + 5 kuliner Madura),
- **1 duplikat digabung**: "Agen Galon Le Minerale Krisnadi" dan
  "AGEN GAS dan AQUA KRISNADI" ternyata satu toko (RT.5/RW.4 sama),
- **19 mitra tanpa koordinat warga** dicoba geocode Nominatim. Hasil
  hanya diterima kalau jatuh di dalam borough yang benar dan maksimal
  700 m dari centroid kelurahan (centroid dihitung dari 41 titik warga).
  4 hasil ditolak: SMP Negeri 43 (Jl. Kapten Tendean), "Jalan Kuningan
  Barat IV" untuk kueri Mampang Prapatan XV, centroid kecamatan, dan
  Jalan Kemang Utara di Duren Tiga (kelurahan lain).
- **Alamat dilengkapi `Kel.`** — dipakai form jastip/ojek sebagai
  alamat tujuan.
- **Pasar Rengas**: alamat lama "Rawa Barat / Kebayoran Baru" salah,
  OSM menaruh Pasar Rengas di **Jl. Rengas I, Kel. Kuningan Barat**.
- **Jam buka dusta dibuang.** Pasar Ar Riyadh tadinya `05:00 - 11:00`
  (karangan) sehingga lencana menampilkan "Tutup sekarang" padahal
  buka sampai 22.30. Sekarang lencana buka/tutup **tidak ditampilkan**
  kalau jam buka belum dikonfirmasi warga (`jamBukaPasti`).
- **Peta mitra** dapat tombol **zoom in / zoom out** di tengah kanan.

### Peta mitra

- Pin memakai `AnyLatLng(m.titik.lat, m.titik.lng)` dengan
  `AnyMarkerAnchor.center`, jadi titik persis di koordinat — tidak ada
  offset buatan anymore.
- `any_map` 1.0.0 tidak punya tombol zoom bawaan dan adapter MapLibre
  **tidak meneruskan `onCameraMove`** ke peta asli. Jadi tombol membaca
  `getCameraPosition()` lalu `animateCamera()` dengan zoom +/- 1,
  dibatasi 11-18. Jangan pakai `onCameraMove` di sini.
- `initialCamera` hanya berlaku sekali, jadi ganti filter kategori tidak
  memindahkan kamera (batasan library, bukan bug).

### Alur pembaruan data mitra

Jangan edit 755 baris Dart secara manual. Sumber kebenaran =
`tool/data_mitra_baru.json`, ditulis oleh `tool/gen_mitra_usaha.py`:

```bash
python3 tool/gen_mitra_usaha.py   # validasi dulu, gagal = berkas Dart utuh
python3 tool/check_dart.py        # harus 0 masalah
python3 tool/check_nonlatin.py    # harus 0 masalah
gh workflow run build.yml --ref feat/order-jastip-ojek -f analyze-only=yes -f release=no
```

Generator menolak menulis kalau: kelurahan/kategori tidak dikenal, pola
jam buka salah, ada karakter non-Latin, ada dua pin < 5.5 m, id/nama
ganda. Helper di ekor file (`jumlahKelurahan`, `mitraUsahaById`,
`saringMitraUsaha`, `mitraTerdekat`, `produkUmum`) diambil ulang dari
berkas yang ada sebelum ditulis, dan hasil tulis dibaca balik untuk
diverifikasi.

## Absensi QR: kamera asli (28 Okt 2026)

Sebelumnya tombol "Pindai QR" hanya menampilkan lembar tiruan — tidak ada
kamera sama sekali, jadi absensi tidak pernah bisa dari QR pengurus.
Sekarang memakai kamera sungguhan.

- Paket: **`mobile_scanner: ^6.0.11`**. Versi 7.x **tidak bisa dipakai**:
  butuh SDK `^3.7.0` + Flutter >= 3.29, sedangkan project masih
  `>=3.4.0 <4.0.0`. 6.0.11 = ML Kit offline, tidak butuh internet.
- Izin `CAMERA` disuntik `tool/patch_android.sh` (bagian 2) dan ikut
  diverifikasi di bagian 5. Tanpa ini `MobileScanner` langsung
  `permissionDenied`.
- Lembar pindai: `lib/features/absen/presentation/qr_absen_sheet.dart`
  (`QrAbsenSheet.tampilkan(context) -> Future<Kegiatan?>`), berisi kamera,
  bingkai 4 sudut, tombol lampu + ganti kamera, dan kartu konfirmasi.
  `absen_screen.dart` hanya memanggilnya lalu `_catat`.
- ⛔ **`stop()` harus di-`await` sebelum `start()`** saat memindai ulang.
  Memanggil `start()` saat `stop()` masih berjalan melempar
  `controllerAlreadyInitialized` dan kamera mati sampai lembar ditutup.
- QR dibaca oleh `bacaAbsenKode()` di `absen_state.dart` (bentuk
  `karta-kubar://absen/YYYYMMDD/<judul>`). **Tanggal rusak/kosong TIDAK
  membatalkan absen** — `tanggal` jadi `null`, judul tetap dipakai.
- ⛔ `absenPayload()` tidak boleh memakai `a.tanggal!`: baris kegiatan dari
  server bisa tanpa tanggal dan itu crash saat pengurus membuka panel QR.
  Tanggal kosong ditulis sebagai segmen kosong.
- Judul QR dicocokkan ke `kegiatanProvider` (case-insensitive). Kalau tidak
  ada (QR dari daftar versi lain), kehadiran tetap dicatat memakai data QR.
- Ikon baru `assets/icons/bolt.svg` + `flip.svg` (duotone, gaya sama dengan
  ikon lain), masuk enum `Ik` sebagai `bolt`/`flip`.
- Uji: `test/absen_kode_test.dart` (round-trip payload, tolak teks bukan QR,
  tanggal 20260231 jadi null, kegiatan tanpa tanggal tetap bisa di-QR).
