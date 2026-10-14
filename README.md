# KUNBAR Connect

Aplikasi warga **Kuningan Barat** — satu untuk Android **dan** iOS dari satu
kode yang sama.

> Nama di layar: **KUNBAR**. Nama proyek di `pubspec.yaml`: `kubar_connect`.

---

## Isi

1. [Struktur proyek](#struktur-proyek)
2. [Menjalankan di mesin sendiri](#menjalankan-di-mesin-sendiri)
3. [Build Android](#build-android)
4. [Menandatangani rilis (keystore)](#menandatangani-rilis-keystore)
5. [Menyimpan keystore dengan aman](#menyimpan-keystore-dengan-aman)
6. [Backend Supabase](#backend-supabase)
7. [Build iOS (nanti)](#build-ios-nanti)
8. [Pemeriksaan otomatis](#pemeriksaan-otomatis)

---

## Struktur proyek

Satu codebase Flutter. Folder `android/` dan `ios/` **dibuat ulang di CI**, jadi
tidak ikut git — itulah sebabnya `tool/patch_*.py` semuanya idempotent.

```
lib/
  core/
    auth/         session + level akses (guest/warga/anggota/pengurus/admin)
    config/       AppConfig + AppEnv  <- semua kunci/config dari --dart-define
    data/         Hasil<T>, klien Supabase REST, provider repository
    router.dart   go_router + penjaga rute per role
    theme/        Material 3, palet hijau, mode terang/gelap
  features/
    <fitur>/
      domain/     model murni (tanpa sumber data, tanpa Flutter)
      data/       data lokal + repository (Lokal | Supabase)
      presentation/  layar
  shared/widgets/ komponen yang dipakai lintas fitur
assets/
  brand/          logo & emblem
  ilustrasi/      ilustrasi onboarding & sampul
  icons/          ikon SVG
```

Aturan yang dijaga alat otomatis:

- **Tidak ada layar yang membaca data demo langsung.** Semua lewat
  `ref.watch(...Provider)`. Bukti:
  `grep "Lokal\." lib/features/*/presentation/` harusnya kosong.
- **Tidak ada URL/API key di file Dart.** Semuanya lewat `--dart-define`.
- **Satu kelas = satu file**, dan semua file harus terjangkau dari
  `lib/main.dart`.

---

## Menjalankan di mesin sendiri

Prasyarat: Flutter SDK (stable) dan Android SDK.

```bash
flutter --version          # pastikan >= 3.27 (pakai Color.withValues)
flutter pub get
flutter run
```

Tanpa backend, aplikasi jalan penuh dalam **mode lokal** (data demo di
perangkat, kode OTP `123456`). Tidak ada yang perlu dikonfigurasi.

> **Catatan:** proyek ini pernah dibangun sepenuhnya dari HP (Termux) lewat
> GitHub Actions. Flutter tidak bisa di-build di dalam Termux, jadi build
> selalu lewat `.github/workflows/build.yml`.

---

## Build Android

### APK (untuk dibagikan langsung)

```bash
flutter build apk --release --target-platform android-arm64
```

Hasil: `build/app/outputs/flutter-apk/app-release.apk` — **sekitar 18 MB**.

`--target-platform android-arm64` membuat
APK hanya berisi satu arsitektur CPU. Semua HP Android modern (2017 ke atas)
memakai arm64, jadi tidak ada yang kalah fungsi.

| Opsi | Ukuran | Untuk siapa |
|---|---|---|
| `--target-platform android-arm64` | ~18 MB | HP Android modern — **rekomendasi** |
| `--split-per-abi` | 3 file, ~14-18 MB tiapnya | Installer per CPU |
| tanpa flag (universal) | ~53 MB | Emulator x86, HP sangat lama |

> APK arm64 **tidak bisa** dipasang di emulator `x86_64`/`x86`. Untuk tes di
> emulator, pakai AAB lewat `bundletool`, atau build tanpa flag.

### AAB (untuk Google Play)

```bash
flutter build appbundle --release
```

Play Store **wajib** memakai AAB untuk aplikasi baru. Play otomatis memisah
per ABI saat memasang, jadi ukuran unduhan pengguna tetap kecil.

---

## Menandatangani rilis (keystore)

Build tanpa konfigurasi apa pun menghasilkan APK bertanda tangan **debug**.
Itu **tidak bisa** diunggah ke Play dan **tidak bisa** dipakai untuk memperbarui
aplikasi yang sudah terpasang (tanda tangan harus sama).

### 1. Buat keystore sekali saja

```bash
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias kartakubar
```

Kata sandi minimal 6 karakter. **Jawab `yes` saat ditanya "same password for
key and store"** supaya signing otomatis.

### 2. Daftarkan sidik jari sertifikat (sha-256)

```bash
keytool -list -v -keystore upload-keystore.jks -alias kartakubar \
  | grep 'SHA256'
```

Simpan sidik jarinya. Kalau hilang, Play Console tidak akan pernah menerima
aplikasi yang ditandatangani ulang dengan keystore berbeda.

### 3. Siapkan `android/key.properties`

Folder `android/` dibuat ulang tiap build, jadi file ini harus dibuat **di
setiap mesin / runner**:

```properties
storeFile=upload-keystore.jks
storePassword=...
keyAlias=kartakubar
keyPassword=...
```

> `storeFile` relatif ke `android/app/`, bukan `android/`. Salah di sini bikin
> build gagal dengan error yang membingungkan.

### 4. Pasang blok `signingConfigs`

`tool/patch_signing.py` sudah mengerjakan ini otomatis dan
idempotent (ditandai `// KUNBAR-SIGNING`). Kalau Anda membuat folder
`android/` sendiri, jalankan skrip itu setelahnya.

### Verifikasi hasilnya

```bash
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

Kalau yang muncul `CN=Android Debug`, berarti signing belum terpasang.

---

## Menyimpan keystore dengan aman

Aturan besarnya: **keystore hanya boleh ada di dua tempat** — laptop/komputer
anda, dan Secret Manager CI. Tidak di dalam git, tidak di WhatsApp, tidak di
cloud drive yang disharing.

| Yang disimpan | Di mana | Keterangan |
|---|---|---|
| `upload-keystore.jks` | Secret `KK_KEYSTORE_BASE64` | base64 file, bukan file-nya |
| Kata sandi store | Secret `KK_KEYSTORE_PASSWORD` | |
| Alias | Secret `KK_KEY_ALIAS` | `kartakubar` |
| Kata sandi key | Secret `KK_KEY_PASSWORD` | |
| Cadangan offline | Flashdisk / HDD tersandi | **wajib ada**, minimal 2 salinan di tempat berbeda |

Membuat base64 untuk GitHub Secrets:

```bash
base64 -w 0 upload-keystore.jks > keystore.b64
# salin isi keystore.b64 ke Settings > Secrets and variables > Actions
```

Aturan tambahan:

- Jangan pernah `git add` keystore. `.gitignore` sudah menutup `*.jks`,
  `*.keystore`, `*.p12`, dan `key.properties` — tapi `.gitignore` hanya menyingkirkan
  file yang **belum** pernah ter-commit. Kalau terlanjur,
  riwayat git harus dibersihkan dan kunci considered sudah bocor (rotasi).
- Keystore yang hilang = aplikasi tidak bisa pernah diperbarui. Simpan
  salinan offline, bukan cuma di laptop.
- Untuk menyimpan kunci API, jangan pernah pakai `--dart-define` untuk
  `service_role` key. Kunci itu harus tinggal di server.

### Kalau ingin ganti library Android ke publik

Buat keystore **baru**, upload **sebagai upload key**, lalu aktifkan **Play
App Signing**.Mulailah dengan begitu, keystoreupload bisa hilang tanpa
menghapusgjaring aplikasi dari Play.

---

## Backend Supabase

Aplikasi dirancang Supabase-siap, tapi **tidak memaksa** backend: tanpa
konfigurasi, aplikasi jalan penuh dengan data lokal.

### 1. Siapkan variabel

```bash
cp .env.example .env
```

Isi `.env` (file ini **tidak** ikut git — sudah ada di `.gitignore`).

| Kunci | Isi |
|---|---|
| `SUMBER_DATA` | `supabase` |
| `SUPABASE_URL` | `https://xxxx.supabase.co` |
| `SUPABASE_ANON_KEY` | anon / publishable key |
| `SUPABASE_SCHEMA` | `public` |
| `SUPABASE_STORAGE_BUCKET` | nama bucket foto |

> `SUPABASE_ANON_KEY` aman dipublikasikan — kuncinya wajib ada di dalam
> aplikasi dan sudah dibatasi aturan RLS. Yang tidak boleh bocor adalah
> `service_role` key.

### 2. Jalankan dengan backend

```bash
flutter run \
  --dart-define=SUMBER_DATA=supabase \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

Atau cukup `--dart-define-from-file=.env` (Flutter >= 3.27).

### 3. Tabel yang dibutuhkan

| Tabel | Kolom minimal |
|---|---|
| `profiles` | `id` (= `auth.users.id`), `nama`, `role`, `divisi`, `nomor_anggota`, `poin`, `total_kegiatan` |
| `kegiatan` | `judul`, `kategori`, `tanggal`, `lokasi`, `mendatang` |
| `berita` | `judul`, `sumber`, `waktu`, `tag` |
| `pengumuman` | `tag`, `judul`, `isi` |
| `iuran` | `periode`, `nominal`, `lunas` |
| `kas_bulanan` | `label`, `juta` |

### 4. Hak akses (role)

`UserRole` punya 5 tingkat: `guest` → `warga` → `anggota` → `pengurus` →
`admin`. Nilai di kolom `profiles.role`.

**Penjaga sesungguhnya ada di server**, lewat Row Level Security. Guard di
aplikasi (`RoleGate`) hanya untuk tampilan — utamanya RLS:

```sql
alter table profiles enable row level security;
create policy "warga baca profilnya sendiri"
  on profiles for select using (auth.uid() = id);
create policy "warga ubah profilnya sendiri"
  on profiles for update using (auth.uid() = id);
```

### 5. Beralih antara lokal dan Supabase

Hanya lewat `SUMBER_DATA`. Tidak ada kode layar yang berubah — itu gunanya
lapisan repository.

### 6. Yang belum aman untuk rilis sungguhan

- Token sesi disimpan di `shared_preferences` (teks polos). Ganti dengan
  `flutter_secure_storage` sebelum rilis — titik penggantinya ada di
  `lib/core/data/supabase_rest.dart`, kelas `PenyimpanToken`.
- Belum ada verifikasi identitas warga (mis. cek NIK). Backend recién
  disiapkan.

---

## Build iOS (nanti)

Folder `ios/` **sudah disiapkan** dan tidak akan dibangun sampai Android
benar-benar pas.

Kenapa belum: `flutter build ipa` harus jalan di **macOS**. Workflow
`.github/workflows/build-ios.yml` sudah ada dan hanya bisa dijalankan manual.

```bash
gh workflow run build-ios.yml
```

Yang sudah disiapkan:

- `tool/patch_ios.py` — nama tampilan, izin kamera/lokasi/foto, deep link,
  `platform :ios '13.0'`
- `tool/ios-checklist.md` — status, langkah verifikasi gratis, batas Apple ID
  gratis

Yang **tidak** bisa dilakukan dari HP/Windows: build, signing, dan
mengunggah ke App Store. Untuk itu butuh Akun Developer Apple (gratis ada
batasnya: sertifikat kedaluwarsa 7 hari dan maksimal 3 aplikasi per
perangkat).

> Catatan: **APK Android tidak bisa dipasang di iPhone, dan iPhone tidak
> bisa memakai file APK.** Yang lintas platform adalah *kode*-nya, bukan
> file-nya. Satu kode ini menghasilkan APK (Android) dan IPA (iOS).

---

## Pemeriksaan otomatis

Jalankan sebelum commit:

```bash
python3 tool/check_dart.py      # dead file, import hilang, rute, kurung
python3 tool/check_nonlatin.py  # huruf CJK/Kana/Hangul di seluruh repo
flutter analyze                  # kalau Flutter terpasang
```

`check_dart.py` itu **blocking** di CI (tanpa `|| true`). Alasannya: Flutter
hanya mengompilasi file yang terjangkau dari `lib/main.dart`, jadi file yang
yatim bisa berisi `undefined name` tanpa(build hijau selama beberapa rilis.

---

## Berkas penting

| Berkas | Isi |
|---|---|
| `.env.example` | daftar variabel backend (aman ikut git) |
| `tool/patch_android.sh` | branding + izin Android (idempotent) |
| `tool/patch_signing.py` | menyuntik blok `signingConfigs` |
| `tool/patch_ios.py` | patch iOS untuk rilis |
| `tool/check_dart.py` | analyzer statis Dart |
| `tool/check_nonlatin.py` | cek karakter non-Latin repo-wide |
| `PROGRESS.md` | tahap mana yang sudah selesai |
| `CARA-ACODE.md` | cara mengedit dari Acode |