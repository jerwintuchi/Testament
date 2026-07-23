#!/usr/bin/env python3
"""gen_nave.py — the title screen's held image: THE EMPTY NAVE (TD-071 / R231).

A dark stone hall receding into black: an arcade of arched bays down each side, a floor of
worn flags running away from the viewer, ONE broad shaft of pale light falling across the
hall from an unseen high window, and ONE lit candle standing on the flags.

Deliberately EMPTY. No character, creature, weapon or effect ever enters this image — a
title screen showing an Incarnate would leak the mystery the whole game is built on
(Pillar 3), and combat imagery would advertise the failure state (the order's aims are
witness, contain, redeem). The quiet screen is the canonical one, not merely the pretty one.

Surfaces + light only, so this is Python's half of the TD-057 split — no Aseprite, no figure
work. Authored at the canonical internal resolution (640x360, TD-042) and drawn NEAREST at an
integer scale, centred, with the image's own near-black filling the rest.

Geometry is a real one-point corridor projection, not a painted fake: every pixel casts a ray
from the vanishing point and is resolved to floor / ceiling / side wall / far wall, with a
depth `t` that drives perspective spacing. That is what makes the bays and flags converge
consistently instead of reading as vertical bars.

Run from client/assets/ui/:  python3 gen_nave.py  ->  title/nave.png
"""
import math
import os

import ashember as A

W, H = 640, 360

# ── The corridor, as fractions of the frame ──────────────────────────────────
VPX, VPY = 0.5, 0.545     # vanishing point — slightly above centre, so the floor dominates
HALF_W = 0.46             # hall half-width at the near plane
UP = 0.52                 # ceiling height above the vanishing point at the near plane
DOWN = 0.46               # floor depth below it
FAR_T = 0.17              # nearer than this the hall has ended: the far wall
BAY = 1.25                # arcade rhythm, in world units along the hall

BLACK = (6, 5, 7)
COLD = A.RAMP["stone"][0]

# ── The light ────────────────────────────────────────────────────────────────
# A broad slab of daylight leaning in from an unseen window high on the left. Angled, because
# a vertical beam reads as a flame or a laser rather than as light through a window.
SHAFT_ANG = 0.42          # x drift per unit y — the lean
SHAFT_X = 0.30            # where it crosses the floor line
SHAFT_HALF = 0.115        # half-width across the beam
CANDLE_X, CANDLE_Y = 0.605, 0.845   # off the beam, so the two lights stay legible apart


def _resolve(fx, fy):
    """Ray-cast a pixel to its surface. Returns (surface, t, along, height).

    `t` is depth: 0 at the vanishing point, 1 at the near plane. `along` is the world
    coordinate that runs down the hall (used for bay/flag rhythm); `height` is the world
    coordinate across it.
    """
    u = fx - VPX
    v = fy - VPY
    rx = abs(u) / HALF_W
    ry = (v / DOWN) if v >= 0 else (-v / UP)
    t = max(rx, ry)
    if t < FAR_T:
        return "far", t, 0.0, 0.0
    if rx >= ry:
        # A side wall: height across the wall is the ratio of vertical to horizontal offset.
        return ("wall", rx, 1.0 / max(rx, 1e-4), v / max(abs(u), 1e-4))
    if v >= 0:
        return ("floor", ry, 1.0 / max(ry, 1e-4), u / max(v, 1e-4))
    return ("vault", ry, 1.0 / max(ry, 1e-4), u / max(-v, 1e-4))


def _shaft(fx, fy):
    """The daylight slab. 0..1, deliberately gentle — this room is dark."""
    cx = SHAFT_X + SHAFT_ANG * (0.78 - fy)
    d = abs(fx - cx) / SHAFT_HALF
    if d >= 1.0:
        return 0.0
    core = (1.0 - d * d) ** 2.6
    # Fades out near the top (lost in the vault) and at the floor (spent).
    vert = A.smooth(0.02, 0.30, fy) * (1.0 - 0.55 * A.smooth(0.62, 0.98, fy))
    return core * vert * 0.30


def _pool(fx, fy):
    """Where the slab meets the flags. Sheared along the beam's lean so it is the foot of the
    light, not a separate bright object lying on the floor."""
    cx = SHAFT_X + SHAFT_ANG * (0.78 - fy)
    dx = (fx - cx) / 0.20
    dy = (fy - 0.80) / 0.10
    d = math.sqrt(dx * dx + dy * dy)
    return max(0.0, 1.0 - A.smooth(0.0, 1.0, d)) ** 1.6


def _candle(fx, fy):
    """The candle's own warm falloff — small, so it stays a candle and not a bonfire."""
    dx = (fx - CANDLE_X) / 0.105
    dy = (fy - CANDLE_Y + 0.004) / 0.042
    return max(0.0, 1.0 - A.smooth(0.0, 1.0, math.sqrt(dx * dx + dy * dy))) ** 2.6


def nave_px(x, y):
    fx, fy = (x + 0.5) / W, (y + 0.5) / H
    surf, t, along, hgt = _resolve(fx, fy)

    if surf == "far":
        # The hall does not resolve; it simply ends in the dark.
        base = A.lerp_rgb(BLACK, COLD, 0.16 * (t / FAR_T))
    elif surf == "vault":
        # Overhead: near-black, with the faintest suggestion of ribs crossing the bays.
        base = A.lerp_rgb(BLACK, COLD, 0.10)
        rib = abs(((along / BAY) % 1.0) - 0.5)
        if rib > 0.44 and t > 0.35:
            base = A.over(base, COLD, 0.22)
    elif surf == "floor":
        # Worn flags: courses across the hall, joints running away from the viewer.
        base = A.ramp_shade("stone", 0.05 + 0.13 * t)
        course = abs(((along / 0.62) % 1.0) - 0.5)
        joint = abs(((hgt / 0.42) % 1.0) - 0.5)
        if course > 0.455 or joint > 0.465:
            base = A.over(base, BLACK, 0.5)
        else:
            base = A.over(base, COLD, 0.05 * (A.noise(x // 2, y // 2, 11) + 8) / 16.0)
        base = A.lerp_rgb(base, BLACK, 1.0 - (0.20 + 0.80 * min(1.0, t * 1.15)))
    else:
        # The arcade: a pier, then an arched opening onto the dark aisle beyond.
        base = A.ramp_shade("stone", 0.04 + 0.11 * t)
        p = (along / BAY) % 1.0
        # Arched opening: a bay is open between the piers, its head a semicircle.
        open_half = 0.34
        dp = abs(p - 0.5)
        arch_top = -0.62
        if dp < open_half:
            head = math.sqrt(max(0.0, 1.0 - (dp / open_half) ** 2))
            arch_top = -0.62 - 0.42 * head          # the curve of the arch head
            if hgt > arch_top:
                # Into the dark of the side aisle — the deepest black in the image.
                base = A.lerp_rgb(BLACK, COLD, 0.05)
                base = A.lerp_rgb(base, BLACK, 0.55 * (1.0 - min(1.0, t * 1.6)))
                base = A.lerp_rgb(base, BLACK, 0.30)
                r, g, b = A.quantize(_light(base, fx, fy, 0.35))
                return (r, g, b, 255)
        # Pier face: grain, plus a lit inner edge that gives the arcade its relief.
        base = A.over(base, COLD, 0.06 * (A.noise(x, y // 3, 7) + 8) / 16.0)
        edge = 1.0 - min(1.0, abs(dp - open_half) * 9.0)
        base = A.over(base, A.RAMP["stone"][2], 0.26 * max(0.0, edge))
        base = A.lerp_rgb(base, BLACK, 0.45 * (1.0 - min(1.0, t * 1.3)))

    r, g, b = A.quantize(_light(base, fx, fy, 1.0))
    return (r, g, b, 255)


_DITHER = ((0, 8, 2, 10), (12, 4, 14, 6), (3, 11, 1, 9), (15, 7, 13, 5))


def _dither(base, x, y):
    """Nudge a colour by less than one ramp step, on a 4x4 ordered pattern, so a smooth
    gradient breaks up instead of banding into rings under quantize()."""
    k = (_DITHER[y & 3][x & 3] / 16.0 - 0.5) * 8.0
    return (base[0] + k, base[1] + k, base[2] + k)


def _light(base, fx, fy, recv):
    """Apply the two lights + vignette. `recv` scales how much a surface takes (the dark
    aisles behind the arches take little, which is what keeps them reading as depth)."""
    s = _shaft(fx, fy)
    if s > 0.0:
        pale = A.lerp_rgb(A.RAMP["stone"][-1], (206, 214, 230), 0.5)
        base = A.over(base, pale, min(0.34, s * recv))
    p = _pool(fx, fy)
    if p > 0.0:
        base = A.over(base, A.lerp_rgb(A.RAMP["stone"][-1], (214, 220, 232), 0.35), min(0.26, p * 0.26 * recv))
    c = _candle(fx, fy)
    if c > 0.0:
        base = A.over(base, A.FLAME_PALE, min(0.34, c * 0.34 * recv))
    # The taper itself: a short wax stub with a flame, drawn last so nothing washes it out.
    cx, cy = CANDLE_X * W, CANDLE_Y * H
    px, py = fx * W, fy * H
    if abs(px - cx) <= 1.6 and 0 <= py - (cy - 11) <= 11:
        base = A.ramp_shade("parchment", 0.42 if px < cx else 0.72)
    elif abs(px - cx) <= 1.1 and -5 <= py - (cy - 11) < 0:
        base = A.FLAME_PALE
    v = max(abs(fx - 0.5) / 0.5, abs(fy - 0.5) / 0.5)
    base = A.lerp_rgb(base, BLACK, 0.66 * A.smooth(0.58, 1.06, v))
    return _dither(base, int(fx * W), int(fy * H))


if __name__ == "__main__":
    os.makedirs(os.path.join(os.path.dirname(os.path.abspath(__file__)), "title"), exist_ok=True)
    A.assert_on_palette(W, H, nave_px, "title/nave.png")
    # A LITERAL relative path, run from client/assets/ui/ (canon S5b): tools/asset_map.py derives
    # producer edges from this string, so an os.path.join here silently drops nave.png's producer.
    A.write_png("title/nave.png", W, H, nave_px)
    print("gen_nave OK — the empty nave, %dx%d, palette-locked." % (W, H))
