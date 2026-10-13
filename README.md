# KARTA KUBAR

**Satu Komando, Satu Karya** — aplikasi mobile Karang Taruna Kelurahan
Kuningan Barat, Jakarta Selatan.

## Tentang

Aplikasi mobile modern (Flutter 3.x) untuk Karang Taruna: keanggotaan,
kegiatan, keuangan, aspirasi warga, galeri, chat, dan UMKM warga. Dibangun
**offline-first** — berjalan penuh tanpa backend; lapisan Supabase
(auth, database, pembayaran) ditambahkan belakangan lewat Repository Pattern
tanpa mengubah UI.

## Arsitektur

```
lib/
  core/            # theme, constants, utils, error
  features/        # satu folder per fitur (auth, home, kegiatan, ...)
    <fitur>/presentation/
  shared/          # widgets & models bersama
  main.dart
assets/            # images, fonts, data (seed demo)
tool/              # skrip patch Android (idempotent)
```

- **State:** Riverpod · **Navigasi:** go_router
- **Pola:** Clean Architecture + Repository Pattern
- **Backend (nanti):** Supabase (auth, Postgres + RLS, storage, realtime),
  Midtrans (QRIS/VA), Firebase Cloud Messaging

## Build

Tidak perlu memasang Flutter di HP — APK dibangun otomatis di **GitHub
Actions** setiap push ke `main`:

1. `flutter create` membuat folder `android/` di cloud
2. `tool/patch_android.sh` menerapkan branding + permission
3. `flutter build apk --release` → **Releases** (APK siap install)

Build manual (di komputer dengan Flutter):

```bash
flutter pub get
flutter build apk --release
```

## Roadmap

FASE 0 fondasi → 14 rilis. Sasaran v1: FASE 0–7 (Onboarding, Auth, Home,
Profil, Kegiatan, Keuangan) fully functional.

## Lisensi

Proyek internal Karang Taruna Kelurahan Kuningan Barat.
