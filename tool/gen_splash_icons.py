#!/usr/bin/env python3
"""Buat aset ikon splash yang MUAT di mask lingkaran Android 12+.

MASALAH YANG DISELESAIKAN
--------------------------
`assets/brand/emblem-512.png` (file lama, dipakai splash Flutter) punya isi
434 x 458 px di dalam canvas 512 x 512. Android 12+ `Theme.SplashScreen`
menempatkan drawable di kotak 288dp lalu MEMASKINGNYA jadi lingkaran diameter
192dp (= 288 * 2/3). Jadi isi logo harus punya half-diagonal <= 96dp.

  1 px pada canvas 512px  =  288 / 512  =  0.5625 dp
  jari-jari circle        =  96 / 0.5625  =  170.67 px
  half-diagonal isi sekarang = sqrt(217^2 + 229^2) = 315.5 px   <-- 1.85x Terlalu besar

Kalau emblem lama dipakai apa adanya, Android akan memotong hampir separuh
logo. Script ini membuat dua aset yang sudah dihitung ulang:

  A. splash_icon.png        - emblem putih langsung di atas hijau (tanpa badge)
  B. splash_icon_badge.png  - badge lingkaran putih + emblem hijau (gaya 2026)
  C. splash_icon_ios.png    - ukuran intrinsic untuk UILaunchScreen iOS

Semua angka di sini disalin dari `lib/core/theme/app_colors.dart`.
Jalankan ulang setiap kali file emblem sumber berubah.
"""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SUMBER = ROOT / "assets/brand/emblem-512.png"
KELUAR = ROOT / "assets/brand"

# --- dari app_colors.dart ---
PRIMARY = (0x1B, 0x5E, 0x20)   # AppColors.primary
PUTIH = (255, 255, 255)

# --- geometri Android 12+ Theme.SplashScreen ---
KOTAK_DP = 288.0        # kotak tempat drawable diletakkan
CIRCLE_DP = 192.0       # diameter mask lingkaran (= KOTAK_DP * 2/3)
CANVAS = 512            # sisi file PNG yang kita hasilkan
AMAN = 0.95             # margin 5% supaya tepi tidak ikut terpotong

DP_PER_PX = KOTAK_DP / CANVAS
JARI_PX = (CIRCLE_DP / 2.0) * AMAN / DP_PER_PX     # 153.6 px


def half_diagonal(w: int, h: int) -> float:
    return math.hypot(w / 2.0, h / 2.0)


def muat(src: Image.Image, jari_px: float) -> Image.Image:
    """Skala `src` (RGBA) supaya radius true-nya persis <= jari_px, center.

    Pakai `radius_maks`, BUKAN half-diagonal bounding box: logo figuratif
    (pohon + warga + pin) punya sudut kotak yang KOSONG. Kalau pakai
    half-diagonal, logo hanya jadi 58dp dari 96dp yang tersedia - kelihatan
    kecil dan messaging brand-nya hilang.
    """
    s = jari_px / radius_maks(src)
    w, h = src.size
    baru = src.resize(
        (max(1, round(w * s)), max(1, round(h * s))),
        Image.LANCZOS,
    )
    return baru


def tempel(kanvas: Image.Image, img: Image.Image) -> Image.Image:
    x = (kanvas.size[0] - img.size[0]) // 2
    y = (kanvas.size[1] - img.size[1]) // 2
    kanvas.alpha_composite(img, (x, y))
    return kanvas


def warnai(src: Image.Image, rgb: tuple[int, int, int]) -> Image.Image:
    """Pertahankan alpha, ganti semua piksel warna jadi `rgb`."""
    a = src.split()[3]
    solid = Image.new("RGBA", src.size, rgb + (0,))
    solid.putalpha(a)
    return solid


def simpan(img: Image.Image, nama: str) -> None:
    p = KELUAR / nama
    img.save(p, "PNG", optimize=True)
    a = img.split()[3]
    bbox = a.getbbox()
    isi = (bbox[2] - bbox[0], bbox[3] - bbox[1]) if bbox else (0, 0)
    print(
        f"    + {nama:24s} {img.size[0]}x{img.size[1]}px  "
        f"isi {isi[0]}x{isi[1]}px "
        f"({isi[1] / CANVAS * 100:.1f}% tinggi)  {p.stat().st_size // 1024} KB"
    )


def radius_maks(img: Image.Image) -> float:
    """Jaraktrue terbesar dari titik tengah ke piksel yang tidak transparan.

    WAJIB begini, bukan half-diagonal bounding box: untuk aset BERBENTUK
    LINGKARAN, sudut-sudut kotak pembatasnya justru bagian yang transparan,
    jadi half-diagonal akan Orts overstated (memories: badge 338px ->
    134dp "terpotong" padahal bulatannya cuma 93dp).
    """
    a = img.split()[3]
    w, h = img.size
    cx, cy = (w - 1) / 2.0, (h - 1) / 2.0
    px = a.load()
    best = 0.0
    # sample step 2 -> cukup presisi untuk aset 512px, 4x lebih cepat
    for y in range(0, h, 2):
        dy = y - cy
        for x in range(0, w, 2):
            if px[x, y] > 8:
                d = math.hypot(x - cx, dy)
                if d > best:
                    best = d
    return best


def cek_muat_android(nama: str) -> None:
    """Pastikan isi aset MUAT di circle 192dp setelah diskalakan ke 288dp."""
    im = Image.open(KELUAR / nama).convert("RGBA")
    if im.split()[3].getbbox() is None:
        raise SystemExit(f"FAIL: {nama} kosong")
    r_dp = radius_maks(im) * DP_PER_PX
    batas = CIRCLE_DP / 2.0
    status = "OK " if r_dp <= batas else "FAIL"
    print(
        f"      {status} radius {r_dp:6.1f}dp  "
        f"(batas {batas:.0f}dp, sisa {batas - r_dp:5.1f}dp)"
    )
    if r_dp > batas:
        raise SystemExit(f"FAIL: {nama} akan TERPOTONG oleh mask Android 12")


def main() -> int:
    if not SUMBER.is_file():
        raise SystemExit(f"FAIL: emblem sumber tidak ada: {SUMBER}")

    emblem = Image.open(SUMBER).convert("RGBA")
    print(f"==> gen_splash_icons: emblem {emblem.size[0]}x{emblem.size[1]}px")
    print(f"    mask circle  : {CIRCLE_DP:.0f}dp di kotak {KOTAK_DP:.0f}dp")
    print(f"    jari aman    : {JARI_PX:.1f}px (={AMAN:.0%} dari {CIRCLE_DP / 2 / DP_PER_PX:.1f}px)")

    # ---- A: emblem putih langsung (gaya paling minimal) ----
    a = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    tempel(a, muat(emblem, JARI_PX))
    simpan(a, "splash_icon.png")

    # ---- B: badge lingkaran putih + emblem hijau ----
    b = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    jari_badge = round((CIRCLE_DP / 2.0) * 0.97 / DP_PER_PX)   # 97% dari mask
    kelipatan = 4                                      # anti-alias saat resize
    mask = Image.new("L", (CANVAS * kelipatan, CANVAS * kelipatan), 0)
    ImageDraw.Draw(mask).ellipse(
        (
            CANVAS * kelipatan // 2 - jari_badge * kelipatan,
            CANVAS * kelipatan // 2 - jari_badge * kelipatan,
            CANVAS * kelipatan // 2 + jari_badge * kelipatan,
            CANVAS * kelipatan // 2 + jari_badge * kelipatan,
        ),
        fill=255,
    )
    badge = Image.new("RGBA", mask.size, PUTIH + (0,))
    badge.putalpha(mask)
    b.alpha_composite(badge.resize((CANVAS, CANVAS), Image.LANCZOS))
    # emblem putih tidak terlihat di badge putih -> recolor ke hijau brand
    hi = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    tempel(hi, muat(emblem, jari_badge * 0.62))
    b.alpha_composite(warnai(hi, PRIMARY))
    simpan(b, "splash_icon_badge.png")

    # ---- C: iOS UILaunchScreen (tanpa mask lingkaran) ----
    # UILaunchScreen memakai UKURAN INTRINSIC gambar dalam POINT, jadi aset
    # iOS dibuat terpisah - memakai splash_icon.png yang 512px akan tampil
    # 512pt dan memenuhi layar.
    #
    # 160pt adalah ukuran logo splash yang wajar di layar 393pt (iPhone 16
    # Pro) -> isi logo jadi sekitar 24% lebar layar.
    IOS_PT = 160
    for skala, px in (("1x", IOS_PT), ("2x", IOS_PT * 2), ("3x", IOS_PT * 3)):
        c = Image.new("RGBA", (px, px), (0, 0, 0, 0))
        tempel(c, muat(emblem, px * 0.36))
        nama = "splash_icon_ios.png" if skala == "1x" else f"splash_icon_ios@{skala}.png"
        simpan(c, nama)

    print("    -- verifikasi mask Android 12 (hanya aset Android) --")
    cek_muat_android("splash_icon.png")
    cek_muat_android("splash_icon_badge.png")

    # Aset iOS TIDAK lewat mask Android: UILaunchScreen memakai ukuran
    # intrinsik dalam point, tidak ada lingkaran 192dp. Yang diverifikasi di
    # sini hanya konsistensi skala 1x/2x/@3x dan isi tidak kosong.
    print("    -- verifikasi aset iOS (skala 1x/2x/3x) --")
    cek_skala_ios()
    print("==> gen_splash_icons: OK")
    return 0


def cek_skala_ios() -> None:
    from PIL import Image as _I

    base = 160
    for skala, px in (("1x", base), ("2x", base * 2), ("3x", base * 3)):
        nama = "splash_icon_ios.png" if skala == "1x" else f"splash_icon_ios@{skala}.png"
        p = KELUAR / nama
        if not p.is_file():
            raise SystemExit(f"FAIL: {nama} tidak ada")
        im = _I.open(p)
        if im.size != (px, px):
            raise SystemExit(f"FAIL: {nama} berukuran {im.size}, harusnya ({px}, {px})")
        bbox = im.convert("RGBA").split()[3].getbbox()
        if bbox is None:
            raise SystemExit(f"FAIL: {nama} kosong (tidak ada piksel opaque)")
        isi = bbox[3] - bbox[1]
        print(f"      OK  {nama:26s} {px}x{px}px  isi {isi}px = {isi / px * base:.0f}pt")


if __name__ == "__main__":
    raise SystemExit(main())
