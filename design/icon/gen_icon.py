#!/usr/bin/env python3
"""Generator ikon KUBAR Connect (1024x1024) — v3.

Perbaikan atas v2:
- Figur dibikin 3 orang, TIDAK saling tumpang tindih, tinggi berbeda jelas.
- Badan memakai bahu melengkung (bukan dome setengah lingkaran) supaya tidak
  terbaca sebagai bidak catur.
- Akar beringin jadi bentuk berisi yang menebal di atas, bukan garis tipis
  (yang di v2 terbaca sebagai antena).
- Lengan berpegangan dipindah ke warna emas agar kontras dengan figur krem.
"""
from __future__ import annotations

import math
import sys

W = H = 1024
CX, CY = 512, 512
R_EMBLEM = 384

GREEN_DEEP = "#14451A"
GREEN_MID = "#0F3412"
GREEN_DARK = "#0A2409"
GREEN_EDGE = "#061A05"
CANOPY_LIGHT = "#8CCF8E"
CANOPY_MID = "#57A85A"
CANOPY_DEEP = "#2E7D32"
GOLD = "#FFC107"
GOLD_DEEP = "#E9A800"
GOLD_LIGHT = "#FFD452"
BLUE = "#0D47A1"
CREAM = "#F3F8F1"
MINT_CREAM = "#F5FBF4"
LIGHT_GREEN = "#C9E5CB"


def f(v: float) -> str:
    return f"{v:.2f}".rstrip("0").rstrip(".")


def figure(cx: float, baseline: float, body_w: float, body_h: float,
           head_r: float) -> str:
    """Orang: kepala + badan dengan bahu melengkung, kaki sedikit melebar."""
    half = body_w / 2
    top = baseline - body_h
    sh = head_r * 1.15          # tinggi lengkung bahu
    foot = body_w * 0.12        # sedikit melebar di dasar
    return (
        f'    <circle cx="{f(cx)}" cy="{f(top - head_r * 0.78)}" r="{f(head_r)}"/>\n'
        f'    <path d="M {f(cx - half)} {f(baseline)}'
        f' Q {f(cx - half)} {f(baseline - foot)} {f(cx - half - 3)} {f(baseline - foot * 2)}'
        f' L {f(cx - half + 2)} {f(top + sh * 0.55)}'
        f' Q {f(cx - half + 4)} {f(top)} {f(cx)} {f(top)}'
        f' Q {f(cx + half - 4)} {f(top)} {f(cx + half - 2)} {f(top + sh * 0.55)}'
        f' L {f(cx + half + 3)} {f(baseline - foot * 2)}'
        f' Q {f(cx + half)} {f(baseline - foot)} {f(cx + half)} {f(baseline)} Z"/>\n'
    )


def tapered_root(x_top: float, y_top: float, x_bot: float, y_bot: float,
                 w_top: float, w_bot: float) -> str:
    """Akar beringin: pita menebal di atas, menipis ke bawah."""
    dx, dy = x_bot - x_top, y_bot - y_top
    ln = math.hypot(dx, dy) or 1.0
    nx, ny = -dy / ln, dx / ln
    p = [(x_top + nx * w_top / 2, y_top + ny * w_top / 2),
         (x_bot + nx * w_bot / 2, y_bot + ny * w_bot / 2),
         (x_bot - nx * w_bot / 2, y_bot - ny * w_bot / 2),
         (x_top - nx * w_top / 2, y_top - ny * w_top / 2)]
    return f'    <path d="M {f(p[0][0])} {f(p[0][1])} L {f(p[1][0])} {f(p[1][1])} L {f(p[2][0])} {f(p[2][1])} L {f(p[3][0])} {f(p[3][1])} Z" fill="{GREEN_DARK}"/>\n'


def build(canopy_w: float, canopy_top: float, canopy_bottom: float,
          trunk_y: float, ground: float,
          figs: list[tuple[float, float, float, float]],
          pin_head_r: float, pin_head_cy: float, pin_tip: float) -> str:
    half = canopy_w / 2
    shoulder = canopy_bottom - canopy_top * 0.0

    # kanopi beringan: kubah lebar + tepi bawah beriak lembut (daun rindu)
    d = (
        f"M {f(CX - half)} {f(canopy_bottom - 26)}"
        f" C {f(CX - half - 6)} {f(canopy_top + 84)}"
        f" {f(CX - half * 0.54)} {f(canopy_top)}"
        f" {f(CX)} {f(canopy_top)}"
        f" C {f(CX + half * 0.54)} {f(canopy_top)}"
        f" {f(CX + half + 6)} {f(canopy_top + 84)}"
        f" {f(CX + half)} {f(canopy_bottom - 26)}"
        f" C {f(CX + half * 0.78)} {f(canopy_bottom + 14)}"
        f" {f(CX + half * 0.30)} {f(canopy_bottom - 6)}"
        f" {f(CX)} {f(canopy_bottom - 14)}"
        f" C {f(CX - half * 0.30)} {f(canopy_bottom + 16)}"
        f" {f(CX - half * 0.78)} {f(canopy_bottom + 12)}"
        f" {f(CX - half)} {f(canopy_bottom - 26)} Z"
    )

    # location pin teardrop
    pr = pin_head_r
    bh = pin_tip - pin_head_cy
    pin = (
        f"M {f(CX)} {f(pin_tip)}"
        f" C {f(CX - pr * 0.42)} {f(pin_head_cy + bh * 0.64)}"
        f" {f(CX - pr)} {f(pin_head_cy + bh * 0.30)}"
        f" {f(CX - pr)} {f(pin_head_cy)}"
        f" A {f(pr)} {f(pr)} 0 1 1 {f(CX + pr)} {f(pin_head_cy)}"
        f" C {f(CX + pr)} {f(pin_head_cy + bh * 0.30)}"
        f" {f(CX + pr * 0.42)} {f(pin_head_cy + bh * 0.64)}"
        f" {f(CX)} {f(pin_tip)} Z"
    )

    # batang + akar beringin
    # Batang ditaper: lebar di atas (menyatu dgn kanopi), ramping ke bawah.
    roots = (
        f'    <path d="M {f(CX - 34)} {f(canopy_bottom - 56)}'
        f' C {f(CX - 30)} {f(trunk_y - 30)} {f(CX - 21)} {f(trunk_y - 6)} {f(CX - 17)} {f(trunk_y)}'
        f' L {f(CX + 17)} {f(trunk_y)}'
        f' C {f(CX + 21)} {f(trunk_y - 6)} {f(CX + 30)} {f(trunk_y - 30)} {f(CX + 34)} {f(canopy_bottom - 56)}'
        f' Z" fill="{CANOPY_DEEP}"/>\n'

    )

    # figur: (cx, baseline, body_w, scale)
    parts: list[str] = []
    for cx, baseline, bw, sc in figs:
        parts.append(figure(cx, baseline, bw, 126 * sc, 50 * sc))

    # lengan berpegangan: busur emas di tulang bahu, digambar SEBELUM figur
    ay = 560
    arc_d = (
        f"M {f(CX - 196)} {f(ay + 4)}"
        f" Q {f(CX)} {f(ay - 26)} {f(CX + 196)} {f(ay + 4)}"
    )

    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">
  <defs>
    <radialGradient id="bg" cx="50%" cy="34%" r="76%">
      <stop offset="0%" stop-color="{MINT_CREAM}"/>
      <stop offset="58%" stop-color="#E4F2E5"/>
      <stop offset="100%" stop-color="{LIGHT_GREEN}"/>
    </radialGradient>
    <radialGradient id="emblem" cx="36%" cy="24%" r="84%">
      <stop offset="0%" stop-color="#1B5E20"/>
      <stop offset="46%" stop-color="{GREEN_DEEP}"/>
      <stop offset="100%" stop-color="{GREEN_EDGE}"/>
    </radialGradient>
    <linearGradient id="rim" x1="12%" y1="6%" x2="86%" y2="96%">
      <stop offset="0%" stop-color="#FFFFFF" stop-opacity=".60"/>
      <stop offset="46%" stop-color="#FFFFFF" stop-opacity=".08"/>
      <stop offset="100%" stop-color="{BLUE}" stop-opacity=".40"/>
    </linearGradient>
    <linearGradient id="canopy" x1="22%" y1="0%" x2="80%" y2="100%">
      <stop offset="0%" stop-color="{CANOPY_LIGHT}"/>
      <stop offset="50%" stop-color="{CANOPY_MID}"/>
      <stop offset="100%" stop-color="{CANOPY_DEEP}"/>
    </linearGradient>
    <linearGradient id="gold" x1="18%" y1="6%" x2="82%" y2="96%">
      <stop offset="0%" stop-color="{GOLD_LIGHT}"/>
      <stop offset="56%" stop-color="{GOLD}"/>
      <stop offset="100%" stop-color="{GOLD_DEEP}"/>
    </linearGradient>
    <radialGradient id="halo" cx="50%" cy="44%" r="52%">
      <stop offset="0%" stop-color="{GOLD}" stop-opacity=".26"/>
      <stop offset="62%" stop-color="{GOLD}" stop-opacity=".08"/>
      <stop offset="100%" stop-color="{GOLD}" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="sheen" cx="32%" cy="18%" r="54%">
      <stop offset="0%" stop-color="#FFFFFF" stop-opacity=".30"/>
      <stop offset="100%" stop-color="#FFFFFF" stop-opacity="0"/>
    </radialGradient>
    <clipPath id="badge"><circle cx="{CX}" cy="{CY}" r="{R_EMBLEM}"/></clipPath>
  </defs>

  <rect x="0" y="0" width="{W}" height="{H}" rx="232" fill="url(#bg)"/>

  <circle cx="{CX}" cy="{CY}" r="{R_EMBLEM}" fill="url(#emblem)"/>
  <g clip-path="url(#badge)">
    <circle cx="{CX}" cy="{CY}" r="{R_EMBLEM}" fill="url(#sheen)"/>
    <circle cx="{CX}" cy="368" r="238" fill="url(#halo)"/>
  </g>

  <g>
    <path d="{d}" fill="url(#canopy)"/>
    <path d="{pin}" fill="url(#gold)"/>
    <circle cx="{CX}" cy="{f(pin_head_cy)}" r="{f(pr * 0.28)}" fill="{GREEN_DARK}"/>
{roots}  </g>

  <path d="{arc_d}" fill="none" stroke="{GOLD}" stroke-width="11"
        stroke-linecap="round" opacity=".62"/>

  <ellipse cx="{CX}" cy="{f(ground + 8)}" rx="272" ry="24"
           fill="{GREEN_EDGE}" opacity=".5"/>

  <g fill="{CREAM}">
{''.join(parts)}  </g>

  <circle cx="{CX}" cy="{CY}" r="{R_EMBLEM - 5}" fill="none"
          stroke="url(#rim)" stroke-width="7"/>
</svg>
"""


def main() -> int:
    out = sys.argv[1] if len(sys.argv) > 1 else "kubar-icon.svg"
    svg = build(
        canopy_w=536,
        canopy_top=206,
        canopy_bottom=416,
        trunk_y=500,
        ground=650,
        # tiga orang: anak (kiri), dewasa (tengah), elder (kanan)
        figs=[(300, 650, 84, 0.78), (512, 650, 102, 1.08), (724, 650, 84, 0.86)],
        pin_head_r=84,
        pin_head_cy=318,
        pin_tip=436,
    )
    with open(out, "w") as fh:
        fh.write(svg)
    print(f"tulis {out} ({len(svg)} byte)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
