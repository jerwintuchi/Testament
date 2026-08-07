#!/usr/bin/env python3
"""gen_collegium_tiles.py — the Collegium's floor and walls (TD-081, T311).

    tiles/tiles.png     64x32   a 4x2 atlas of 16x16 cells
    tiles/tiles_n.png   64x32   its normal map, for the Light2D rig (T312)

Replaces a 32x16 greybox containing **four colours** — one flat floor cell, one flat wall cell —
which was the complete art of the hall the player spends most of their time in.

    (0,0) (1,0) (2,0) (3,0)   floor, four variants
    (0,1)                     floor lying under a wall (shadow along its top edge)
    (1,1) (2,1) (3,1)         wall, three variants

**The palette is `navestone`**, the warm ashlar authored for the Hall of Petitions' nave (TD-072) —
which is what this room *is*, seen from above instead of down its axis. Using it here is what makes
the Collegium and the title screen the same building; `stone` (cool) stays for the field.

**On the grid.** The first pass avoided joints entirely, for fear of redrawing the debug grid, and
produced noisy rubble instead. That was the wrong diagnosis: the difference between a stone floor
and a debug grid is not whether joints exist — a flagstone floor *is* a grid of joints — it is
whether the STONES vary. So joints are back, on two edges only so neighbours share one line, broken
in places; and each variant carries its own base tone, wear and cracking, picked by the caller from
a hash of the tile's coordinates (deterministic, P144).

**No per-pixel noise anywhere.** Flat tones and large clusters, the Contract Board's register, which
TD-075 made binding. Every colour is an exact ramp index, so `assert_on_palette` passes.

Run from client/assets/ui/:  python3 gen_collegium_tiles.py
"""
import os

import ashember as A
# The Sobel + green-channel convention MUST match the board's, or lights read inverted on one
# surface and not the other. Importing is the point: one definition, not a copy that drifts.
from gen_normals import _normal_pixel

CELL = 16
COLS, ROWS = 4, 2
W, H = CELL * COLS, CELL * ROWS

NS = A.RAMP["navestone"]          # 0 darkest … 6 lightest


# ── the four floor variants ─────────────────────────────────────────────────
# WEAR IS BETWEEN FLAGS, NOT INSIDE THEM. Two passes went the other way and both failed at 16px:
# small patches read as pebbles lying on the floor, and a large stepped diagonal read as a
# decorative tiled pattern. With only seven ramp steps, a whole step across part of a 16px tile is
# enormous contrast — far more than worn stone has. So each flag is ONE tone and the variation is
# flag-to-flag, which is what a stone floor actually looks like; the detail budget goes on a crack
# and a chipped corner instead.
#
# AUTHORED AT FULL-LIGHT VALUE, not at the value the hall should look. T312 put a CanvasModulate
# under the lights, so anything authored to read correctly UNLIT is then darkened a second time and
# lands nearly black. The diffuse is what the stone looks like with a lamp on it; the darkness is
# the rig's job, not the texture's.
#
#   base tone index, crack?, chipped corner?
FLOORS = [
    (3, False, False),
    (4, False, False),
    (3, True, False),
    (4, False, True),
]


def floor_px(base, cracked, chipped, shade_top=0):
    """One flagstone. `shade_top` darkens the upper rows, for the cell that lies under a wall."""
    def px(x, y):
        i = base

        # A crack, on one variant only: a short stepped line, never edge to edge.
        if cracked and 4 <= y <= 12 and x == 6 + (y - 4) // 4:
            i = base - 1
        # A chipped corner on another: the flag has lost a bite out of its lower right.
        if chipped and x + (15 - y) > 26:
            i = base - 1

        # The joint, on two edges only, so neighbouring flags share one line rather than doubling
        # it — and broken in one place, because an unbroken 16px rule is what reads as a grid.
        if (y == 0 and x > 1 and not (6 <= x <= 8)) or (x == 0 and y > 1):
            i = 1
        # The lit lip just inside the top joint: stone has thickness, and this is what shows it.
        # Only part of the width — a full-width lip under a full-width joint is a double rule, which
        # is the grid coming back by another route.
        elif y == 1 and 3 <= x <= 10:
            i = min(6, base + 1)

        if shade_top and y < shade_top:
            i -= (shade_top - y)
        return NS[max(0, min(6, i))] + (255,)
    return px


# ── the wall: the base of a wall seen from above ────────────────────────────
def wall_px(v):
    """A lit top course catching the light, a turn, then a dark face falling away in courses.
    Three variants whose coursing is offset, so the border is not one extruded block."""
    def px(x, y):
        if y == 0:
            i = 6                                   # the very top edge, brightest
        elif y < 5:
            i = 5                                   # the top of the wall
        elif y < 7:
            i = 4                                   # the turn into shadow
        else:
            i = 2                                   # the face

        if y >= 7:
            if y == 10 + v:                         # one course line across the face
                i = 1
            phase = 0 if y < 10 + v else 4          # blocks break bond above and below it
            if (x + v * 3 + phase) % 8 == 0:
                i = 1
        elif y < 5 and (x + v * 3) % 8 == 0:
            i = 4                                   # joints on the crown too, or it reads as paint
        return NS[i] + (255,)
    return px


def atlas():
    """The whole sheet as one pixel(x, y), so it is written and Sobelled from one definition."""
    cells = {}
    for v, (base, cracked, chipped) in enumerate(FLOORS):
        cells[(v, 0)] = floor_px(base, cracked, chipped)
    # The one directional case worth a cell: the wall above casts down onto the floor. Top-down
    # convention puts the light overhead, so this is the join the eye actually checks.
    cells[(0, 1)] = floor_px(FLOORS[0][0], FLOORS[0][1], FLOORS[0][2], shade_top=5)
    for v in range(3):
        cells[(v + 1, 1)] = wall_px(v)

    def px(x, y):
        return cells[(x // CELL, y // CELL)](x % CELL, y % CELL)
    return px


def main():
    px = atlas()
    A.assert_on_palette(W, H, px, "tiles/tiles.png")
    # LITERAL relative paths, run from client/assets/ui/ (canon S5b): tools/asset_map.py derives
    # producer edges from these strings.
    A.write_png("../tiles/tiles.png", W, H, px)

    # The normal map comes from the diffuse's own luminance, so relief and shading can never
    # disagree — the same height field drew both.
    lum = [0.0] * (W * H)
    for y in range(H):
        for x in range(W):
            r, g, b, _a = px(x, y)
            lum[y * W + x] = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0
    A.write_png("../tiles/tiles_n.png", W, H, _normal_pixel(W, H, lum, 2.2))
    # 2.2, not 5.0: at 5.0 the joints caught the lights hard enough to GLOW, which reads as molten
    # mortar rather than as stone with relief. The strength is a lighting decision, so it was set by
    # looking at the lit hall, not at the normal map.

    print("gen_collegium_tiles OK — %dx%d atlas (4 floor, 1 under-wall, 3 wall) + normal map."
          % (W, H))


if __name__ == "__main__":
    main()
