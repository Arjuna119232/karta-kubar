# KUNBAR Connect — Cara Membuka & Edit di Acode

Versi: **0.11.0** · Kelurahan Kuningan Barat, Jakarta Selatan

Aplikasi warga (Flutter) — **bukan** aplikasi admin. Panel pengurus
dipindah ke web terpisah.

---

## 1. Cara buka di Acode

1. **Ekstrak** `KUNBAR-Connect-v0.11.0-source.zip` ke folder di HP, misal
   `/storage/emulated/0/Acode/kunbar/`.
2. Acode → **Open Folder** → pilih folder **yang berisi `pubspec.yaml`**
   (bukan folder di dalam zip).
3. Tunggu Acode mengunduh Flutter SDK (sekali saja, ~1 GB).
4. Tekan **Run ▶**.

> Folder `android/` sengaja tidak disertakan. Flutter/Acode membuatnya
> sendiri saat Run pertama. Folder itu juga tidak ada di repo GitHub karena
> selalu digenerate ulang di server CI.

---

## 2. Isi paket ini

| Folder / berkas | Isi |
|---|---|
| `lib/core/` | Tema, router, sesi + role, konfigurasi, klien Supabase |
| `lib/features/` | Satu folder per fitur: `domain` + `data` + `presentation` |
| `lib/shared/widgets/` | Komponen dipakai lintas fitur |
| `assets/` | Ilustrasi, ikon, berkas brand splash |
| `tool/` | Skrip Python: cek kode, cek karakter, patch Android/iOS |
| `supabase/schema.sql` | Skema 15 tabel + aturan RLS |
| `design/` | Pratinjau tampilan (PNG sengaja tidak disertakan) |
| `aset-dari-user/` | Aset gambar yang kamu kirim |

---

## 3. Aturan main saat mengedit

### a. Urutan check WAJIB sebelum commit

```bash
python3 tool/check_dart.py       # WAJIB —Analyze Dart tanpa Flutter
python3 tool/check_nonlatin.py   # WAJIB —cekan karakter asing di SELURUH repo
```

`check_dart.py` menangkap apa yang lolos `flutter analyze`: file mati (tidak
terjangkau dari `main.dart`), import hilang, rute yang tidak terdaftar,
import tidak terpakai, member yang tidak ada, kurung tidak seimbang.

**Sudah terbukti menangkap bug nyata:**
- `const _Chip({required this.selected})` tanpa `final bool selected;`
- `import app_colors.dart` terhapus padahal `context.colors` milik
  extension di file itu
- `navigationIndexProvider = 3` meleset ke tab yang salah untuk role lain

### b. Kalau `check_dart.py` bilang "0 masalah", itu belum tentu benar

Setiap cek baru **wajib diuji dengan sengaja rusak**, lalu dikembalikan:

```bash
# contoh: hapus satu import yang dipakai, cek harus GAGAL
python3 tool/check_dart.py   # harus exit 1
# kembalikan seperti semula
python3 tool/check_dart.py   # harus OK - 0 masalah
```

### c. Warna & teks

Jangan menulis hex warna langsung di layar. Ambil dari `AppColors` atau
`Theme.of(context)`. Warna yang tidak ada di Material ColorScheme ada di
`AppSemantic` (`context.semantic`).

`context.colors`, `context.text`, `context.semantic` ketiganya milik **satu
extension `AppSemanticX` di `lib/core/theme/app_colors.dart`**. Jangan
menghapus import itu.

### d. Data

Semua layar membaca lewat repository (`lib/features/*/data/`). Jangan pernah
baca data langsung dari layar:

```bash
grep -rn "Lokal\." lib/features/*/presentation/   # harus kosong
```

Baris data bawaan wajib `contoh: true` + label "data contoh" di layar, dan
**tidak ikut ditulis ke penyimpanan**.

### e. Navigasi

Indeks tab **tidak boleh dipatok**. Jumlah tab berbeda per role. Pakai:

```dart
indeksTab(session.efektif, 'Galeri')   // dari features/shell/data/app_tabs.dart
```

Tiap `context.go('/x')` harus punya rute di `lib/core/router.dart`.

---

## 4. Jebakan yang sudah kejadian (jangan diulang)

1. **Build hijau ≠ aplikasi jalan.** Flutter hanya mengompilasi file yang
   terjangkau dari `main.dart`. File yatim dengan `undefined name` pernah
   lolos 4 rilis.
2. **`AnimationController` dibaca `.value` di `build` tanpa listener** →
   widget tidak pernah dibangun ulang → layar kosong. Pakai dua
   `AnimatedBuilder` bersarang.
3. **`Column` + `Spacer(flex:)` bukan centering.** Pakai `Stack` + `Center` +
   `Positioned(bottom:)`.
4. **`Padding(right:)` di item terakhir `Row` yang di-center** → seluruh
   kelompok bergeser setengah jarak. Pakai `mainAxisSize: min` + padding
   hanya di antara item.
5. **Ganti-string massal menyisakan prefiks.** Setelah refactor, selalu
   `grep` nama kelas lama.
6. **Import yang "tidak terpakai" bisa bermasalah.** Cek dulu apakah file itu
   mendeklarasikan extension.
7. **Parameter opsional `this.x = false`** — kalau field-nya lupa ditulis,
   compile error. Sudah ada cek `FIELD-HILANG`.

---

## 5. Riwayat versi

| Versi | Isi |
|---|---|
| 0.10.0 | Papan FISH warga + Panel Pengurus |
| 0.11.0 | Katalog UMKM + Lapor darurat + perbaikan aksi cepat |

Dependency penting:
- `url_launcher ^6.3.1` — **jangan** naikkan ke 6.3.3, butuh Dart `^3.11`
  sedangkan project mendeklarasikan `sdk >=3.4.0`.
- `sdk: ">=3.4.0 <4.0.0"` di `pubspec.yaml`

---

## 6. Apa yang belum ada (status jujur)

**Sudah jadi (10):** berita & pengumuman, agenda, galeri, UMKM, aspirasi &
pengaduan, lapor darurat, absensi QR, profil, pengaturan (sebagian),
pengumuman di beranda.

**Setengah (2):** kartu anggota digital (QR-nya masih gambar tiruan, belum
bisa discan), pengaturan (Edit profil / Notifikasi / Bantuan masih kosong).

**Belum (3 + 2):** peta wilayah, forum warga, booking fasilitas, chat,
donasi.

**Tidak bisa tanpa akun lain:** donasi sungguhan (butuh akun merchant
Midtrans), push (butuh Firebase), broadcast WhatsApp (butuh WA Business),
verifikasi NIK otomatis (tidak ada API publik).