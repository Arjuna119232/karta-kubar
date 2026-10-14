# Checklist Splash Screen — KUNBAR Connect

Splash sekarang **Sepenuhnya native** (dikerjakan sistem operasi, bukan Flutter).
Widget splash buatan sendiri sudah **dihapus** dari `lib/features/splash/`.

| Platform | Yang dipakai | Sumber kebenaran |
|---|---|---|
| Android 12+ | `Theme.SplashScreen` + `androidx.core:core-splashscreen:1.0.1` | `tool/patch_splash_android.py` |
| Android 11 ke bawah | layer-list hijau polos | `launch_background.xml` |
| iOS 14+ | `UILaunchScreen` (Info.plist) | `tool/patch_splash_ios.py` |
| iOS 13 | storyboard, latar sudah hijau | `LaunchScreen.storyboard` |

---

## 1. Durasi maksimal 1,2 detik

- [x] **Android** — `windowSplashScreenAnimationDuration` = `500` ms.
      Batas keras 1000 ms dijaga `DURASI_MS` di `tool/patch_splash_android.py`;
      kalau diubah lewat 1000, script exit 1 dan build berhenti.
- [x] **Tidak ada** `setKeepOnScreenCondition` yang menahan splash.
      Tanpa itu, splash hilang tepat saat frame pertama Flutter digambar,
      jadi durasi = waktu startup aplikasi (tipikal 400–800 ms), bukan 1800 ms.
- [x] **Dart** — tidak ada lagi `kDurasiSplash`, tidak ada `Future.delayed`
      menunggu sebelum `runApp`.
- [x] **iOS** — durasi launch screen dikendalikan sistem; tidak ada parameter
      durasi di `UILaunchScreen`.

> Bukti: `grep -rn "kDurasiSplash\|setKeepOnScreenCondition" lib/ android/` → kosong.

## 2. Logo + nama aplikasi + warna solid (15 Okt 2026)

> **Diperbarui 15 Okt 2026.** Versi pertama splash native sengaja tidak
> menampilkan teks sama sekali. User minta nama aplikasi terlihat supaya jelas
> APK apa yang sedang dibuka, dan kredit "From KATAR KUNBAR" di paling bawah.

### Batas keras API yang discovered (dari developer.android.com + Apple docs)

- [ ] **Android 12+ TIDAK punya API teks sama sekali.** Hanya ada
      `windowSplashScreenAnimatedIcon` (1 drawable, di-mask **lingkaran
      192dp**) dan `windowSplashScreenBrandingImage` (1 gambar di bawah).
      Tidak ada slot untuk wordmark di samping logo.
- [x] **Solusinya** — nama aplikasi ikut DIGAMBAR di dalam drawable ikon:
      emblem di atas + `KUNBAR` + `CONNECT` (lockup dua baris, `CONNECT` lebih
      kecil dengan letter-spacing lebar), semuanya muat di circle 192dp.
      ⚠️ Ini MEMAKAI seluruh ruang yang ada: emblem harus dikecilkan dan
      `CONNECT` cuma ~79 dp. Menambah baris ketiga tidak akan muat lagi.
- [x] **Kredit "From KATAR KUNBAR"** memakai
      `android:windowSplashScreenBrandingImage` (200×80 dp, slot paling bawah).
- [x] **`windowSplashScreenBrandingImage` adalah ATRIBUT PLATFORM** (prefix
      `android:`), bukan milik `core-splashscreen`.
      ⚠️ **Konsekuensi: hanya muncul di Android 12+ (API 31+).** Di Android 11
      ke bawah atribut ini diabaikan diam-diam — kompatibilitasnya tidak
      di-backport oleh library.
- [x] **Branding image wajib di SEMUA density** (`hdpi` 1,5× / `xhdpi` 2× /
      `xxhdpi` 3× / `xxxhdpi` 4×). Kalau hanya ada satu density, Android
      memakai yang paling kecil dan teksnya pecah.
- [ ] **Harus pakai folder density, BUKAN `drawable-nodpi`.** Di `nodpi`,
      600 px = 600 dp = **delapan kali** lebih besar dari slot 200 dp.

### iOS: tidak ada slot terpisah sama sekali

- [x] `UILaunchScreen` (Apple docs, iOS 14+) hanya menerima `UIColorName`,
      `UIImageName`, `UIImageRespectsSafeAreaInsets`, dan elemen border.
      **Tidak ada teks, tidak ada kontrol posisi** — gambar SELALU dipusatkan.
- [x] Karena itu emblem + `KUNBAR` + `CONNECT` + `From KATAR KUNBAR`
      **digabung jadi satu gambar** 260 pt, dipusatkan.
- [ ] **Kredit iOS TIDAK bisa berada di paling bawah layar** seperti di
      Android. Itu konsekuensi langsung dari API Apple, bukan pilihan desain.

### Dulu (tetap berlaku sebagai riwayat)


- [x] **Android** — `styles.xml` hanya punya `windowSplashScreenBackground` dan
      `windowSplashScreenAnimatedIcon`. Tidak ada `<item>` teks/progress.
- [x] **iOS** — `UILaunchScreen` berisi **tepat 2 key**:
      `UIColorName` + `UIImageName`. `tool/patch_splash_ios.py` menolak apa pun
      selain itu dan menggandakan ulang seluruh dict, jadi key sisa dari
      percobaan sebelumnya ikut terhapus.
- [x] **Dihapus** — 3 titik loading dan animasi wordmark per-huruf dari versi
      lama. Teks yang tersisa hanya nama aplikasi + kredit.
- [x] **Tidak ada** animasi bounce/fade berlapis/partikel, tidak ada progress
      bar palsu. Satu-satunya animasi adalah `windowSplashScreenAnimationDuration`
      milik sistem (icon+fade keluar).
- [x] **Tidak ada** `UILabel` di `LaunchScreen.storyboard`.
- [x] **Tidak ada** animasi: teks statis di dalam PNG, tanpa bounce/fade.

> Bukti: `grep -c UILabel ios/Runner/Base.lproj/LaunchScreen.storyboard` → 0.

## 3. Background splash 100% sama dengan halaman pertama

- [x] **Warna** — `windowSplashScreenBackground` = `@color/kunbar_brand` = `#1B5E20`,
      identik dengan `AppColors.primary`.
- [x] **Dijaga otomatis** — `patch_splash_android.py` dan `patch_splash_ios.py`
      membandingkan `#1B5E20` dengan `AppColors.primary` di
      `lib/core/theme/app_colors.dart`. Kalau warna brand diganti di Dart dan
      splash tidak ikut, build **exit 1**.
- [x] **Tidak ada frame putih di belakang Flutter** — `NormalTheme` (dipakai
      sejak frame pertama) memakai `android:windowBackground` = warna brand.
      Template Flutter asli memakai `?android:colorBackground` yang inilah
      sumber kedip putih/hitam — sudah diganti.
- [x] **iOS 13** — storyboard Likewise diganti dari putih ke hijau.
- [ ] **⚠️ Lihat bagian "Yang tidak bisa 100% terpenuhi"** — warna hijau splash
      ke halaman onboarding yang berlatar `#F6F7F9` tetap ada crossfade
      ~200 ms milik sistem.

## 4. Pakai API native, bukan custom widget

- [x] **Android** — `android/app/src/main/res/values/styles.xml`:
      `<style name="LaunchTheme" parent="Theme.SplashScreen">`
- [x] **Android** — `installSplashScreen()` dipanggil **sebelum** `super.onCreate()`
      di `MainActivity.kt`. Script memverifikasi **urutannya**, bukan hanya
      keberadaan teks (lihat " Jebakan verifikasi" di bawah).
- [x] **Logo muat dalam circle 192 dp** — dihitung, bukan dikira-kira:

  ```
  1 px (canvas 512 px) = 288 / 512 dp = 0,5625 dp
  jari-jari mask       = 96 / 0,5625  = 170,7 px
  isi logo SEBELUM      = radius 176,2 px  -> 1,03x  TERLALU BESAR
  isi splash_icon.png  = radius 162,1 px  -> 91,4 dp  < 96 dp  AMAN
  ```

  `tool/gen_splash_icons.py` menghitung ulang tiap aset dan **exit 1** kalau
  melewati 96 dp.
- [ ] **⚠️ Logo lama `emblem-512.png` kalau dipakai apa adanya akan terpotong**
      (isi 434×458 px di canvas 512 px). Karena itu ada aset baru
      `assets/brand/splash_icon.png` khusus splash.
- [x] **iOS** — `UILaunchScreen` di `Info.plist`, **bukan** storyboard custom.
      Warna dari colorset `LaunchBackground`, gambar dari imageset `splash_icon`
      (160 pt @1x/@2x/@3x).

> Bukti: `python3 tool/patch_splash_android.py --verify-only` → exit 0.

## 5. Handoff tanpa frame putih/blank

- [x] **Rute `/` dihapus** dari `lib/core/router.dart`. Dulu `/` memuat widget
      splash Flutter yang baru THEN berpindah — artinya aplikasi sempat
      menggambar satu halaman penuh sebelum halaman yang benar.
- [x] **`lib/core/boot.dart`** membaca SharedPreferences **sebelum** `runApp`,
      saat splash native masih menutupi layar.
- [x] **`main.dart`** memakai `initialLocation: pathUntuk(awal)` — router
      langsung dibuka di halaman tujuan.
- [x] **`SplashScreen` dihapus** dari `lib/features/splash/` (sudah di-`git rm`).

---

## Jebakan verifikasi yang sudah ditemukan (jangan diulang)

Semuanya ditemukan dengan **fault injection**, bukan dengan membaca kode:

| Jebakan | Gejala | Perbaikan |
|---|---|---|
| Cek urutan pakai `find("installSplashScreen")` | Nama yang sama ada di baris `import`, posisinya selalu lebih dulu → cek **selalu lulus** | Cari panggilannya: `installSplashScreen()` |
| Cek urutan baca komentar | Komentar `// ... SEBELUM super.onCreate()` mengandung teks yang dicari → cek selalu **gagal** | `tanpa_komentar()` dulu |
| Cek XML cari `Theme.SplashScreen` | Kalimat yang sama ada di komentar `<!-- ... (Theme.SplashScreen) -->` → cek selalu **lulus** | Buang `<!-- -->`, cari `parent="Theme.SplashScreen"` |
| `Color(0xFF1B5E20)` diambil 6 digit | Alpha `FF` ikut terambil → warna brand selalu dianggap tidak cocok | Tangkap 8 digit `AARRGGBB`, ambil 6 terakhir |
| Verifikasi bandingkan konstanta dengan dirinya sendiri | Ganti `BRAND_HEX` → yang ditulis DAN yang diharapkan ikut berubah → selalu lolos | Bandingkan ke `app_colors.dart` |
| Batas durasi dicek dari file XML | `styles.xml` ditulis ulang tiap jalan → nilainya selalu sama, cek sia-sia | Cek dari konstanta `DURASI_MS` |
| Bbox half-diagonal untuk mengukur logo | Sudut kotak kosong untuk logo figuratif → logo hanya jadi 58 dp dari 96 dp | Hitung radius true dari alpha |
| `putalpha` saat mem-preview | Mengganti alpha ikon (harusnya dikalkan) → lingkaran hitam muncul | `ImageChops.multiply` |
| `drawable-nodpi` untuk branding image | nodpi = 1 px = 1 dp, jadi 600 px jadi **600 dp** (slotnya 200 dp) | folder density: hdpi/xhdpi/xxhdpi/xxxhdpi |
| Posisi lockup dipatok `y = canvas * 0.68` | Begitu font/emblem diganti, blok meleset dan bisa keluar mask — build tetap hijau | Pusatkan blok dari tinggi visual terukur |

## Cara memverifikasi sendiri

```bash
# 1. Aset muat mask circle 192 dp + skala iOS benar
python3 tool/gen_splash_icons.py

# 2. Splash native Android terpasang & sesuai (exit 0 = bersih)
python3 tool/patch_splash_android.py --verify-only

# 3. Kode Dart tetap sehat
python3 tool/check_dart.py
python3 tool/check_nonlatin.py

# 4. Pratinjau di browser (tanpa build APK)
#    http://127.0.0.1:8484/design/browser/splash-native.html
```

## Yang TIDAK bisa 100%epenuhi

1. **Warna handoff hijau → `#F6F7F9`.** Aturan 3 minta background splash
   100% sama dengan halaman pertama. Halaman pertama untuk pengguna baru
   adalah onboarding yang berlatar terang. Android menutupi celah ini dengan
   crossfade ~200 ms, jadi **tidak ada frame putih atau kosong** — tapi strictly
  Warnanya berubah dari hijau ke terang.
   Kalau benar-benar perlu 100% identik: ubah `Scaffold(backgroundColor:)` di
   `onboarding_screen.dart` dan `auth_screen.dart` menjadi `AppColors.primary`.
   Itu **1 baris per file**, tapi seluruh desain terang onboarding ikut berubah.
   *Keputusan diambil: tidak diubah — warna hijau hanya 200 ms.*

2. **Durasi persis 1,2 detik tidak bisa dipatok.** Android yang menentukan sendiri kapan
   splash ditutup (saat frame pertama). Yang bisa dijamin hanya "tidak lebih
   dari 1,2 detik", dan itu sudah terpenuhi karena tidak ada penahan.

3. **Logo di circle 192 dp tidak bisa 100% penuh.** Sudut kotak logo terpotong
   kalauarkusnya mendekati diameter. Yang dipakai 91,4 dp dari 96 dp
   (95%) — sisa 4,6 dp untuk keamanan tepi.
