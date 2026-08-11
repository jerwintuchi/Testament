#!/usr/bin/env python3
"""Generate the Quartermaster's ROOM — the Collegium's stores (TD-101).

The Quartermaster stopped being a writ with a list on it and became a place: a
supply room with open shelving, labelled compartments, an inspection counter and a
lamp. This generator emits the MODULAR pieces that room is assembled from, never a
single painted backdrop — the brief forbids that (§17), and TD-072 already recorded
a procedurally generated hero plate as a structural failure.

The SHELVING, the PLANK, the BENCH and the STOCK sheet are no longer here (TD-113):
the author drew that furniture by hand, and `gen_qm_furniture.py` derives the runtime
pieces from it. Their painters and normal maps are deleted rather than left dormant —
generated art with no consumer is what TD-070 had to go back and clean up. This file
now covers the wall, the label plate, the props and the room's smaller fittings.

Authored at DISPLAY size and shown 1:1 NEAREST (TD-050/TD-055: the client rasterises
UI at native resolution, so a downscale is mush). Chunky clusters, hard edges, no
anti-aliasing, no gradients; every opaque colour resolves to an Ash & Ember stop,
which `assert_on_palette` proves.

`navestone` is reused deliberately: it is the nave's own ashlar, so this room and the
title screen's hall are the same building (the TD-081 rule).

Deterministic and safe to re-run: same bytes every time, and it writes only the files
named below.

    cd client/assets/ui && python3 gen_qm_room.py
      -> stations/qm_wall.png      64x64   tiling ashlar backdrop
      -> stations/qm_label.png     24x14   9-slice label plate, 7px margins
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
        # The mortar is not a ruled line. Its depth varies along the run, which is
        # what stops a wall of identical joints reading as printed graph paper.
        return 0.10 - 0.05 * _rnd(x // 2, y // 2, 67)
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
    # CHIPPED ARRISES (R394). Wear is structural: a block loses its corners first,
    # because that is where two exposed edges meet and nothing supports the stone
    # behind them. Scattering the same number of dark pixels evenly over the face
    # would read as dirt; concentrating them on the arrises reads as age.
    arris = min(ly, COURSE - 1 - ly, lx, BLOCK - 1 - lx)
    if arris <= 3 and _rnd(x, y, 53) > 0.86:
        hgt -= 0.18 * (1.0 - arris / 4.0)
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


# ── qm_cloth.png — the altar cloth over the bench ───────────────────────────
# The reference's most striking counter element, and NOT decoration: this is the
# inspection surface (author ruling, TD-110) — the instrument the player chooses is
# set down on it. Crimson with gold crosses, darker folds at the sides, and a fringed
# hem living in the 9-slice's BOTTOM border so it never stretches.
# AUTHORED AT DISPLAY SIZE and drawn 1:1 NEAREST (TD-050/TD-055). The first pass made
# it a 9-slice and the crosses live in the centre — which is the region a 9-slice
# STRETCHES, so they smeared into gold streaks. A 9-slice is for frames whose middle is
# a uniform fill; a patterned cloth has to be drawn at the size it is shown.
# Re-cut for the author's bench (TD-113). At 128x80 it covered a 92px-tall table almost
# entirely and read as a banner hung over it rather than as a cloth laid on it — the
# generated counter it was drawn for had no visible top plane to lay against. 104x46 sits
# on the top plane and hangs the hem a little past the arris, which is what a cloth on a
# table does, and it leaves the bench's own wood showing at both ends where the writing
# set and the sealing tools stand.
CLOTH_W, CLOTH_H = 104, 46
FRINGE = 11           # rows of loose thread at the hem


def _cross(lx, ly, size):
    """A Collegium cross in a size x size box, as a boolean stamp."""
    c = size // 2
    arm = max(1, size // 8)
    if abs(lx - c) <= arm and 0 <= ly < size:
        return True                                   # the upright
    if abs(ly - (c - size // 8)) <= arm and 1 <= lx < size - 1:
        return True                                   # the crossbar
    return False


def _cloth(x, y):
    right = CLOTH_W - 1 - x
    bottom = CLOTH_H - 1 - y
    edge_x = min(x, right)

    # The fringe: loose threads, each column its own length, so the hem reads as
    # thread rather than as a serrated edge.
    if bottom < FRINGE:
        depth = FRINGE - 1 - bottom
        length = 3 + int(_rnd(x, 0, 91) * 7.0)
        if depth >= length or (x % 2 and depth >= length - 1):
            return CLEAR
        return _op(A.RAMP["gold"][0] if depth >= length - 1 else A.RAMP["wax"][0])

    # Deep oxblood, not pillar-box red: the reference's cloth is nearly brown in the
    # folds and only the gold lifts it.
    t = 0.20 - 0.10 * (edge_x < 10) - 0.06 * (edge_x < 5)
    t += 0.10 * (1.0 - y / float(CLOTH_H))
    if _rnd(x // 2, y // 2, 71) > 0.92:
        t -= 0.06                                     # a slub in the weave

    # Gold crosses, one per repeat, laid on the field.
    if _cross((x - 18) % 44, (y - 12) % 40, 17) and 8 <= x < CLOTH_W - 8 and y >= 8:
        return _op(A.RAMP["gold"][1] if (x + y) % 5 else A.RAMP["gold"][0])
    if bottom == FRINGE:
        return _op(A.RAMP["gold"][0])                 # a gold band above the hem
    return _op(A.quantize(A.ramp_shade("wax", max(0.05, min(0.95, t)))))


# ── the room's furniture (TD-110 T414) ──────────────────────────────────────
# Node budget is the binding constraint here (204/220), so anything that never moves
# is BAKED into one composite and costs a single node. Only the lantern animates.

# qm_lantern.png — hung on a chain beside the shelves. Its own node: it flickers.
LANT_W, LANT_H = 20, 60


def _lantern(x, y):
    """A hung lantern: chain, hook, then a caged flame.

    The first pass gated the cage on `edge < 6` inside a 20px sprite, so only a narrow
    strip of it ever drew — it read as two vertical bars. The cage is now built from
    explicit bands, which is legible to read and legible to fix.
    """
    cx = LANT_W // 2
    edge = min(x, LANT_W - 1 - x)

    if y < 21:                                   # the chain, links alternating
        off = 1 if (y // 3) % 2 else -1
        if abs(x - (cx + off)) <= 1 and (y % 3) != 2:
            return _op(IRON_DARK if (y % 3) else IRON)
        return CLEAR
    if y < 24:                                   # the hook it hangs from
        return _op(IRON) if abs(x - cx) in (2, 3) else CLEAR
    if y > 55 or edge < 1:
        return CLEAR

    if y < 27:                                   # the crown
        return _op(IRON_DARK if y == 24 else IRON)
    if y > 51:                                   # the base
        return _op(IRON_DARK if y == 55 else IRON)

    # The body: iron uprights, a warm pane between, and a flame at its heart.
    if edge < 3:
        return _op(IRON_DARK if edge < 2 else IRON)
    if abs(x - cx) <= 1 and 33 <= y <= 45:
        return _op(FLAME_HI)
    if abs(x - cx) <= 3 and 31 <= y <= 48:
        return _op(FLAME_LOW)
    return _op(A.quantize(A.ramp_shade("gold", 0.26 + 0.20 * (1.0 - abs(x - cx) / 8.0))))


# qm_banner.png — the Collegium's colours at the top-left corner of the room.
BANN_W, BANN_H = 26, 54


def _banner(x, y):
    if y < 3:                                    # the rod
        return _op(IRON if y == 1 else IRON_DARK) if 1 <= x < BANN_W - 1 else CLEAR
    edge = min(x, BANN_W - 1 - x)
    if edge < 2:
        return CLEAR
    # A swallowtail hem: the cloth splits into two points at its foot.
    if y > BANN_H - 12:
        depth = y - (BANN_H - 12)
        if abs(x - BANN_W // 2) < depth - 1:
            return CLEAR
    if _cross(x - 5, y - 16, 15):
        return _op(A.RAMP["gold"][1] if (x + y) % 4 else A.RAMP["gold"][0])
    t = 0.22 + 0.10 * (1.0 - y / float(BANN_H)) - 0.08 * (edge < 4)
    return _op(A.quantize(A.ramp_shade("wax", t)))


# qm_notes.png — pinned scraps, BAKED as one composite (P175).
NOTE_W, NOTE_H = 44, 34


def _notes(x, y):
    # Three scraps at slightly different sizes and offsets. Positions are literal
    # rather than seeded: a wall of notes is arranged by a person, not scattered.
    for ox, oy, w, h, pin in ((0, 2, 17, 22, True), (19, 0, 14, 18, True), (22, 21, 20, 12, False)):
        if ox <= x < ox + w and oy <= y < oy + h:
            lx, ly = x - ox, y - oy
            if pin and ly == 0 and lx == w // 2:
                return _op(WAX_RED)              # the wax blob holding it up
            if lx == 0 or ly == 0 or lx == w - 1 or ly == h - 1:
                return _op(PARCH_DEEP)
            # Ruled writing: short ink dashes, never a solid block.
            if ly % 3 == 1 and 2 <= lx <= w - 3 and (lx + ly) % 7 < 4:
                return _op(INK)
            return _op(PARCH if (lx + ly) % 9 else PARCH_HI)
    return CLEAR


# qm_floor.png — flagstones at the foot of the frame. Tiles horizontally.
FLOOR_W, FLOOR_H = 32, 18


def _floor(x, y):
    if y < 2:
        return _op(A.RAMP["black"][0])           # where the floor meets the wall
    lx = (x + (16 if (y // 9) % 2 else 0)) % 16
    if lx == 0 or y % 9 == 2:
        return _op(A.RAMP["navestone"][0])       # joints
    v = _rnd(x // 16, y // 9, 13)
    return _op(A.quantize(A.ramp_shade("navestone", 0.05 + 0.06 * v)))


# qm_rite.png — the SEAL & DEPART plate. A 9-slice whose CENTRE IS A UNIFORM FIELD,
# which is the only shape a 9-slice may take (the lesson from the cloth and the rule).
RITE_W, RITE_H, RITE_M = 32, 24, 10


def _rite(x, y):
    right, bottom = RITE_W - 1 - x, RITE_H - 1 - y
    edge = min(min(x, right), min(y, bottom))
    if edge == 0:
        return _op(A.RAMP["black"][0])
    if edge == 1:
        return _op(A.RAMP["gold"][1])            # the gold rule
    if edge == 2:
        return _op(A.RAMP["gold"][0])
    if edge == 3:
        return _op(A.RAMP["wax"][0])
    return _op(A.quantize(A.ramp_shade("wax", 0.24)))    # uniform field: stretch-safe


# qm_rite_seal.png — the disc at the plate's left hand.
SEAL_W = SEAL_H = 18


def _rite_seal(x, y):
    cx = cy = SEAL_W // 2
    d = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
    if d > 8.4:
        return CLEAR
    if d > 7.0:
        return _op(A.RAMP["gold"][0])
    if d > 6.0:
        return _op(A.RAMP["wax"][0])
    if _cross(x - cx + 4, y - cy + 5, 10):
        return _op(A.RAMP["gold"][1])
    return _op(A.quantize(A.ramp_shade("wax", 0.30 + 0.16 * (1.0 - d / 6.0))))


# ── normal maps ─────────────────────────────────────────────────────────────
# Emitted from the SAME height functions that drive the paint, so relief and shading
# can never disagree. The room's surfaces are then lit at run time by the Contract
# Board's own shader (`board_surface.gdshader`) from a candle rig — Light2D cannot
# reach Control nodes (TD-047), which is exactly why that shader exists.
NORMALS = [
    ("stations/qm_wall_n.png",    WALL_W,  WALL_H,  _wall_h,    2.6),
    ("stations/qm_satchel_n.png", SATCH_W, SATCH_H, _satchel_h, 2.6),
]


def _emit_normal(path, w, h, hfn, strength):
    lum = [hfn(x, y) for y in range(h) for x in range(w)]
    A.write_png(path, w, h, _normal_pixel(w, h, lum, strength))
    print("wrote %s (%dx%d) normal" % (path, w, h))


TARGETS = [
    ("stations/qm_wall.png",    WALL_W,  WALL_H,  _wall),
    ("stations/qm_label.png",   LABEL_W, LABEL_H, _label),
    ("stations/qm_satchel.png", SATCH_W, SATCH_H, _satchel),
    ("stations/qm_cloth.png",   CLOTH_W, CLOTH_H, _cloth),   # 1:1, never 9-sliced
    ("stations/qm_lantern.png", LANT_W,  LANT_H,  _lantern),
    ("stations/qm_banner.png",  BANN_W,  BANN_H,  _banner),
    ("stations/qm_notes.png",   NOTE_W,  NOTE_H,  _notes),
    ("stations/qm_floor.png",   FLOOR_W, FLOOR_H, _floor),
    ("stations/qm_rite.png",    RITE_W,  RITE_H,  _rite),
    ("stations/qm_rite_seal.png", SEAL_W, SEAL_H, _rite_seal),
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
    # The label plate is the only 9-slice this generator still emits: the shelving, the
    # plank and the bench are the author's hand-drawn furniture now, and their margins
    # are declared beside the art in `gen_qm_furniture.py` and `room.gd`.
    print("9-slice margins: label=%d" % LABEL_M)
