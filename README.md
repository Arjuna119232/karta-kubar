# KUNBAR Connect

**Kuningan Barat Connected Community**
*"Satu Kelurahan, Satu Komunitas, Satu Aplikasi"*

Aplikasi warga untuk **Kelurahan Kuningan Barat, Jakarta Selatan** — untuk
seluruh warga: anak muda, orang tua, RT/RW, UMKM, sampai pengurus kelurahan.

---

## Status Saat Ini

**Versi 0.5.0+5** — Fondasi + Role System selesai.

| Fase | Isi | Status |
|---|---|---|
| 0–4 | Theme, shell, auth + OTP, beranda/kegiatan/kas/galeri/profil, Absen QR | ✅ |
| **5** | **Role system 5 level, bottom nav per role, route guard** | ✅ |
| 6 | Layer Repository (Supabase-ready) | ⏳ |
| 7 | Restruktur navigasi per role | ⏳ |
| 8 | Fitur publik: Berita, Agenda, UMKM, Peta, Profil Kelurahan, Pengaturan | ⏳ |
| 9 | Fitur warga: Aspirasi, Lapor Darurat, Forum, Booking, Donasi | ⏳ |
| 10 | Fitur anggota: Kartu digital, Absensi GPS, Iuran, Voting, Poin | ⏳ |
| 11 | Pengurus/Admin: Dashboard, QR sesi, Verifikasi, Broadcast, CRUD | ⏳ |
| 12 | Integrasi: Supabase, Midtrans, FCM, WhatsApp Business | ⏳ butuh akun |
| 13 | Polish: Mode Lansia, multi-bahasa, tablet, analytics | ⏳ |

---

## 5 Level Akses

| Level | Syarat | Kemampuan inti |
|---|---|---|
| **Tamu** | tanpa login | baca berita, agenda, UMKM, profil kelurahan |
| **Warga** | NIK + alamat KUNBAR terverifikasi | aspirations, lapor darurat, forum, booking, donasi sukarela |
| **Anggota KT** | dipilih pengurus | absensi QR + GPS, kartu digital, iuran wajib, voting, poin |
| **Pengurus** | ditunjuk | buat sesi absensi, kelola kegiatan, verifikasi warga, broadcast |
| **Admin** | super access | kelola role, moderasi konten, analytics, laporan |

Bottom navigation **berbeda per role** — lihat `lib/features/shell/data/app_tabs.dart`.

---

## Yang Sudah Bisa Dicoba

- **Splash → Onboarding (3 slide) → Auth → OTP** (kode demo `123456`)
- **Beranda** — greeting sesuai nama, pengumuman carousel, statistik,
  aksi cepat, agenda dengan hitung mundur, berita
- **Kegiatan** — filter kategori, kelompok "Akan Datang"/"Sudah Lewat",
  detail lewat bottom sheet
- **Absen QR** (role Anggota ke atas) — mode anggota (pindai) dan mode
  penyelenggara (tampilkan QR). Payload `karta-kubar://absen/YYYYMMDD/<judul>`
  benar-benar bisa di-decode.
- **Kas** — saldo, grafik batang 5 bulan, riwayat iuran, transparansi
- **Galeri** — grid kegiatan + berita
- **Profil** — kartu anggota digital, **switcher role untuk preview semua
  5 level**, ganti tema terang/gelap/otomatis, logout

### Cara preview semua role

Profil → **Preview level akses** → tap role yang mau dilihat. Tool bantu
developer; nanti diganti verifikasi oleh pengurus.

---

## Menjalankan

```bash
flutter pub get
flutter run                 # development
flutter build apk --release # APK rilis
```

### Build di Termux (tanpa install Flutter di HP)

`android/` **tidak** disimpan di repo — di-generate ulang tiap build.
`tool/patch_android.sh` menerapkan branding, package id `id.kubarkonek.app`,
dan permission. `tool/patch_signing.py` memasang signing release dari
`android/key.properties` (dibuat workflow dari GitHub Secrets).

---

## Arsitektur

```
lib/
  core/
    auth/          UserRole (5 level) + Session (user + role, persisten)
    theme/         AppColors, AppTypography, AppTheme
    router.dart    go_router + RoleGate
    providers.dart state UI umum (tab, tema)
    utils/         format tanggal Bahasa Indonesia
  features/
    shell/         AppShell + app_tabs.dart (tab per role)
    splash/ onboarding/ auth/ absen/
    home/ kegiatan/ keuangan/ galeri/ profile/
  shared/
    data/          seed data (offline-first)
    widgets/       AppCard, PrimaryButton, StatTile, PseudoQr, ...
```

State: **Riverpod 2** · Routing: **go_router** · Arsitektur:
Clean Architecture + Repository (Supabase tinggal diimplementasikan di
layer repository tanpa mengubah UI).

---

## Catatan Penting (baca sebelum=jual)

1. **Verifikasi NIK otomatis via Dukcapil tidak ada API publik.** Yang
   realistis: verifikasi manual oleh pengurus + OCR KTP. Jangan menjanjikan
   cek otomatis ke Dukcapil.
2. **Guard role di aplikasi ini hanya untuk UX.** Keamanan sesungguhnya
   harus ditegakkan di sisi server lewat **Row Level Security Supabase**.
3. **iOS butuh mesin macOS** — tidak bisa di-build dari HP/Termux. Tapi
   repo ini **PUBLIK**, jadi GitHub Actions runner macOS = **gratis &
   tak terbatas**. Workflow-nya sudah disiapkan: `.github/workflows/
   build-ios.yml` (manual-only, tidak jalan tiap push). Checklist +
   langkah signing ada di [`tool/ios-checklist.md`](tool/ios-checklist.md).
   **Tidak ada kode yang perlu ditulis ulang** — semua `lib/` dipakai
   apa adanya oleh Android maupun iOS.
4. **Certificate pinning tidak dipakai** — rotasi sertifikat dan captive
   portal membuat app mati untuk pengguna.
5. Semua data masih **offline** (dari `seed_data.dart`).

---

## Lisensi

Hak cipta Karang Taruna / Kelurahan Kuningan Barat.