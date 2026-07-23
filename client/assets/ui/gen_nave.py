#!/usr/bin/env python3
"""gen_nave.py — the title screen's held image: THE EMPTY NAVE (TD-071 / TD-072).

A High Gothic nave seen from the floor, looking up: compound piers rising as bundles of
colonnettes, three storeys of pointed openings (arcade / triforium / clerestory), a ribbed
quadripartite vault whose bosses chain away overhead, and a far end that glows.

STRUCTURE is taken from the author's Chartres reference — the angle, the verticality, the
bones. The LOOK is the design bible's, not the photograph's (TD-072): warm, weathered, aged,
and dramatically torch-lit, authored from the shipped Ash & Ember ramps with no additions.
Chartres is a daylight building whose drama is sun through glass; ours is a firelit one, so
FIRE is the key here and the cold shaft is only TD-043's warm/cool counterpoint.

Deliberately EMPTY. No character, creature, weapon, effect or furniture ever enters this
image — a title screen showing an Incarnate would leak the mystery the whole game is built on
(Pillar 3), and combat imagery would advertise the failure state. The reference's chairs are
not reproduced: they clutter the frame and date the space.

Geometry is a real one-point projection, not a painted fake: every pixel is ray-cast from the
vanishing point onto floor / vault / side wall, carrying a depth `z` and a surface coordinate,
so bays, ribs and flags all converge from the same arithmetic.

Run from client/assets/ui/:  python3 gen_nave.py  ->  title/nave.png
"""
import math
import os

import ashember as A

W, H = 640, 360

# ── The camera (R238) ────────────────────────────────────────────────────────
# The vanishing point sits LOW, so the viewer looks UP the vault and it owns the frame's
# upper half. At eye level the same geometry is merely a corridor.
VPX, VPY = 0.5, 0.66
HALF_W = 0.235            # hall half-width at the near plane
UP = 0.72                 # vault height above the vanishing line, at the near plane
DOWN = 0.34               # floor depth below it
# Height/width ≈ 2.3 : tall and narrow, which is what makes stone read as drawn upward.

BAY = 0.62                # bay length in half-widths — the arcade's rhythm
K_LANCET = 0.55           # two-centred arch: a lancet, not a wide Tudor arch

H_FLOOR = DOWN / HALF_W           # wall height coordinate at the floor  (+1.45)
H_VAULT = -UP / HALF_W            # …and at the vault springing          (-3.06)

BLACK = (7, 6, 8)


def lancet(dp, half, springing):
    """Head height of a two-centred pointed arch at |dp| from the opening's centre.

    Each half is an arc struck from the OPPOSITE springing point, so the two meet at an apex
    instead of closing as a semicircle. Height is negative-upward, like `h` below.
    """
    r = half * (1.0 + K_LANCET)
    dx = dp + half * K_LANCET
    return springing - math.sqrt(max(0.0, r * r - dx * dx))


# ── The three storeys, in wall-height units (negative is up) ─────────────────
ARC_SPRING, ARC_HALF = -0.30, 0.36              # main arcade
TRI_LO, TRI_HI, TRI_HALF = -1.30, -1.62, 0.13   # triforium band
CLR_SPRING, CLR_HALF = -2.05, 0.20              # clerestory (the glazed storey)

# ── Fire (R236). Braziers stand in the aisles at bay intervals: the KEY light. ──
BRAZIERS = [(side * 0.86, z) for z in (1.15, 1.95, 3.1, 4.9) for side in (-1, 1)]


def _braziers_screen():
    """Project each brazier to screen space once, with a perspective radius and intensity."""
    out = []
    for cross, z in BRAZIERS:
        fx = VPX + cross * HALF_W / z
        fy = VPY + (H_FLOOR - 0.12) * HALF_W / z
        rad = 0.30 * HALF_W / z            # nearer flames pool wider
        inten = min(1.0, 0.55 / (z * 0.55))
        out.append((fx, fy, rad, inten))
    return out


BZ = _braziers_screen()


def _firelight(fx, fy):
    """Summed warm falloff from every brazier. This is the image's key light."""
    tot = 0.0
    for bx, by, rad, inten in BZ:
        dx = (fx - bx) / (rad * 3.2)
        dy = (fy - by) / (rad * 2.1)       # pools wider than tall: light lying on flags
        d2 = dx * dx + dy * dy
        if d2 < 1.0:
            tot += inten * (1.0 - d2) ** 2
    return min(1.35, tot)


def _farglow(fx, fy):
    """The hall's far end. Depth reads as LUMINANCE (TD-072): the near is darkest and the
    distance opens into light, so near piers fall to silhouette against it."""
    dx = (fx - VPX) / 0.115
    dy = (fy - VPY + 0.015) / 0.085
    return max(0.0, 1.0 - A.smooth(0.0, 1.0, math.sqrt(dx * dx + dy * dy))) ** 1.5


def _shaft(fx, fy):
    """The cold counterpoint (TD-043) — a pale shaft through a high clerestory lancet. Dimmer
    than the fire and no longer the source of the image."""
    cx = 0.335 + 0.30 * (0.80 - fy)
    d = abs(fx - cx) / 0.085
    if d >= 1.0:
        return 0.0
    return (1.0 - d * d) ** 2.4 * A.smooth(0.0, 0.26, fy) * (1.0 - 0.6 * A.smooth(0.5, 0.95, fy))


_DITHER = ((0, 8, 2, 10), (12, 4, 14, 6), (3, 11, 1, 9), (15, 7, 13, 5))


def _dither(base, x, y):
    """Break a smooth falloff so a stepped ramp does not band it into contour rings."""
    k = (_DITHER[y & 3][x & 3] / 16.0 - 0.5) * 8.0
    return (base[0] + k, base[1] + k, base[2] + k)


def nave_px(x, y):
    fx, fy = (x + 0.5) / W, (y + 0.5) / H
    u, v = fx - VPX, fy - VPY
    rx = abs(u) / HALF_W
    ry = (v / DOWN) if v >= 0 else (-v / UP)

    if max(rx, ry) < 0.055:
        # The far end: not a wall, an opening full of light.
        base = A.ramp_shade("stone", 0.55)
    elif rx >= ry:
        # ── Side wall: compound piers and three storeys of pointed openings ──
        au = max(abs(u), 1e-5)
        z = HALF_W / au                             # depth
        h = v / au                                  # wall height, negative-upward
        p = (z / BAY) % 1.0
        dp = abs(p - 0.5)
        base = A.ramp_shade("stone", 0.10 + 0.16 * min(1.0, 1.4 / z))

        arc_head = lancet(dp, ARC_HALF, ARC_SPRING) if dp < ARC_HALF else 0.0
        clr_head = lancet(dp, CLR_HALF, CLR_SPRING) if dp < CLR_HALF else 0.0
        in_arcade = dp < ARC_HALF and arc_head < h < H_FLOOR
        in_clere = dp < CLR_HALF and clr_head < h < CLR_SPRING
        in_trif = dp < TRI_HALF and TRI_HI < h < TRI_LO

        if in_arcade:
            # Through into the dark side aisle — the deepest value in the image.
            base = A.lerp_rgb(BLACK, A.RAMP["stone"][0], 0.10 * min(1.0, 1.6 / z))
        elif in_clere:
            # Glazing. Jewelled from ramps already in hand (R235): no foreign palette.
            mull = abs(((dp / (CLR_HALF * 0.5)) % 1.0) - 0.5)   # stone mullions divide the light
            lit = min(1.0, 1.5 / z)
            base = A.lerp_rgb(BLACK, A.RAMP["stone"][3], 0.30 + 0.22 * lit)
            if mull > 0.40:
                base = A.over(base, A.RAMP["stone"][1], 0.60)
        elif in_trif:
            base = A.lerp_rgb(BLACK, A.RAMP["stone"][0], 0.22)
        else:
            # Pier face. Quantised into colonnettes, each shaded as a half-round: this is what
            # turns a flat wall into a BUNDLE OF SHAFTS, which is the whole Gothic read.
            shafts = 5.0
            sp = (dp * shafts) % 1.0
            round_ = math.sin(sp * math.pi)                 # half-cylinder across each shaft
            base = A.over(base, A.RAMP["stone"][2], 0.34 * round_)
            if sp < 0.10 or sp > 0.90:
                base = A.over(base, BLACK, 0.42)            # the seam between shafts
            # Capitals at the arcade springing, and a string-course under the clerestory.
            if abs(h - ARC_SPRING) < 0.055 or abs(h - (TRI_LO + 0.06)) < 0.035:
                base = A.over(base, A.RAMP["stone"][3], 0.45)
            base = A.over(base, A.RAMP["stone"][0], 0.05 * (A.noise(x, y // 3, 7) + 8) / 16.0)
    elif v >= 0:
        # ── Floor: worn flags, courses across the hall, joints running away ──
        z = DOWN / max(v, 1e-5)
        cross = u / max(v, 1e-5) * DOWN / HALF_W
        base = A.ramp_shade("stone", 0.07 + 0.10 * min(1.0, 1.5 / z))
        if abs(((z / 0.42) % 1.0) - 0.5) > 0.455 or abs(((cross / 0.5) % 1.0) - 0.5) > 0.462:
            base = A.over(base, BLACK, 0.55)
        else:
            base = A.over(base, A.RAMP["stone"][0], 0.05 * (A.noise(x // 2, y // 2, 11) + 8) / 16.0)
    else:
        # ── Vault: ribbed quadripartite bays, bosses chaining away overhead ──
        nv = max(-v, 1e-5)
        z = UP / nv
        cross = u / nv * UP / HALF_W                # -1..1 across the vault
        a = (z / BAY) % 1.0
        base = A.ramp_shade("stone", 0.05 + 0.09 * min(1.0, 1.3 / z))
        diag = abs(abs(cross) - abs(2.0 * a - 1.0))     # the crossing diagonals
        trans = min(a, 1.0 - a)                          # the bay division
        ridge = abs(cross)
        rw = 0.030 + 0.030 / max(1.0, z)                 # ribs thin with distance
        fade = max(0.0, min(1.0, 1.9 / z - 0.55))        # ribs resolve near, then the dark takes it
        base = A.over(base, BLACK, 0.62)                 # webs sit deep — this is a dark ceiling
        if diag < rw or trans < rw * 0.5:
            base = A.over(base, A.RAMP["stone"][2], 0.30 * fade)   # rib, catching a little light
            if diag < rw * 0.5 and abs(a - 0.5) < 0.08:
                base = A.over(base, A.RAMP["stone"][3], 0.28 * fade)   # the boss where they cross
        elif ridge < rw * 0.35:
            base = A.over(base, A.RAMP["stone"][1], 0.22 * fade)   # ridge rib, quiet

    # ── Light. Fire is the key; the far end opens; the shaft is the cold accent. ──
    fire = _firelight(fx, fy)
    far = _farglow(fx, fy)
    cold = _shaft(fx, fy)

    base = A.over(base, A.lerp_rgb(A.RAMP["stone"][3], A.RAMP["parchment"][2], 0.35),
                  min(0.62, far * 0.62))
    if cold > 0.0:
        base = A.over(base, A.RAMP["stone"][4], min(0.20, cold * 0.20))
    if fire > 0.0:
        warm = A.RAMP["flame"][1] if fire > 0.5 else A.RAMP["gold"][2]
        base = A.over(base, warm, min(0.72, fire * 0.55))
    # The flames themselves, drawn last so nothing washes them out.
    for bx, by, rad, inten in BZ:
        dx = (fx - bx) / max(rad * 0.30, 1e-5)
        dy = (fy - by + rad * 0.18) / max(rad * 0.55, 1e-5)
        if dx * dx + dy * dy < 1.0:
            base = A.FLAME_PALE

    v_ = max(abs(fx - 0.5) / 0.5, abs(fy - 0.5) / 0.5)
    base = A.lerp_rgb(base, BLACK, 0.60 * A.smooth(0.60, 1.08, v_))
    r, g, b = A.quantize(_dither(base, x, y))
    return (r, g, b, 255)


if __name__ == "__main__":
    os.makedirs(os.path.join(os.path.dirname(os.path.abspath(__file__)), "title"), exist_ok=True)
    A.assert_on_palette(W, H, nave_px, "title/nave.png")
    # A LITERAL relative path, run from client/assets/ui/ (canon S5b): tools/asset_map.py derives
    # producer edges from this string, so an os.path.join here silently drops nave.png's producer.
    A.write_png("title/nave.png", W, H, nave_px)
    print("gen_nave OK — the empty nave, %dx%d, existing ramps only." % (W, H))
