# PROGRESS — KUNBAR Connect

Berkas ini supaya sesi baru bisa melanjutkan tanpa membaca ulang semua riwayat.

**Terakhir diperbarui:** 14 Okt 2026
**Versi aplikasi:** 0.7.0+13 (build 20 sudah DIRUSAK, jangan dipakai sebagai acuan)

---

## Ringkasan

Aplikasi warga Kuningan Barat, satu codebase Flutter untuk Android + iOS.
Splash dan 3 sampul sudah selesai. Lapisan data + backend Supabase sudah
disiapkan. Yang tersisa: konfigurasi `.env` asli dan verifikasi di perangkat.

---

## Tahap per fitur

| # | Tahap | Status | Commit |
|---|---|---|---|
| 0 | Fondasi: tema M3, ikon, router, build CI | ✅ | `c3d6bb3`, `1440406` |
| 1 | `SplashScreen` + `onFinished`, navigasi di router | ✅ | `f512dca` |
| 2 | `OnbArt` (aspirasi, komunitas, terhubung) untuk 3 sampul | ✅ | `f512dca` |
| 3 | `.env` → `--dart-define` → `AppEnv`, tanpa API key di kode | ✅ | `8a4a2eb` |
| 4 | Lapisan repository + klien Supabase + role warga/admin | ✅ | `8a4a2eb` |
| 5 | Struktur `{data,domain,presentation}` per fitur | ✅ | `0580097` |
| 5a | Pembersihan karakter non-Latin + alat cek repo-wide | ✅ | `8ba3a2d` |
| 6 | Build APK arm64 (~18 MB) + AAB + dokumen signing | ✅ | `9f0e8e3` |
| 7 | README + PROGRESS.md | ✅ | (commit ini) |

### Fitur yang sudah ada dan jalan

- Splash (1,8 dtk) → onboarding / beranda / login
- Onboarding 3 slide beranimasi, bisa digeser
- Masuk / daftar (mode demo, OTP `123456`)
- Beranda: greeting, pengumuman, berita, agenda, aksi cepat
- Kegiatan: filter kategori, tinggi ilustrasi dihitung dari lebar layar
- Absen: scan QR tiruan, riwayat, ubah status
- Keuangan: saldo, grafik kas 5 bulan, riwayat iuran
- Galeri: berita + sampul
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