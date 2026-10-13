# Checklist iOS — KUNBAR Connect

Status per 13 Okt 2026: **persiapan selesai, belum ada build iOS yang dijalankan.**
Semua yang bisa disiapkan tanpa biaya sudah ada di repo ini. Yang tersisa hanya
langkah yang butuh akun Apple dan keputusan biaya.

---

## ✅ Yang sudah selesai (biaya $0)

| Item | Status | File |
|---|---|---|
| Kode Dart lintas-platform | **Siap** — semua layar, Riverpod, go_router, QR | `lib/` |
| Workflow build iOS | **Siap, manual-only** (tidak jalan tiap push) | `.github/workflows/build-ios.yml` |
| Script patch konfigurasi iOS | **Siap, idempotent** | `tool/patch_ios.py` |
| Bundle ID `id.kubarkonek.app` | **Siap** (diverifikasi oleh script, gagal keras kalau salah) | `tool/patch_ios.py` |
| Nama di bawah ikon "KUNBAR Connect" | **Siap** | `tool/patch_ios.py` |
| Permission string (kamera / lokasi / galeri) | **Siap** | `tool/patch_ios.py` |
| Deep link `karta-kubar://absen/...` | **Siap** | `tool/patch_ios.py` |
| Deployment target iOS 13.0 | **Siap** | `tool/patch_ios.py` |
| Dukungan iPad | **Siap** | `tool/patch_ios.py` |

> **Penting:** tidak ada kode yang perlu ditulis ulang. Semua dari `lib/` dipakai
> apa adanya oleh Flutter untuk Android maupun iOS. Yang dipisah hanya file
> native tipis (`ios/`), itu pun di-generate ulang di server.

---

## ⏳ Belum dikerjakan — dan kenapa

| Langkah | Kenapa belum |
|---|---|
| Apple Developer account | Butuh keputusan biaya ($99/tahun) |
| Signing certificate + provisioning profile | Butuh akun Developer |
| Upload ke App Store / TestFlight | Butuh akun Developer + review Apple |
| Nama file icon + launch screen iOS | Ikon app sendiri masih ditunda (lihat `design/icon/`) |

---

## 🚀 Saat waktunya — langkah-langkahnya

### 1. Verifikasi compile dulu (gratis, 5 menit)

Tanpa akun Apple apa pun. Cuma memastikan kodenya memang bisa dikompilasi untuk iOS.

Di HP (Termux):

```bash
cd ~/karta-kubar
git push origin main
gh workflow run build-ios.yml
gh run watch
```

Hasilnya dua artefak: `kubar-connect-ios-unsigned` (folder `.app`) dan
`kuban-connect-ipa-unsigned`. Keduanya **belum bisa dipasang ke iPhone** — itu
normal, memang belum ditandatangani. Yang dicek: build hijau atau tidak.

### 2a. Uji di iPhone sendiri — GRATIS (Apple ID biasa)

- Daftar di <https://developer.apple.com/account> pakai Apple ID biasa (gratis)
- Di workflow, signing diisi lewat **secret** (jangan tulis di repo publik):
  - `IOS_TEAM_ID`
  - `IOS_SIGNING_CERTIFICATE_P12` (base64)
  - `IOS_SIGNING_PASSWORD`
- Build dengan `flutter build ipa` (tanpa `--no-codesign`)
- Pasang pakai AltStore / SideStore / Sideloadly

**Batasnya (kebijakan Apple, bukan salah tool):**
- Sertifikat berlaku **7 hari** → setelah itu app harus di-sign ulang
- **Maksimal 3 app** per perangkat
- Tidak ada push notification & in-app purchase di tier gratis

Cukup untuk memastikan app jalan di iPhone. Tidak untuk dibagikan ke warga.

### 2b. Bagikan ke warga — berbayar (WAJIB)

- Apple Developer Program: **$99/tahun** → <https://developer.apple.com/programs/enroll/>
- Setelah aktif:
  1. Buat App ID `id.kubarkonek.app`
  2. Buat Distribution certificate
  3. Isi signing ke GitHub Secrets (sama seperti keystore Android, tapi `.p12` + `.mobileprovision`)
  4. `flutter build ipa` → upload ke **TestFlight**
  5. Warga pasang lewat **TestFlight app** (gratis, tanpa bypass apa pun)

TestFlight adalah cara paling bersih: tidak ada cara sideload, tidak ada sertifikat
gratis yang bisa dicabut, dan app bisa di-update kapan saja lewat App Store.

---

## 🔐 Kalau nanti signing aktif — pitfall yang sudah diketahui

| Jebakan | Solusi |
|---|---|
| `flutter create` menghasilkan bundle id yang berbeda | `patch_ios.py` **verifikasi** dan gagal keras — bukan diam-diam signed salah |
| Repo ini **PUBLIK** | Jangan pernah commit `.p12`, `.mobileprovision`, atau `DEVELOPMENT_TEAM` yang terisi → lewat GitHub **Secrets** |
| Sertifikat gratisExpired 7 hari | Jangan pakai untuk distribusi — hanya untuk tes |
| Enterprisescertifikat gratis | **Jangan dipakai.** Dicabut Apple dalam gelombang besar, semua app mati mendadak untuk semua orang |
| `macos-14` runner dipensiunkan 2 Nov 2026 | Workflow sudah pakai `macos-15` |

---

## Ringkas

- **Build iOS = gratis** (repo publik → GitHub Actions macOS gratis & tak terbatas)
- **Menjalankan di iPhone sendiri = gratis** (7 hari per sign)
- **Menybarkan ke warga = $99/tahun** (Apple Developer Program)
- **Tidak ada kode ulang** — cukup klik "Run workflow"