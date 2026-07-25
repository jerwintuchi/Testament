#!/usr/bin/env python3
"""gen_title_overlays.py — the title scene's atmosphere overlays (TD-073, T260).

Three greyscale-white sheets that the rig lays over the hall with an ADDITIVE material at 20%
(`title_scene.gd` OVERLAYS): hanging dust, incense drift, and one shaft of light. Greyscale-white
because they are tinted at runtime — one asset then serves a warm pass and a cold one, which is
what the asset manifest asks for.

    title/dust_overlay.png    1920x1080   motes hanging in the volume
    title/smoke_overlay.png   1920x1080   incense rising off the censers
    title/light_shaft.png      900x1080   one god-ray wedge through the clerestory

**Alpha carries everything.** RGB is flat white; the image is shaped entirely in the alpha
channel. Under an additive blend that makes the sheet's contribution exactly its alpha, so the
runtime `modulate` is a single honest dimmer and nothing has a colour baked into it.

Each sheet is SPLATTED into an alpha buffer first and only then written, rather than solved per
pixel: a mote field asked per-pixel is O(pixels x motes) and would take minutes for a result that
is identical. Everything is seeded from `ashember`-style integer hashing, so a re-run reproduces
the same sheet byte for byte.

The centre of the frame is deliberately kept thin. The menu is read there (R245), and atmosphere
that crosses the reading area is the difference between mood and noise.

Run from client/assets/ui/:  python3 gen_title_overlays.py
"""
import math
import os

import ashember as A

FW, FH = 640, 360            # the internal resolution: authored at the size it is shown
SW, SH = 300, 360            # the light shaft's own size


def rnd(i, salt):
    """Deterministic 0..1. The generators may not use `random`: a re-run must reproduce."""
    n = (i * 374761393 + salt * 668265263) & 0xFFFFFFFF
    n = (n ^ (n >> 13)) * 1274126177 & 0xFFFFFFFF
    return ((n >> 8) & 0xFFFF) / 65535.0


def quiet(fx, fy):
    """1 in the open frame, falling to ~0.25 over the menu's reading area (R245)."""
    dx = max(0.0, 1.0 - abs(fx - 0.5) / 0.30)
    dy = max(0.0, 1.0 - abs(fy - 0.60) / 0.32)
    return 1.0 - 0.75 * dx * dy


def splat(buf, w, h, cx, cy, r, peak):
    """Add one soft round mote, quadratic falloff, clamped into the buffer."""
    x0, x1 = max(0, int(cx - r)), min(w - 1, int(cx + r))
    y0, y1 = max(0, int(cy - r)), min(h - 1, int(cy + r))
    r2 = r * r
    for y in range(y0, y1 + 1):
        row = y * w
        dy2 = (y - cy) ** 2
        for x in range(x0, x1 + 1):
            d2 = (x - cx) ** 2 + dy2
            if d2 < r2:
                v = buf[row + x] + int(peak * (1.0 - d2 / r2) ** 2)
                buf[row + x] = 255 if v > 255 else v


# ── Dust: motes hanging in the volume ────────────────────────────────────────

def dust_buf():
    """Sparse motes at wildly different sizes. Real dust in a shaft is mostly invisible with a
    few grains catching the light, so a uniform field of identical specks reads as snow."""
    buf = bytearray(FW * FH)
    for i in range(520):
        fx, fy = rnd(i, 11), rnd(i, 13)
        q = quiet(fx, fy)
        if rnd(i, 17) > q:                       # thinned over the menu, not clipped to a box
            continue
        # A few big soft grains, many small hard ones — the size distribution does the work.
        big = 1 if rnd(i, 19) > 0.82 else 0
        peak = int((70.0 + 140.0 * rnd(i, 23)) * q * (0.55 + 0.65 * (1.0 - fy)))
        px_, py_ = int(fx * FW), int(fy * FH)
        for dy in range(big + 1):
            for dx in range(big + 1):
                if 0 <= px_ + dx < FW and 0 <= py_ + dy < FH:
                    buf[(py_ + dy) * FW + px_ + dx] = min(255, peak)
    return buf


# ── Smoke: incense rising off the censers ────────────────────────────────────

def _fbm(x, y, salt):
    """Two octaves of interpolated value noise. Enough for smoke; a third octave is invisible
    once the sheet is drawn at 20% over a dark hall."""
    tot = 0.0
    amp, sc = 1.0, 1.0
    for o in range(2):
        gx, gy = x * sc, y * sc
        ix, iy = int(gx), int(gy)
        tx, ty = gx - ix, gy - iy
        tx = tx * tx * (3.0 - 2.0 * tx)
        ty = ty * ty * (3.0 - 2.0 * ty)
        n00 = rnd(ix * 8191 + iy, salt + o)
        n10 = rnd((ix + 1) * 8191 + iy, salt + o)
        n01 = rnd(ix * 8191 + iy + 1, salt + o)
        n11 = rnd((ix + 1) * 8191 + iy + 1, salt + o)
        tot += amp * ((n00 * (1 - tx) + n10 * tx) * (1 - ty) + (n01 * (1 - tx) + n11 * tx) * ty)
        amp *= 0.5
        sc *= 2.3
    return tot / 1.5


# The censers hang at these frame fractions, so the smoke leaves from under them. A plume that
# starts nowhere in particular is the tell that it was drawn, not lit — which makes this table a
# MIRROR of `title_scene.gd`'s CENSER_LX / CENSER_RX / CENSER_FIRE_Y. Move a censer there and this
# must follow, or the hall smokes from a spot where nothing hangs.
PLUMES = ((0.292, 0.404, 1.00), (0.708, 0.404, 0.92), (0.500, 0.560, 0.55))


def smoke_px(x, y):
    fx, fy = (x + 0.5) / FW, (y + 0.5) / FH
    a = 0.0
    for px_, py_, strength in PLUMES:
        # The column widens and drifts sideways as it rises — smoke does not go straight up.
        rise = py_ - fy
        if rise < -0.04:
            continue
        wob = 0.055 * math.sin(rise * 7.0 + px_ * 40.0) * rise
        wide = 0.035 + 0.30 * max(0.0, rise)
        d = abs(fx - px_ - wob) / wide
        if d > 1.0:
            continue
        body = (1.0 - d * d) ** 2 * max(0.0, 1.0 - rise / 0.62) ** 1.4
        a += strength * body * _fbm(fx * 7.0, fy * 4.0 - rise * 2.2, 31)
    v = a * 210.0 * quiet(fx, fy)
    return 0 if v < 14 else (18 if v < 34 else (30 if v < 58 else 44))


# ── Light shaft: one wedge through the clerestory ────────────────────────────

def shaft_px(x, y):
    fx, fy = (x + 0.5) / SW, (y + 0.5) / SH
    # A wedge falling from the upper left, widening as it descends and dying before the floor:
    # a real shaft is only visible where there is dust to catch it.
    axis = 0.30 + 0.46 * fy
    wide = 0.10 + 0.30 * fy
    d = abs(fx - axis) / wide
    if d > 1.0:
        return 0
    body = (1.0 - d * d) ** 2
    body *= A.smooth(0.0, 0.16, fy) * (1.0 - A.smooth(0.55, 1.0, fy)) ** 1.3
    # THREE flat steps, not a falloff: a smooth cone needs dithering to survive, and dithering is
    # what the brief rules out.
    lvl = 0 if body < 0.18 else (1 if body < 0.42 else (2 if body < 0.72 else 3))
    return (0, 14, 24, 34)[lvl]


def main():
    os.makedirs(os.path.join(os.path.dirname(os.path.abspath(__file__)), "title"), exist_ok=True)

    dust = dust_buf()

    def dust_px(x, y):
        return (255, 255, 255, dust[y * FW + x])

    def smoke(x, y):
        return (255, 255, 255, smoke_px(x, y))

    def shaft(x, y):
        return (255, 255, 255, shaft_px(x, y))

    # LITERAL relative paths, run from client/assets/ui/ (canon S5b): tools/asset_map.py derives
    # producer edges from these strings, so an os.path.join here drops the producer silently.
    A.write_png("title/dust_overlay.png", FW, FH, dust_px)
    A.write_png("title/smoke_overlay.png", FW, FH, smoke)
    A.write_png("title/light_shaft.png", SW, SH, shaft)
    print("gen_title_overlays OK — dust %dx%d, smoke %dx%d, shaft %dx%d (alpha-only)."
          % (FW, FH, FW, FH, SW, SH))


if __name__ == "__main__":
    main()
