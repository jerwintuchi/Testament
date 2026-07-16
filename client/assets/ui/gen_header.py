#!/usr/bin/env python3
"""gen_header.py — the Contract Board's institutional header (TD-053 / board-header).

Emits two hand-painted raster PNGs (canonical register, TD-046), run FROM this dir
(relative filenames):

  board_header.png  248x44  a carved sign STRAPPED to the wall (TD-054, to the author's
                            reference): vertical iron strap-hinges at both ends carrying
                            bronze bolts, an open plank field between them, a lit top rail
                            and a routed bottom rail. 9-slice-safe (margins 36/13/36/13).
                            SHORT by design: the medallion crowns it, overlapping its top
                            rail, so sign + medallion share one 76px header budget (every px
                            of header costs the two rows of writs ~0.5px each).
                            Godot draws the medallion + engraved Cinzel title over it.
  board_seal.png     40x40  the RING MEDALLION crowning the sign: a bronze annulus (bead-
                            and-fillet profile) around a recessed field carrying the
                            Collegium emblem in RAISED RELIEF, with scroll bosses at the
                            3- and 9-o'clock seats where it bolts to the sign. Dim bronze,
                            matte — no glow, no specular hotspot.

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
BRONZE_LT = (214, 174, 104)
PATINA = (58, 74, 56)          # verdigris creep in the recesses
# Aged dark walnut. A.RAMP["wood"] alone is a saturated orange-brown that reads as polished
# mahogany — luxurious, the exact note the brief rejects. Blend toward this neutral to age it.
WALNUT = (50, 39, 30)


def _cl(v, a=0.0, b=1.0):
    return max(a, min(b, v))


# ── The carved plaque (248x96, 9-slice) ────────────────────────────────────────
HW, HH = 248, 44
HMX, HMY = 36, 13              # 9-slice patch margins — the end straps live inside these

# The END STRAP: a vertical iron hinge-plate closing each end of the sign — a bar between two
# bolted plates, the fitting the reference hangs the sign from. It must live inside the 9-slice
# margin (HMX=36) so the centre stretch never smears it.
STRAP_W = 26.0                 # how far in from each end the fitting reaches
BAR_X0, BAR_X1 = 7.0, 17.0     # the vertical bar's span, measured in from the end
PLATE_H = 10.0                 # the plate capping the bar top and bottom


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


def _strap(cl, fy):
    """Forged iron end-strap at distance `cl` in from the nearest end. Returns rgb or None."""
    if cl >= STRAP_W:
        return None
    ct = min(fy, HH - 1.0 - fy)
    in_plate = ct < PLATE_H and cl < 21.0
    in_bar = BAR_X0 <= cl <= BAR_X1
    if not (in_plate or in_bar):
        return None
    # Relief: the fitting is a raised plate, so its outer edges take the key. `edge` is the
    # distance to whichever silhouette we are inside.
    if in_plate:
        edge = min(ct, cl, 21.0 - cl, PLATE_H - ct)
        lit = 0.22 + _cl((PLATE_H - ct) / PLATE_H) * 0.06
    else:
        edge = min(cl - BAR_X0, BAR_X1 - cl)
        lit = 0.20 + _cl((BAR_X1 - cl) / (BAR_X1 - BAR_X0)) * 0.08
    if edge < 1.0:                                         # the outer rim catches the key
        lit += 0.34
    elif edge < 2.0:
        lit += 0.12
    if fy > HH * 0.5:                                      # the fitting's lower half sits in shade
        lit -= 0.06
    lit += A.noise(int(cl), int(fy), 11) * 0.006           # hammered, not milled
    body = A.lerp_rgb(IRON_D, IRON_H, _cl(lit))
    # Bronze bolts: one through each plate, on the bar's centreline.
    if in_plate:
        bd = math.hypot(cl - 12.0, ct - 5.0)
        if bd < 2.9:
            blit = _cl(0.32 + (-(cl - 12.0) * LX - (ct - 5.0) * LY) / 2.9 * 0.55)
            body = A.lerp_rgb(A.lerp_rgb(IRON_B, IRON_H, blit), BRONZE_MID, 0.46)
            if (cl - 12.0) > 0.7 and (ct - 5.0) > 0.7:     # hard down-right AO crescent
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
    strap = _strap(min(left, right), fy)
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

    # ── the sign's plank field, closed by a lit top rail and a routed bottom rail ──
    c = _wood(fx, fy)
    if fy < 5.0:                                           # top rail: catches the key
        c = A.lerp_rgb(c, WOOD_LIP, 0.30 * (1.0 - fy / 5.0) + 0.14)
    elif fy > HH - 7.0:
        # bottom rail: a routed channel above a lit lip — the reference's decorative under-rail.
        # Kept slim: the sign's plank field has to seat two lines under the medallion's overlap.
        rb = fy - (HH - 7.0)
        if rb < 2.5:
            c = A.lerp_rgb(c, (8, 6, 4), 0.62)             # the cut channel
        elif rb < 4.5:
            c = A.lerp_rgb(c, WOOD_LIP, 0.34)              # the lip below it
        else:
            c = A.lerp_rgb(c, (8, 6, 4), 0.30)
    # A soft vertical falloff: the sign is lit from above, so its foot sits in its own shade.
    c = A.lerp_rgb(c, (8, 6, 4), _cl((fy / HH - 0.35) * 0.34))
    return A.clamp_rgb(c) + (255,)


# ── The ring medallion (44x44) ─────────────────────────────────────────────────
# Crowns the sign, bolted to it at the 3- and 9-o'clock scroll bosses (TD-054, to the
# author's reference). A bronze annulus with a bead-and-fillet profile around a recessed
# field carrying the emblem in raised relief. NOT a floating icon: the bosses seat it on
# the sign's top rail, so it reads as mounted hardware.
SW, SH = 40, 40
SCX, SCY = SW * 0.5, SH * 0.5
R_OUT = 18.0                   # the annulus's outer edge
R_IN = 13.0                    # where the ring meets the recessed field
BOSS_R = 3.4                   # the scroll bosses at 3 and 9 o'clock

EMB_SRC = "collegium_logo.png"
DEV_H = 23.0                   # the struck device's height, in output px


def _load_device():
    """The Collegium emblem, LANCZOS-scaled to the device slot. Returns (pixels, w, h)."""
    im = Image.open(EMB_SRC).convert("RGBA")
    h = int(round(DEV_H))
    w = max(1, int(round(h * im.width / im.height)))
    im = im.resize((w, h), Image.LANCZOS)
    return im.load(), w, h


DEV, DEV_W, DEV_H_PX = _load_device()
DEV_X, DEV_Y = SCX - DEV_W * 0.5, SCY - DEV_H_PX * 0.5


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


def _bronze(lit, rim=0.0):
    c = A.lerp_rgb(BRONZE_DK, BRONZE_MID, _cl(lit))
    if rim > 0.0:
        c = A.lerp_rgb(c, BRONZE_LT, _cl(rim))
    return c


def seal_px(fx, fy):
    ox, oy = fx - SCX, fy - SCY
    r = math.hypot(ox, oy)
    # Surface normal toward the key, reused by every layer so the medallion is lit as ONE object.
    nlit = _cl(0.42 + (-ox * LX - oy * LY) / R_OUT * 0.62)

    # ── scroll bosses: the seats where the medallion bolts to the sign ──
    for s_ in (-1, 1):
        bd = math.hypot(ox - s_ * (R_OUT - 1.0), oy)
        if bd < BOSS_R:
            blit = _cl(0.34 + (-(ox - s_ * (R_OUT - 1.0)) * LX - oy * LY) / BOSS_R * 0.6)
            return A.clamp_rgb(_bronze(blit, rim=_cl(0.85 - bd / BOSS_R) * 0.45)) + (255,)

    if r >= R_OUT:
        # A tight contact shadow so the medallion sits ON the sign rather than over it.
        t = (r - R_OUT) / 2.2
        if t >= 1.0:
            return (0, 0, 0, 0)
        return (0, 0, 0, A.clamp((1.0 - t) ** 1.6 * 150))

    if r >= R_IN:
        # ── the annulus: a bead-and-fillet profile. `crown` rides the ring's rounded top, so
        # the band reads as turned metal rather than a flat washer.
        t = (r - R_IN) / (R_OUT - R_IN)
        crown = 1.0 - abs(t - 0.45) * 2.0
        lit = _cl(nlit * (0.34 + _cl(crown) * 0.92) + 0.10)
        c = _bronze(lit, rim=_cl(crown - 0.40) * (0.9 if nlit > 0.5 else 0.28))
        if t < 0.14:                                       # AO where the ring overhangs the field
            c = A.lerp_rgb(c, (0, 0, 0), (0.14 - t) / 0.14 * 0.5)
        if t > 0.9:                                        # the outer fillet turns away
            c = A.lerp_rgb(c, BRONZE_DK, (t - 0.9) / 0.1 * 0.55)
        return A.clamp_rgb(c) + (255,)

    # ── the recessed field the device is struck on: dark, so the gilt relief reads ──
    c = A.lerp_rgb(BRONZE_DK, BRONZE_MID, _cl(0.26 - r / R_IN * 0.12 + nlit * 0.10))
    c = A.lerp_rgb(c, PATINA, _cl(A.noise(int(fx * 1.3), int(fy * 1.3), 29) * 0.012 + 0.07))
    if r > R_IN - 2.5:                                     # the field's own shadow under the ring
        c = A.lerp_rgb(c, (0, 0, 0), (r - R_IN + 2.5) / 2.5 * 0.45)

    # ── the emblem STRUCK IN RELIEF: a raised plateau with a lit upper-left lip and a
    # shadowed lower-right one. Sampling the mask offset BOTH ways gives both lips, which is
    # what separates a struck medal from lines painted on a disc.
    a, lum = _dev(fx, fy)
    if a > 0.02:
        aul, _ = _dev(fx - 1.1, fy - 1.1)
        adr, _ = _dev(fx + 1.1, fy + 1.1)
        g = adr - aul
        face = A.lerp_rgb(BRONZE_MID, BRONZE_LT, 0.30 + lum * 0.34)
        if g > 0.02:
            face = A.lerp_rgb(face, BRONZE_LT, _cl(g * 1.8) * 0.95)
        elif g < -0.02:
            face = A.lerp_rgb(face, (6, 4, 2), _cl(-g * 1.5) * 0.72)
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
