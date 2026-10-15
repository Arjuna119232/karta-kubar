# PROGRESS — KUNBAR Connect

Berkas ini supaya sesi baru bisa melanjutkan tanpa membaca ulang semua riwayat.

**Terakhir diperbarui:** 15 Okt 2026
**Versi aplikasi:** 0.11.0+21 (build 20 = 0.7.0 sudah DIRUSAK, jangan dipakai sebagai acuan)

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
| 10 | FISH warga (kirim + pantau status) + Pengurus (antrean + aksi status) | ✅ | (commit ini) |

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
| 12 | Kartu anggota digital | ⚠️ | Kartu sudah ada, **QR-nya masih gambar tiruan** (belum bisa discan) |
| 13 | Chat | ❌ | Skema `pesan` ada. Butuh login Supabase Auth + Realtime |
| 14 | Profil | ✅ | Kartu anggota, hak akses, menu |
| 15 | Pengaturan | ⚠️ | Tema, mode Lansia, status backend jalan. Edit profil / Notifikasi / Bantuan masih "segera hadir" |

**Angka: 10 jadi, 2 setengah, 3 belum.** Tidak ada fitur yang ditandai selesai
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
- Kegiatan: filter kategori, tinggi ilustrasi dihitung dari lebar layar
- Absen: scan QR tiruan, riwayat, ubah status
- Keuangan: saldo, grafik kas 5 bulan, riwayat iuran
- Galeri: berita + sampul
- Aspirasi & Laporan: kirim FISH, filter status, tersimpan di perangkat
- Panel Pengurus: antrean FISH, tandai Diproses/Selesai/Ditolak + catatan
- Profil: kartu anggota, level akses 5 tingkat, **kartu "Sumber data"**
- Mode terang/gelap + mode Lansia


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