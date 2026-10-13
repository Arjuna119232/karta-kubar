#!/usr/bin/env python3
"""Render pratinjau splash KUNBAR Connect ke PNG.

Tujuan: LIHAT hasilnya sebelum menulis kode Flutter. Splash dinilai dari
penampilan, jadi membaca kode tidak cukup.

Ini APPROXIMASI: jarak, proporsi, dan matematika warna yang bisa dibuktikan.
Cek akhir tetap di perangkat.
"""

import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

W, H = 1080, 2160
OUT = Path(__file__).resolve().parent / "preview-splash.png"

# palet - WAJIB sama dengan lib/core/theme/app_colors.dart
# (mode gelap memakai nilai yang sama persis dengan AppColors.bgDark /
#  cardDark / primary dark, supaya pratinjau ini bukan karangan)
THEMES = {
    "terang": dict(
        green=(27, 94, 32),          # AppColors.primary
        mid=(46, 125, 50),           # AppColors.primary dark-mode
        surface=(246, 248, 245),     # AppColors.bgLight
        ink=(17, 24, 19),
        soft=(110, 124, 114),
        rule=(232, 237, 232),
        track=(222, 230, 223),
        gold=(245, 185, 20),
        mark_text=(255, 255, 255),
    ),
    "gelap": dict(
        green=(127, 201, 138),       # AppColors.primary dark
        mid=(168, 224, 176),
        surface=(16, 26, 19),        # AppColors.bgDark
        ink=(238, 245, 239),
        soft=(150, 168, 155),
        rule=(38, 52, 43),
        track=(38, 52, 43),
        gold=(255, 193, 7),
        mark_text=(14, 28, 18),
    ),
}

FONTS = [
    "/system/fonts/RobotoFlex-Regular.ttf",
    "/data/data/com.termux/files/usr/share/fonts/TTF/DejaVuSans.ttf",
]


def font(size):
    for p in FONTS:
        if Path(p).is_file():
            try:
                return ImageFont.truetype(p, size)
            except OSError:
                pass
    return None


def tw(d, text, f, tr=0):
    if not text:
        return 0.0
    return sum(d.textlength(c, font=f) for c in text) + tr * (len(text) - 1)


def tracked(d, cx, y, text, f, fill, tr=0):
    x = cx - tw(d, text, f, tr) / 2
    for ch in text:
        d.text((x, y), ch, font=f, fill=fill)
        x += d.textlength(ch, font=f) + tr
    return tw(d, text, f, tr)


def build(mode="terang"):
    C = THEMES[mode]
    GREEN_DEEP, GREEN_MID = C["green"], C["mid"]
    SURFACE, INK, INK_SOFT = C["surface"], C["ink"], C["soft"]
    RULE, TRACK_BG, GOLD = C["rule"], C["track"], C["gold"]
    img = Image.new("RGB", (W, H), SURFACE)
    d = ImageDraw.Draw(img)
    cx = W // 2

    # ---- posisi dihitung dari bbox NYATA, bukan asumsi tinggi font ----
    # (versi lama memakai konstanta h_word, hasilnya garis aksen menabrak
    #  huruf "KUNBAR" karena tinggi visual font != tinggi em box.)
    mark = 320
    gap_mark_word = 84
    gap_word_accent = 34
    gap_accent_sub = 46
    gap_sub_tag = 66
    gap_tag_footer = 40

    fw = font(122)
    fk = font(34)
    ft = font(37)
    fs = font(29)

    word = "KUNBAR"
    sub = "CONNECT"
    tag = "Satu Kelurahan, Satu Komunitas, Satu Aplikasi"

    def box(t, f, tr=0):
        w = tw(d, t, f, tr)
        b = d.textbbox((0, 0), t, font=f)
        return w, b[3] - b[1], b[1]          # lebar, tinggi, offset atas

    _, h_word, o_word = box(word, fw, 12)
    _, h_sub, o_sub = box(sub, fk, 9)
    _, h_tag, _ = box(tag, ft)

    total = (mark + gap_mark_word + h_word + gap_word_accent + 6
             + gap_accent_sub + h_sub + gap_sub_tag + h_tag)
    top = int(H * 0.415 - total / 2)

    # ---- mark: kotak membulat hijau + monogram K putih ----------------
    y = top
    r = int(mark * 0.265)
    d.rounded_rectangle([cx - mark // 2, y, cx + mark // 2, y + mark],
                        radius=r, fill=GREEN_DEEP)
    fkm = font(178)
    bb = d.textbbox((0, 0), "K", font=fkm)
    d.text((cx - d.textlength("K", font=fkm) / 2 - bb[0],
            y + mark / 2 - (bb[1] + bb[3]) / 2), "K", font=fkm, fill=C["mark_text"])
    y += mark + gap_mark_word

    # ---- wordmark ------------------------------------------------------
    tracked(d, cx, y - o_word, word, fw, INK, 12)
    y += h_word + gap_word_accent
    d.rounded_rectangle([cx - 34, y, cx + 34, y + 6], radius=3, fill=GOLD)
    y += 6 + gap_accent_sub

    # ---- sub-wordmark + tagline ---------------------------------------
    tracked(d, cx, y - o_sub, sub, fk, GREEN_MID, 9)
    y += h_sub + gap_sub_tag
    d.text((cx - tw(d, tag, ft) / 2, y), tag, font=ft, fill=INK_SOFT)

    # ---- footer --------------------------------------------------------
    d.rounded_rectangle([cx - 150, H - 286, cx + 150, H - 282], radius=2, fill=RULE)
    t = "Kelurahan Kuningan Barat  ·  Jakarta Selatan"
    d.text((cx - tw(d, t, fs) / 2, H - 256), t, font=fs, fill=INK_SOFT)

    # ---- progres: batang tipis, bukan spinner bulat -------------------
    bw, bh, by = 232, 6, H - 156
    d.rounded_rectangle([cx - bw // 2, by, cx + bw // 2, by + bh], radius=bh // 2, fill=TRACK_BG)
    d.rounded_rectangle([cx - bw // 2, by, cx - bw // 2 + 106, by + bh], radius=bh // 2, fill=GREEN_MID)

    return img, top, mark


if __name__ == "__main__":
    for mode in ("terang", "gelap"):
        out, top, _m = build(mode)
        dst = OUT.with_name(f"preview-splash-{mode}.png")
        out.save(dst)
        print(f"OK -> {dst.name}  ({dst.stat().st_size/1024:.0f} KB)")
    sys.exit(0)
