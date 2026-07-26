#!/usr/bin/env python3
"""gen_menu_sigil.py — the laurel that marks the selected menu option (TD-077).

    shared/menu_sigil.png   34x30, the RIGHT-hand branch (the UI mirrors it for the left)

Taken from the Collegium's own device. The crest's wreath is two branches meeting at the base and
opening upward and outward around the sword; this is one of them. Rooted at the bottom INNER corner,
arcing up and AWAY from the word it marks, so the pair frames the option the way the wreath frames
the blade — the author's sketch was `\\ word /`.

It replaces a plain gilt lozenge, and it replaces the focus rectangle before that: a box drawn round
gilt Cinzel turns an image back into a dialog, which is what R232 exists to stop.

**The leaves are hand-authored pixel maps, not a shape function.** Five parameter passes were spent
trying to draw them analytically at this size and every one failed a different way: thin sin-tapered
lenses read as THORNS, fat ones as PODS, long ones fused into a single gilt mass, and spacing them
apart until they stopped fusing left a fishbone. That is TD-057's finding arriving again — *a shape
function samples a curve; it cannot decide which pixel carries the leaf* — measured there at 17x22
and true here at 34x30. So each leaf is an ASCII stamp, and the only thing computed is where it
lands on the branch.

The **rim is derived, not drawn**: every empty pixel touching gold becomes `wood[0]`. That is what
separates two overlapping leaves — at four pixels across, distance cannot do it, only a dark edge —
and being a dilation it can never be forgotten on one leaf and not another. `wood[0]` is near enough
to the hall's darkness that the OUTER silhouette dissolves into it while the INTERNAL gaps read.

Authored at the title hall's grain (one art pixel per device pixel at 720p), hard-edged, on the Ash
& Ember ramps — `assert_on_palette` passes.

Run from client/assets/ui/:  python3 gen_menu_sigil.py
"""
import os

import ashember as A

W, H = 34, 30
GOLD_D, GOLD_M, GOLD_L = A.RAMP["gold"][0], A.RAMP["gold"][1], A.RAMP["gold"][2]
RIM = A.RAMP["wood"][0]
NONE = (0, 0, 0, 0)
INK = {"l": GOLD_L, "m": GOLD_M, "d": GOLD_D}

# ── the two leaf stamps, hand-placed pixel by pixel ──────────────────────────
# A laurel leaf sweeps toward the tip of its branch, so on a branch running up-and-right the leaves
# above it stand nearly upright and the ones below it lie nearly flat. Two stamps, not six: the
# variety comes from where they sit and how far each is clipped, which is cheaper than authoring
# six near-identical maps and getting one of them subtly wrong.

STEEP = [                      # stands up off the branch; tip at the top. 4x8, base at (1, 7)
    "..l.",
    ".llm",
    "llmm",
    "llmm",
    ".lmm",
    ".lmm",
    "..mm",
    "..m.",
]

FLAT = [                       # lies along the branch; tip at the right. 8x4, base at (0, 2)
    "....lll.",
    "..llllmm",
    "llmmmmm.",
    ".mmmm...",
]

# ── where each leaf sits on the branch ───────────────────────────────────────
# The stem runs from the root at the bottom inner corner to the tip at the top outer corner. Points
# are authored outright rather than sampled off a curve, for the same reason the leaves are.
STEM = [(5, 27), (8, 24), (11, 21), (14, 18), (17, 15), (20, 12), (23, 9), (26, 6), (29, 4)]

#           stamp,  the stem point it grows from, rows to keep (a shorter leaf near the tip)
PLACEMENTS = [
    (FLAT,  (7, 25), 4),
    (STEEP, (10, 22), 8),
    (FLAT,  (13, 19), 4),
    (STEEP, (16, 16), 7),
    (FLAT,  (19, 13), 3),
    (STEEP, (22, 10), 6),
    (FLAT,  (24, 8), 3),
]

BASE = {id(STEEP): (1, 7), id(FLAT): (0, 2)}


def build():
    px = [[NONE] * W for _ in range(H)]

    def put(x, y, c):
        if 0 <= x < W and 0 <= y < H:
            px[y][x] = c

    # The stem first; the leaves are stamped over it, which is what roots them to the branch.
    for i in range(len(STEM) - 1):
        (x0, y0), (x1, y1) = STEM[i], STEM[i + 1]
        steps = max(abs(x1 - x0), abs(y1 - y0))
        for s in range(steps + 1):
            x = x0 + (x1 - x0) * s // steps
            y = y0 + (y1 - y0) * s // steps
            put(x, y, GOLD_M)
            put(x, y + 1, GOLD_D)

    for stamp, (ax, ay), keep in PLACEMENTS:
        bx, by = BASE[id(stamp)]
        rows = stamp[len(stamp) - keep:] if stamp is FLAT else stamp[:keep]
        oy = ay - by + (len(stamp) - keep if stamp is FLAT else 0)
        for ry, row in enumerate(rows):
            for rx, ch in enumerate(row):
                if ch in INK:
                    put(ax - bx + rx, oy + ry, INK[ch])

    # Two berries where the branch is cut.
    for bxx, byy in ((3, 26), (5, 29)):
        put(bxx, byy, GOLD_L)
        put(bxx + 1, byy, GOLD_M)

    # ── the rim, DERIVED: every empty pixel touching gold ────────────────────
    rim = []
    for y in range(H):
        for x in range(W):
            if px[y][x] != NONE:
                continue
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < W and 0 <= ny < H and px[ny][nx] not in (NONE, RIM):
                        rim.append((x, y))
                        break
                else:
                    continue
                break
    for x, y in rim:
        px[y][x] = RIM
    return px


BUF = build()


def px(x, y):
    c = BUF[y][x]
    return NONE if c == NONE else (c[0], c[1], c[2], 255)


if __name__ == "__main__":
    os.makedirs(os.path.join(os.path.dirname(os.path.abspath(__file__)), "shared"), exist_ok=True)
    A.assert_on_palette(W, H, px, "shared/menu_sigil.png")
    # A LITERAL relative path, run from client/assets/ui/ (canon S5b).
    A.write_png("shared/menu_sigil.png", W, H, px)
    print("gen_menu_sigil OK — the laurel branch, %dx%d, hand-authored, on-palette." % (W, H))
