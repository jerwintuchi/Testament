#!/usr/bin/env python3
"""gen_title_hall.py — the Collegium's Great Hall, authored as PIXEL ART (TD-075).

    title/hall_plate.png   640x360, on-palette, shown 1:1 at integer scale

Replaces the painterly plate. The author's ruling: the Contract Board is the visual authority, and
where the concept art and the board disagree, **the board wins**. The board is authored at the
canonical 640x360 internal resolution and displayed 1:1 through NEAREST at an integer scale, so its
pixels are square, hard-edged and on a curated ramp. A 1920x1080 plate squeezed 3:1 through a LINEAR
filter cannot match that no matter how it is shaded — the register is decided by the pipeline, not
by the brushwork.

So this generator inverts every habit the painted plate had:

  * **Authored at 640x360**, the size it is displayed at. No downscale, no resampling.
  * **Every colour is a ramp entry.** Shading picks an INDEX into an Ash & Ember ramp — never a
    lerp between two arbitrary colours. `A.assert_on_palette` proves it, which is the same check
    the board's own art passes and the reason the two sit together.
  * **Banded light, not gradients.** A candle's pool is two or three flat steps, the way a pixel
    artist paints one. Nothing fades continuously, so nothing needs dithering to hide banding.
  * **No per-pixel noise.** Variation is per BLOCK — a course of masonry may sit a shade darker
    than its neighbour, which reads as hand-placed stone. Per-pixel jitter reads as film grain and
    is the loudest "generated" tell there is.
  * **Detail is gated by distance.** Joints stop being drawn once a course projects under ~2px, so
    the far nave stays quiet and large stone surfaces read as large stone surfaces.

Structure — the bays, the elevation, the convergence — still comes from the camera TD-072 measured
(imported from `gen_nave`, hfov 105 deg, pitched up 15 deg). That was always correct; it is only
the RENDER that was wrong.

Run from client/assets/ui/:  python3 gen_title_hall.py
"""
import math
import os

import ashember as A
import pngio
from gen_nave import (ARC_HALF, ARC_SPRING, BAY, CLR_HALF, CLR_SPRING, HALF_W, TRI_HI, TRI_LO,
                      Z_FAR, hit, lancet, project, ray)

W, H = 640, 360                  # the canonical internal resolution (TD-042), shown 1:1

# The nave is SHORTENED from the ray-caster's 115m. At that depth the far wall projects 35px wide
# and the sanctuary is a smudge; Reference A's altar reads as a destination you could walk to. The
# camera is unchanged — only how far away the hall closes. `hit` reads this at call time.
import gen_nave
gen_nave.Z_FAR = 58.0

# And the camera is pitched FURTHER UP, 15 deg -> 21. Reference A puts the vault across the top
# 40% of the frame and the altar low, around two thirds down; at 15 deg our sanctuary landed at
# 0.37 — directly behind the title. More pitch drops the far wall, opens the vault above it, and
# hands the middle of the frame back to the UI (R245). The lens is unchanged; only the tilt.
gen_nave.PITCH = math.radians(21.0)
gen_nave.SINP = math.sin(gen_nave.PITCH)
gen_nave.COSP = math.cos(gen_nave.PITCH)

EMB_SRC = "board/collegium_logo.png"
EMB_W = 44                       # the crest on the far wall, in pixels


def ramp(name, i):
    """The ONLY way a colour is chosen here: an index into a shipped ramp."""
    r = A.RAMP[name]
    return r[max(0, min(len(r) - 1, int(i)))]


CRIMSON = (A.RAMP["black"][1], A.RAMP["black"][2], A.RAMP["wax"][0], A.RAMP["wax"][1])


def crimson(i):
    return CRIMSON[max(0, min(len(CRIMSON) - 1, int(i)))]


def blk(i, j, salt=0):
    """Per-BLOCK variation, -1/0/+1. Never per pixel: a stone varies, a pixel does not."""
    n = A.noise(int(i), int(j), salt)
    return -1 if n < -4 else (1 if n > 4 else 0)


# ── Light. Flat steps, the way a pixel artist paints a candle ────────────────
# (fx, fy, radius in frame widths, how many ramp steps it lifts at the centre)
LIGHTS = (
    (0.500, 0.560, 0.150, 2),    # the altar at the end of the nave — the eye's destination
    (0.118, 0.735, 0.082, 2),    # the near candle tables, left and right
    (0.882, 0.735, 0.082, 2),
    (0.300, 0.660, 0.070, 1),    # a pair further down the aisles
    (0.700, 0.660, 0.070, 1),
    (0.500, 0.300, 0.130, 1),    # the great window over the sanctuary
)


def light(fx, fy):
    """How many ramp steps this point is lifted, as an INTEGER. Two or three flat rings per
    source: the moment this returns a float, the image needs dithering and stops being pixel art."""
    best = 0
    for lx, ly, r, k in LIGHTS:
        d = math.hypot((fx - lx), (fy - ly) * (H / float(W)) * (W / float(H)) * 0.62)
        if d < r:
            step = k if d < r * 0.45 else (k - 1 if d < r * 0.75 else 0)
            if step > best:
                best = step
    return best


def vignette(fx, fy):
    """Corners fall away in steps, so the frame's edges stay quiet under the UI."""
    v = max(abs(fx - 0.5) / 0.5, abs(fy - 0.5) / 0.5)
    if v > 1.00:
        return 2
    if v > 0.74:
        return 1
    return 0


def depth_band(dist):
    """Distance in four steps. Depth reads as luminance, but in bands, never as a fade."""
    if dist < 13.0:
        return 0
    if dist < 27.0:
        return 1
    if dist < 52.0:
        return 2
    return 3


def course_visible(dist):
    """Draw a masonry joint only while a course is thicker than ~2px on screen. Past that it is
    noise pretending to be detail, and it is what makes generated stone look like static."""
    return (0.85 / max(dist, 0.1)) * (H / (2.0 * 0.733)) > 2.2


# ── The crest, read once and thresholded (never smoothly resampled) ──────────

def _emblem():
    w, h, px = pngio.read_png(EMB_SRC)
    scale = w / float(EMB_W)
    eh = int(h / scale)
    out = []
    for y in range(eh):
        row = []
        for x in range(EMB_W):
            # Box-average the source, then THRESHOLD into three levels. A smooth resample would
            # hand back grey mush at this size — the same lesson TD-054 recorded for the medallion.
            x0, x1 = int(x * scale), max(int(x * scale) + 1, int((x + 1) * scale))
            y0, y1 = int(y * scale), max(int(y * scale) + 1, int((y + 1) * scale))
            tot = n = 0.0
            for yy in range(y0, min(y1, h)):
                for xx in range(x0, min(x1, w)):
                    r, g, b, a = px(xx, yy)
                    if a > 96:
                        tot += (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
                        n += 1
            cover = n / max(1.0, (x1 - x0) * (y1 - y0))
            row.append(0 if cover < 0.34 else (1 if (tot / max(n, 1.0)) < 0.55 else 2))
        out.append(row)
    return out, EMB_W, eh


def _apse_box():
    """Where the far wall actually lands on screen, scanned at 2px. Placement is derived."""
    x0, y0, x1, y1 = W, H, -1, -1
    for y in range(0, H, 2):
        for x in range(0, W, 2):
            if hit((x + 0.5) / W, (y + 0.5) / H)[0] == "apse":
                x0, y0 = min(x0, x), min(y0, y)
                x1, y1 = max(x1, x), max(y1, y)
    return x0, y0, x1, y1


APSE_X0, APSE_Y0, APSE_X1, APSE_Y1 = _apse_box()
EMB, EMB_PW, EMB_PH = _emblem()
# The far wall lands at fy 0.38-0.78 — the exact column the title, the rule and the menu occupy.
# So the crest does NOT hang there: a pale device behind the lettering fights the UI, and R245 gives
# the centre of this frame to the interface. The brief asks for the crest on the BANNERS, and that
# is where it stays. Set CREST_ON_WALL to put it back; the seat is derived, so it will land right.
CREST_ON_WALL = False
EMB_X0 = (APSE_X0 + APSE_X1) // 2 - EMB_PW // 2
EMB_Y0 = APSE_Y0 + int((APSE_Y1 - APSE_Y0) * 0.16)


# ── Surfaces ─────────────────────────────────────────────────────────────────

def _wall(fx, fy, a, b, dist, side, x, y):
    h_m = b
    loc = (a / BAY) % 1.0
    dp = abs(loc - 0.5) * BAY
    bi = int(a / BAY)
    # Depth bands PER BAY, not per pixel. Banding on raw distance drew a straight diagonal across
    # the frame wherever the band changed — a huge flat slab with an edge that belongs to nothing,
    # which is what kept ghosting on the piers. A bay is a real architectural unit, so its edges
    # are the pier faces and a change of tone there reads as construction, not as a seam.
    db = depth_band(math.hypot((bi + 0.5) * BAY, HALF_W))

    # Openings. Bay widths differ side to side so the arcade is not a mirror.
    arc_half = ARC_HALF * (0.94 + 0.06 * (blk(bi, side, 23) + 1))
    clr_half = CLR_HALF * (0.96 + 0.04 * (blk(bi, side, 29) + 1))

    if dp < arc_half and h_m < lancet(dp, arc_half, ARC_SPRING) and h_m > 0.4:
        # Into the aisle: near-black, lifting a step in the far bays so the arches read as
        # openings into a space rather than as holes cut in a wall.
        return ramp("navestone", max(0, db - 2))

    if dist > 9.0 and dp < clr_half and CLR_SPRING < h_m < CLR_SPRING + 5.2:
        # ── Stained glass: the hall's own light. Flat panes, hard mullions. ──
        # ONE mullion, not a grid: at this distance the wall is grazing, so a pane is only a few
        # pixels across and a fine tracery collapses into noise.
        mull = abs(((dp / (clr_half * 0.85)) % 1.0) - 0.5)
        if mull > 0.42:
            return ramp("navestone", 1)                       # stone mullion
        tint = blk(bi, side, 17)
        if tint < 0:
            return ramp("wax", 2)                             # a crimson light
        if tint > 0:
            return ramp("parchment", max(2, 4 - db))          # bone-bright
        return ramp("gold", max(2, 3 - db))                   # warm amber

    if dist > 9.0 and dp < 0.95 and TRI_LO < h_m < TRI_HI:
        return ramp("navestone", 1)                           # the triforium band, kept quiet

    # ── Pier face: a bundle of shafts, read as flat vertical strips ──
    # A candle lights the foot of a wall, not its clerestory. Without this the pools read as
    # pale ghosts hanging on the masonry.
    lit = light(fx, fy) if h_m < 5.0 else 0
    idx = 2 - db + lit - vignette(fx, fy)
    if dist > 6.0:
        sp = (dp / 0.95) % 1.0
        if sp < 0.10 or sp > 0.90:
            idx -= 1                                          # the seam between two shafts
        elif 0.34 < sp < 0.62:
            idx += 1                                          # the lit round of the shaft
    if abs(h_m - ARC_SPRING) < 0.55 or abs(h_m - TRI_HI) < 0.35 or abs(h_m - CLR_SPRING) < 0.40:
        idx += 1                                              # capitals and string-courses
    if course_visible(dist) and dist > 12.0:
        ch = 0.85
        course = h_m / ch
        bed = abs((course % 1.0) - 0.5)
        perp = abs(((a / 1.7 + 0.5 * (int(course) % 2)) % 1.0) - 0.5)
        if bed > 0.46 or perp > 0.48:
            idx -= 1                                          # the joint
        else:
            if dist > 17.0:
                idx += blk(int(course), int(a / 1.7), 11)     # one stone darker than its neighbour
    # Soot: the wall remembers every candle. A step, not a gradient.
    if h_m < 3.2 and db < 2:
        idx -= 1                                              # soot at the foot of the wall
    return ramp("navestone", idx)


def _vault(fx, fy, a, b, dist):
    cross = b / HALF_W
    loc = (a / BAY) % 1.0
    db = depth_band(dist)
    idx = 1 - min(1, 2 - db) - vignette(fx, fy)
    rw = 0.085
    diag = abs(abs(cross) - abs(2.0 * loc - 1.0))
    # Ribs only while a bay is still big on screen. Drawn all the way down the nave they stopped
    # reading as a vault and became a truss — a lattice of thin lines is the enemy of "immense".
    if course_visible(dist * 2.0):
        if diag < rw or min(loc, 1.0 - loc) < rw * 0.45:
            idx += 1
            if diag < rw * 0.5 and abs(loc - 0.5) < 0.10:
                idx += 1                                      # the boss where they cross
        elif abs(cross) < rw * 0.4:
            idx += 1                                          # ridge rib
    if abs(cross) < 0.55:
        idx -= 1                                              # centuries of smoke along the crown
    return ramp("navestone", max(0, idx))


def _floor(fx, fy, a, b, dist):
    db = depth_band(dist)
    idx = 2 - min(2, db) + light(fx, fy) - vignette(fx, fy)

    if abs(b) < 1.05:
        # The runner. Narrow, and lit only where it passes a light — a broad bright wedge across
        # the foreground was the first pass's loudest mistake: it fought the UI and out-saturated
        # a hall whose whole point is restraint.
        if abs(abs(b) - 1.32) < 0.10 and light(fx, fy) > 0:
            return ramp("gold", 1)                            # a dulled border, only where lit
        ci = 2 + light(fx, fy) - vignette(fx, fy)
        if abs(b) < 0.45 and light(fx, fy) > 1:
            ci += 1                                           # the worn spine, under a light
        return crimson(ci)

    if course_visible(dist * 1.4):
        if abs(((a / 1.9) % 1.0) - 0.5) > 0.455 or abs(((b / 1.9) % 1.0) - 0.5) > 0.455:
            idx -= 1                                          # flag joints
        elif dist > 14.0 and blk(int(a / 1.9), int(b / 1.9), 33) < 0:
            idx -= 1                                          # a ledger slab, sunk darker
    return ramp("navestone", max(0, idx))


def _apse(fx, fy, a, b, x, y):
    """The sanctuary: an elevated altar, a great crest above it, tall lancets flanking."""
    ex, ey = x - EMB_X0, y - EMB_Y0
    if CREST_ON_WALL and 0 <= ex < EMB_PW and 0 <= ey < EMB_PH:
        v = EMB[ey][ex]
        if v:
            return ramp("navestone", 4 if v == 1 else 6)      # the crest, in pale worn stone

    if abs(b) < 3.1 and 12.0 < a < lancet(abs((b + 3.1) % 2.05 - 1.03), 0.80, 21.0):
        mull = abs(((b + 3.1) / 2.05) % 1.0 - 0.5)
        if mull > 0.38:
            return ramp("navestone", 1)
        return ramp("gold", 1)                                # the lancets behind the altar

    idx = 1 + light(fx, fy) - vignette(fx, fy)
    if a < 3.4:
        # The altar platform: three steps, worn pale along the tread the order has walked.
        step = int(a / 1.1)
        idx = 2 + step - vignette(fx, fy)
        if abs(a - 1.1 * step) < 0.16:
            idx += 1
    return ramp("navestone", max(0, idx))


def hall_px(x, y):
    fx, fy = (x + 0.5) / W, (y + 0.5) / H
    kind, a, b, dist = hit(fx, fy)
    if kind == "wall":
        side = -1 if ray(fx, fy)[0] < 0.0 else 1
        c = _wall(fx, fy, a, b, dist, side, x, y)
    elif kind == "vault":
        c = _vault(fx, fy, a, b, dist)
    elif kind == "floor":
        c = _floor(fx, fy, a, b, dist)
    else:
        c = _apse(fx, fy, a, b, x, y)
    return (c[0], c[1], c[2], 255)


if __name__ == "__main__":
    os.makedirs(os.path.join(os.path.dirname(os.path.abspath(__file__)), "title"), exist_ok=True)
    # The named test: every pixel is a curated Ash & Ember entry, exactly as the board's own art
    # is. This is what "matches the Contract Board" means in a form a machine can check.
    A.assert_on_palette(W, H, hall_px, "title/hall_plate.png")
    # A LITERAL relative path, run from client/assets/ui/ (canon S5b).
    A.write_png("title/hall_plate.png", W, H, hall_px)
    print("gen_title_hall OK — the Great Hall, %dx%d, on-palette, 1:1." % (W, H))
