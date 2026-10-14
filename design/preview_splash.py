#!/usr/bin/env python3
"""Pratinjau splash KUNBAR Connect - mensimulasikan geometri HP SUNGGUHAN.

Kenapa script ini berbeda dari versi sebelumnya:

  Versi lama menggambar di kanvas 1080x2160 lalu angka dp ditebak manual.
  Akibatnya yang terlihat di pratinjau TIDAK sama dengan yang muncul di HP:
  - tidak ada inset status bar / navigation bar
  - tidak ada textscalel pengaturan sistem
  - tidak ada uji di ukuran layar yang berbeda

Script ini menggambar pada ukuran DP NYATA (360x800 dan 412x915) memakai
angka dan algoritma yang PERSIS SAMA dengan kode Dart-nya, lalu mengukur
posisi blok konten terhadap titik tengah layar secara angka.
"""

import math
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

OUT = Path(__file__).resolve().parent

# Perangkat nyata
DEVICES = [
    # nama, lebar dp, tinggi dp, inset atas, inset bawah
    ("kecil", 360, 800, 28, 24),
    ("besar", 412, 915, 30, 26),
]

SCALE = 3  # px per dp, supaya teks tetap tajam saat dilihat

THEMES = {
    "terang": dict(green=(27, 94, 32), mid=(46, 125, 50), surface=(246, 248, 245),
                   ink=(17, 24, 19), soft=(110, 124, 114),
                   rule=(232, 237, 232), track=(222, 230, 223),
                   gold=(245, 185, 20), mark_text=(255, 255, 255), glow=(27, 94, 32),
                   tint=(233, 242, 234)),
    "gelap": dict(green=(127, 201, 138), mid=(168, 224, 176), surface=(16, 26, 19),
                  ink=(238, 245, 239), soft=(150, 168, 155),
                  rule=(38, 52, 43), track=(38, 52, 43),
                  gold=(255, 193, 7), mark_text=(14, 28, 18), glow=(127, 201, 138),
                   tint=(23, 37, 27)),
}

FONTS = ["/system/fonts/RobotoFlex-Regular.ttf",
         "/data/data/com.termux/files/usr/share/fonts/TTF/DejaVuSans.ttf"]
_font_cache = {}


def font(dp):
    key = int(dp)
    if key in _font_cache:
        return _font_cache[key]
    px = max(8, int(round(dp * SCALE)))
    for p in FONTS:
        if Path(p).is_file():
            try:
                f = ImageFont.truetype(p, px)
                _font_cache[key] = f
                return f
            except OSError:
                pass
    f = ImageFont.load_default()
    _font_cache[key] = f
    return f


def tw(d, text, f, tr=0.0):
    if not text:
        return 0.0
    return sum(d.textlength(c, font=f) for c in text) + tr * (len(text) - 1)


def tracked(d, cx, y, text, f, fill, tr=0.0):
    trpx = tr * SCALE
    x = cx - tw(d, text, f, trpx) / 2
    for ch in text:
        d.text((x, y), ch, font=f, fill=fill)
        x += d.textlength(ch, font=f) + trpx
    return tw(d, text, f, trpx)


def measure(mode="terang"):
    """Hitung ukuran & posisi dalam DP - identik dengan kode Flutter."""
    C = THEMES[mode]
    dp = {k: v * SCALE for k, v in C.items() if k not in ("mark_text",)}
    return C, dp


def layout(w_dp, h_dp, inset_top, inset_bottom, C, S=1.0):
    """Kembalikan daftar (jenis, nilai) + tinggi blok, dalam DP.

    S = faktor skala responsif. Meniru Flutter:
        final u = (shortest / 360).clamp(1.0, 1.22);
    """
    shortest = min(w_dp, h_dp)
    u = max(1.0, min(1.22, shortest / 360.0))

    mark = 88 * u
    gap1 = 22 * u          # mark -> wordmark
    f_word = 30 * u
    gap2 = 11 * u          # wordmark -> aksen
    bar_w, bar_h = 22 * u, 3 * u
    gap3 = 12 * u          # aksen -> CONNECT
    f_sub = 10.5 * u
    gap4 = 15 * u          # CONNECT -> tagline
    f_tag = 12.5 * u
    gap5 = 15 * u          # tagline -> tagline-2
    f_tag2 = 12.5 * u

    h_word = f_word * 1.0
    h_sub = f_sub * 1.25
    h_tag = f_tag * 1.35

    blocks = [
        ("mark", mark, mark),
        ("gap", gap1, gap1),
        ("word", f_word, h_word),
        ("gap", gap2, gap2),
        ("bar", bar_w, bar_h),
        ("gap", gap3, gap3),
        ("sub", f_sub, h_sub),
        ("gap", gap4, gap4),
        ("tag", f_tag, h_tag),
        ("gap", gap5, gap5),
        ("tag2", f_tag2, h_tag),
    ]
    total = sum(b[2] for b in blocks)
    return blocks, total, u, dict(mark=mark, f_word=f_word, bar_w=bar_w,
                                  bar_h=bar_h, f_sub=f_sub, f_tag=f_tag,
                                  f_tag2=f_tag2)



def glow_mask(size, inner_frac=0.0, strength=255):
    """Topeng cahaya radial: pusat terang, tepi transparan.

    Dibangun di kanvas kecil (72x72) lalu di-upscale - jauh lebih cepat dan
    bebas dari aliasing. Urutan benar: nilai dihitung dari jarak ternormalisasi
    (t = d/maks), jadi PUSAT selalu paling terang.
    """
    k = 72
    c = (k - 1) / 2
    maks = math.hypot(c, c)
    m = Image.new("L", (k, k), 0)
    px = m.load()
    for yy in range(k):
        for xx in range(k):
            t = min(1.0, math.hypot(xx - c, yy - c) / maks)
            v = max(0.0, 1.0 - t)
            px[xx, yy] = int(strength * (v ** 2.2))
    return m.resize((size, size), Image.Resampling.BILINEAR)


def soft_shadow(img, box, radius, blur, color, offset_y):
    """Bayangan lembut di bawah mark."""
    lay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(lay).rounded_rectangle(box, radius=radius, fill=color)
    lay = lay.filter(ImageFilter.GaussianBlur(blur))
    img.alpha_composite(lay, (0, offset_y))


def render(dev, mode, with_guides=True):
    """Gambar persis seperti Stack+Center di Flutter, lalu UKUR hasilnya."""
    nama, w_dp, h_dp, it, ib = dev
    C = THEMES[mode]
    W, H = w_dp * SCALE, h_dp * SCALE
    img = Image.new("RGBA", (W, H), C["surface"] + (255,))
    # --- gradasian aksen halus: permukaan -> sedikit lebihFRESH ke arah
    #     tengah atas. Cukup tipis untuk tetap terbaca sebagai warna APPLE,
    #     tapi cukup terasa untuk tidak terlihat "datar".
    grad = Image.new("RGB", (1, H))
    gd = ImageDraw.Draw(grad)
    a, b = C["surface"], C["tint"]
    for yy in range(H):
        t = (yy / (H - 1)) ** 0.85
        gd.point((0, yy), fill=tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3)))
    img.paste(grad.resize((W, H), Image.Resampling.BILINEAR), (0, 0))
    d = ImageDraw.Draw(img)
    cx = W / 2

    # --- skala responsif, sama persis dengan Flutter ---
    u = max(1.0, min(1.22, min(w_dp, h_dp) / 360.0))

    font_mark = font(88 * u * 0.46)
    f_word = font(30 * u)
    f_sub = font(10.5 * u)
    f_tag = font(12.5 * u)
    f_tag2 = font(12.5 * u)

    WORD, SUB = "KUNBAR", "CONNECT"
    TAG = "Satu Kelurahan, Satu Komunitas, Satu Aplikasi"
    TAG2 = "Dibuat bersama warga Kuningan Barat"
    FOOT = "Kelurahan Kuningan Barat  ·  Jakarta Selatan"

    def ink_h(text, f):
        """Tinggi TINTA teks dalam px - inilah yang benar-benar terlihat."""
        b = d.textbbox((0, 0), text, font=f)
        return b[3] - b[1], b

    mark = 88 * u
    bar_w, bar_h = 22 * u, 3 * u
    h_word_px, bb_word = ink_h(WORD, f_word)
    h_sub_px, bb_sub = ink_h(SUB, f_sub)
    h_tag_px, _ = ink_h(TAG, f_tag)
    h_tag2_px, _ = ink_h(TAG2, f_tag2)

    # tinggi tiap elemen dalam px (DP x SCALE)
    px = SCALE
    blocks = [
        ("mark",  mark * px,   mark * px),
        ("gap",   22 * u * px, 22 * u * px),
        ("word",  0,           h_word_px),
        ("gap",   11 * u * px, 11 * u * px),
        ("bar",   bar_w * px,  bar_h * px),
        ("gap",   12 * u * px, 12 * u * px),
        ("sub",   0,           h_sub_px),
        ("gap",   15 * u * px, 15 * u * px),
        ("tag",   0,           h_tag_px),
        ("gap",   15 * u * px, 15 * u * px),
        ("tag2",  0,           h_tag2_px),
    ]
    total_px = sum(b[2] for b in blocks)

    safe_top, safe_bot = it * px, (h_dp - ib) * px
    safe_h = safe_bot - safe_top
    # Stack + Center -> titik tengah blok = titik tengah area aman
    y = safe_top + (safe_h - total_px) / 2.0
    top_px, bawah_px = y, y + total_px

    if with_guides:
        d.line([(0, H / 2), (W, H / 2)], fill=(232, 60, 140), width=2)
        d.line([(safe_top, 0), (safe_top, H)], fill=(60, 170, 255), width=1)
        d.line([(safe_bot, 0), (safe_bot, H)], fill=(60, 170, 255), width=1)

    def draw_text(kind, text, f, color, tr, blk_h):
        b = d.textbbox((0, 0), text, font=f)
        ink = b[3] - b[1]
        top = y + (blk_h - ink) / 2 - b[1]
        if tr:
            trpx = tr * px
            x = cx - tw(d, text, f, trpx) / 2
            for ch in text:
                d.text((x, top), ch, font=f, fill=color)
                x += d.textlength(ch, font=f) + trpx
        else:
            d.text((cx - tw(d, text, f) / 2, top), text, font=f, fill=color)

    for kind, a, h in blocks:
        if kind == "gap":
            y += h
            continue
        if kind == "mark":
            # --- kedalaman: cahaya radial lembut + bayangan (Material 3 Expressive) ---
            gr = int(a * 2.5)
            gx0, gy0 = int(cx - gr / 2), int(y + h / 2 - gr / 2)
            gl = Image.new("RGBA", (gr, gr), C["glow"] + (0,))
            gr = int(a * 2.9)
            gm = glow_mask(gr, strength=(62 if mode == "terang" else 105))
            gl.putalpha(ImageChops.multiply(gm, gl.split()[3]))
            img.alpha_composite(gl, (gx0, gy0))
            base = Image.new("RGBA", img.size, (0, 0, 0, 0))
            soft_shadow(base,
                        [cx - a / 2, y + h * 0.10, cx + a / 2, y + h * 0.97],
                        int(a * 0.265), a * 0.14,
                        (10, 40, 16, (62 if mode == "terang" else 120)), int(a * 0.09))
            img.alpha_composite(base)
            d = ImageDraw.Draw(img)
            d.rounded_rectangle([cx - a / 2, y, cx + a / 2, y + h],
                                radius=int(a * 0.265), fill=C["green"])
            b = d.textbbox((0, 0), "K", font=font_mark)
            d.text((cx - d.textlength("K", font=font_mark) / 2 - b[0],
                    y + (h - (b[3] - b[1])) / 2 - b[1]),
                   "K", font=font_mark, fill=C["mark_text"])
        elif kind == "bar":
            d.rounded_rectangle([cx - a / 2, y, cx + a / 2, y + h],
                                radius=int(h / 2), fill=C["gold"])
        elif kind == "word":
            draw_text(kind, WORD, f_word, C["ink"], 3.2 * u, h)
        elif kind == "sub":
            draw_text(kind, SUB, f_sub, C["green"], 3.6 * u, h)
        elif kind == "tag":
            draw_text(kind, TAG, f_tag, C["soft"], 0, h)
        elif kind == "tag2":
            draw_text(kind, TAG2, f_tag2, C["soft"], 0, h)
        y += h

    # ---- footer dipin ke dasar area aman ----
    f_foot = font(10.5 * u)
    rule_w = 120 * u * px
    fy = safe_bot - 52 * u * px
    d.rounded_rectangle([cx - rule_w / 2, fy, cx + rule_w / 2, fy + 2],
                        radius=1, fill=C["rule"])
    draw_text_fy = fy + 12 * u * px
    b = d.textbbox((0, 0), FOOT, font=f_foot)
    d.text((cx - tw(d, FOOT, f_foot) / 2, draw_text_fy - b[1]), FOOT,
           font=f_foot, fill=C["soft"])

    pw, ph = 108 * u * px, 3 * u * px
    py = safe_bot - 24 * u * px
    d.rounded_rectangle([cx - pw / 2, py, cx + pw / 2, py + ph],
                        radius=int(ph / 2), fill=C["track"])
    d.rounded_rectangle([cx - pw / 2, py, cx - pw / 2 + pw * 0.45, py + ph],
                        radius=int(ph / 2), fill=C["green"])

    tengah_blok_px = (top_px + bawah_px) / 2
    tengah_layar_px = H / 2
    return img, dict(
        top_dp=top_px / px, bottom_dp=bawah_px / px, tinggi_dp=total_px / px,
        tengah_dp=tengah_blok_px / px, tengah_layar_dp=tengah_layar_px / px,
        geser_dp=(tengah_blok_px - tengah_layar_px) / px,
        u=u, mark_dp=mark, word_sp=30 * u,
    )


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "terang"
    semua = []
    for dev in DEVICES:
        img, m = render(dev, mode)
        p = OUT / f"splash-{mode}-{dev[0]}.png"
        img.save(p)
        semua.append((dev[0], m))
        print(f"{dev[0]:6s} {dev[1]}x{dev[2]}dp  skala u={m['u']:.2f}  "
              f"mark={m['mark_dp']:.0f}dp  wordmark={m['word_sp']:.0f}sp")
        print(f"       blok konten : atas {m['top_dp']:.0f}dp -> bawah {m['bottom_dp']:.0f}dp "
              f"(tinggi {m['tinggi_dp']:.0f}dp)")
        print(f"       TENGAH blok = {m['tengah_dp']:.1f}dp | TENGAH layar = {m['tengah_layar_dp']:.1f}dp "
              f"| SELISIH = {m['geser_dp']:+.1f}dp")
    # samakan tinggi untuk lihat berdampingan
    a = Image.open(OUT / f"splash-{mode}-kecil.png")
    b = Image.open(OUT / f"splash-{mode}-besar.png")
    gap = 18
    c = Image.new("RGB", (a.width + b.width + gap, max(a.height, b.height)), (120, 120, 120))
    c.paste(a, (0, 0)); c.paste(b, (a.width + gap, 0))
    c.resize((c.width // 2, c.height // 2), Image.Resampling.LANCZOS).save(
        OUT / f"preview-splash-band.png")
    print(f"\nbanding: preview-splash-band.png")
    sys.exit(0)