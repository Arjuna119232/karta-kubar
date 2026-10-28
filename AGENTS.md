# KUNBAR Connect (warga) — catatan proyek

Aplikasi Flutter untuk warga Kelurahan Kuningan Barat. Package id
`id.kubarkonek.app`, pubspec `name: kubar_connect` (**jangan diganti** —
ganti = user wajib uninstall dan data hilang).

## Alur kerja

- Branch kerja: `feat/order-jastip-ojek`. **Jangan push ke `main`** — `main`
  memicu build + release otomatis.
- Flutter **tidak ada** di Termux. Oracle kompilasi = CI:
  `gh workflow run build.yml --ref <branch> -f analyze-only=yes -f release=no`
  (~2 menit, tanpa APK).
- Gerbang lokal sebelum push:
  ```bash
  python3 tool/check_dart.py        # harus 0 masalah
  python3 tool/check_nonlatin.py    # harus 0 masalah
  ```
- Build APK: `gh workflow run build.yml --ref <branch> -f demo=true
  -f abi=universal -f release=no -f analyze-only=no`

## Aturan kode

- Warna **hanya** dari `AppColors` / `Theme.of(context)`; ikon **hanya**
  `AppIcon(Ik.x)` dengan SVG di `assets/icons/`. Tidak ada `Icons.*`.
- Radius/spasi dari `AppRadius` / `AppSpacing` (di-export `app_theme.dart`).
- `num.clamp()` mengembalikan `num` → untuk `double` pakai ternary.
- `const` tidak boleh membungkus pemanggilan method/fungsi
  (`const_eval_method_invocation`).
- Import model: sempitkan (`show Order`) supaya tidak bentrok nama widget.
- Sheet/dialog: `AppSheet`, `AppDialog`, `AppCard` di `lib/shared/widgets/`.

## Status singkat

- v0.14.6+34 · 121 file Dart · absensi QR pakai kamera asli (mobile_scanner 6.0.11) · peta pakai tile raster OpenStreetMap (.de) + atribusi · 7 fitur warga belum ada (lihat PROGRESS.md).
- Peta: gaya dipusatkan di `lib/shared/services/peta_gaya.dart` — `gayaPetaGratis` = tile raster `tile.openstreetmap.de` (bukan `tile.openstreetmap.org`, server itu memblokir aplikasi), `gayaPetaCadangan` = vector OpenFreeMap. Atribusi wajib lewat `lib/shared/widgets/atribusi_peta.dart` di SEMUA peta.
- ⚠️ `flutter analyze` di CI FATAL pada warning: setelah memindahkan konstanta bersama, buang import yang jadi mati (mis. `widgets_order.dart` di `mitra_usaha_peta.dart`). `tool/check_dart.py` tidak menangkap ini.
- Absensi QR = kamera asli (`mobile_scanner ^6.0.11`, izin CAMERA disuntik
  `tool/patch_android.sh`). Detail + jebakan ada di PROGRESS.md bagian
  "Absensi QR: kamera asli".
- Data mitra usaha: sumber kebenaran `tool/data_mitra_baru.json` →
  `tool/gen_mitra_usaha.py` → Dart. Jangan edit Dart-nya manual.
  - **JSON ditulis satu objek per baris** (`json.dumps(separators=(',',':'))`).
    Menulis ulang dengan `indent=` membuat diff 1000+ baris palsu.
  - **Titik mitra di peta = `AnyCircle`, bukan `AnyMarker`.** Sprite
    `marker-15` hanya ada di gaya vektor; di gaya raster OSM penanda tidak
    tampil sama sekali (peta terlihat kosong). Adapter MapLibre membagi
    `AnyCircle.radius` dengan 10 (meter → dp), dan hanya menyinkronkan ulang
    kalau HIMPUNAN id berubah — karena itu id titik terpilih dibedakan.
  - **Aturan koordinat vs label:** koordinat asli warga TIDAK digeser >250 m
    (snap ke jalan hanya untuk titik `perkiraan:true`). Kalau titik asli jauh
    dari jalan, yang diperbaiki adalah **label kelurahan/alamat** mengikuti
    koordinat (reverse geocode zoom 18, `addressdetails=1`, utamakan
    `address.village`), bukan sebaliknya.
  - 5 titik hasil reverse geocode jatuh di luar Kecamatan Mampang Prapatan
    (m2 Rawa Barat, m3 Kuningan Timur, m23 Duren Tiga, m53 Petogogan,
    m58 Pancoran) — sengaja belum diubah, menunggu keputusan user.
