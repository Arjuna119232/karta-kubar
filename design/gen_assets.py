#!/usr/bin/env python3
"""Generator aset visual KUNBAR Connect (tanpa dependensi luar).

Menulis:
  assets/icons/<nama>.svg     ikon duotone 24x24 (garis + isian lembut)
  assets/icons/<nama>_a.svg   versi "aktif" (isian lebih pekat) untuk tab terpilih
  assets/ilustrasi/<nama>.svg ilustrasi berwarna (onboarding, state, cover)

Ikon digambar hitam; di aplikasi diwarnai lewat ColorFilter(srcIn) sehingga
transparansi isian duotone tetap terjaga. Jalankan dari akar repo:
    python3 design/gen_assets.py
"""
from __future__ import annotations

import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
ICON_DIR = ROOT / "assets" / "icons"
ART_DIR = ROOT / "assets" / "ilustrasi"
ICON_DIR.mkdir(parents=True, exist_ok=True)
ART_DIR.mkdir(parents=True, exist_ok=True)


# ------------------------------------------------------------------ ikon
def P(d):
    return f'<path d="{d}"/>'


def C(cx, cy, r):
    return f'<circle cx="{cx}" cy="{cy}" r="{r}"/>'


def R(x, y, w, h, rx=0):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}"/>'


# F = isian lembut + garis, S = garis saja, D = padat (titik/detail kecil)
ICONS: dict[str, list[tuple[str, str]]] = {
    "home": [("F", P("M4 11.2 12 4l8 7.2V19a1.5 1.5 0 0 1-1.5 1.5h-13A1.5 1.5 0 0 1 4 19z")),
             ("S", P("M9.5 20.5v-5a1 1 0 0 1 1-1h3a1 1 0 0 1 1 1v5"))],
    "calendar": [("F", R(4, 5.5, 16, 14.5, 3)), ("S", P("M4 10h16M8.5 3.5V7M15.5 3.5V7"))],
    "calendarCheck": [("F", R(4, 5.5, 16, 14.5, 3)), ("S", P("M4 10h16M8.5 3.5V7M15.5 3.5V7M9 15l2 2 4-4"))],
    "calendarX": [("F", R(4, 5.5, 16, 14.5, 3)), ("S", P("M4 10h16M8.5 3.5V7M15.5 3.5V7M10 14l4 4m0-4-4 4"))],
    "qrScan": [("S", P("M4 8V6a2 2 0 0 1 2-2h2M16 4h2a2 2 0 0 1 2 2v2M20 16v2a2 2 0 0 1-2 2h-2M8 20H6a2 2 0 0 1-2-2v-2")),
               ("F", R(8, 8, 3, 3, .8)), ("F", R(13, 8, 3, 3, .8)), ("F", R(8, 13, 3, 3, .8)),
               ("S", P("M14 14h2v2"))],
    "qrCode": [("F", R(4, 4, 6.5, 6.5, 1.4)), ("F", R(13.5, 4, 6.5, 6.5, 1.4)), ("F", R(4, 13.5, 6.5, 6.5, 1.4)),
               ("S", P("M14 14h2.5v2.5M20 14v.01M14 20h.01M17 20h3v-3"))],
    "wallet": [("F", R(3.5, 7, 17, 12.5, 3)), ("S", P("M17 7V6a1.8 1.8 0 0 0-2.3-1.7L7 6.6")), ("D", C(16.5, 13.2, 1.1))],
    "gallery": [("F", R(3.5, 4.5, 17, 15, 3)), ("D", C(9, 9.5, 1.5)),
                ("S", P("m4 17 4.5-4.2a1.8 1.8 0 0 1 2.5 0l1.5 1.4 2.3-2.4a1.8 1.8 0 0 1 2.6 0L20 14.5"))],
    "camera": [("F", P("M4 9a2.5 2.5 0 0 1 2.5-2.5h1.2L9 4.5h6l1.3 2h1.2A2.5 2.5 0 0 1 20 9v8a2.5 2.5 0 0 1-2.5 2.5h-11A2.5 2.5 0 0 1 4 17z")),
               ("S", C(12, 12.8, 3.2))],
    "addPhoto": [("F", P("M4 9a2.5 2.5 0 0 1 2.5-2.5h1.2L9 4.5h6l1.3 2h1.2A2.5 2.5 0 0 1 20 9v8a2.5 2.5 0 0 1-2.5 2.5h-11A2.5 2.5 0 0 1 4 17z")),
                 ("S", P("M12 10.8v4M10 12.8h4"))],
    "person": [("F", C(12, 8, 3.8)), ("F", P("M5 20.5v-.7a5.3 5.3 0 0 1 5.3-5.3h3.4a5.3 5.3 0 0 1 5.3 5.3v.7z"))],
    "badge": [("F", R(3.5, 5.5, 17, 13, 3)), ("F", C(9, 11, 2)),
              ("S", P("M6.5 16c.4-1.6 1.4-2.4 2.5-2.4s2.1.8 2.5 2.4M14 10h3.5M14 13.5h3.5"))],
    "groups": [("F", C(8.5, 8.5, 3)), ("F", C(16.5, 9.5, 2.4)), ("F", P("M2.8 19.5c.4-3 2.7-4.8 5.7-4.8s5.3 1.8 5.7 4.8z")),
               ("S", P("M15.3 14.8c2.7-.3 4.8 1.3 5.2 4.2h-3.8"))],
    "shieldCheck": [("F", P("M12 3.5 19 6v5.6c0 4.2-2.8 7.2-7 8.9-4.2-1.7-7-4.7-7-8.9V6z")), ("S", P("m8.8 12 2.3 2.3 4.2-4.6"))],
    "adminShield": [("F", P("M12 3.5 19 6v5.6c0 4.2-2.8 7.2-7 8.9-4.2-1.7-7-4.7-7-8.9V6z")), ("D", C(12, 10.2, 1.8)),
                    ("S", P("M8.9 16c.6-1.4 1.7-2 3.1-2s2.5.6 3.1 2"))],
    "personCheck": [("F", C(9.5, 8, 3.5)), ("F", P("M3.5 20v-.4a5.1 5.1 0 0 1 5.1-5.1h1.8a5.1 5.1 0 0 1 3 1z")),
                    ("S", P("m15.5 16.5 2 2 3.5-3.8"))],
    "place": [("F", P("M12 21s6.5-5.6 6.5-11a6.5 6.5 0 0 0-13 0c0 5.4 6.5 11 6.5 11z")), ("D", C(12, 10, 2.2))],
    "bell": [("F", P("M6 16.5V11a6 6 0 0 1 12 0v5.5l1.5 2h-15z")), ("S", P("M10 20.7a2.2 2.2 0 0 0 4 0"))],
    "search": [("S", C(10.8, 10.8, 6)), ("S", P("m15.4 15.4 4.6 4.6"))],
    "close": [("S", P("M6 6l12 12M18 6 6 18"))],
    "chevronRight": [("S", P("m9.5 5.5 6.5 6.5-6.5 6.5"))],
    "arrowForward": [("S", P("M5 12h14M13.5 6.5 19 12l-5.5 5.5"))],
    "arrowBack": [("S", P("M19 12H5M10.5 6.5 5 12l5.5 5.5"))],
    "northEast": [("S", P("M7 17 17 7M9 7h8v8"))],
    "southWest": [("S", P("M17 7 7 17M15 17H7V9"))],
    "trendingUp": [("S", P("m3.5 16.5 6-6 4 4 7-7M15 7.5h5.5V13"))],
    "check": [("S", P("m5 12.5 4.5 4.5L19 7.5"))],
    "checkCircle": [("F", C(12, 12, 8.5)), ("S", P("m8 12.3 2.8 2.8 5.5-5.6"))],
    "xCircle": [("F", C(12, 12, 8.5)), ("S", P("m9 9 6 6m0-6-6 6"))],
    "clock": [("F", C(12, 12, 8.5)), ("S", P("M12 7.5V12l3 2"))],
    "history": [("S", P("M4 12a8 8 0 1 0 2.5-5.8L4 8.5M4 4v4.5h4.5M12 8v4.2l2.8 1.6"))],
    "megaphone": [("F", P("M4 10v4a1 1 0 0 0 1 1h2.5L14 19V5L7.5 9H5a1 1 0 0 0-1 1z")),
                  ("S", P("M17 9.5a3.5 3.5 0 0 1 0 5M19.5 7a7 7 0 0 1 0 10"))],
    "handHeart": [("F", P("M12 11.5s-3.8-2.2-3.8-4.8a2.1 2.1 0 0 1 3.8-1.2 2.1 2.1 0 0 1 3.8 1.2c0 2.6-3.8 4.8-3.8 4.8z")),
                  ("S", P("M3.5 14h3l3 1.5h4a1.3 1.3 0 0 1 0 2.6H10M13.5 17.8 18.6 15a1.6 1.6 0 0 1 1.8 2.6L16 20.5l-5 .8-4-1.6H3.5"))],
    "handshake": [("F", P("M2.5 9.5 6.5 7l3.5 1.2L14 7l4 .8 3.5 1.7v5.5l-3 3-3-1-2 1.5-3-2.2-3 .6-3.5-2.5z")),
                  ("S", P("m10 8.2 3.5 2.8M9 12.2l2.5 2"))],
    "chat": [("F", P("M4 6.5A2.5 2.5 0 0 1 6.5 4h11A2.5 2.5 0 0 1 20 6.5v7a2.5 2.5 0 0 1-2.5 2.5H11l-4 3.5V16h-.5A2.5 2.5 0 0 1 4 13.5z")),
             ("D", C(9, 10, .9)), ("D", C(12, 10, .9)), ("D", C(15, 10, .9))],
    "phone": [("F", R(7, 3, 10, 18, 2.6)), ("S", P("M10.5 18h3"))],
    "mail": [("F", R(3.5, 5.5, 17, 13, 3)), ("S", P("m4.5 8 7.5 5.5L19.5 8"))],
    "lock": [("F", R(5, 10.5, 14, 10, 3)), ("S", P("M8 10.5V8a4 4 0 0 1 8 0v2.5")), ("D", C(12, 15.5, 1.3))],
    "logout": [("S", P("M10 4H7a2.5 2.5 0 0 0-2.5 2.5v11A2.5 2.5 0 0 0 7 20h3M15 8l4 4-4 4M19 12H9.5"))],
    "login": [("S", P("M14 4h3a2.5 2.5 0 0 1 2.5 2.5v11A2.5 2.5 0 0 1 17 20h-3M9.5 8l4 4-4 4M13.5 12H4.5"))],
    "sun": [("F", C(12, 12, 4)), ("S", P("M12 3v2M12 19v2M3 12h2M19 12h2M5.6 5.6 7 7M17 17l1.4 1.4M18.4 5.6 17 7M7 17l-1.4 1.4"))],
    "moon": [("F", P("M20 14.2A8 8 0 0 1 9.8 4a8 8 0 1 0 10.2 10.2z"))],
    "autoMode": [("F", C(12, 12, 8.5)), ("S", P("M12 3.5v17")), ("D", P("M12 3.5a8.5 8.5 0 0 0 0 17z"))],
    "edit": [("F", P("M4 20h4l11-11a2.1 2.1 0 0 0-3-3L5 17z")), ("S", P("m14 7 3 3"))],
    "help": [("F", C(12, 12, 8.5)), ("S", P("M9.6 9.6a2.5 2.5 0 1 1 3.6 2.2c-.8.4-1.2 1-1.2 1.9")), ("D", C(12, 16.8, .9))],
    "code": [("S", P("m8.5 8-4 4 4 4M15.5 8l4 4-4 4M13.5 5.5l-3 13"))],
    "download": [("S", P("M12 4v11M7.5 10.5 12 15l4.5-4.5M5 19.5h14"))],
    "refresh": [("S", P("M19.5 12a7.5 7.5 0 1 1-2.3-5.4M19.5 4v4.5H15"))],
    "cloudOff": [("F", P("M7 18a4.5 4.5 0 0 1-.6-8.9 6 6 0 0 1 11.1 1.6A3.7 3.7 0 0 1 17 18z")), ("S", P("m4 4 16 16"))],
    "broom": [("S", P("M19 4.5 11.5 12")), ("F", P("m11.5 12 2.4 2.4-3.4 5.1H4.5l2.3-4z"))],
    "ball": [("F", C(12, 12, 8.5)),
             ("S", P("M12 8.2l3.4 2.4-1.3 4h-4.2l-1.3-4zM12 3.5v4.7M20.2 9.5l-4.8 1.1M17 19.2l-2.9-4.6M7 19.2l2.9-4.6M3.8 9.5l4.8 1.1"))],
    "mosque": [("F", P("M6 20v-5.5a6 6 0 0 1 12 0V20z")), ("D", C(12, 5.2, 1)),
               ("S", P("M3 20h18M12 8.5V6.5M10.2 20v-2.6a1.8 1.8 0 0 1 3.6 0V20M3.8 20V11M20.2 20V11"))],
    "drop": [("F", P("M12 3.5s6 6.2 6 10.7A6 6 0 0 1 6 14.2C6 9.7 12 3.5 12 3.5z")), ("S", P("M9.5 14.5a2.7 2.7 0 0 0 2.5 2.4"))],
    "party": [("F", P("m3.5 20.5 4.2-11.6a1 1 0 0 1 1.6-.4l5.6 5.6a1 1 0 0 1-.4 1.6z")),
              ("S", P("M14.5 9.5c1-1.5 1-3 0-4.2M17 12c2-.5 3.4-.2 4.5.5M18.5 6.5v.01M20 9v.01"))],
    "trophy": [("F", P("M7.5 4.5h9v5a4.5 4.5 0 0 1-9 0z")),
               ("S", P("M7.5 6.5H4.5V8a3 3 0 0 0 3 3M16.5 6.5h3V8a3 3 0 0 1-3 3M12 14v3.5M8.5 20h7M10 17.5h4"))],
    "accessibility": [("D", C(12, 4.8, 1.6)), ("S", P("M5 8.5l7 1.5 7-1.5M12 10v4.5M12 14.5l-3 5.5M12 14.5l3 5.5"))],
    "dot": [("D", C(12, 12, 4))],
    "newspaper": [("F", R(4, 4.5, 16, 15, 3)), ("S", P("M8 9h8M8 12.5h8M8 16h5"))],
    # --- ikon order (jastip & ojek), ditambah 16 Okt 2026 ---
    "cart": [("F", P("M3 4.5h2.2l1.6 8.6a1.4 1.4 0 0 0 1.4 1.1h7.3a1.4 1.4 0 0 0 1.4-1.1L18.6 8H6.1")),
             ("D", C(9.4, 18.6, 1.5)), ("D", C(16.6, 18.6, 1.5)),
             ("F", P("M9.6 14.2 10.8 11h5.9l-1 3.2z"))],
    "package": [("F", P("M12 3.2 20 7v10l-8 3.8L4 17V7z")),
                ("S", P("M4 7l8 3.8L20 7M12 10.8v10")),
                ("S", P("M8.2 5 16.4 9v3.6"))],
    "motorcycle": [("D", C(6, 17.4, 3.3)), ("D", C(18, 17.4, 3.3)),
                   ("S", P("M9.3 17.4h5.4")),
                   ("S", P("M6 14.1 9.6 9.4h3.2M9.6 9.4h4.3l3.2 5")),
                   ("S", P("M12.8 9.4h-2.4M17.6 11.6h2.6")),
                   ("S", P("M8.4 8.2h2.8"))],
    "route": [("D", C(6, 6.2, 2.2)), ("D", C(18, 17.8, 2.2)),
              ("S", P("M7.9 8 7.4 12a3.4 3.4 0 0 0 3.4 3.4h4.5")),
              ("S", P("M8.6 6.2h5.2a3 3 0 0 1 3 3v2.1")),
              ("F", R(3.4, 17, 5.2, 4.4, 1.2))],
    "star": [("F", P("M12 3.6l2.6 5.4 5.9.8-4.3 4.1 1.1 5.9L12 17l-5.3 2.8 1.1-5.9L3.5 9.8l5.9-.8z")),
             ("S", P("M12 7.6v9.9"))],
    "pinMitra": [("F", P("M12 21.2c4.1-4.3 6.2-7.6 6.2-10.4a6.2 6.2 0 1 0-12.4 0c0 2.8 2.1 6.1 6.2 10.4z")),
                ("D", C(12, 10.6, 2.3)),
                ("S", P("M9.6 4.4 12 2.2l2.4 2.2"))],
    "shop": [("F", P("M4 8.6 5.5 4.5h13L20 8.6v10.9H4z")),
             ("F", P("M4 8.6h16v1.9H4z")),
             ("S", P("M9.5 10.5V19M14.5 10.5V19")),
             ("S", P("M3.2 8.6 5.5 4.5h13l2.3 4.1"))],
    "basket": [("F", P("M3.4 9.5h17.2l-1.9 10a1.6 1.6 0 0 1-1.6 1.4H6.9a1.6 1.6 0 0 1-1.6-1.4z")),
               ("S", P("M8.4 9.5 10 3.4M15.6 9.5 14 3.4M9.8 13.2v4M14.2 13.2v4"))],
    "flame": [("F", P("M12 2.8c3.4 3.4 5.4 6 5.4 9.4a5.4 5.4 0 1 1-10.8 0c0-1.7.7-3.1 1.9-4.4.4 1.1 1 1.8 1.8 2.1-.3-2.7.2-5 1.7-7.1z")),
              ("F", P("M12 13.4c1.2 1.1 1.9 2 1.9 3.1a1.9 1.9 0 1 1-3.8 0c0-1.1.7-2 1.9-3.1z")),
              ("F", P("M12 13.4c1.2 1.1 1.9 2 1.9 3.1a1.9 1.9 0 1 1-3.8 0c0-1.1.7-2 1.9-3.1z"))],
    "plus": [("S", P("M12 5v14M5 12h14"))],
    "minus": [("S", P("M5 12h14"))],
    "cash": [("F", R(3, 6.5, 18, 11, 2)),
             ("D", C(12, 12, 2.4)),
             ("S", P("M6.4 9.6v4.8M17.6 9.6v4.8"))],
    # --- ikon mitra usaha OSM (tokoRoti / apotek / spbu), 28 Okt 2026 ---
    "bread": [("F", P("M5 15.6c0-4.5 3.1-7.6 7-7.6s7 3.1 7 7.6c0 1.2-.3 2.2-.8 2.9H5.8c-.5-.7-.8-1.7-.8-2.9z")),
              ("S", P("m9.3 11.2-.7 2.3M12.9 10.5l-.7 2.3M16.1 11.7l-.6 2"))],
    "pill": [("F", P("M13.2 3.9 20.1 10.8a4.8 4.8 0 0 1-6.8 6.8L6.4 10.7A4.8 4.8 0 0 1 13.2 3.9z")),
             ("S", P("m10 7.2 6.8 6.8"))],
    "pump": [("F", R(5.2, 6.5, 8.6, 13, 2)),
             ("S", P("M7.7 9.6h3.6v3H7.7z")),
             ("S", P("M13.8 11.5h2.3a1.7 1.7 0 0 1 1.7 1.7v4.2a1.4 1.4 0 0 1-2.8 0v-1.6")),
             ("S", P("M16.3 9.5V8l-2-2"))],
}


def icon_svg(elems, fill_op, stroke_w):
    f = "".join(e for k, e in elems if k == "F")
    s = "".join(e for k, e in elems if k in ("F", "S"))
    d = "".join(e for k, e in elems if k == "D")
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">'
        f'<g fill="#000" fill-opacity="{fill_op}" stroke="none">{f}</g>'
        f'<g fill="none" stroke="#000" stroke-width="{stroke_w}" stroke-linecap="round" stroke-linejoin="round">{s}</g>'
        f'<g fill="#000" stroke="none">{d}</g>'
        "</svg>\n"
    )


for name, elems in ICONS.items():
    (ICON_DIR / f"{name}.svg").write_text(icon_svg(elems, 0.14, 1.8))
    (ICON_DIR / f"{name}_a.svg").write_text(icon_svg(elems, 0.42, 2.0))


# ------------------------------------------------------------------ ilustrasi
GREEN, GREEN2, LGREEN, MINT = "#1B5E20", "#2E7D32", "#A5D6A7", "#E8F5E9"
YELLOW, BLUE, PINK = "#FFC107", "#0D47A1", "#E91E63"
INK, WHITE, SKIN, HAIR = "#263238", "#FFFFFF", "#F2C9A0", "#3B2A20"


def svg(w, h, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" '
            f'width="{w}" height="{h}">{body}</svg>\n')


def person(x, base, s, shirt, pants="#37474F", skin=SKIN, hair=HAIR):
    """Orang berdiri sederhana; (x, base) = tengah kaki."""
    hr = 10 * s
    hy = base - 74 * s
    return (
        f'<rect x="{x - 9 * s:.1f}" y="{base - 30 * s:.1f}" width="{7.5 * s:.1f}" height="{30 * s:.1f}" rx="{3 * s:.1f}" fill="{pants}"/>'
        f'<rect x="{x + 1.5 * s:.1f}" y="{base - 30 * s:.1f}" width="{7.5 * s:.1f}" height="{30 * s:.1f}" rx="{3 * s:.1f}" fill="{pants}"/>'
        f'<rect x="{x - 14 * s:.1f}" y="{hy + 10 * s:.1f}" width="{28 * s:.1f}" height="{38 * s:.1f}" rx="{11 * s:.1f}" fill="{shirt}"/>'
        f'<circle cx="{x}" cy="{hy}" r="{hr:.1f}" fill="{skin}"/>'
        f'<path d="M{x - hr:.1f} {hy:.1f}a{hr:.1f} {hr:.1f} 0 0 1 {2 * hr:.1f} 0z" fill="{hair}"/>'
    )


def house(x, y, w, h, wall, roof):
    return (
        f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="4" fill="{wall}"/>'
        f'<path d="M{x - 6} {y + 2}L{x + w / 2} {y - h * .45}L{x + w + 6} {y + 2}z" fill="{roof}"/>'
        f'<rect x="{x + w / 2 - 7}" y="{y + h - 24}" width="14" height="24" rx="3" fill="{WHITE}" fill-opacity=".85"/>'
        f'<rect x="{x + 8}" y="{y + 12}" width="11" height="11" rx="2" fill="{WHITE}" fill-opacity=".7"/>'
        f'<rect x="{x + w - 19}" y="{y + 12}" width="11" height="11" rx="2" fill="{WHITE}" fill-opacity=".7"/>'
    )


def tree(x, base, s=1.0, c=GREEN2):
    return (f'<rect x="{x - 3 * s}" y="{base - 26 * s}" width="{6 * s}" height="{26 * s}" rx="2" fill="#6D4C41"/>'
            f'<circle cx="{x}" cy="{base - 38 * s}" r="{19 * s}" fill="{c}"/>'
            f'<circle cx="{x - 11 * s}" cy="{base - 28 * s}" r="{12 * s}" fill="{c}"/>'
            f'<circle cx="{x + 11 * s}" cy="{base - 28 * s}" r="{12 * s}" fill="{c}"/>')


def heart(x, y, s, c=PINK):
    return (f'<path transform="translate({x} {y}) scale({s})" fill="{c}" '
            'd="M0 8C-10 0-8-9 0-6 8-9 10 0 0 8z"/>')


def sparkle(x, y, r, c=YELLOW):
    return (f'<path d="M{x} {y - r}L{x + r * .3} {y - r * .3}L{x + r} {y}L{x + r * .3} {y + r * .3}'
            f'L{x} {y + r}L{x - r * .3} {y + r * .3}L{x - r} {y}L{x - r * .3} {y - r * .3}z" fill="{c}"/>')


ART: dict[str, str] = {}

# ---- onboarding 1: komunitas
ART["onb_komunitas"] = svg(320, 240,
    f'<circle cx="160" cy="128" r="108" fill="{MINT}"/>'
    f'<circle cx="258" cy="52" r="19" fill="{YELLOW}"/><circle cx="258" cy="52" r="27" fill="{YELLOW}" fill-opacity=".25"/>'
    f'<ellipse cx="160" cy="208" rx="136" ry="14" fill="{LGREEN}"/>'
    + house(48, 112, 62, 84, "#C8E6C9", GREEN)
    + house(124, 96, 72, 100, "#A5D6A7", BLUE)
    + house(212, 118, 58, 78, "#DCEDC8", GREEN2)
    + tree(28, 206, .8) + tree(298, 206, .75, GREEN)
    + person(104, 210, .95, PINK) + person(142, 210, 1.05, YELLOW, hair="#212121")
    + person(180, 210, 1.0, BLUE, skin="#E0AC82") + person(220, 210, .92, GREEN, hair="#5D4037")
    + heart(160, 70, 1.4) + sparkle(82, 78, 8) + sparkle(236, 92, 6, PINK))

# ---- onboarding 2: aspirasi
ART["onb_aspirasi"] = svg(320, 240,
    '<circle cx="160" cy="128" r="108" fill="#FCE4EC"/>'
    f'<rect x="108" y="40" width="104" height="168" rx="20" fill="{INK}"/>'
    f'<rect x="115" y="52" width="90" height="144" rx="13" fill="{WHITE}"/>'
    f'<rect x="141" y="45" width="38" height="5" rx="2.5" fill="#455A64"/>'
    f'<rect x="124" y="66" width="62" height="24" rx="9" fill="{PINK}"/>'
    f'<rect x="134" y="98" width="62" height="24" rx="9" fill="{LGREEN}"/>'
    f'<rect x="124" y="130" width="52" height="22" rx="9" fill="#FFE082"/>'
    f'<rect x="132" y="72" width="40" height="5" rx="2.5" fill="{WHITE}"/><rect x="132" y="80" width="26" height="5" rx="2.5" fill="{WHITE}" fill-opacity=".7"/>'
    f'<rect x="142" y="104" width="40" height="5" rx="2.5" fill="{GREEN}"/><rect x="142" y="112" width="24" height="5" rx="2.5" fill="{GREEN}" fill-opacity=".6"/>'
    f'<circle cx="160" cy="176" r="13" fill="{GREEN2}"/><path d="m153 176 5 5 9-10" stroke="{WHITE}" stroke-width="3.5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
    f'<path d="M34 128l50-22v70l-50-22z" fill="{PINK}"/><rect x="22" y="120" width="18" height="16" rx="4" fill="#AD1457"/>'
    f'<path d="M44 160l10 30h12l-8-28z" fill="#AD1457"/>'
    f'<path d="M92 120a18 18 0 0 1 0 22M102 112a30 30 0 0 1 0 38" stroke="{PINK}" stroke-width="5" fill="none" stroke-linecap="round"/>'
    f'<path d="M246 72l44-16-16 44-10-14z" fill="{YELLOW}"/><path d="M264 86l-8 20 10-14z" fill="#FFA000"/>'
    + heart(240, 150, 1.2) + sparkle(282, 150, 8, PINK) + sparkle(66, 70, 7))

# ---- onboarding 3: terhubung
ART["onb_terhubung"] = svg(320, 240,
    '<circle cx="160" cy="128" r="108" fill="#E3F2FD"/>'
    f'<ellipse cx="160" cy="210" rx="130" ry="12" fill="#BBDEFB"/>'
    f'<rect x="112" y="58" width="96" height="104" rx="14" fill="{WHITE}"/>'
    f'<path d="M112 72a14 14 0 0 1 14-14h68a14 14 0 0 1 14 14v18H112z" fill="{BLUE}"/>'
    f'<rect x="132" y="48" width="8" height="18" rx="4" fill="{INK}"/><rect x="180" y="48" width="8" height="18" rx="4" fill="{INK}"/>'
    + "".join(f'<rect x="{126 + c * 22}" y="{102 + r * 20}" width="14" height="12" rx="3" fill="{col}"/>'
              for r in range(2) for c, col in enumerate([LGREEN, "#FFE082", "#F8BBD0", LGREEN] if r == 0 else ["#BBDEFB", LGREEN, "#FFE082", "#F8BBD0"]))
    + f'<rect x="20" y="118" width="66" height="70" rx="6" fill="#FFF3E0"/>'
    f'<path d="M14 118h78l-8-26H22z" fill="{YELLOW}"/><path d="M30 118l4-26M46 118l2-26M62 118l-2-26M78 118l-6-26" stroke="{WHITE}" stroke-width="5"/>'
    f'<rect x="34" y="136" width="20" height="52" rx="3" fill="#8D6E63"/><rect x="60" y="136" width="18" height="18" rx="3" fill="#BBDEFB"/>'
    f'<path d="M262 96c-14 0-24 10-24 24 0 18 24 42 24 42s24-24 24-42c0-14-10-24-24-24z" fill="{PINK}"/><circle cx="262" cy="120" r="9" fill="{WHITE}"/>'
    f'<path d="M92 150C104 168 116 176 130 176M212 160c14 8 20 4 28-12" stroke="{BLUE}" stroke-width="3" fill="none" stroke-dasharray="2 8" stroke-linecap="round"/>'
    + person(190, 210, .85, GREEN) + person(224, 210, .8, PINK, skin="#E0AC82")
    + heart(150, 192, 1.3) + sparkle(290, 60, 8) + sparkle(56, 66, 6, BLUE))

# ---- state kosong
ART["empty_kegiatan"] = svg(320, 240,
    f'<circle cx="160" cy="124" r="100" fill="{MINT}"/>'
    f'<ellipse cx="160" cy="206" rx="104" ry="11" fill="{LGREEN}"/>'
    f'<rect x="92" y="52" width="136" height="136" rx="18" fill="{WHITE}"/>'
    f'<path d="M92 70a18 18 0 0 1 18-18h100a18 18 0 0 1 18 18v22H92z" fill="{GREEN}"/>'
    f'<rect x="120" y="40" width="9" height="22" rx="4.5" fill="{INK}"/><rect x="191" y="40" width="9" height="22" rx="4.5" fill="{INK}"/>'
    + "".join(f'<rect x="{108 + c * 30}" y="{106 + r * 28}" width="20" height="16" rx="4" fill="{GREEN}" fill-opacity=".1"/>'
              for r in range(3) for c in range(4))
    + f'<circle cx="214" cy="160" r="26" fill="{WHITE}" stroke="{YELLOW}" stroke-width="8"/>'
    f'<path d="m234 180 22 22" stroke="{YELLOW}" stroke-width="10" stroke-linecap="round"/>'
    f'<path d="M206 156h16M214 148v16" stroke="{YELLOW}" stroke-width="0"/>'
    f'<path d="M204 166c4-5 14-5 20 0" stroke="#90A4AE" stroke-width="3.5" fill="none" stroke-linecap="round"/>'
    f'<circle cx="207" cy="154" r="2.6" fill="#90A4AE"/><circle cx="221" cy="154" r="2.6" fill="#90A4AE"/>'
    + sparkle(66, 84, 8) + sparkle(262, 76, 6, PINK))

# ---- state error / offline
ART["error_offline"] = svg(320, 240,
    '<circle cx="160" cy="124" r="100" fill="#ECEFF1"/>'
    '<ellipse cx="160" cy="206" rx="104" ry="11" fill="#CFD8DC"/>'
    '<path d="M100 150a30 30 0 0 1-2-59 46 46 0 0 1 88-12 36 36 0 0 1 36 71z" fill="#B0BEC5"/>'
    '<path d="M110 150a24 24 0 0 1 0-48 40 40 0 0 1 76-8 30 30 0 0 1 28 56z" fill="#CFD8DC"/>'
    f'<path d="M96 176 232 62" stroke="{PINK}" stroke-width="9" stroke-linecap="round"/>'
    f'<rect x="126" y="166" width="14" height="22" rx="4" fill="{INK}"/><rect x="152" y="166" width="14" height="22" rx="4" fill="{INK}"/>'
    f'<path d="M122 188h48v8a12 12 0 0 1-12 12h-24a12 12 0 0 1-12-12z" fill="#455A64"/>'
    f'<path d="M146 208v14" stroke="#455A64" stroke-width="5" stroke-linecap="round"/>'
    + sparkle(70, 70, 7, "#90A4AE") + sparkle(262, 130, 6, "#90A4AE"))


# ---- cover 160x120
def cover(bg1, bg2, body):
    return svg(160, 120,
        f'<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1">'
        f'<stop offset="0" stop-color="{bg1}"/><stop offset="1" stop-color="{bg2}"/></linearGradient></defs>'
        f'<rect width="160" height="120" fill="url(#g)"/>' + body)


ART["cover_sosial"] = cover("#C8E6C9", "#81C784",
    '<circle cx="132" cy="26" r="13" fill="#FFF59D"/>'
    '<ellipse cx="80" cy="108" rx="90" ry="16" fill="#388E3C" fill-opacity=".5"/>'
    + tree(30, 100, .8, GREEN2) + tree(132, 102, .7, GREEN)
    + person(66, 104, .62, PINK) + person(92, 104, .66, YELLOW, hair="#212121")
    + '<path d="M72 54l8 4 8-4" fill="none"/>' + heart(80, 22, 1.2))

ART["cover_olahraga"] = cover("#BBDEFB", "#64B5F6",
    '<rect y="84" width="160" height="36" fill="#43A047"/>'
    '<path d="M0 84h160" stroke="#fff" stroke-width="2"/>'
    '<rect x="96" y="40" width="50" height="44" rx="3" fill="none" stroke="#fff" stroke-width="4"/>'
    '<path d="M104 40v44M114 40v44M124 40v44M134 40v44M96 54h50M96 68h50" stroke="#fff" stroke-opacity=".5" stroke-width="1.5"/>'
    '<circle cx="54" cy="70" r="24" fill="#fff"/><circle cx="54" cy="70" r="24" fill="none" stroke="#263238" stroke-width="3"/>'
    '<path d="M54 56l12 9-4.5 14h-15L42 65z" fill="#263238"/>'
    '<path d="M54 46v10M78 62l-12 3M69 92l-8-13M39 92l8-13M30 62l12 3" stroke="#263238" stroke-width="3" stroke-linecap="round"/>'
    + sparkle(26, 30, 7, YELLOW))

ART["cover_religi"] = cover("#FFE0B2", "#FFB74D",
    '<circle cx="124" cy="34" r="16" fill="#FFF8E1"/><circle cx="130" cy="30" r="14" fill="#FFCC80"/>'
    '<path d="M44 104V70a36 36 0 0 1 72 0v34z" fill="#FFF8E1"/>'
    '<path d="M80 34v-10" stroke="#FFF8E1" stroke-width="4" stroke-linecap="round"/>'
    '<circle cx="80" cy="20" r="4" fill="#FFC107"/>'
    '<rect x="18" y="52" width="14" height="52" rx="3" fill="#FFF8E1"/><path d="M18 52l7-16 7 16z" fill="#8D6E63"/>'
    '<rect x="128" y="62" width="14" height="42" rx="3" fill="#FFF8E1"/><path d="M128 62l7-14 7 14z" fill="#8D6E63"/>'
    '<path d="M70 104V84a10 10 0 0 1 20 0v20z" fill="#8D6E63"/>'
    '<rect x="0" y="104" width="160" height="16" fill="#8D6E63" fill-opacity=".5"/>'
    + sparkle(22, 26, 6, "#FFF8E1") + sparkle(146, 90, 5, "#FFF8E1"))

ART["cover_donor"] = cover("#F8BBD0", "#F06292",
    '<circle cx="124" cy="96" r="30" fill="#fff" fill-opacity=".2"/>'
    '<path d="M62 14s30 32 30 56a30 30 0 0 1-60 0c0-24 30-56 30-56z" fill="#C2185B"/>'
    '<path d="M62 14s30 32 30 56a30 30 0 0 1-60 0c0-24 30-56 30-56z" fill="#E91E63"/>'
    '<path d="M46 72a16 16 0 0 0 14 14" stroke="#fff" stroke-opacity=".7" stroke-width="5" fill="none" stroke-linecap="round"/>'
    '<rect x="108" y="30" width="30" height="44" rx="8" fill="#fff"/><rect x="116" y="22" width="14" height="10" rx="3" fill="#fff"/>'
    '<path d="M123 42v20M113 52h20" stroke="#E91E63" stroke-width="6" stroke-linecap="round"/>'
    + heart(124, 98, 1.3, "#fff"))

ART["cover_lomba"] = cover("#FFCDD2", "#EF5350",
    '<path d="M0 22Q80 54 160 22" stroke="#fff" stroke-width="2.5" fill="none"/>'
    + "".join(f'<path d="M{x} {y}l10 0-5 16z" fill="{c}"/>' for x, y, c in
              [(14, 30, "#fff"), (34, 38, YELLOW), (54, 43, "#fff"), (74, 45, YELLOW),
               (94, 43, "#fff"), (114, 38, YELLOW), (134, 30, "#fff")])
    + '<path d="M58 68h44v14a22 22 0 0 1-44 0z" fill="#FFC107"/>'
    '<path d="M58 72H46v6a12 12 0 0 0 12 12M102 72h12v6a12 12 0 0 1-12 12" stroke="#FFC107" stroke-width="5" fill="none"/>'
    '<rect x="74" y="102" width="12" height="8" fill="#FFA000"/><rect x="62" y="108" width="36" height="8" rx="3" fill="#FFA000"/>'
    + sparkle(30, 84, 7, "#fff") + sparkle(132, 80, 6, "#fff"))

ART["cover_rapat"] = cover("#BBDEFB", "#7986CB",
    '<ellipse cx="80" cy="96" rx="62" ry="14" fill="#fff" fill-opacity=".85"/>'
    '<rect x="22" y="92" width="116" height="10" rx="5" fill="#fff"/>'
    + person(52, 94, .6, PINK) + person(80, 94, .64, YELLOW, hair="#212121") + person(108, 94, .6, GREEN)
    + '<rect x="28" y="14" width="46" height="26" rx="9" fill="#fff"/><path d="M40 40l-6 10 16-10z" fill="#fff"/>'
    '<rect x="38" y="22" width="26" height="4" rx="2" fill="#7986CB"/><rect x="38" y="30" width="16" height="4" rx="2" fill="#7986CB" fill-opacity=".6"/>'
    '<rect x="92" y="22" width="40" height="22" rx="8" fill="#FFC107"/>'
    '<circle cx="104" cy="33" r="2.6" fill="#fff"/><circle cx="112" cy="33" r="2.6" fill="#fff"/><circle cx="120" cy="33" r="2.6" fill="#fff"/>')

ART["cover_keuangan"] = cover("#C8E6C9", "#26A69A",
    '<rect x="22" y="70" width="18" height="34" rx="3" fill="#fff" fill-opacity=".9"/>'
    '<rect x="46" y="54" width="18" height="50" rx="3" fill="#fff" fill-opacity=".9"/>'
    '<rect x="70" y="38" width="18" height="66" rx="3" fill="#fff"/>'
    '<path d="M24 52 50 40l22-14 28-8" stroke="#FFC107" stroke-width="4" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
    '<path d="M92 18l10 2-6 8z" fill="#FFC107"/>'
    + "".join(f'<ellipse cx="124" cy="{104 - i * 9}" rx="22" ry="7" fill="#FFC107"/><ellipse cx="124" cy="{101 - i * 9}" rx="22" ry="7" fill="#FFD54F"/>' for i in range(4))
    + '<circle cx="124" cy="68" r="2" fill="#FFA000"/>')

ART["cover_umum"] = cover("#E8F5E9", "#A5D6A7",
    '<circle cx="126" cy="28" r="14" fill="#FFF59D"/>'
    '<ellipse cx="80" cy="110" rx="96" ry="16" fill="#66BB6A" fill-opacity=".6"/>'
    + house(24, 62, 38, 44, "#fff", GREEN) + house(68, 52, 44, 54, "#C8E6C9", BLUE) + house(118, 66, 32, 40, "#fff", GREEN2)
    + heart(88, 24, 1.1))

for name, body in ART.items():
    (ART_DIR / f"{name}.svg").write_text(body)

print(f"ikon: {len(ICONS)} x2 varian | ilustrasi: {len(ART)}")
