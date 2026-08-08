#!/usr/bin/env python3
"""Generate the Quartermaster's expedition-pack surfaces (TD-090 Phase B).

The requisition writ is parchment; the PACK is the one object on it that is not
paper. It is a real case a Seeker carries: waxed leather over a wood frame, iron
corner straps, brass fittings, and compartments a thing drops INTO. That contrast
is the point — you are looking at a document, and at the kit it commissions.

Authored at DISPLAY size and shown 1:1 NEAREST (TD-050/TD-055: the client
rasterises UI at native resolution, so a downscale is mush). Chunky clusters,
hard edges, no anti-aliasing, no gradients — every colour resolves to an Ash &
Ember ramp, which `assert_on_palette` proves.

Deterministic and safe to re-run: same bytes every time, and it writes only the
four files named below.

    cd client/assets/ui && python3 gen_quartermaster.py
      -> stations/pack_case.png       64x64  9-slice, 20px margins
      -> stations/pack_slot.png       36x36  9-slice, 12px margins (a compartment)
      -> stations/pack_clasp.png      18x22  brass closure
      -> stations/label_strip.png     48x16  9-slice, 8px margins (a tied-on label)
"""
import ashember as A

# Ash & Ember stops this surface set uses. Named here so the intent is readable and
# so a palette check has something to compare against.
LEATHER_DEEP = A.RAMP["wood"][0]      # #2A1B10 — the case in shadow
LEATHER      = A.RAMP["wood"][1]      # #3A2617 — waxed hide
LEATHER_WORN = A.RAMP["wood"][2]      # #5A3D28 — where a strap has rubbed it
WOOD_LIP     = A.RAMP["wood"][3]      # #7A5334 — the frame under the hide
IRON_DARK    = A.RAMP["stone"][0]
IRON         = A.RAMP["stone"][2]
IRON_LIT     = A.RAMP["stone"][3]
BRASS_DIM    = A.RAMP["gold"][1]
BRASS        = A.RAMP["gold"][2]
BRASS_LIT    = A.RAMP["gold"][3]
PARCH        = A.RAMP["parchment"][2]
PARCH_HI     = A.RAMP["parchment"][3]
PARCH_DEEP   = A.RAMP["parchment"][0]
INK          = A.RAMP["ink"][0]
BLACK        = A.RAMP["black"][1]

CLEAR = (0, 0, 0, 0)


def _op(c, a=255):
    return (c[0], c[1], c[2], a)


# ── pack_case.png — the case itself, as a 9-slice ────────────────────────────
# 20px margins so the corner straps never stretch; the middle tiles as flat hide.
CASE_W = CASE_H = 64
CASE_M = 20


def _case(x, y):
    # Distance from each edge, so the border logic is written once and mirrored.
    dl, dr, dt, db = x, CASE_W - 1 - x, y, CASE_H - 1 - y
    d = min(dl, dr, dt, db)
    near_x, near_y = min(dl, dr), min(dt, db)

    if d == 0:
        return _op(BLACK)                       # a hard outline: this is an object

    # Brass corner brackets. These must be tested BEFORE the rim, not after — the
    # first attempt put them below the d-based returns, so they could only run deep
    # inside the panel where their own condition was unreachable and nothing drew.
    if near_x <= 11 and near_y <= 11 and 1 <= d <= 4:
        # BRASS_DIM/BRASS, not BRASS_LIT: the bright stop read as gold plate against a
        # muted hide and pulled the eye off the compartments, which are the mechanic.
        return _op(BRASS if d <= 2 else BRASS_DIM)
    if near_x <= 12 and near_y <= 12 and d == 5:
        return _op(IRON_DARK)                   # the bracket's own shadow

    # Straps: two bands buckled over the case, crossing the rim so they read as
    # holding it shut rather than as decals painted on the hide.
    strap = abs(x - CASE_W // 3) <= 3 or abs(x - 2 * CASE_W // 3) <= 3
    if strap and near_y <= 10:
        edge = abs(x - CASE_W // 3) == 3 or abs(x - 2 * CASE_W // 3) == 3
        if near_y <= 1:
            return _op(BLACK if edge else LEATHER_DEEP)
        return _op(LEATHER_DEEP if edge else (LEATHER_WORN if near_y <= 6 else LEATHER))

    if d == 1:
        return _op(IRON_DARK)
    if d in (2, 3):
        # Iron rim. Only the OUTER row of the top/left edge takes the highlight.
        lit = d == 2 and ((dt <= dl and dt <= dr) or (dl <= dt and dl <= db))
        return _op(IRON_LIT if lit else IRON)
    if d == 4:
        return _op(LEATHER_DEEP)                # a shadow line under the rim
    if d in (5, 6):
        return _op(LEATHER)
    if d == 7:
        return _op(WOOD_LIP if (x + y) % 4 != 0 else LEATHER)   # stitching, dashed

    # THE CENTRE MUST BE NEARLY FLAT. A 9-slice stretches its middle, so banding or a
    # scatter here is smeared and repeated into a patchwork — which is exactly what the
    # first two passes produced (camouflage, then brickwork). Character lives in the
    # BORDER, which does not stretch.
    c = LEATHER
    if A.noise(x // 5, y // 5, 17) > 0.93:
        c = A.quantize(A.lerp_rgb(LEATHER, LEATHER_WORN, 0.35))
    return _op(c)


# ── pack_slot.png — one compartment ──────────────────────────────────────────
# A recess, not a button: dark at the top where the lip overhangs, lighter at the
# bottom where the floor catches light. 12px margins keeps the corners square.
SLOT_W = SLOT_H = 36
SLOT_M = 12


def _slot(x, y):
    dl, dr, dt, db = x, SLOT_W - 1 - x, y, SLOT_H - 1 - y
    d = min(dl, dr, dt, db)

    # A LOOP, not a box: a leather band across the top and bottom that a thing is
    # slid behind, with the case's own dark interior showing between them. The first
    # pass drew a bevelled rectangle, which read as a button.
    if dt <= 2:
        return _op(WOOD_LIP if dt == 1 else LEATHER_WORN)     # upper band, lit
    if db <= 2:
        return _op(LEATHER_DEEP if db == 0 else LEATHER)      # lower band, in shadow
    if d == 0:
        return _op(BLACK)

    # Stitch marks where each band is sewn down.
    if dt in (3, 4) and (x % 6 == 2):
        return _op(LEATHER_DEEP)
    if db in (3, 4) and (x % 6 == 2):
        return _op(LEATHER_DEEP)

    # The interior behind the loop — darkest at the top where the band overhangs.
    t = min(1.0, (y - 3) / float(SLOT_H - 6))
    c = A.quantize(A.lerp_rgb(BLACK, LEATHER_DEEP, 0.20 + 0.55 * t))
    return _op(c)


# ── pack_clasp.png — the brass closure ───────────────────────────────────────
CLASP_W, CLASP_H = 18, 22


def _clasp(x, y):
    # A tongue-and-loop clasp: a wide plate up top, a narrowed tongue, a stud.
    if 0 <= y <= 8:
        if 1 <= x <= CLASP_W - 2:
            if y == 0 or y == 8 or x == 1 or x == CLASP_W - 2:
                return _op(IRON_DARK)
            return _op(BRASS_LIT if y <= 3 else BRASS)
        return CLEAR
    if 9 <= y <= 16:
        if 5 <= x <= CLASP_W - 6:
            if x == 5 or x == CLASP_W - 6 or y == 16:
                return _op(IRON_DARK)
            return _op(BRASS if y <= 12 else BRASS_DIM)
        return CLEAR
    if 17 <= y <= 21:
        # The stud, centred.
        cx, cy, r = CLASP_W // 2, 19, 2
        dd = (x - cx) ** 2 + (y - cy) ** 2
        if dd <= r * r + r:
            return _op(BRASS_LIT if dd <= 1 else BRASS)
        if dd <= (r + 1) ** 2 + r:
            return _op(IRON_DARK)
    return CLEAR


# ── label_strip.png — a parchment label tied to the case ─────────────────────
LABEL_W, LABEL_H = 48, 16
LABEL_M = 8


def _label(x, y):
    dl, dr, dt, db = x, LABEL_W - 1 - x, y, LABEL_H - 1 - y
    d = min(dl, dr, dt, db)
    if d == 0:
        return _op(PARCH_DEEP)                 # a deckled-ish edge, one step down
    if d == 1:
        return _op(A.quantize(A.lerp_rgb(PARCH_DEEP, PARCH, 0.5)))
    c = PARCH_HI if dt <= 3 else PARCH         # light from above
    if A.noise(x // 3, y // 3, 7) > 0.96:
        c = A.quantize(A.lerp_rgb(PARCH, INK, 0.12))   # foxing fleck, sparse
    # Two punch holes where a cord would pass, one at each end.
    for hx in (3, LABEL_W - 4):
        if (x - hx) ** 2 + (y - LABEL_H // 2) ** 2 <= 2:
            return _op(INK)
    return _op(c)


TARGETS = [
    ("stations/pack_case.png",   CASE_W,  CASE_H,  _case),
    ("stations/pack_slot.png",   SLOT_W,  SLOT_H,  _slot),
    ("stations/pack_clasp.png",  CLASP_W, CLASP_H, _clasp),
    ("stations/label_strip.png", LABEL_W, LABEL_H, _label),
]


def _assert_on_palette():
    """Every opaque pixel must resolve to a defined Ash & Ember stop.

    This is the board's own check (TD-046): the strict 15-colour lock is retired,
    but a surface that wanders off the curated ramps stops belonging to the game.
    """
    bad = {}
    for _, w, h, fn in TARGETS:
        for y in range(h):
            for x in range(w):
                r, g, b, a = fn(x, y)
                if a == 0:
                    continue
                if (r, g, b) not in A.PALETTE_SET:
                    bad[(r, g, b)] = bad.get((r, g, b), 0) + 1
    assert not bad, "off-palette colours: %r" % (sorted(bad.items())[:6],)


if __name__ == "__main__":
    _assert_on_palette()
    for path, w, h, fn in TARGETS:
        A.write_png(path, w, h, fn)
        print("wrote %s (%dx%d)" % (path, w, h))
    print("9-slice margins: case=%d slot=%d label=%d" % (CASE_M, SLOT_M, LABEL_M))
