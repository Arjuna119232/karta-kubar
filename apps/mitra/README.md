# KUNBAR Mitra (Flutter)

Aplikasi driver/kurir jastip & ojek. Bisa langsung dicoba tanpa server (MODE DEMO).

## Coba cepat (mode demo, tanpa Supabase/FCM)
```bash
cd apps/mitra
bash tools/setup_android.sh      # sekali saja: buat folder android + izin
flutter pub get
flutter run                      # login bebas -> ONLINE -> order dummy muncul
# Pengaturan > "Buat order dummy" untuk menambah order baru
```

## Build APK sungguhan
1. Supabase: jalankan `supabase/schema.sql`, buat user, lalu jadikan mitra:
   `update profiles set role='mitra' ...` (contoh ada di akhir file SQL).
   Pastikan baris `profiles` terbuat untuk tiap user baru (trigger signup atau insert manual).
2. FCM: Firebase Console > Project settings > Your apps > Android (package `id.kunbar.kunbar_mitra`).
   Ambil apiKey, appId, senderId, projectId. Tidak perlu `google-services.json` (diinisialisasi dari Dart).
3. Build:
```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=FCM_API_KEY=... --dart-define=FCM_APP_ID=... \
  --dart-define=FCM_SENDER_ID=... --dart-define=FCM_PROJECT_ID=...
```
APK: `build/app/outputs/flutter-apk/app-release.apk`.
Atau lewat GitHub: tambah 6 secret di atas, jalankan workflow "Build KUNBAR Mitra APK".

## Catatan desain
- **Google Maps** lewat intent `google.navigation:` (tanpa Maps SDK/API key, lebih ringan).
- **GPS** hanya jalan saat ada order aktif (foreground service, akurasi sedang, filter 30 m).
- **Offline**: order/riwayat terakhir disimpan di perangkat; banner muncul saat tanpa sinyal.
- **Push FCM**: sisi app siap (channel `orders`, suara + getar). Pengirimnya harus server
  (Edge Function/trigger saat insert order) memakai `fcm_token` di tabel `profiles`.
  Kirim sebagai **data-only**: `{"data":{"title":"Order baru","body":"..."}, "android":{"priority":"high"}}`.
  Selama app terbuka & ONLINE, order tetap masuk realtime lewat Supabase + notifikasi lokal.
- Tolak order hanya menyembunyikan di perangkat mitra tersebut.
- Tema/komponen ada di `lib/core/theme.dart`; ganti dengan token `packages/shared/` bila tersedia.
