#!/usr/bin/env python3
"""Contact shadows derived from the instruments' own silhouettes (TD-108 R380).

Every instrument used to cast the same 2px rectangle — the clearest remaining tell
that the shelf held UI sprites rather than objects. A shadow belongs to the thing that
casts it, so these are DERIVED from `gear_icons.png` rather than drawn: read each
icon's base silhouette, and emit a cluster that is dense where the object actually
touches the board and scatters to loose pixels outward.

Why derived and not authored: ten hand-drawn shadows would need an eleventh drawn by
hand the moment an instrument is added, and nothing would notice if one drifted from
its icon. Deriving makes the claim checkable — this generator FAILS if an icon has no
shadow or a shadow has no icon (P173).

Pixel clusters, never a gradient: the alpha steps are three discrete values, because a
smooth ramp is not something this register has (TD-046).

Deterministic: the scatter is a seeded hash, so the sheet is byte-identical every run.

    cd client/assets/ui && python3 gen_qm_shadows.py
      -> stations/gear_shadows.png   240x3, ten cells at the icons' own 24px pitch
"""
import ashember as A
from pngio import read_png

SRC = "stations/gear_icons.png"
OUT = "stations/gear_shadows.png"

ICON_PX = 24
ROWS = 3                      # contact, spread, scatter — three and no more
LIFT_LIMIT = 6.0              # a column this far above the contact row casts nothing

# Discrete alphas. A shadow is dark cloth on wood, not a blur.
ALPHA = (190, 110, 55)
SHADOW = A.RAMP["black"][0]


def _rnd(x, y, seed=0):
    n = (x * 73856093) ^ (y * 19349663) ^ (seed * 83492791)
    n = (n ^ (n >> 13)) * 1274126177
    return ((n ^ (n >> 16)) & 0xFFFF) / 65535.0


def _bases(px, cell):
    """Lowest opaque row per column for one icon, or None where the column is empty."""
    out = []
    for lx in range(ICON_PX):
        low = None
        for y in range(ICON_PX):
            _r, _g, _b, a = px(cell * ICON_PX + lx, y)
            if a > 0:
                low = y
        out.append(low)
    return out


def build():
    w, h, px = read_png(SRC)
    cells = w // ICON_PX
    assert h == ICON_PX, "icon sheet must be one row of %dpx cells" % ICON_PX

    # grid[cell][row][col] -> alpha
    grid = [[[0] * ICON_PX for _ in range(ROWS)] for _ in range(cells)]
    covered = []

    for c in range(cells):
        bases = _bases(px, c)
        present = [b for b in bases if b is not None]
        if not present:
            covered.append(0)
            continue
        contact = max(present)          # the row the object actually rests on

        for lx, b in enumerate(bases):
            if b is None:
                continue
            # A lifted rim (a magnifier's glass, a lantern's hood) casts far less than
            # the part standing on the board. Without this the shadow is as wide as the
            # widest point of the object, which is what a rectangle already looked like.
            depth = contact - b
            weight = max(0.0, 1.0 - depth / LIFT_LIMIT)
            if weight <= 0.0:
                continue
            for row in range(ROWS):
                a = ALPHA[row] * weight
                if row == 0:
                    _put(grid[c], lx, 0, a)
                    continue
                # Spread outward, thinned by a seeded scatter so the edge breaks into
                # clusters instead of stepping like a stair.
                for dx in (-row, 0, row):
                    s = _rnd(c * 31 + lx, row * 7 + dx, 11)
                    if s > 0.42:
                        _put(grid[c], lx + dx, row, a * (0.55 + 0.45 * s))
        covered.append(sum(1 for r in grid[c] for v in r if v > 0))

    # P173: every instrument casts, and nothing casts for an instrument that is not there.
    empty = [i for i, n in enumerate(covered) if n == 0]
    assert not empty, "instruments with no shadow: %r" % empty

    def pixel(x, y):
        c, lx = divmod(x, ICON_PX)
        a = int(grid[c][y][lx])
        if a <= 0:
            return (0, 0, 0, 0)
        return (SHADOW[0], SHADOW[1], SHADOW[2], min(a, 255))

    A.write_png(OUT, w, ROWS, pixel)
    print("wrote %s (%dx%d) — %d shadows derived from %s" % (OUT, w, ROWS, cells, SRC))


def _put(cell, x, y, a):
    if 0 <= x < ICON_PX and 0 <= y < ROWS:
        cell[y][x] = max(cell[y][x], a)


if __name__ == "__main__":
    build()
