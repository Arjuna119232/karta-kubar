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
def _tinggi_teks(teks: str, fs: int, tracking: float) -> int:
    """Tinggi VISUAL (piksel alpha terisi) - bukan tinggi font."""
    probe = Image.new("RGBA", (900, fs * 3 + 20), (0, 0, 0, 0))
    teks_tracking(probe, teks, 450, (fs * 3 + 20) / 2, fs, PUTIH, tracking=tracking)
    bb = probe.split()[3].getbbox()
    return 0 if bb is None else bb[3] - bb[1]


def susun_blok(baris: list[tuple[str, int, float]], r_emblem: int, gap: int) -> tuple[float, list[tuple]]:
    """Hitung (cy_emblem, posisi_baris) untuk seluruh isi, dengan blok DIPUSATKAN.

    `baris` = [(teks, ukuran_font, tracking), ...] dari atas ke bawah.
    Semua tinggi diambil dari piksel yang benar-benar terisi, lalu blok
    dipusatkan terhadap titik tengah kanvas.

    Posisi tidak pernah dipatok ke angka tetap. Kalau dipatok, begitu font
    atau emblem diganti bloknya meleset keluar mask circle - dan build tetap
    hijau.

    JARAK SETIAP ELEMEN dihitung bergantian, termasuk jarak emblem ke baris
    pertama. Versi pertama fw lupa menambahkan jarak itu, hasilnya emblem
    menimpa teks (terlihat di render iOS).
    """
    # urutan elemen: emblem, gap, baris0, gap, baris1, ...
    tinggi = [2 * r_emblem]
    for teks, fs, tr in baris:
        tinggi.append(gap)
        tinggi.append(_tinggi_teks(teks, fs, tr))
    total = sum(tinggi)

    y = (CANVAS - total) / 2.0
    cy_emblem = y + r_emblem
    y += 2 * r_emblem

    posisi = []
    for teks, fs, tr in baris:
        y += gap
        h = _tinggi_teks(teks, fs, tr)
        posisi.append((teks, fs, tr, y + h / 2))
        y += h
    return cy_emblem, posisi


def buat_ikon_android() -> Image.Image:
    """Lockup di dalam circle 192dp: emblem + KUNBAR + CONNECT.

    "KUNBAR" besar, "CONNECT" lebih kecil dengan letter-spacing lebar -
    lockup klasik dua baris. Parameter hasil SEARCH, bukan tebakan:
    maximize ukuran teks dengan syarat emblem >= 88 px dan sisa radius
    cukup dari batas mask 96 dp.
    """
    kanvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    emblem = Image.open(SUMBER).convert("RGBA")
    r_emblem = 92
    fs_kunbar, fs_connect = 48, 22
    baris = [
        (WORDMARK, fs_kunbar, fs_kunbar * 0.12),
        ("CONNECT", fs_connect, fs_connect * 0.28),
    ]
    cy_emblem, posisi = susun_blok(baris, r_emblem, gap=18)
    tempel(kanvas, muat(emblem, r_emblem), CANVAS / 2, cy_emblem)
    for teks, fs, tr, cy in posisi:
        teks_tracking(kanvas, teks, CANVAS / 2, cy, fs, PUTIH, tracking=tr)
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
    """Lockup untuk UILaunchScreen: emblem + KUNBAR + CONNECT + From KATAR KUNBAR.

    iOS tidak punya slot terpisah: UILaunchScreen hanya boleh UIColorName +
    UIImageName, dan gambar SELALU dipusatkan - tidak ada cara menaruh
    kredit di paling bawah layar. Jadi semuanya jadi satu gambar.
    """
    emblem = Image.open(SUMBER).convert("RGBA")
    sisi = px * 3                      # kanvas besar lalu di-crop ke tengah
    r_embl = round(px * 0.19)
    fs1 = round(px * 0.105)
    fs2 = round(px * 0.050)
    fs3 = round(px * 0.044)
    gap = round(px * 0.055)

    kanvas = Image.new("RGBA", (sisi, sisi), (0, 0, 0, 0))
    rows = [
        (WORDMARK, fs1, fs1 * 0.12),
        ("CONNECT", fs2, fs2 * 0.28),
        ("From KATAR KUNBAR", fs3, fs3 * 0.06),
    ]
    hs = [_tinggi_teks(t, f, k) for t, f, k in rows]
    tinggi = 2 * r_embl + sum(hs) + gap * (len(rows) + 1)
    y = (sisi - tinggi) / 2.0
    cy = y + r_embl
    tempel(kanvas, muat(emblem, r_embl), sisi / 2, cy)
    y += 2 * r_embl
    for i, (teks, fs, tr) in enumerate(rows):
        y += gap + hs[i] / 2
        teks_tracking(kanvas, teks, sisi / 2, y, fs, PUTIH, tracking=tr)
        y += hs[i] / 2
    return kanvas.crop((px, px, px * 2, px * 2))


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
    ikon = buat_ikon_android()
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