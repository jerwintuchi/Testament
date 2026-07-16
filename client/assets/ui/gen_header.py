#!/usr/bin/env python3
"""gen_header.py — the Contract Board's institutional header (TD-053 / board-header).

Emits two hand-painted raster PNGs (canonical register, TD-046), run FROM this dir
(relative filenames):

  board_header.png  248x76  a carved oak/walnut plaque, 9-slice-safe (margins 36/18/36/18):
                            horizontal grain + age bands, a routed recessed field (groove +
                            double bevel), forged IRON corner straps each carrying BRONZE
                            bolts, and a worn/eroded rim. Utilitarian + institutional — dim,
                            matte, no gloss. Godot draws the seal + engraved title over it.
  board_seal.png     36x50  the inset bronze seal: a VESICA medallion (the medieval church
                            seal shape) — outer socket AO ring, forged iron rim, aged bronze
                            disc, and the Collegium emblem in RAISED RELIEF. Reads as set
                            INTO the wood; no glow, no specular hotspot.

@produces board_header.png, board_seal.png
@consumes collegium_logo.png  (via PIL — the emblem struck in relief on the seal's disc)
@why      The generator->emblem edge is an INPUT, invisible to tools/asset_map.py (which
          only tracks `write_png` for .py producers), hence this header. Both PNGs are
          authored at their EXACT on-screen size: the client's internal resolution is a
          fixed 640x360 (PixelScale integer-scales to fill), so BoardGeo.placard_rect is
          deterministic — authoring 1:1 and showing NEAREST avoids the LINEAR-downscale
          mush TD-050 diagnosed. Supersede: board_nameplate.png + crest_v1.png.

Stdlib + PIL (sanctioned for generators); writes via ashember.write_png so the asset-map
producer edge holds. Brand-new PNGs need `godot --headless --import`.
"""
import math

from PIL import Image

import ashember as A

SS = 4
LX, LY = -0.60, -0.66          # upper-left key (points toward the light) — matches gen_heraldry

# Forged iron for the corner straps — near-black warm, like the sconce (dungeon-dark, TD-048).
IRON_D = (14, 13, 11)
IRON_B = (32, 29, 24)
IRON_H = (82, 72, 56)          # dim lit iron edge (NOT a light grey frame)
# Aged bronze / brass. Matte: the seal reads by RELIEF, never by a specular hotspot (R175).
BRONZE_DK = (40, 28, 15)
BRONZE_MID = (104, 74, 38)
BRONZE_LT = (198, 158, 92)
PATINA = (58, 74, 56)          # verdigris creep in the recesses
# Aged dark walnut. A.RAMP["wood"] alone is a saturated orange-brown that reads as polished
# mahogany — luxurious, the exact note the brief rejects. Blend toward this neutral to age it.
WALNUT = (50, 39, 30)


def _cl(v, a=0.0, b=1.0):
    return max(a, min(b, v))


# ── The carved plaque (248x96, 9-slice) ────────────────────────────────────────
HW, HH = 248, 76
HMX, HMY = 36, 18              # 9-slice patch margins — the corner straps live inside these

STRAP_X, STRAP_Y = 28.0, 16.0  # the L-strap's corner footprint (< the margins, so it never smears)
STRAP_T = 8.0                  # arm thickness


def _wood(fx, fy):
    """Aged walnut over oak: grain runs ALONG the plank (mostly a function of y), so the
    9-slice centre stretch smears nothing. Narrow, dim value range — this sits on a
    near-black board and must read utilitarian, not luxurious."""
    base = A.ramp_shade("wood", 0.34)
    # Grain is scaled into RGB units (~+-9), not left as a fraction — the ramp is the value,
    # the grain is the tooth on top of it.
    grain = (math.sin(fy * 1.9) * 3.4
             + math.sin(fy * 0.7 + fx * 0.06) * 4.2       # long, near-horizontal streaks
             + A.noise(int(fx), int(fy), 7) * 0.6)
    band = math.sin(fy * 0.42 + 1.1)                       # a few darker age bands
    c = (base[0] + grain, base[1] + grain * 0.72, base[2] + grain * 0.5)
    c = A.lerp_rgb(c, A.RAMP["wood"][0], _cl(band * 0.20 + 0.10))
    return A.lerp_rgb(c, WALNUT, 0.46)                     # age it out of the mahogany register


def _aged(v):
    """A wood-ramp value, aged out of the saturated orange register (see WALNUT)."""
    return A.lerp_rgb(A.ramp_shade("wood", v), WALNUT, 0.46)


WOOD_LIP = A.lerp_rgb(A.RAMP["wood"][4], WALNUT, 0.38)     # the recess's lit lip, desaturated


def _strap(cl, ct):
    """Forged iron L-strap wrapping a corner, with two bronze bolts. Returns rgb or None."""
    if cl >= STRAP_X or ct >= STRAP_Y:
        return None
    if cl >= STRAP_T and ct >= STRAP_T:                    # the L's open elbow — bare wood
        return None
    edge = min(cl, ct)
    lit = 0.24 + (STRAP_T - min(STRAP_T, max(cl, ct) % STRAP_T)) / STRAP_T * 0.06
    if edge <= 1.0:                                        # the outer rim catches the key
        lit += 0.36
    if cl >= STRAP_T - 1.4 or ct >= STRAP_Y - 1.4:         # inner edge shades down into the wood
        lit -= 0.13
    lit += A.noise(int(cl), int(ct), 11) * 0.006           # hammered, not milled
    body = A.lerp_rgb(IRON_D, IRON_H, _cl(lit))
    for bx, by in ((4.2, 4.2), (20.0, 3.9)):               # bronze bolts: one at the elbow, one out the arm
        bd = math.hypot(cl - bx, ct - by)
        if bd < 2.8:
            blit = _cl(0.32 + (-(cl - bx) * LX - (ct - by) * LY) / 2.8 * 0.55)
            body = A.lerp_rgb(A.lerp_rgb(IRON_B, IRON_H, blit), BRONZE_MID, 0.44)
            if (cl - bx) > 0.7 and (ct - by) > 0.7:        # hard down-right AO crescent
                body = A.lerp_rgb(body, IRON_D, 0.45)
    return body


def header_px(fx, fy):
    left, top = fx, fy
    right, bot = HW - 1 - fx, HH - 1 - fy
    d = min(left, top, right, bot)

    # ── worn rim: centuries of hands nibble the outer edge away. Low-frequency, so it reads as
    # erosion rather than as a dirty speckle band.
    if d < 1.4 and A.noise(int(fx * 0.35), int(fy * 0.9), 13) > 3.2:
        return (0, 0, 0, 0)

    # ── iron corner straps (drawn over everything, incl. the bevel) ──
    strap = _strap(min(left, right), min(top, bot))
    if strap is not None:
        return A.clamp_rgb(strap) + (255,)

    # ── double bevel: a dark outer line, a lit top-left chamfer, a dark bottom-right ──
    if d <= 3:
        top_lit = (top <= left and top <= right)
        if d == 0:
            return A.clamp_rgb(A.lerp_rgb(A.RAMP["wood"][0], WALNUT, 0.22)) + (255,)
        v = (0.60 if top_lit else 0.12) if d <= 1 else (0.46 if top_lit else 0.20)
        if top_lit and A.noise(int(fx * 0.5), int(fy), 17) > 2.6:   # exposed grain, worn top edge
            v += 0.12
        return A.clamp_rgb(_aged(v)) + (255,)

    # ── routed field: a carved groove ringing an inset recess (the seal + title sit here) ──
    c = _wood(fx, fy)
    rx0, rx1, ry0, ry1 = 22.0, HW - 22.0, 7.0, HH - 7.0
    if rx0 < fx < rx1 and ry0 < fy < ry1:
        rd = min(fx - rx0, rx1 - fx, fy - ry0, ry1 - fy)
        if rd < 2.2:                                       # the routed GROOVE (dark cut channel)
            c = A.lerp_rgb(c, (10, 7, 5), 0.72)
        else:                                              # the recessed field
            c = A.lerp_rgb(c, (10, 7, 5), 0.46)            # deeply routed, for gilt contrast
            if fy < ry0 + 3.5:                             # a firm lit lip along the recess top
                c = A.lerp_rgb(c, WOOD_LIP, 0.44)
            elif fy > ry1 - 3.0:                           # occlusion along the recess bottom
                c = A.lerp_rgb(c, (10, 7, 5), 0.34)
    return A.clamp_rgb(c) + (255,)


# ── The inset bronze seal (36x50 vesica) ───────────────────────────────────────
SW, SH = 24, 33
SCX, SCY = SW * 0.5, SH * 0.5
SA, SB = 10.6, 15.2            # vesica semi-axes
SP = 1.62                      # superellipse exponent < 2 ⇒ the pointed oval of a church seal
RIM_E = 0.68                   # e above this is the iron rim (thick enough to read as forged)
SOCK_E = 1.30                  # e above this is bare wood (the socket AO fades out by here)

EMB_SRC = "collegium_logo.png"
DEV_H = 26.0                   # the struck device's height, in output px


def _load_device():
    """The Collegium emblem, LANCZOS-scaled to the device slot. Returns (pixels, w, h)."""
    im = Image.open(EMB_SRC).convert("RGBA")
    h = int(round(DEV_H))
    w = max(1, int(round(h * im.width / im.height)))
    im = im.resize((w, h), Image.LANCZOS)
    return im.load(), w, h


DEV, DEV_W, DEV_H_PX = _load_device()
DEV_X, DEV_Y = SCX - DEV_W * 0.5, SCY - DEV_H_PX * 0.5 - 0.5


def _dev(fx, fy):
    """Bilinear (alpha, luminance) of the device at output coords. Outside ⇒ (0, 0)."""
    x, y = fx - DEV_X - 0.5, fy - DEV_Y - 0.5
    if x < -1.0 or y < -1.0 or x > DEV_W or y > DEV_H_PX:
        return 0.0, 0.0
    x0, y0 = math.floor(x), math.floor(y)
    tx, ty = x - x0, y - y0
    a = lum = 0.0
    for j in (0, 1):
        for i in (0, 1):
            sx, sy = x0 + i, y0 + j
            if 0 <= sx < DEV_W and 0 <= sy < DEV_H_PX:
                p = DEV[sx, sy]
                w = (tx if i else 1.0 - tx) * (ty if j else 1.0 - ty)
                pa = p[3] / 255.0
                a += pa * w
                lum += (0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]) / 255.0 * pa * w
    return a, (lum / a if a > 0.001 else 0.0)


def seal_px(fx, fy):
    ox, oy = fx - SCX, fy - SCY
    e = (abs(ox) / SA) ** SP + (abs(oy) / SB) ** SP

    if e >= SOCK_E:
        return (0, 0, 0, 0)
    if e >= 1.0:
        # ── socket: the AO ring of the hole routed through the plank. This is what sells
        # "set INTO the wood" wherever the seal is placed (R172) — no baking into the
        # stretched 9-slice centre, which would smear it.
        t = (e - 1.0) / (SOCK_E - 1.0)
        a = (1.0 - t) ** 1.5 * 0.90
        if oy < 0 and abs(ox) < SA * 0.9:        # the hole's upper lip occludes hardest
            a = min(1.0, a * 1.25)
        return (0, 0, 0, A.clamp(a * 255))

    if e >= RIM_E:
        # ── forged iron rim: a raised ring, so it takes the key on its OUTER upper-left face and
        # occludes on the inner side. Hammered, cool — it must not read as more bronze.
        t = (e - RIM_E) / (1.0 - RIM_E)                    # 0 inner .. 1 outer
        nlit = _cl(0.30 + (-ox * LX - oy * LY) / SB * 0.70)
        crown = 1.0 - abs(t - 0.5) * 1.6                   # the ring's rounded crown catches most
        lit = _cl(nlit * (0.35 + crown * 0.65) + 0.04)
        lit += A.noise(int(fx), int(fy), 23) * 0.014       # hammered, not milled
        c = A.lerp_rgb(IRON_D, IRON_H, _cl(lit))
        if t < 0.18:                                       # hard AO where the rim overhangs the disc
            c = A.lerp_rgb(c, (0, 0, 0), (0.18 - t) / 0.18 * 0.55)
        return A.clamp_rgb(c) + (255,)

    # ── aged bronze disc: DIM + matte, patina-mottled, gentle radial falloff (no hotspot, R175) ──
    base = _cl(0.40 - e * 0.16 + (-ox * LX - oy * LY) / SB * 0.12)
    c = A.lerp_rgb(BRONZE_DK, BRONZE_MID, base)
    mottle = A.noise(int(fx * 1.3), int(fy * 1.3), 29)
    c = A.lerp_rgb(c, PATINA, _cl(mottle * 0.012 + 0.07))      # verdigris creep, faint
    if e > RIM_E - 0.20:                                       # AO where the field meets the rim
        c = A.lerp_rgb(c, (0, 0, 0), _cl((e - RIM_E + 0.20) / 0.20) * 0.50)

    # ── the emblem STRUCK IN RELIEF ──
    # The device is a raised plateau: its light-facing (upper-left) lip catches the candle, its
    # lower-right lip shadows, and its plateau face sits mid-bronze. `rel` is signed coverage
    # gradient — sampling the mask offset both ways gives BOTH lips, which is what separates a
    # struck medal from lines painted on a disc.
    a, lum = _dev(fx, fy)
    if a > 0.02:
        aul, _ = _dev(fx - 1.1, fy - 1.1)
        adr, _ = _dev(fx + 1.1, fy + 1.1)
        g = adr - aul                                          # +1 UL lip, -1 DR lip, 0 plateau
        face = A.lerp_rgb(BRONZE_DK, BRONZE_MID, 0.52 + lum * 0.20)   # the plateau
        if g > 0.02:
            face = A.lerp_rgb(face, BRONZE_LT, _cl(g * 1.8) * 0.95)   # lit lip
        elif g < -0.02:
            face = A.lerp_rgb(face, (6, 4, 2), _cl(-g * 1.3) * 0.72)  # shadowed lip
        # A contact shadow just outside the device's lower-right edge, so it sits ON the disc.
        c = A.lerp_rgb(c, face, _cl(a * 1.2))
    else:
        aul, _ = _dev(fx - 1.2, fy - 1.2)
        if aul > 0.08:
            c = A.lerp_rgb(c, (0, 0, 0), _cl(aul) * 0.42)
    return A.clamp_rgb(c) + (255,)


# ── Supersample → averaged downsample ───────────────────────────────────────────
def _supersample(W, H, sample):
    grid = {}
    for Y in range(H * SS):
        for X in range(W * SS):
            grid[(X, Y)] = sample((X + 0.5) / SS, (Y + 0.5) / SS)

    def pixel(x, y):
        r = g = b = a = 0
        for j in range(SS):
            for i in range(SS):
                pr, pg, pb, pa = grid[(x * SS + i, y * SS + j)]
                r += pr * pa; g += pg * pa; b += pb * pa; a += pa
        n = SS * SS
        if a == 0:
            return (0, 0, 0, 0)
        return (r // a, g // a, b // a, a // n)
    return pixel


def _ascii(W, H, pixel):
    chars = " .:-=+*#%@"
    rows = []
    for y in range(0, H, 2):
        row = ""
        for x in range(W):
            r, g, b, a = pixel(x, y)
            v = (r + g + b) // 3
            row += chars[min(9, v * 10 // 256)] if a > 40 else " "
        rows.append(row)
    return "\n".join(rows)


def main(ascii_only=False):
    plaque = _supersample(HW, HH, header_px)
    seal = _supersample(SW, SH, seal_px)
    if ascii_only:
        print("=== board_header ===\n" + _ascii(HW, HH, plaque))
        print("\n=== board_seal ===\n" + _ascii(SW, SH, seal))
        return
    A.write_png("board_header.png", HW, HH, plaque)
    print("wrote board_header.png (%dx%d)" % (HW, HH))
    A.write_png("board_seal.png", SW, SH, seal)
    print("wrote board_seal.png (%dx%d)" % (SW, SH))


if __name__ == "__main__":
    import sys
    main(ascii_only=("--ascii" in sys.argv))
