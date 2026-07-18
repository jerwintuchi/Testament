#!/usr/bin/env python3
"""gen_header.py — the Contract Board's institutional header (TD-053 / board-header).

Emits one hand-painted raster PNG (canonical register, TD-046), run FROM this dir
(relative filenames):

  board_header.png  204x38  the Contract Board's carved sign, STRAPPED to the wall: vertical
                            iron strap-hinges at both ends carrying bronze bolts, an open
                            plank field between them, a lit top rail and a routed bottom
                            rail. 9-slice-safe (margins 36/11/36/11). Godot draws the
                            engraved Cinzel title over it.

                            This is the WHOLE header — no crowning medallion (TD-058: the
                            sigil was removed and the sign hung at the very top of the board
                            to give the contracts room). Kept to its floor: the title band
                            plus its rails, nothing else. Every px of header costs the two
                            rows of writs ~0.5px each (live_bounds.h = 190 - y - h).

@produces board_header.png
@consumes nothing — the sign is pure SURFACE (grain, rails, forged straps), which is exactly
          the half of the TD-057 split that stays procedural. Aseprite owns sprites; this
          generator owns surfaces.
@why      The PNG is authored at its EXACT on-screen size: the client's internal resolution
          is a fixed 640x360 (PixelScale integer-scales to fill), so BoardGeo.placard_rect is
          deterministic — authoring 1:1 and showing NEAREST avoids the LINEAR-downscale mush
          TD-050 diagnosed. Supersedes board_nameplate.png + crest_v1.png.

Stdlib only (imports ashember); writes via ashember.write_png so the asset-map producer
edge holds. Brand-new PNGs need `godot --headless --import`.
"""
import math

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
# Aged dark walnut. A.RAMP["wood"] alone is a saturated orange-brown that reads as polished
# mahogany — luxurious, the exact note the brief rejects. Blend toward this neutral to age it.
# TD-059: pulled darker so the sign RECEDES into the near-black board (the gilt title, drawn in
# Godot, only gains contrast against it) — "darker but not so much", still warm walnut, not black.
WALNUT = (38, 29, 22)


def _cl(v, a=0.0, b=1.0):
    return max(a, min(b, v))


# ── The carved plaque (248x96, 9-slice) ────────────────────────────────────────
HW, HH = 204, 38
HMX, HMY = 36, 11              # 9-slice patch margins — the end straps live inside these

# The END STRAP: a vertical iron hinge-plate closing each end of the sign — a bar between two
# bolted plates, the fitting the reference hangs the sign from. It must live inside the 9-slice
# margin (HMX=36) so the centre stretch never smears it.
STRAP_W = 26.0                 # how far in from each end the fitting reaches
BAR_X0, BAR_X1 = 7.0, 17.0     # the vertical bar's span, measured in from the end
PLATE_H = 9.0                  # the plate capping the bar top and bottom


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
    return A.lerp_rgb(c, WALNUT, 0.56)                     # age it out of the mahogany register + recede (TD-059)


def _aged(v):
    """A wood-ramp value, aged out of the saturated orange register (see WALNUT)."""
    return A.lerp_rgb(A.ramp_shade("wood", v), WALNUT, 0.56)


WOOD_LIP = A.lerp_rgb(A.RAMP["wood"][4], WALNUT, 0.46)     # the recess's lit lip, desaturated


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
    if fy < 4.0:                                           # top rail: catches the key
        c = A.lerp_rgb(c, WOOD_LIP, 0.30 * (1.0 - fy / 4.0) + 0.14)
    elif fy > HH - 5.0:
        # bottom rail: a routed channel above a lit lip — the reference's decorative under-rail.
        # Kept slim: the sign's plank field has to seat two lines under the medallion's overlap.
        rb = fy - (HH - 5.0)
        if rb < 2.0:
            c = A.lerp_rgb(c, (8, 6, 4), 0.62)             # the cut channel
        elif rb < 3.5:
            c = A.lerp_rgb(c, WOOD_LIP, 0.34)              # the lip below it
        else:
            c = A.lerp_rgb(c, (8, 6, 4), 0.30)
    # A soft vertical falloff: the sign is lit from above, so its foot sits in its own shade.
    c = A.lerp_rgb(c, (8, 6, 4), _cl((fy / HH - 0.35) * 0.34))
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
    if ascii_only:
        print("=== board_header ===\n" + _ascii(HW, HH, plaque))
        return
    A.write_png("board_header.png", HW, HH, plaque)
    print("wrote board_header.png (%dx%d)" % (HW, HH))


if __name__ == "__main__":
    import sys
    main(ascii_only=("--ascii" in sys.argv))
