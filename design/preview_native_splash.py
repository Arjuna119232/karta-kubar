#!/usr/bin/env python3
"""Pratinjau splash NATIVE (Android 12+ & iOS) dari aset asli di assets/brand.

Angka dp di sini disalin dari Aturan Android:
  - ikon di kotak 288dp, di-mask circle 192dp (jari 96dp)
  - branding image 200x80dp, menempel di paling bawah
  - iOS UILaunchScreen: gambar 260pt, selalu di pusat

Jalankan: python3 design/preview_native_splash.py
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
BRAND = ROOT / "assets" / "brand"
OUT = ROOT / "design"

HIJAU = (27, 94, 32, 255)          # AppColors.primary #1B5E20
PUTIH = (255, 255, 255, 255)
PUTIH_LUNAR = (235, 235, 235, 255)  # ikon putih di layar gelap

ANDROID_D = (360, 800)
ANDROID_S = 3
IOS_D = (414, 896)
IOS_S = 3


def font(px: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    # Font yang sama dengan generator splash (Roboto Flex + variation Bold).
    f = ImageFont.truetype("/system/fonts/RobotoFlex-Regular.ttf", px)
    if hasattr(f, "set_variation_by_name"):
        try:
            f.set_variation_by_name("Bold" if bold else "Regular")
        except Exception:
            pass
    return f


def circle_mask(px: int) -> Image.Image:
    """Mask yang sama dengan Android 12: kotak 288dp -> circle 192dp."""
    m = Image.new("L", (px, px), 0)
    ImageDraw.Draw(m).ellipse((0, 0, px - 1, px - 1), fill=255)
    return m


def status_bar(d: ImageDraw.ImageDraw, w: int, s: int) -> None:
    """Bilah status Android 12: transparan, hanya ikon + jam."""
    jam = font(int(12 * s), True)
    d.text((int(14 * s), int(7 * s)), "12:30", font=jam, fill=PUTIH)
    for i in range(3):
        x = w - int((16 + i * 5) * s)
        d.rounded_rectangle((x, int(9 * s), x + int(3 * s), int(14 * s)),
                            radius=int(1 * s), fill=PUTIH)


def pratinjau_android() -> Image.Image:
    w, h = ANDROID_D[0] * ANDROID_S, ANDROID_D[1] * ANDROID_S
    im = Image.new("RGBA", (w, h), HIJAU)
    d = ImageDraw.Draw(im)
    status_bar(d, w, ANDROID_S)

    # ikon 288dp dipusatkan (anchor tengah layar)
    src = Image.open(BRAND / "splash_icon.png").convert("RGBA")
    kotak = 288 * ANDROID_S
    ikon = src.resize((kotak, kotak), Image.LANCZOS)
    ikon.putalpha(Image.composite(ikon.getchannel("A"),
                                  Image.new("L", ikon.size, 0),
                                  circle_mask(kotak)))
    im.alpha_composite(ikon, ((w - kotak) // 2, (h - kotak) // 2))

    # branding 200x80dp di paling bawah
    br = Image.open(BRAND / "splash_branding_xxxhdpi.png").convert("RGBA")
    br = br.resize((200 * ANDROID_S, 80 * ANDROID_S), Image.LANCZOS)
    im.alpha_composite(br, ((w - br.width) // 2, h - br.height - int(18 * ANDROID_S)))
    return im


def pratinjau_ios() -> Image.Image:
    w, h = IOS_D[0] * IOS_S, IOS_D[1] * IOS_S
    im = Image.new("RGBA", (w, h), HIJAU)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((int(10 * IOS_S), int(14 * IOS_S), w - int(10 * IOS_S),
                          int(34 * IOS_S)), radius=int(10 * IOS_S),
                         outline=PUTIH, width=int(2 * IOS_S))
    jam = font(int(12 * IOS_S), True)
    d.text((int(24 * IOS_S), int(18 * IOS_S)), "12:30", font=jam, fill=PUTIH)

    src = Image.open(BRAND / "splash_icon_ios@3x.png").convert("RGBA")
    px = 260 * IOS_S
    im.alpha_composite(src.resize((px, px), Image.LANCZOS),
                       ((w - px) // 2, (h - px) // 2))
    return im


def main() -> None:
    a = pratinjau_android().resize((ANDROID_D[0], ANDROID_D[1]), Image.LANCZOS)
    i = pratinjau_ios().resize((IOS_D[0], IOS_D[1]), Image.LANCZOS)

    pad = 16
    band = Image.new("RGB", (a.width + i.width + pad * 3, a.height + pad * 2), (24, 24, 27))
    band.paste(a.convert("RGB"), (pad, pad))
    band.paste(i.convert("RGB"), (pad * 2 + a.width, pad))
    band.save(OUT / "pratinjau-splash-native.png")

    a.save(OUT / "pratinjau-splash-native-android.png")
    print("-> design/pratinjau-splash-native.png (Android | iOS)")
    print("-> design/pratinjau-splash-native-android.png")


if __name__ == "__main__":
    main()