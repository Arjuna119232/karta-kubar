#!/usr/bin/env python3
"""Pratinjau splash + 3 sampul onboarding KUNBAR Connect.

Kenapa harus render (skill visual-redesign-render-and-look): hasil yang
dinilai user adalah TAMPILAN, bukan kode. Tidak ada Flutter di Termux, jadi
tidak bisa lihat hasilnya langsung. Script ini menggambar ulang tata letak
dengan ANGKA YANG PERSIS SAMA seperti kode Dart-nya, pada ukuran dp HP
sungguhan (bukan kanvas 1080x2160 yang bikin proporsi bohong).

Semua warna diambil dari `lib/core/theme/app_colors.dart`. Tidak ada hex
karangan - kalau palet berubah, pratinjau ikut berubah.
"""

import math
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

AKAR = Path(__file__).resolve().parent.parent
OUT = AKAR / "design"
OUT.mkdir(exist_ok=True)

SCALE = 3  # px per dp
PANDUAN = False  # True = gambar garis bantu pengukuran

# ---- Palet: SALINAN PERSIS dari lib/core/theme/app_colors.dart ----
PRIMARY = (0x1B, 0x5E, 0x20)
SECONDARY = (0xFF, 0xC1, 0x07)
ACCENT = (0x0D, 0x47, 0xA1)
SOCIAL = (0xE9, 0x1E, 0x63)
SUCCESS = (0x2E, 0x7D, 0x32)
BG_LIGHT = (0xF6, 0xF7, 0xF9)
TEXT_PRI_LIGHT = (0x1A, 0x1A, 0x1A)
TEXT_SEC_LIGHT = (0x6A, 0x6A, 0x72)
LINE_LIGHT = (0xEC, 0xEC, 0xEF)
HIJAU_MUDA = (0xE8, 0xF5, 0xE9)  # _SplashScreenState.hijauMuda

# Flutter tidak membundel font di app ini (lihat blok `assets:` pubspec),
# jadi teks dirender dengan Roboto - sama seperti di HP.
FONT_REG = "/system/fonts/RobotoFlex-Regular.ttf"
FONT_ALT = "/data/data/com.termux/files/usr/share/fonts/TTF/DejaVuSans.ttf"
_font_cache = {}


def font(dp, bold=False):
    key = (round(dp, 2), bold)
    if key in _font_cache:
        return _font_cache[key]
    px = max(6, int(round(dp * SCALE)))
    f = None
    for path in ([FONT_REG] if Path(FONT_REG).is_file() else []) + [FONT_ALT]:
        try:
            f = ImageFont.truetype(path, px)
            if bold and hasattr(f, "set_variation_by_name"):
                try:
                    f.set_variation_by_name("Bold")
                except Exception:
                    pass
            break
        except Exception:
            f = None
    if f is None:
        f = ImageFont.load_default()
    _font_cache[key] = f
    return f


def px(dp):
    return int(round(dp * SCALE))


def rgba(rgb, a=1.0):
    return (rgb[0], rgb[1], rgb[2], int(round(255 * a)))


# =====================================================================
# 1. SPLASH  -  cerminan lib/features/splash/presentation/splash_screen.dart
# =====================================================================


def splash(dev_w, dev_h, inset_top, inset_bottom, nama):
    u = min(max(dev_w / 360, 1.0), 1.22)
    W, H = px(dev_w), px(dev_h)
    img = Image.new("RGBA", (W, H), rgba(PRIMARY))

    # (1) grid bergerak: sel 100dp, geser 0 -> 100 -> 0
    geser = 50 * SCALE
    lapis = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(lapis)
    sel = px(100)
    for i in range(-1, W // sel + 2):
        for j in range(-1, H // sel + 2):
            x, y = i * sel, j * sel
            d.line([(x + sel, y), (x, y)], fill=rgba(SUCCESS, 0.20), width=max(1, px(0.9)))
            d.line([(x, y + sel), (x, y)], fill=rgba(SUCCESS, 0.20), width=max(1, px(0.9)))
    img.alpha_composite(lapis)

    # (2) cahaya radial di belakang logo - tengah LAYAR (widget Center)
    glow = px(250 * u)
    kecil = 96
    topeng = Image.new("L", (kecil, kecil), 0)
    td = ImageDraw.Draw(topeng)
    c = (kecil - 1) / 2
    maks = math.hypot(c, c)
    for y in range(kecil):
        for x in range(kecil):
            dist = math.hypot(x - c, y - c) / maks
            t = max(0.0, min(1.0, 1.0 - dist))  # terang di tengah
            topeng.putpixel((x, y), int(0.13 * (t ** 1.4) * 255))
    topeng = topeng.resize((glow, glow), Image.Resampling.BILINEAR)
    halo = Image.new("RGBA", (glow, glow), (255, 255, 255, 0))
    halo.putalpha(topeng)
    img.alpha_composite(halo, ((W - glow) // 2, (H - glow) // 2))

    d = ImageDraw.Draw(img)

    # ---- mengukur blok konten persis seperti Column(mainAxisSize.min) ----
    fs_kunbar = 31 * u
    f_kun = font(fs_kunbar, bold=True)
    lebar_huruf = [d.textlength(ch, font=f_kun) for ch in "KUNBAR"]
    jarak = px(5.5 * u)
    lebar_wordmark = sum(lebar_huruf) + jarak * (len(lebar_huruf) - 1)
    tinggi_wordmark = fs_kunbar * SCALE  # height: 1

    f_connect = font(10.5 * u)
    lebar_connect = sum(d.textlength(ch, font=f_connect) for ch in "CONNECT") + px(6 * u) * 6

    f_lokasi = font(12.5 * u)
    tinggi_lokasi = 12.5 * u * 1.2

    tinggi_blok = (
        136 * u              # logo
        + 30 * u             # jarak
        + tinggi_wordmark    # KUNBAR
        + 10 * u             # jarak
        + 10.5 * u * 1.0     # CONNECT
        + 26 * u             # jarak
        + tinggi_lokasi      # Kuningan Barat
        + 30 * u             # jarak
        + 7                  # loader
    )

    # ---- Stack: konten Center di seluruh area aman, footer Positioned ----
    tinggi_footer = 10.5 * u * 1.2
    pad_bawah = 18 * u
    tengah_y = inset_top + (dev_h - inset_top - inset_bottom) / 2

    y = tengah_y - tinggi_blok / 2

    # (3) logo: emblem 512 -> 136dp, breathing scale 1.03
    ukuran_logo = px(136 * u)
    emblem = Image.open(AKAR / "assets/brand/emblem-512.png").convert("RGBA")
    emblem = emblem.resize((ukuran_logo, ukuran_logo), Image.Resampling.LANCZOS)
    # 'denyut' = titik tengah animasi bernapas
    denyut = 1 + 0.03 * 0.5
    e2 = emblem.resize(
        (int(ukuran_logo * denyut), int(ukuran_logo * denyut)), Image.Resampling.LANCZOS
    )
    img.alpha_composite(
        e2, (int((W - e2.width) / 2), int(px(y) + (ukuran_logo - e2.height) / 2))
    )
    y += 136 * u

    # (4) KUNBAR - satu huruf per satu, jarak 5.5dp
    y += 30 * u
    xk = (W - lebar_wordmark) / 2
    y_teks = px(y) + (tinggi_wordmark * SCALE - fs_kunbar * SCALE) / 2
    for i, ch in enumerate("KUNBAR"):
        d.text((xk, y_teks), ch, font=f_kun, fill=(255, 255, 255, 255))
        xk += lebar_huruf[i] + jarak
    y += tinggi_wordmark

    # (5) CONNECT - tracking disimulasikan manual (Pillow tidak punya
    # letterSpacing), tapi TANPA menimpa garis grid di belakangnya.
    y += 11 * u
    x = (W - lebar_connect) / 2
    for ch in "CONNECT":
        d.text((x, px(y)), ch, font=f_connect, fill=rgba(HIJAU_MUDA, 0.72))
        x += d.textlength(ch, font=f_connect) + px(6 * u)
    y += 10.5 * u

    # (6) Kuningan Barat - Jakarta Selatan
    y += 26 * u
    d.text(
        (W / 2, px(y)),
        "Kuningan Barat  ·  Jakarta Selatan",
        font=f_lokasi,
        fill=rgba(HIJAU_MUDA, 0.80),
        anchor="ma",
    )
    y += tinggi_lokasi

    # (7) loading: tiga pill, fase tengah -> pill 1 & 3 perubahan, 2 hampir bulat
    y += 30 * u
    lebar_dasar, lebar_maks, tinggi_pill, jarak_pill = 7, 26, 7, 9 * u
    fase = 0.10  # satu saat di tengah siklus
    pills = []
    for jeda in (0.00, 0.18, 0.36):
        p = (fase + jeda) % 1.0
        m = 0.5 - 0.5 * math.cos(p * 2 * math.pi)
        k = m * m * (3 - 2 * m)
        pills.append((lebar_dasar + (lebar_maks - lebar_dasar) * k, 0.55 + 0.45 * k))
    total = sum(w for w, _ in pills) + jarak_pill * 2
    x = (W - total) / 2
    for w, a in pills:
        d.rounded_rectangle(
            [x, px(y), x + px(w), px(y + tinggi_pill)],
            radius=px(tinggi_pill) / 2,
            fill=rgba(HIJAU_MUDA, a),
        )
        x += px(w) + px(jarak_pill)

    # (8) FOOTER - paling bawah, di bawah loading
    y_footer = dev_h - inset_bottom - tinggi_footer - pad_bawah + tinggi_footer / 2
    d.text(
        (W / 2, px(y_footer)),
        "from Katar KunBar",
        font=font(10.5 * u),
        fill=rgba(HIJAU_MUDA, 0.55),
        anchor="ma",
    )

    # Garis bantu hanya untuk pengukuran. Pratinjau yang dinilai user TIDAK
    # memakainya, supaya tidak salah dianggap bagian dari desain.
    if PANDUAN:
        d.line([(0, H // 2), (W, H // 2)], fill=(255, 80, 80, 90), width=1)
        d.line([(0, px(inset_top)), (W, px(inset_top))], fill=(255, 255, 255, 40), width=1)
        d.line([(0, px(dev_h - inset_bottom)), (W, px(dev_h - inset_bottom))],
               fill=(255, 255, 255, 40), width=1)

    path = OUT / f"pratinjau-splash-{nama}.png"
    img.convert("RGB").save(path)
    print(f"  splash {nama}: blok konten {tinggi_blok:.0f}dp, "
          f"tengah blok y={tengah_y:.0f}dp (tengah layar {dev_h/2:.0f}dp), "
          f"footer y={y_footer:.0f}dp (dasar {dev_h-inset_bottom:.0f}dp) -> {path.name}")
    return path


# =====================================================================
# 2. TIGA SAMPUL -  cerminan onboarding_screen.dart
# =====================================================================

SLIDES = [
    ("onb_komunitas", "Selamat datang di KUNBAR Connect",
     "Untuk seluruh warga Kuningan Barat — dari anak muda, orang tua, RT/RW, UMKM, "
     "sampai pengurus kelurahan.", PRIMARY),
    ("onb_aspirasi", "Sampaikan tanpa ribet",
     "Kirim aspirasi, laporan masalah, sampai kondisi darurat keamanan. Semua "
     "tercatat dan bisa dilacak statusnya.", SOCIAL),
    ("onb_terhubung", "Terhubung & terbuka",
     "Baca pengumuman RT/RW, lihat agenda, dukung UMKM warga, dan pesan fasilitas "
     "balai tanpa datang langsung.", ACCENT),
]


def raster_svg(nama, tinggi_px):
    cache = OUT / f".cache-{nama}-{tinggi_px}.png"
    if not cache.is_file():
        subprocess.run(
            ["rsvg-convert", "-w", str(int(tinggi_px * 4 / 3)), "-h", str(tinggi_px),
             "-o", str(cache), str(AKAR / "assets/ilustrasi" / f"{nama}.svg")],
            check=True,
        )
    return Image.open(cache).convert("RGBA")


def bungkus_teks(d, teks, f, lebar_maks):
    """Lebar -> beberapa baris (maxWidth di Flutter)."""
    kata, baris, hasil = teks.split(), [], []
    for w in kata:
        coba = " ".join(baris + [w])
        if d.textlength(coba, font=f) <= lebar_maks or not baris:
            baris.append(w)
        else:
            hasil.append(" ".join(baris))
            baris = [w]
    if baris:
        hasil.append(" ".join(baris))
    return hasil


def onboarding(dev_w, dev_h, inset_top, inset_bottom, index, aktif):
    u = min(max(dev_w / 360, 1.0), 1.22)
    W, H = px(dev_w), px(dev_h)
    img = Image.new("RGBA", (W, H), rgba(BG_LIGHT))
    d = ImageDraw.Draw(img)

    nama, judul, isi, tint = SLIDES[index]

    # SafeArea -> tinggi area slide
    tinggi_lewat = 48  # baris "Lewati"
    tinggi_dots_btn = 8 + 22 + 48 + 24
    tinggi_slide = dev_h - inset_top - inset_bottom - tinggi_lewat - tinggi_dots_btn
    y_atas = inset_top + tinggi_lewat

    pad = 28 * u
    lebar_teks = dev_w - pad * 2
    tinggi_ilus = min(max((dev_w - pad * 2) / (4 / 3), 150), 250)

    # Keadaan SETTLED: semua animasi sudah selesai
    v_ilustrasi = 1.0
    v_judul = 1.0
    v_isi = 1.0
    v_glow = 1.0
    angkat = 0.5  # titik tengah gerakan melayang

    f_judul = font(24, bold=True)   # headlineMedium ~24sp
    f_isi = font(15.5)               # bodyLarge ~16sp

    baris_judul = bungkus_teks(d, judul, f_judul, lebar_teks * SCALE)
    baris_isi = bungkus_teks(d, isi, f_isi, lebar_teks * SCALE)
    tinggi_judul = len(baris_judul) * 24 * 1.25
    tinggi_isi = len(baris_isi) * 15.5 * 1.5

    # Posisi ilustrasi dikunci (lihat _SlideViewState.build): tinggi slot teks
    # tetap, teks centering di dalamnya. Judul 1 vs 2 baris TIDAK boleh
    # menggeser ilustrasi.
    jarak_teks = 26 * u
    tinggi_slot_teks = tinggi_slide * 0.46
    y = y_atas + max(0.0, min(96.0, tinggi_slide - tinggi_slot_teks - tinggi_ilus - jarak_teks))

    # cahaya lembut dengan warna sampul
    g = px(tinggi_ilus * 1.30)
    kecil = 96
    topeng = Image.new("L", (kecil, kecil), 0)
    td = ImageDraw.Draw(topeng)
    cc = (kecil - 1) / 2
    maks = math.hypot(cc, cc)
    for yy in range(kecil):
        for xx in range(kecil):
            dist = math.hypot(xx - cc, yy - cc) / maks
            t = max(0.0, min(1.0, 1.0 - dist))
            td.point((xx, yy), int(0.16 * (t ** 1.5) * 255 * v_glow))
    topeng = topeng.resize((g, g), Image.Resampling.BILINEAR)
    halo = Image.new("RGBA", (g, g), tint + (0,))
    halo.putalpha(topeng)
    img.alpha_composite(halo, (int((W - g) / 2), int(px(y + tinggi_ilus / 2) - g / 2)))

    ilus = raster_svg(nama, px(tinggi_ilus))
    scale = 1.0 + 0.035 * angkat
    ilus = ilus.resize((int(ilus.width * scale), int(ilus.height * scale)),
                       Image.Resampling.LANCZOS)
    ox = (W - ilus.width) / 2
    oy = px(y) - (ilus.height - px(tinggi_ilus)) / 2 - px(5 * angkat)
    img.alpha_composite(ilus, (int(ox), int(oy)))

    y += tinggi_ilus + jarak_teks
    y += (tinggi_slot_teks - (tinggi_judul + 12 * u + tinggi_isi)) / 2

    for baris in baris_judul:
        d.text((W / 2, px(y)), baris, font=f_judul, fill=rgba(TEXT_PRI_LIGHT),
               anchor="ma")
        y += 24 * 1.25
    y += 12 * u
    for baris in baris_isi:
        d.text((W / 2, px(y)), baris, font=f_isi, fill=rgba(TEXT_SEC_LIGHT),
               anchor="ma")
        y += 15.5 * 1.5

    # "Lewati" di kanan atas
    d.text((dev_w - 16, inset_top + 24), "Lewati", font=font(14),
           fill=rgba(TEXT_SEC_LIGHT), anchor="rm")

    # titik halaman + tombol
    y_dots = dev_h - inset_bottom - tinggi_dots_btn + 12
    lebar_dots = (24 if aktif else 8) + 2 * (8 + 6) + (8 if not aktif else 0)
    x = (W - px(24 + 6 + 8 + 6 + 8)) / 2
    for i in range(3):
        w = 24 if i == index else 8
        d.rounded_rectangle([x, px(y_dots), x + px(w), px(y_dots + 8)],
                            radius=px(4),
                            fill=rgba(PRIMARY) if i == index else rgba(LINE_LIGHT))
        x += px(w + 6)
    y_btn = y_dots + 22
    d.rounded_rectangle([px(24), px(y_btn), W - px(24), px(y_btn + 48)],
                        radius=px(14), fill=rgba(PRIMARY))
    label = "Masuk KUNBAR Connect" if index == 2 else "Lanjut"
    d.text((W / 2, px(y_btn + 24)), label, font=font(15.5, bold=True),
           fill=(255, 255, 255, 255), anchor="mm")

    path = OUT / f"pratinjau-sampul-{index + 1}.png"
    img.convert("RGB").save(path)
    print(f"  sampul {index + 1} ({nama}): tinggi ilustrasi {tinggi_ilus:.0f}dp -> {path.name}")
    return path


def band(paths, nama, lebar=3):
    """Gabung beberapa PNG jadi satu baris perbandingan."""
    imgs = [Image.open(p) for p in paths]
    skala = min(1.0, lebar * 520 / max(i.width for i in imgs))
    imgs = [i.resize((int(i.width * skala), int(i.height * skala)),
                     Image.Resampling.LANCZOS) for i in imgs]
    pad = 24
    W = sum(i.width for i in imgs) + pad * (len(imgs) + 1)
    H = max(i.height for i in imgs) + pad * 2
    kanvas = Image.new("RGB", (W, H), (24, 26, 28))
    x = pad
    for i in imgs:
        kanvas.paste(i, (x, pad))
        x += i.width + pad
    p = OUT / nama
    kanvas.save(p)
    print(f"  band -> {p.name}")
    return p


if __name__ == "__main__":
    print("Membuat pratinjau...")
    a = splash(360, 800, 28, 24, "kecil")
    b = splash(412, 915, 30, 26, "besar")
    band([a, b], "pratinjau-splash-band.png", lebar=2)
    s = [onboarding(360, 800, 28, 24, i, i == 0) for i in range(3)]
    band(s, "pratinjau-sampul-band.png", lebar=3)
    print("Selesai.")
