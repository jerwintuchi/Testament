#!/usr/bin/env python3
"""Generate the Quartermaster's ROOM — the Collegium's stores (TD-101).

The Quartermaster stopped being a writ with a list on it and became a place: a
supply room with open shelving, labelled compartments, an inspection counter and a
lamp. This generator emits the MODULAR pieces that room is assembled from, never a
single painted backdrop — the brief forbids that (§17), and TD-072 already recorded
a procedurally generated hero plate as a structural failure.

Authored at DISPLAY size and shown 1:1 NEAREST (TD-050/TD-055: the client rasterises
UI at native resolution, so a downscale is mush). Chunky clusters, hard edges, no
anti-aliasing, no gradients; every opaque colour resolves to an Ash & Ember stop,
which `assert_on_palette` proves.

`navestone` is reused deliberately: it is the nave's own ashlar, so this room and the
title screen's hall are the same building (the TD-081 rule).

Deterministic and safe to re-run: same bytes every time, and it writes only the seven
files named below.

    cd client/assets/ui && python3 gen_qm_room.py
      -> stations/qm_wall.png      64x64   tiling ashlar backdrop
      -> stations/qm_shelf.png     48x48   9-slice shelving frame, 16px margins
      -> stations/qm_board.png     16x12   9-slice plank, 4px margins
      -> stations/qm_label.png     24x14   9-slice label plate, 7px margins
      -> stations/qm_counter.png   64x40   9-slice counter, 16px margins
      -> stations/qm_stock.png    128x16   8 dressing objects (never interactive)
      -> stations/qm_props.png     96x24   4 counter props
"""
import ashember as A
from gen_normals import _normal_pixel

# ── the room's tones, named so the intent is readable ────────────────────────
# Deep end of navestone: this is a cellar-level store, lit by one lamp.
WALL_DARK  = A.RAMP["navestone"][0]   # #14100D
WALL_BASE  = A.RAMP["navestone"][1]   # #241D19
WALL_MID   = A.RAMP["navestone"][2]   # #332A24
WALL_JOINT = A.RAMP["navestone"][0]   # mortar reads as a shadow, not a light line

WOOD_DEEP  = A.RAMP["wood"][0]        # #2A1B10
WOOD_DARK  = A.RAMP["wood"][1]        # #3A2617
WOOD_BASE  = A.RAMP["wood"][2]        # #5A3D28
WOOD_LIT   = A.RAMP["wood"][3]        # #7A5334
WOOD_HI    = A.RAMP["wood"][4]        # #916339

IRON_DARK  = A.RAMP["stone"][0]
IRON       = A.RAMP["stone"][2]
IRON_LIT   = A.RAMP["stone"][3]

BRASS_DIM  = A.RAMP["gold"][0]
BRASS      = A.RAMP["gold"][1]
BRASS_LIT  = A.RAMP["gold"][2]

PARCH_DEEP = A.RAMP["parchment"][0]
PARCH      = A.RAMP["parchment"][1]
PARCH_HI   = A.RAMP["parchment"][2]

INK        = A.RAMP["ink"][0]
BLACK      = A.RAMP["black"][0]
BLACK_SOFT = A.RAMP["black"][1]

GLASS      = A.RAMP["stone"][3]
FLAME_LOW  = A.RAMP["flame"][0]
FLAME_HI   = A.RAMP["flame"][2]
WAX_RED    = A.RAMP["wax"][1]

CLEAR = (0, 0, 0, 0)


def _op(c, a=255):
    return (c[0], c[1], c[2], a)


def _rnd(x, y, seed=0):
    """Deterministic hash noise. Same room every time (P166)."""
    n = (x * 73856093) ^ (y * 19349663) ^ (seed * 83492791)
    n = (n ^ (n >> 13)) * 1274126177
    return ((n ^ (n >> 16)) & 0xFFFF) / 65535.0


# ── qm_wall.png — the ashlar behind everything ───────────────────────────────
# Tiles in both directions: courses 16px tall, blocks 32px wide, offset every other
# course. Kept DARK on purpose — it is the backdrop, and the instruments are what the
# eye must find. Detail is joint lines plus a two-step grain, never per-pixel noise.
WALL_W = WALL_H = 64
COURSE = 32
BLOCK = 64


def _wall_h(x, y):
    """Height field for the wall — drives both its shading and its normal map.

    Painting and relief come from ONE function so they cannot disagree: the pixel a
    generator darkens as a recess is the same pixel the normal map tilts away from the
    light. That is what the board's surfaces do, and it is why they read as carved.
    """
    course = y // COURSE
    ly = y % COURSE
    off = (BLOCK // 2) if (course % 2) else 0
    lx = (x + off) % BLOCK
    if ly <= 1 or lx <= 1:
        return 0.10                     # the joint: a deep recess
    v = _rnd(x // BLOCK + off, course, 7)
    hgt = 0.62 + 0.10 * v               # each block sits a little proud, by its own amount
    if ly == 2 or lx == 2:
        hgt += 0.22                     # the chamfer catching light at the block's top-left
    if ly >= COURSE - 3 or lx >= BLOCK - 3:
        hgt -= 0.16                     # and falling away at the bottom-right
    # Pitting: shallow, sparse, and per-block-seeded so it reads as worn stone rather
    # than as noise sprayed over everything.
    if _rnd(x, y, 31) > 0.955:
        hgt -= 0.14
    return max(0.0, min(1.0, hgt))


def _wall(x, y):
    """Larger, quieter ashlar (R370).

    The first pass laid 16px courses of 32px blocks, which repeats four times across a
    64px tile and reads as brick wallpaper — the eye lands on the wall before it lands
    on the shelves. Now: one course and one block per tile edge, so the pattern repeats
    once; the joint is a two-pixel RECESS rather than a bright line; and the tonal
    spread is one step instead of two, because contrast here is contrast stolen from
    the instruments.

    Painted, not flat-filled (TD-103): the height field above is shaded along the
    `navestone` ramp, so a block carries a lit chamfer, a body tone of its own, and a
    shadowed foot — the same construction the Contract Board's masonry uses. The
    surface is ALSO normal-mapped and lit at run time, so this diffuse stays a
    material rather than a painted-in lighting scheme.
    """
    hgt = _wall_h(x, y)
    # Deep end of the ramp: this is a cellar wall, and it must not out-shout the shelves.
    return _op(A.quantize(A.ramp_shade("navestone", 0.06 + hgt * 0.42)))


# ── qm_board.png — one shelf plank ───────────────────────────────────────────
# 9-slice with 4px margins so it stretches to any shelf width while the lit top edge
# and the shadow beneath stay one pixel each. Objects STAND on the top edge.
BOARD_W, BOARD_H, BOARD_M = 16, 12, 4


def _board_h(x, y):
    """Height for a shelf plank: a rounded front edge over a shadowed underside."""
    if y == 0:
        return 0.86                     # the top arris, catching the room's light
    if y == 1:
        return 0.94                     # the crown of the rounded edge
    if y == 2:
        return 0.80
    if y == 3:
        return 0.62
    if y == 4:
        return 0.42                     # rolling under
    if y == 5:
        return 0.20
    return 0.0


def _board(x, y):
    """One shelf plank, painted along the wood ramp with grain (TD-103).

    The first pass was five flat bands. A plank has a rounded front arris, end grain,
    and a shadow it throws on whatever is beneath — all of which the height field above
    now carries, so the normal map tilts with the paint.
    """
    if y >= 6:
        # Under the plank: the shadow it throws, fading out. Alpha, not a colour, so it
        # darkens whatever it happens to fall across.
        fall = (y - 6) / float(BOARD_H - 6)
        return (BLACK[0], BLACK[1], BLACK[2], max(int(155 * (1.0 - fall)), 0))
    hgt = _board_h(x, y)
    # Grain runs ALONG the plank in long strokes, never as scattered dots — a modulo on
    # (x + y) makes diagonal hatching, which is what an earlier pass shipped by accident.
    grain = 0.0
    if _rnd(x // 3, y, 17) > 0.72:
        grain -= 0.07
    if y in (1, 2) and _rnd(x // 5, 0, 23) > 0.80:
        grain += 0.06                   # a bright fleck where the arris is worn through
    return _op(A.quantize(A.ramp_shade("wood", 0.10 + hgt * 0.72 + grain)))


# ── qm_shelf.png — the shelving frame ────────────────────────────────────────
# 9-slice, 16px margins: uprights left and right, a top rail with iron brackets, a
# base rail. The centre is the dark back of the shelf, so contents read against it.
SHELF_W = SHELF_H = 48
SHELF_M = 16


# ── the alcove ──────────────────────────────────────────────────────────────
# The shelves are an OPENING CUT INTO THE WALL, not a carcass standing in front of it
# (author ruling, TD-108). Rings from the outside in:
#   0        the shadow line where the cut meets the wall face
#   1..4     the REVEAL — the wall's own thickness, 4px
#   5..6     an occlusion ramp falling into the interior
#   7+       the interior, near-black, lifting a little at the foot
#
# The reveal is `navestone`, the same ashlar as the wall and the Great Hall: a wooden
# lining would say "a cabinet was fitted here", and the brief asks for shelves cut into
# the building (TD-081 — one stone, one building).
REVEAL_PX = 4


def _alcove_ring(x, y):
    """Distance in from the opening's edge, in pixels."""
    return min(min(x, SHELF_W - 1 - x), min(y, SHELF_H - 1 - y))


def _shelf_h(x, y):
    ring = _alcove_ring(x, y)
    if ring == 0:
        return 0.20                     # the cut's outer shadow line
    if ring <= REVEAL_PX:
        # The reveal FACES the room. A cut's top face catches light and its bottom face
        # is in shadow wherever the alcove sits — that is what makes it read as a hole
        # rather than as a printed border.
        top = y <= REVEAL_PX
        bottom = (SHELF_H - 1 - y) <= REVEAL_PX
        if top:
            return 0.92 - 0.06 * ring
        if bottom:
            return 0.34 - 0.04 * ring
        return 0.62 - 0.05 * ring       # the side faces, between the two
    if ring <= REVEAL_PX + 2:
        return 0.16                     # occlusion ramp into the interior
    # The interior: darkest at the top, lifting slightly at the foot where the boards
    # bounce a little light back up (the TD-104 finding, kept).
    down = y / float(SHELF_H)
    return 0.02 + 0.07 * down


def _shelf(x, y):
    """The alcove, painted from the height field that also drives its normal map."""
    ring = _alcove_ring(x, y)
    hgt = _shelf_h(x, y)

    if ring == 0:
        return _op(A.RAMP["black"][0])                     # the cut line
    if ring <= REVEAL_PX:
        # Stone, and lit by facing. Grain is per-block-ish rather than per-pixel so the
        # reveal reads as cut masonry and not as noise.
        grain = -0.04 if _rnd(x // 3, y // 3, 29) > 0.74 else 0.0
        return _op(A.quantize(A.ramp_shade("navestone", 0.06 + hgt * 0.60 + grain)))
    return _op(A.quantize(A.ramp_shade("navestone", 0.015 + hgt * 0.30)))


# ── qm_label.png — a shelf's label plate ─────────────────────────────────────
# Brass-edged parchment, tied on. 9-slice so a heading of any length keeps its ends.
LABEL_W, LABEL_H, LABEL_M = 24, 14, 7


def _label_h(x, y):
    right, bottom = LABEL_W - 1 - x, LABEL_H - 1 - y
    edge_x, edge_y = min(x, right), min(y, bottom)
    if edge_x == 0 or edge_y == 0:
        return 0.30                     # the plate's outer edge, turned down
    if edge_x == 1 or edge_y == 1:
        return 0.92                     # a bright bevel catching the room
    return 0.60


def _label(x, y):
    """A category plaque: a painted crimson board with a gold-leaf border (TD-107).

    SIGNAGE, not a UI tab. Crimson is already the Collegium's own cloth — the banners
    flanking the Contract Board are this same `wax` ramp — so a plaque nailed to a
    shelf in the same building reads as belonging to the order rather than to the
    interface, which is the whole distinction the brief is drawing.
    """
    right, bottom = LABEL_W - 1 - x, LABEL_H - 1 - y
    edge_x, edge_y = min(x, right), min(y, bottom)

    if edge_x == 0 or edge_y == 0:
        return _op(A.RAMP["wax"][0])               # the turned edge, deepest crimson
    if edge_x == 1 or edge_y == 1:
        return _op(BRASS)                          # a thin line of gold leaf
    if edge_x == 2 or edge_y == 2:
        return _op(A.RAMP["wax"][0])
    # The painted field, lit from above so it reads as a board and not a swatch.
    t = 0.30 + 0.34 * (1.0 - (y / float(LABEL_H)))
    if _rnd(x, y, 61) > 0.93:
        t -= 0.10                                  # flaked paint, sparse
    return _op(A.quantize(A.ramp_shade("wax", t)))


# ── qm_counter.png — the inspection counter ──────────────────────────────────
# 9-slice, 16px margins. A worn top surface the lamp lands on, a panelled front, and
# iron feet. The object under inspection sits ON the top band.
CTR_W, CTR_H, CTR_M = 64, 40, 16


def _counter_h(x, y):
    right = CTR_W - 1 - x
    bottom = CTR_H - 1 - y
    edge_x = min(x, right)
    if y <= 5:                          # the working surface and its front lip
        return [0.66, 0.96, 0.90, 0.78, 0.58, 0.26][y]
    if bottom >= 4:                     # the panelled front
        if edge_x < 3:
            return 0.52                 # the stile
        if edge_x == 3:
            return 0.70                 # the panel's raised bevel
        if edge_x == 4:
            return 0.34
        if y in (9, 10):
            return 0.56                 # a rail across the panel's head
        return 0.40                     # the recessed field
    return 0.16 if edge_x < 5 else 0.04  # iron feet, and deep shadow between them


def _counter(x, y):
    """The inspection counter, painted to the board's register (TD-103).

    The top is the brightest wood in the room because it is where you look; the panel
    recedes; the feet are iron. Wear concentrates at the FRONT EDGE, where a
    quartermaster's forearms have rested for a century — wear that is even across a
    surface reads as noise, wear with a cause reads as age.
    """
    bottom = CTR_H - 1 - y
    edge_x = min(x, CTR_W - 1 - x)
    hgt = _counter_h(x, y)

    if bottom < 4 and edge_x >= 5:
        return _op(BLACK_SOFT)
    if bottom < 4:
        return _op(A.quantize(A.ramp_shade("stone", 0.10 + hgt * 0.9)))

    grain = 0.0
    if y > 5 and _rnd(x // 2, y, 11) > 0.80:
        grain -= 0.05                   # grain in the panel, running with the plank
    if y in (1, 2) and _rnd(x, 0, 41) > 0.62:
        grain += 0.07                   # the polished front edge, rubbed lighter
    return _op(A.quantize(A.ramp_shade("wood", 0.08 + hgt * 0.74 + grain)))


# ── qm_stock.png — dressing. NEVER interactive (R363/P167) ───────────────────
# Eight objects at 16x16. Deliberately low-contrast and small: they say "this
# institution stores hundreds of things" without ever competing with the ten real
# instruments, which are the only lit, reachable objects on the shelves.
STOCK_TILE = 16
STOCK_N = 8
STOCK_W, STOCK_H = STOCK_TILE * STOCK_N, STOCK_TILE


def _crate(x, y):
    if not (1 <= x <= 14 and 4 <= y <= 15):
        return CLEAR
    if x in (1, 14) or y in (4, 15):
        return _op(WOOD_DEEP)
    if y == 5:
        return _op(WOOD_BASE)
    if y in (9, 10):
        return _op(WOOD_DARK)           # the banding strap
    return _op(WOOD_DARK if (x + y) % 5 else WOOD_DEEP)


def _bottle(x, y):
    if 6 <= x <= 9 and 2 <= y <= 4:
        return _op(WOOD_BASE if x in (7, 8) else WOOD_DEEP)   # the stopper
    if 6 <= x <= 9 and 5 <= y <= 7:
        return _op(WOOD_DARK if x in (7, 8) else WOOD_DEEP)   # the neck
    # The shoulder: the body widens over two rows rather than starting square.
    if 8 <= y <= 15:
        half = 2 if y == 8 else (3 if y == 9 else 4)
        if abs(x - 7) <= half or abs(x - 8) <= half:
            if y == 15 or abs(x - 7) == half or abs(x - 8) == half:
                return _op(WOOD_DEEP)
            if x == 5:
                return _op(PARCH_DEEP)  # a dull highlight down the glass
            return _op(WOOD_DARK)
    return CLEAR


def _jar(x, y):
    if 3 <= x <= 12 and 5 <= y <= 15:
        if y == 5 or y == 15 or x in (3, 12):
            return _op(WOOD_DEEP)
        if y == 6:
            return _op(WOOD_BASE)       # the lid's rim
        return _op(WOOD_DARK if x > 4 else IRON_DARK)
    return CLEAR


def _books(x, y):
    if not (2 <= x <= 13 and 6 <= y <= 15):
        return CLEAR
    band = (y - 6) // 3                 # three stacked volumes
    if (y - 6) % 3 == 0:
        return _op(WOOD_DEEP)           # the gap between them
    if x in (2, 13):
        return _op(WOOD_DEEP)
    return _op([WOOD_DARK, WOOD_BASE, WOOD_DARK][band % 3])


def _tin(x, y):
    # Warm, not cold. `stone` reads blue against lamp-lit wood, and a cold box in
    # the middle of the shelf pulls the eye harder than the real instruments do.
    if 3 <= x <= 12 and 7 <= y <= 15:
        if y == 7 or x in (3, 12) or y == 15:
            return _op(WOOD_DEEP)
        if y == 8:
            return _op(BRASS_DIM)       # a banded lid
        return _op(WOOD_DARK if y % 3 else WOOD_BASE)
    return CLEAR


def _roll(x, y):
    # Rolled charts stacked on their sides: three tubes, each with a lit top and a
    # dark mouth, so they read as rolls rather than as one filled block.
    if not (1 <= x <= 14 and 7 <= y <= 15):
        return CLEAR
    tube = (y - 7) // 3
    ly = (y - 7) % 3
    if ly == 0:
        return _op(PARCH_DEEP)          # the shadow between rolls
    # Kept at the DEEP end of parchment: stock must never be the brightest thing on
    # the shelf, or the eye goes to the scenery instead of the ten real instruments.
    if ly == 1:
        return _op(PARCH_DEEP if tube != 1 else PARCH)
    return _op(INK if x in (3, 4) else A.RAMP["foxing"][0])   # the hollow end


def _sack(x, y):
    if 4 <= x <= 11 and 4 <= y <= 15:
        if y <= 5:
            return _op(WOOD_DEEP) if 6 <= x <= 9 else CLEAR   # the tied neck
        if x in (4, 11) or y == 15:
            return _op(WOOD_DEEP)
        return _op(WOOD_DARK)
    return CLEAR


def _case(x, y):
    if 1 <= x <= 14 and 5 <= y <= 15:
        if x in (1, 14) or y in (5, 15):
            return _op(WOOD_DEEP)
        if y == 10:
            return _op(IRON_DARK)       # the seam where it opens
        if x in (7, 8) and 9 <= y <= 11:
            return _op(BRASS_DIM)       # a small clasp
        return _op(WOOD_DARK)
    return CLEAR


STOCK = [_crate, _bottle, _jar, _books, _tin, _roll, _sack, _case]


def _stock(x, y):
    return STOCK[x // STOCK_TILE](x % STOCK_TILE, y)


# ── qm_props.png — the counter's few props ───────────────────────────────────
# Four only. The brief is explicit that the counter must not be cluttered (§8): the
# object under inspection is what matters, and these frame it.
PROP_TILE = 24
PROP_N = 7
PROP_W, PROP_H = PROP_TILE * PROP_N, PROP_TILE


def _ledger(x, y):
    # An open book, seen from slightly above: two leaves and a spine.
    if not (1 <= x <= 22 and 10 <= y <= 21):
        return CLEAR
    if y == 21 or x in (1, 22):
        return _op(WOOD_DEEP)           # the boards
    if x in (11, 12):
        return _op(WOOD_DARK)           # the spine
    if y == 10:
        return _op(PARCH_HI)            # the top leaf, catching the lamp
    if y >= 19:
        return _op(PARCH_DEEP)
    # Ruled writing: short ink dashes, never a solid block.
    if 12 <= y <= 18 and (y % 2 == 0) and (3 <= x <= 9 or 14 <= x <= 20):
        return _op(INK)
    return _op(PARCH)


def _candle(x, y):
    # A lit candle: the room's one warm source, baked. (Light2D cannot reach Control.)
    if 10 <= x <= 13 and 4 <= y <= 17:
        if y <= 5:
            return _op(FLAME_HI if x in (11, 12) else FLAME_LOW)
        return _op(PARCH_HI if x in (11, 12) else PARCH_DEEP)
    if x in (11, 12) and y in (2, 3):
        return _op(FLAME_HI)            # the flame's tip
    if 7 <= x <= 16 and 18 <= y <= 21:
        if y == 18:
            return _op(BRASS_LIT)       # the dish, brightest under the flame
        return _op(BRASS if y == 19 else BRASS_DIM)
    return CLEAR


def _inkwell(x, y):
    if 6 <= x <= 17 and 12 <= y <= 21:
        if y == 12 or x in (6, 17) or y == 21:
            return _op(IRON_DARK)
        if y == 13:
            return _op(IRON)
        if 9 <= x <= 14 and 14 <= y <= 17:
            return _op(INK)             # the ink itself
        return _op(IRON_DARK)
    # The quill standing in it.
    if 13 <= x <= 15 and 2 <= y <= 11:
        return _op(PARCH_HI if x == 14 else PARCH_DEEP)
    return CLEAR


def _scale(x, y):
    # A balance: a post, a beam, and two PANS. The first pass drew each pan as a
    # single row and it disappeared at display size — a pan needs a bowl.
    if x in (11, 12) and 5 <= y <= 19:
        return _op(BRASS_DIM if x == 11 else BRASS)   # the post, lit on one side
    if y == 5 and 3 <= x <= 20:
        return _op(BRASS)               # the beam
    if y == 4 and x in (11, 12):
        return _op(BRASS_LIT)           # the pivot
    if 6 <= y <= 8 and x in (3, 20):
        return _op(BRASS_DIM)           # the chains
    if 9 <= y <= 11:
        for cx in (3, 20):
            if abs(x - cx) <= 3 - (y - 9):
                return _op(BRASS_LIT if y == 9 else BRASS_DIM)
    if y == 20 and 7 <= x <= 16:
        return _op(BRASS)               # the foot
    if y == 21 and 6 <= x <= 17:
        return _op(BRASS_DIM)
    return CLEAR


def _wax(x, y):
    """A stick of sealing wax and a stamp — the tools the rite actually uses."""
    if 9 <= x <= 13 and 4 <= y <= 15:
        return _op(WAX_RED if x in (10, 11, 12) else A.RAMP["wax"][0])
    if 6 <= x <= 16 and 16 <= y <= 18:
        return _op(BRASS if y == 16 else BRASS_DIM)      # the stamp's collar
    if 8 <= x <= 14 and 19 <= y <= 21:
        return _op(BRASS_DIM if y == 21 else BRASS)      # its face
    return CLEAR


def _papers(x, y):
    """A leaning stack of filed paperwork. Three sheets, offset."""
    for i, (ox, oy) in enumerate(((0, 0), (2, -3), (1, -6))):
        left, right = 3 + ox, 19 + ox
        top = 18 + oy
        if left <= x <= right and top <= y <= top + 3:
            if y == top:
                return _op(PARCH_HI)
            if y == top + 3 or x in (left, right):
                return _op(PARCH_DEEP)
            return _op(PARCH if (x + i) % 6 else INK)
    return CLEAR


def _lamp(x, y):
    """A small iron wall-lamp, hung on a bracket.

    It exists because the shelves needed a fill light and **a light with no visible
    source is a cheat** — the Contract Board couples every flame to its sconce (P95),
    and this room should not be the exception. Dimmer than the candle by design: it is
    the far end of the room, and the bench is meant to stay the lit place.
    """
    # The bracket, out to the left and hooking over.
    if 2 <= x <= 4 and 3 <= y <= 5:
        return _op(IRON_DARK)
    if 4 <= x <= 10 and y == 3:
        return _op(IRON if x > 5 else IRON_DARK)
    if x == 10 and 4 <= y <= 6:
        return _op(IRON_DARK)
    # The lamp body: an iron cage over a warm pane.
    if 6 <= x <= 15 and 7 <= y <= 18:
        if x in (6, 15) or y in (7, 18):
            return _op(IRON_DARK)
        if y == 8 or y == 17:
            return _op(IRON)
        if x in (10, 11) and 9 <= y <= 16:
            return _op(FLAME_LOW)          # the flame seen through the glass
        if 8 <= x <= 13 and 9 <= y <= 16:
            return _op(BRASS)              # the warm pane
        return _op(IRON_DARK)
    if 8 <= x <= 13 and y == 19:
        return _op(IRON_DARK)              # the drip lip
    return CLEAR


PROPS = [_ledger, _candle, _inkwell, _scale, _wax, _papers, _lamp]


def _props(x, y):
    return PROPS[x // PROP_TILE](x % PROP_TILE, y)


# ── qm_satchel.png — the pack, OPEN ─────────────────────────────────────────
# A closed case says "storage". An OPEN satchel says "being loaded", which is what
# this screen is for (author brief): the flap is folded back over the top, the mouth
# gapes, and the compartments inside are what the instruments drop into.
SATCH_W, SATCH_H, SATCH_M = 64, 48, 18


def _satchel_h(x, y):
    edge_x = min(x, SATCH_W - 1 - x)
    if y <= 6:
        return 0.86 - 0.05 * y          # the flap, folded back and catching light
    if y == 7:
        return 0.20                     # the fold's shadow
    if y <= 10:
        return 0.12                     # the open mouth, dark
    if edge_x < 4:
        return 0.62                     # the bag's sides
    return 0.26                         # the interior


def _satchel(x, y):
    edge_x = min(x, SATCH_W - 1 - x)
    bottom = SATCH_H - 1 - y
    hgt = _satchel_h(x, y)

    if y <= 7:                                     # the folded-back flap
        if y == 6 and (x % 4) in (1, 2):
            return _op(A.RAMP["parchment"][0])     # a stitch line along the hem
        return _op(A.quantize(A.ramp_shade("wood", 0.16 + hgt * 0.62)))
    if y <= 10:                                    # the mouth: darkest band on the
        return _op(BLACK_SOFT if y < 10 else WOOD_DEEP)   # object, so it reads OPEN
    if edge_x < 4:
        if edge_x == 3:
            return _op(WOOD_BASE)                  # the lit inner lip
        return _op(A.quantize(A.ramp_shade("wood", 0.10 + hgt * 0.55)))
    if bottom < 3:
        return _op(A.quantize(A.ramp_shade("wood", 0.10 + (3 - bottom) * 0.12)))
    return _op(A.quantize(A.ramp_shade("navestone", 0.03 + hgt * 0.10)))


# ── normal maps ─────────────────────────────────────────────────────────────
# Emitted from the SAME height functions that drive the paint, so relief and shading
# can never disagree. The room's surfaces are then lit at run time by the Contract
# Board's own shader (`board_surface.gdshader`) from a candle rig — Light2D cannot
# reach Control nodes (TD-047), which is exactly why that shader exists.
NORMALS = [
    ("stations/qm_wall_n.png",    WALL_W,  WALL_H,  _wall_h,    2.6),
    ("stations/qm_shelf_n.png",   SHELF_W, SHELF_H, _shelf_h,   3.0),
    ("stations/qm_board_n.png",   BOARD_W, BOARD_H, _board_h,   3.0),
    ("stations/qm_counter_n.png", CTR_W,   CTR_H,   _counter_h, 2.4),
    ("stations/qm_satchel_n.png", SATCH_W, SATCH_H, _satchel_h, 2.6),
]


def _emit_normal(path, w, h, hfn, strength):
    lum = [hfn(x, y) for y in range(h) for x in range(w)]
    A.write_png(path, w, h, _normal_pixel(w, h, lum, strength))
    print("wrote %s (%dx%d) normal" % (path, w, h))


TARGETS = [
    ("stations/qm_wall.png",    WALL_W,  WALL_H,  _wall),
    ("stations/qm_shelf.png",   SHELF_W, SHELF_H, _shelf),
    ("stations/qm_board.png",   BOARD_W, BOARD_H, _board),
    ("stations/qm_label.png",   LABEL_W, LABEL_H, _label),
    ("stations/qm_counter.png", CTR_W,   CTR_H,   _counter),
    ("stations/qm_satchel.png", SATCH_W, SATCH_H, _satchel),
    ("stations/qm_stock.png",   STOCK_W, STOCK_H, _stock),
    ("stations/qm_props.png",   PROP_W,  PROP_H,  _props),
]


def _assert_on_palette():
    """Every opaque pixel must resolve to a defined Ash & Ember stop.

    The board's own check (TD-046). Semi-transparent shadow pixels are exempt: they
    are black at a varying alpha, which is a compositing operation, not a new colour.
    """
    bad = {}
    for _, w, h, fn in TARGETS:
        for y in range(h):
            for x in range(w):
                r, g, b, a = fn(x, y)
                if a == 0 or (r, g, b) == A.RAMP["black"][0] and a < 255:
                    continue
                if (r, g, b) not in A.PALETTE_SET:
                    bad[(r, g, b)] = bad.get((r, g, b), 0) + 1
    assert not bad, "off-palette colours: %r" % (sorted(bad.items())[:6],)


if __name__ == "__main__":
    _assert_on_palette()
    for path, w, h, fn in TARGETS:
        A.write_png(path, w, h, fn)
        print("wrote %s (%dx%d)" % (path, w, h))
    for path, w, h, hfn, strength in NORMALS:
        _emit_normal(path, w, h, hfn, strength)
    print("9-slice margins: shelf=%d board=%d label=%d counter=%d"
          % (SHELF_M, BOARD_M, LABEL_M, CTR_M))
