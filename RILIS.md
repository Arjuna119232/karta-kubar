# KUNBAR Connect — Cara Rilis (v0.6.1)

## 1. Sekali saja: isi GitHub Secrets
Repo → Settings → Secrets and variables → Actions:
`KK_KEYSTORE_BASE64`, `KK_KEYSTORE_PASSWORD`, `KK_KEY_ALIAS`, `KK_KEY_PASSWORD`.
Tanpa keystore, build berhenti dengan pesan "keystore kosong". Simpan keystore
cadangan di tempat aman: kalau hilang, update Play Store tidak bisa diterbitkan.

## 2. Build
Push ke `main`, atau Actions → **Build APK** → Run workflow.
Hasil: `app-release.apk` (dibagikan langsung) dan `app-release.aab` (Play Store),
keduanya ada di GitHub Release berstatus **draft** — cek lalu klik Publish.

## 3. Mode demo
Selama backend (Supabase) belum aktif, CI membuild dengan `KUNBAR_DEMO=true`:
OTP `123456` dan pengalih level akses aktif. Ini rilis **pratinjau**.
Setelah backend siap: Run workflow → demo = `false`.
Dengan demo `false`, verifikasi OTP menolak semua kode (belum ada backend).

## 4. Sebelum kirim ke Play Store
- Naikkan angka setelah `+` di `pubspec.yaml` setiap unggahan (sekarang `+12`).
- Siapkan URL kebijakan privasi (wajib) dan isi formulir Data Safety.
- Cek syarat target API terbaru di Play Console sebelum unggah.

## 5. Mengubah ikon / ilustrasi
Semua ikon dan ilustrasi digenerate dari `design/gen_assets.py`
(`python3 design/gen_assets.py` dari akar repo). Ubah di situ, jalankan ulang,
lalu commit folder `assets/icons/` dan `assets/ilustrasi/`.
