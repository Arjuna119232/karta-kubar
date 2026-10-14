#!/usr/bin/env python3
"""Buat aset ikon splash yang MUAT di mask lingkaran Android 12+.

MASALAH YANG DISELESAIKAN
--------------------------
`assets/brand/emblem-512.png` punya isi 434 x 458 px di canvas 512 x 512.
Android 12+ `Theme.SplashScreen` menaruh drawable di kotak 288dp lalu
MEMASKINGNYA jadi lingkaran diameter 192dp (= 288 * 2/3). Isi logo harus
punya radius <= 96dp dari titik tengah.

  1 px pada canvas 512px  =  288 / 512  =  0.5625 dp
  jari-jari circle        =  96 / 0.5625  =  170.67 px

Emblem lama: radius 176,2 px = 99,1 dp -> TERPOTONG.

SANDARAN UKURAN (dari developer.android.com "Splash screen dimensions")
  * App icon tanpa icon background : 288x288 dp, muat lingkaran 192 dp
  * App icon dengan icon background: 240x240 dp, muat lingkaran 160 dp
  * Branding image                 : 200x80 dp  (tidak direkomendasikan
                                     Google's, tapi itu satu-satunya slot
                                     "di paling bawah")
"""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
SUMBER = ROOT / "assets/brand/emblem-512.png"
KELUAR = ROOT / "assets/brand"

# --- dari lib/core/theme/app_colors.dart ---
PRIMARY = (0x1B, 0x5E, 0x20)
PUTIH = (255, 255, 255)

# --- teks yang diminta ---
WORDMARK = "KUNBAR"
KREDIT = "From KATAR KUNBAR"

FONT = "/system/fonts/RobotoFlex-Regular.ttf"

# --- geometri Android 12+ ---
KOTAK_DP = 288.0
CIRCLE_DP = 192.0
CANVAS = 512
AMAN = 0.95             # margin 5% supaya tepi tidak ikut terpotong
BRANDING_DP = (200, 80)  # slot "paling bawah"

DP_PER_PX = KOTAK_DP / CANVAS
JARI_PX = (CIRCLE_DP / 2.0) * AMAN / DP_PER_PX


def font_tebal(px: int) -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(FONT, px)
    f.set_variation_by_name("Bold")
    return f


def radius_maks(img: Image.Image) -> float:
    """Jarak true terbesar dari titik tengah ke piksel yang tidak transparan.

    WAJIB begini, bukan half-diagonal bounding box: untuk bentuk LINGKARAN
    sudut kotak justru yang transparan, dan untuk logo figuratif (pohon,
    warga, pin) sudut kotak juga kosong. Dua-duanya bikin half-diagonal
    meleset jauh.
    """
    a = img.split()[3]
    w, h = img.size
    cx, cy = (w - 1) / 2.0, (h - 1) / 2.0
    px = a.load()
    best = 0.0
    for y in range(0, h, 2):
        dy = y - cy
        for x in range(0, w, 2):
            if px[x, y] > 8:
                d = math.hypot(x - cx, dy)
                if d > best:
                    best = d
    return best


def muat(src: Image.Image, jari_px: float) -> Image.Image:
    """Skala `src` supaya radius true-nya <= jari_px."""
    s = jari_px / radius_maks(src)
    w, h = src.size
    return src.resize((max(1, round(w * s)), max(1, round(h * s))), Image.LANCZOS)


def tempel(kanvas: Image.Image, img: Image.Image, cx: float, cy: float) -> Image.Image:
    kanvas.alpha_composite(img, (round(cx - img.size[0] / 2), round(cy - img.size[1] / 2)))
    return kanvas


def warnai(src: Image.Image, rgb: tuple[int, int, int]) -> Image.Image:
    """Pertahankan alpha, ganti semua piksel warna jadi `rgb`."""
    solid = Image.new("RGBA", src.size, rgb + (0,))
    solid.putalpha(src.split()[3])
    return solid


# --------------------------------------------------------------- teks
def teks_tracking(
    kanvas: Image.Image,
    teks: str,
    cx: float,
    cy: float,
    fs: int,
    rgb: tuple[int, int, int],
    tracking: float = 0.0,
    bobot: str = "Bold",
) -> tuple[float, float]:
    """Gambar teks satu per huruf supaya letter-spacing bisa diatur.

    Returns (lebar, tinggi) - diukur dari bbox AKTUAL, bukan dari ukuran font.
    Meng pakai tinggi font bikin baris meleset: Roboto punya ruang ascender
    yang jauh lebih besar dari tinggi huruf yang terlihat.
    """
    f = font_tebal(fs)
    d = ImageDraw.Draw(kanvas)
    lebar = sum(d.textlength(c, font=f) for c in teks) + tracking * (len(teks) - 1)
    x = cx - lebar / 2
    for c in teks:
        d.text((x, cy), c, font=f, fill=rgb + (255,), anchor="lm")
        x += d.textlength(c, font=f) + tracking
    bb = d.textbbox((0, 0), teks, font=f)
    return lebar, bb[3] - bb[1]


def tinggi_visual(kanvas: Image.Image, y_min: int, y_max: int) -> int:
    """Tinggi piksel yang benar-benar terisi di rentang y tertentu."""
    a = kanvas.crop((0, y_min, kanvas.size[0], y_max)).split()[3]
    bb = a.getbbox()
    return 0 if bb is None else bb[3] - bb[1]


# --------------------------------------------------------------- ikon Android
def buat_ikon_android(fs_wordmark: int, r_emblem: int, gap: int) -> Image.Image:
    """Lockup di dalam circle 192dp: emblem di atas, WORDMARK di bawah.

    Blok DIPUSATKAN dari tinggi visual yang benar-benar terisi, bukan dari
    angka tetap seperti `y = canvas * 0.68`. Kalau posisi dipatok, begitu
    ukuran font atau emblem diganti, bloknya meleset dan bisa keluar dari
    mask - dan build tetap hijau.
    """
    kanvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    emblem = Image.open(SUMBER).convert("RGBA")

    # 1) ukur tinggi VISUAL wordmark (piksel yang terisi, bukan tinggi font)
    probe = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    teks_tracking(probe, WORDMARK, CANVAS / 2, CANVAS / 2, fs_wordmark, PUTIH,
                  tracking=fs_wordmark * 0.10)
    h_word = tinggi_visual(probe, 0, CANVAS)

    # 2) tinggi blok = 2*r_emblem + gap + h_word, lalu dipusatkan
    tinggi_blok = 2 * r_emblem + gap + h_word
    atas = (CANVAS - tinggi_blok) / 2.0
    y_embl = atas + r_emblem
    y_word = atas + 2 * r_emblem + gap + h_word / 2

    tempel(kanvas, muat(emblem, r_emblem), CANVAS / 2, y_embl)
    teks_tracking(kanvas, WORDMARK, CANVAS / 2, y_word, fs_wordmark, PUTIH,
                  tracking=fs_wordmark * 0.10)
    return kanvas


def buat_branding() -> dict[str, Image.Image]:
    """Gambar 'From KATAR KUNBAR' untuk slot 200x80dp di paling bawah.

    Android hanya menyediakan SATU slot branding, jadi nama "From KATAR
    KUNBAR" harus muat di sana. Lebar 200dp dipakai penuh; teks dibungkus ke
    dua baris supaya proporsinya terbaca di layar 360dp.
    """
    hasil: dict[str, Image.Image] = {}
    for dens, px in (("hdpi", 1.5), ("xhdpi", 2.0), ("xxhdpi", 3.0), ("xxxhdpi", 4.0)):
        W = round(BRANDING_DP[0] * px)
        H = round(BRANDING_DP[1] * px)
        c = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        fs = round(H * 0.26)
        # "From KATAR KUNBAR" -> dua baris supaya proporsinya pas di 200dp
        teks_tracking(c, "From", W / 2, H * 0.36, fs, PUTIH, tracking=fs * 0.14)
        teks_tracking(c, "KATAR KUNBAR", W / 2, H * 0.70, fs, PUTIH,
                      tracking=fs * 0.10)
        hasil[f"splash_branding_{dens}.png"] = c
    return hasil


# --------------------------------------------------------------- iOS
def buat_ios(px: int) -> Image.Image:
    """Lockup untuk UILaunchScreen: emblem + KUNBAR + From KATAR KUNBAR.

    iOS tidak punya slot terpisah: UILaunchScreen hanya boleh UIColorName +
    UIImageName, dan gambar SELALU dipusatkan - tidak ada cara menaruh
    teks di paling bawah layar. Jadi ketiganya jadi satu gambar.
    """
    emblem = Image.open(SUMBER).convert("RGBA")
    r_embl = round(px * 0.20)
    fs_w = round(px * 0.115)
    fs_k = round(px * 0.045)
    gap1 = round(px * 0.055)
    gap2 = round(px * 0.075)

    kanvas = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    y_word = int(px * 0.58)
    teks_tracking(kanvas, WORDMARK, px / 2, y_word, fs_w, PUTIH,
                  tracking=fs_w * 0.14)
    h_word = tinggi_visual(kanvas, y_word - fs_w, y_word + fs_w)

    teks_tracking(kanvas, "From", px / 2, y_word + h_word / 2 + gap2 + fs_k * 0.5,
                  fs_k, PUTIH, tracking=fs_k * 0.20)
    teks_tracking(kanvas, "KATAR KUNBAR", px / 2,
                  y_word + h_word / 2 + gap2 + fs_k * 2.1, fs_k, PUTIH,
                  tracking=fs_k * 0.14)

    y_embl = y_word - h_word / 2 - gap1 - r_embl
    tempel(kanvas, muat(emblem, r_embl), px / 2, y_embl)
    return kanvas


# --------------------------------------------------------------- cek
def cek_muat_android(nama: str) -> None:
    im = Image.open(KELUAR / nama).convert("RGBA")
    if im.split()[3].getbbox() is None:
        raise SystemExit(f"FAIL: {nama} kosong")
    r_dp = radius_maks(im) * DP_PER_PX
    batas = CIRCLE_DP / 2.0
    print(f"      {'OK ' if r_dp <= batas else 'FAIL'} radius {r_dp:6.1f}dp "
          f"(batas {batas:.0f}dp, sisa {batas - r_dp:5.1f}dp)")
    if r_dp > batas:
        raise SystemExit(f"FAIL: {nama} akan TERPOTONG oleh mask Android 12")


def cek_branding(nama: str, dens: float) -> None:
    im = Image.open(KELUAR / nama)
    mau = (round(BRANDING_DP[0] * dens), round(BRANDING_DP[1] * dens))
    if im.size != mau:
        raise SystemExit(f"FAIL: {nama} {im.size}, harusnya {mau}")
    if im.convert("RGBA").split()[3].getbbox() is None:
        raise SystemExit(f"FAIL: {nama} kosong")
    print(f"      OK  {nama:32s} {im.size[0]}x{im.size[1]}px = "
          f"{im.size[0] / dens:.0f}x{im.size[1] / dens:.0f}dp")


def main() -> int:
    if not SUMBER.is_file():
        raise SystemExit(f"FAIL: emblem sumber tidak ada: {SUMBER}")
    if not Path(FONT).is_file():
        raise SystemExit(f"FAIL: font tidak ada: {FONT}")

    print("==> gen_splash_icons")
    print(f"    mask circle : {CIRCLE_DP:.0f}dp di kotak {KOTAK_DP:.0f}dp")
    print(f"    jari aman   : {JARI_PX:.1f}px")

    # --- ikon: emblem + KUNBAR dalam satu circle ---
    ikon = buat_ikon_android(fs_wordmark=50, r_emblem=90, gap=24)
    ikon.save(KELUAR / "splash_icon.png", "PNG", optimize=True)
    print(f"    + splash_icon.png  ({KELUAR.joinpath('splash_icon.png').stat().st_size // 1024} KB)")

    # --- branding image (slot paling bawah) ---
    for nama, img in buat_branding().items():
        img.save(KELUAR / nama, "PNG", optimize=True)
    print(f"    + splash_branding_*.png ({len(buat_branding())} density)")

    # --- iOS: satu gambar, semua elemen digabung ---
    for skala, px in (("1x", 260), ("2x", 520), ("3x", 780)):
        im = buat_ios(px)
        nama = "splash_icon_ios.png" if skala == "1x" else f"splash_icon_ios@{skala}.png"
        im.save(KELUAR / nama, "PNG", optimize=True)

    print("    -- verifikasi --")
    cek_muat_android("splash_icon.png")
    for dens in (1.5, 2.0, 3.0, 4.0):
        cek_branding(f"splash_branding_{'hdpi' if dens==1.5 else 'xhdpi' if dens==2 else 'xxhdpi' if dens==3 else 'xxxhdpi'}.png", dens)
    for skala, px in (("1x", 260), ("2x", 520), ("3x", 780)):
        nama = "splash_icon_ios.png" if skala == "1x" else f"splash_icon_ios@{skala}.png"
        im = Image.open(KELUAR / nama)
        if im.size != (px, px):
            raise SystemExit(f"FAIL: {nama} {im.size}, harusnya ({px},{px})")
        print(f"      OK  {nama:26s} {im.size[0]}x{im.size[1]}px = {px}pt")
    print("==> gen_splash_icons: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())