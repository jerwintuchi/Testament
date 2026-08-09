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
COURSE = 16
BLOCK = 32


def _wall(x, y):
    course = y // COURSE
    ly = y % COURSE
    # Every other course is offset half a block, the way ashlar is actually laid.
    off = (BLOCK // 2) if (course % 2) else 0
    lx = (x + off) % BLOCK

    if ly == 0 or lx == 0:
        return _op(WALL_JOINT)          # mortar: a recess, so it reads as a shadow
    if ly == 1:
        return _op(WALL_MID)            # the lit top lip of each block
    # Blocks vary by one step so the wall is not a flat field, chosen per BLOCK
    # (not per pixel) so the variation lands on stone edges — the TD-075 rule.
    v = _rnd(x // BLOCK + off, course, 7)
    base = WALL_BASE if v > 0.42 else WALL_DARK
    if ly >= COURSE - 2:
        return _op(WALL_DARK)           # each block sits in its own shadow
    return _op(base)


# ── qm_board.png — one shelf plank ───────────────────────────────────────────
# 9-slice with 4px margins so it stretches to any shelf width while the lit top edge
# and the shadow beneath stay one pixel each. Objects STAND on the top edge.
BOARD_W, BOARD_H, BOARD_M = 16, 12, 4


def _board(x, y):
    if y == 0:
        return _op(WOOD_LIT)            # the edge the lamp catches
    if y == 1:
        return _op(WOOD_BASE)
    if y in (2, 3):
        return _op(WOOD_DARK)
    if y == 4:
        return _op(WOOD_DEEP)           # the front face falling into shadow
    if y == 5:
        return _op(BLACK_SOFT)
    # Under the plank: the shadow it throws onto whatever is below, fading out.
    fall = (y - 6) / float(BOARD_H - 6)
    a = int(150 * (1.0 - fall))
    return (BLACK[0], BLACK[1], BLACK[2], max(a, 0))


# ── qm_shelf.png — the shelving frame ────────────────────────────────────────
# 9-slice, 16px margins: uprights left and right, a top rail with iron brackets, a
# base rail. The centre is the dark back of the shelf, so contents read against it.
SHELF_W = SHELF_H = 48
SHELF_M = 16


def _shelf(x, y):
    right = SHELF_W - 1 - x
    bottom = SHELF_H - 1 - y
    edge_x = min(x, right)
    edge_y = min(y, bottom)

    # The back of the case: almost black, so an instrument in front of it pops.
    if edge_x >= 6 and edge_y >= 5:
        return _op(BLACK_SOFT)

    # Uprights: a post with a lit inner edge and a dark outer one.
    if edge_x < 6:
        if edge_x == 0:
            return _op(WOOD_DEEP)
        if edge_x == 5:
            return _op(WOOD_LIT)        # the inner face the lamp reaches
        if edge_x in (1, 2):
            return _op(WOOD_DARK)
        return _op(WOOD_BASE)

    # Top rail carries iron brackets; the base rail is plain and dark.
    if y < 5:
        if y == 0:
            return _op(WOOD_DEEP)
        if y == 1:
            return _op(WOOD_HI)         # the top edge, catching the lamp
        # Iron strap every 8px along the rail.
        if y >= 2 and (x % 8) in (3, 4):
            return _op(IRON if y == 2 else IRON_DARK)
        return _op(WOOD_BASE if y == 2 else WOOD_DARK)
    if bottom < 5:
        return _op(WOOD_DEEP if bottom < 2 else WOOD_DARK)
    return _op(BLACK_SOFT)


# ── qm_label.png — a shelf's label plate ─────────────────────────────────────
# Brass-edged parchment, tied on. 9-slice so a heading of any length keeps its ends.
LABEL_W, LABEL_H, LABEL_M = 24, 14, 7


def _label(x, y):
    right = LABEL_W - 1 - x
    bottom = LABEL_H - 1 - y
    edge_x = min(x, right)
    edge_y = min(y, bottom)
    if edge_y == 0 or edge_x == 0:
        return _op(BRASS_DIM)           # the brass rim
    if edge_y == 1 and edge_x >= 1:
        return _op(BRASS if y < LABEL_H // 2 else BRASS_DIM)
    if edge_x == 1:
        return _op(BRASS_DIM)
    # The card itself, darker at the foot so it reads as a plate with depth.
    # FLAT, deliberately: an (x+y) modulo draws diagonal stripes across the plate,
    # which is what the first pass shipped and read as hatching, not paper.
    if bottom <= 3:
        return _op(PARCH_DEEP)
    if y == LABEL_H - 5:
        return _op(PARCH)               # one ruled line under the heading
    return _op(PARCH_HI)


# ── qm_counter.png — the inspection counter ──────────────────────────────────
# 9-slice, 16px margins. A worn top surface the lamp lands on, a panelled front, and
# iron feet. The object under inspection sits ON the top band.
CTR_W, CTR_H, CTR_M = 64, 40, 16


def _counter(x, y):
    right = CTR_W - 1 - x
    bottom = CTR_H - 1 - y
    edge_x = min(x, right)

    # The top surface: the brightest wood in the room, because this is where you look.
    if y == 0:
        return _op(WOOD_BASE)
    if y in (1, 2):
        return _op(WOOD_HI)             # the lit working surface
    if y == 3:
        return _op(WOOD_LIT)
    if y == 4:
        return _op(WOOD_BASE)
    if y == 5:
        return _op(WOOD_DEEP)           # the lip's shadow, separating top from front
    # The panelled front: a recessed panel with a bevel, not a flat slab.
    # Grain runs in LINES along the plank, never as scattered dots — a modulo on
    # (x*3+y) makes a regular polka pattern, which is what the first pass shipped.
    if bottom >= 4:
        if edge_x < 3:
            return _op(WOOD_DARK)
        if edge_x == 3:
            return _op(WOOD_BASE)       # the panel's raised bevel
        if edge_x == 4:
            return _op(WOOD_DEEP)
        if y in (9, 10):
            return _op(WOOD_DARK)       # a rail across the panel's head
        return _op(WOOD_DARK if (y % 5 == 2) else WOOD_DEEP)
    # Iron feet at the corners; deep shadow between them.
    if edge_x < 5:
        return _op(IRON_DARK if bottom == 0 else IRON)
    return _op(BLACK_SOFT)


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
PROP_N = 4
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


PROPS = [_ledger, _candle, _inkwell, _scale]


def _props(x, y):
    return PROPS[x // PROP_TILE](x % PROP_TILE, y)


TARGETS = [
    ("stations/qm_wall.png",    WALL_W,  WALL_H,  _wall),
    ("stations/qm_shelf.png",   SHELF_W, SHELF_H, _shelf),
    ("stations/qm_board.png",   BOARD_W, BOARD_H, _board),
    ("stations/qm_label.png",   LABEL_W, LABEL_H, _label),
    ("stations/qm_counter.png", CTR_W,   CTR_H,   _counter),
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
    print("9-slice margins: shelf=%d board=%d label=%d counter=%d"
          % (SHELF_M, BOARD_M, LABEL_M, CTR_M))
