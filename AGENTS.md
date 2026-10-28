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

- v0.14.4+32 · 119 file Dart · 7 fitur warga belum ada (lihat PROGRESS.md).
- Absensi QR = kamera asli (`mobile_scanner ^6.0.11`, izin CAMERA disuntik
  `tool/patch_android.sh`). Detail + jebakan ada di PROGRESS.md bagian
  "Absensi QR: kamera asli".
- Data mitra usaha: sumber kebenaran `tool/data_mitra_baru.json` →
  `tool/gen_mitra_usaha.py` → Dart. Jangan edit Dart-nya manual.
