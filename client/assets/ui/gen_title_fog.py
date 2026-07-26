#!/usr/bin/env python3
"""gen_title_fog.py — the title scene's three parallax fog banks (TD-077, T283).

    title/fog_far.png    1440x720   thin and high, and the sanctuary's warm depth haze
    title/fog_mid.png    1440x720   the working bank across the nave
    title/fog_near.png   1440x720   heavy ground fog over the flags

**Why three sheets and not one.** The hall is a flat painted plate, so it has no depth of its own to
parallax. Moving the plate would expose that immediately (R246/R267) — but moving fog *against other
fog* does not, because the only thing the eye can compare is one bank to another. Three banks at
three speeds is therefore the entire depth cue, and none of them touches the architecture (P132).

**1440 wide for a 1280 frame.** Each bank drifts up to +-80px; at frame width the leading edge would
walk into view and announce itself as a sheet. The extra 160px is exactly that headroom.

**Alpha carries everything**, as with the other overlays: RGB is flat white and the image lives in
the alpha channel, so under the rig's additive blend the contribution IS the alpha and `modulate`
stays an honest dimmer plus a tint. That is also how `fog_far` becomes *warm* haze without a second
asset — the sheet is neutral, the rig tints it.

**Four alpha steps, never a falloff.** A continuous gradient at this scale needs dithering to
survive, and dithering is what the author's brief rules out. So every sheet is quantised to four
levels, and the bands are what makes it read as painted fog rather than as a blur.

Run from client/assets/ui/:  python3 gen_title_fog.py
"""
import math
import os

import ashember as A

W, H = 1440, 720


def rnd(i, salt):
    """Deterministic 0..1. The generators may not use `random`: a re-run must reproduce."""
    n = (i * 374761393 + salt * 668265263) & 0xFFFFFFFF
    n = (n ^ (n >> 13)) * 1274126177 & 0xFFFFFFFF
    return ((n >> 8) & 0xFFFF) / 65535.0


def fbm(x, y, salt, octaves=3):
    """Interpolated value noise. Three octaves is the point where a fourth stops being visible
    through four alpha steps — measured, not assumed: the fourth changes no band boundary."""
    tot, amp, sc, norm = 0.0, 1.0, 1.0, 0.0
    for o in range(octaves):
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
        norm += amp
        amp *= 0.52
        sc *= 2.17
    return tot / norm


def quiet(fx, fy):
    """1 in the open frame, falling over the menu's reading area (R245). The same shape the other
    overlays use — atmosphere that crosses the reading area is the difference between mood and
    noise, and three fog banks are the most likely thing yet to cross it."""
    dx = max(0.0, 1.0 - abs(fx - 0.5) / 0.32)
    dy = max(0.0, 1.0 - abs(fy - 0.58) / 0.30)
    return 1.0 - 0.80 * dx * dy


def band(v, steps):
    """Quantise to `steps` alpha levels. Banded, never smooth."""
    for lo, out in steps:
        if v < lo:
            return out
    return steps[-1][1]


# ── the three banks ──────────────────────────────────────────────────────────
# Each is `body(fx, fy)` in 0..1 before banding: where this bank has substance at all.

def nave(fx):
    """Weight toward the depth of the nave and away from the frame's edges. The near piers are the
    CLOSEST thing in the picture; hazing them is what made the first pass read as a milky film laid
    over the hall rather than as air standing in the distance."""
    return max(0.0, 1.0 - (abs(fx - 0.5) / 0.46) ** 2.1)


def far_body(fx, fy):
    """Thin, high, small-scale — and the sanctuary's warm depth haze. Baked in rather than added as
    a layer of its own: it IS fog, and one fewer slot is one fewer thing to keep in sync."""
    veil = fbm(fx * 5.2, fy * 3.4, 101) * A.smooth(0.92, 0.30, fy) * nave(fx)
    # The haze: a soft pool at the sanctuary arch, so the nave recedes into light instead of
    # stopping at a wall. Below the menu, deliberately (the reading area is above it).
    d = math.hypot((fx - 0.5) / 0.26, (fy - 0.845) / 0.13)
    haze = max(0.0, 1.0 - d) ** 1.6
    return min(1.0, veil * 0.62 + haze * 0.95)


def mid_body(fx, fy):
    """The working bank: a drift across the nave at the height of the arcade."""
    v = fbm(fx * 3.1 + 4.0, fy * 2.2, 211)
    v *= A.smooth(0.34, 0.62, fy) * (1.0 - A.smooth(0.86, 1.0, fy)) * nave(fx)
    return v


def near_body(fx, fy):
    """Ground fog: heavy, low, large-scale, and the fastest of the three because it is closest."""
    v = fbm(fx * 1.9 + 9.0, fy * 1.5, 331)
    v = v * 0.7 + 0.3                                   # a floor, so the bank is continuous
    v *= A.smooth(0.74, 0.99, fy) * (0.45 + 0.55 * nave(fx))
    return v


BANKS = (
    # name,           body,      threshold steps (value < lo -> alpha)
    ("fog_far.png",  far_body,  ((0.34, 0), (0.48, 5), (0.62, 10), (0.78, 16), (9, 24))),
    ("fog_mid.png",  mid_body,  ((0.32, 0), (0.46, 6), (0.60, 12), (0.76, 19), (9, 27))),
    ("fog_near.png", near_body, ((0.40, 0), (0.54, 7), (0.68, 14), (0.82, 22), (9, 31))),
)


def sheet(body, steps):
    def px(x, y):
        # The sheet is WIDER than the frame, so map x through the frame's own 0..1 — otherwise the
        # noise scale would differ between banks and the drift headroom would stretch the fog.
        fx = (x + 0.5) / W
        fy = (y + 0.5) / H
        v = body(fx, fy)
        a = band(v, steps)
        if a:
            a = int(a * quiet(fx, fy))
        return (255, 255, 255, a)
    return px


def main():
    os.makedirs(os.path.join(os.path.dirname(os.path.abspath(__file__)), "title"), exist_ok=True)
    for name, body, steps in BANKS:
        # LITERAL relative paths, run from client/assets/ui/ (canon S5b): tools/asset_map.py derives
        # producer edges from these strings, so an os.path.join here drops the producer silently.
        A.write_png("title/" + name, W, H, sheet(body, steps))
        print("  %-14s %dx%d" % (name, W, H))
    print("gen_title_fog OK — three banks, alpha-only, four steps each.")


if __name__ == "__main__":
    main()
