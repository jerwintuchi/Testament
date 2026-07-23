#!/usr/bin/env python3
"""Notice Board Pass-2 — Batch 1 structure assets (T141).

Generates the board's structural layer on the Ash & Ember foundation (ashember.py):
a carved 9-slice frame, a plank backing, a hanging placard plaque, a tileable
stone/mortar surround, and the torch (grayscale flame frames + glow source + a
sconce). Board art is quantized to the locked palette; the torch flame/glow are
grayscale-additive VFX sources (white+alpha), tinted to the flame ramp in Godot.

Runnable: `python3 gen_structure.py` → writes the PNGs beside this file and asserts
each is on-palette (VFX sources under allow_vfx). Aseprite finishing happens after.
"""
import os
from ashember import (
    RAMP, write_png, quantize, noise, lerp_rgb, additive, assert_on_palette,
    ramp_shade, warm, cool, over, smooth,
    STONE_DEEP, STONE_MID, STONE_LIT, STONE_SHADOW, STONE_HI,
    WOOD_EDGE, WOOD_BASE, WOOD_BEVEL, WOOD_DEEP, WOOD_HI,
    GOLD_DIM, GOLD, BLACK,
)

HERE = os.path.dirname(os.path.abspath(__file__))


def _q(rgb, a=255):
    return quantize(rgb) + (a,)


# ── Carved frame — 9-slice border, heavy timber, iron corner brackets ────────
# 88×88, border B; the interior is transparent so the backing shows through.
# A thick, deeply-carved moulding (Prototype v1): raised outer bevel → broad face →
# deep routed groove → gilt inner liner, with a wrought-iron L-bracket bolted over
# each corner. Light reads from the top-left (lit top/left faces, shadowed B/R).
FRAME_W = FRAME_H = 88
FRAME_B = 26
_BRACKET = 22          # iron corner bracket reach along each rail
_BRACKET_W = 9         # bracket band width (outer edge inward)
_BOLTS = ((4, 4), (4, 15), (15, 4))   # bolt heads on the bracket (corner-local)


def frame_px(x, y):
    left, top, right, bottom = x, y, FRAME_W - 1 - x, FRAME_H - 1 - y
    d = min(left, top, right, bottom)
    if d >= FRAME_B:
        return (0, 0, 0, 0)                                         # hollow interior

    # Corner-local coordinates (distance from the nearest corner along each rail).
    near_l, near_r = left < FRAME_B, right < FRAME_B
    near_t, near_b = top < FRAME_B, bottom < FRAME_B
    cxr = left if near_l else right
    cyr = top if near_t else bottom
    in_corner = (near_l or near_r) and (near_t or near_b)

    # ── Wrought-iron corner bracket: an L of dark iron bolted over the timber, its
    # outer band beveled and lit at the top-left, with three domed bolt heads.
    if in_corner and cxr < _BRACKET and cyr < _BRACKET and (cxr < _BRACKET_W or cyr < _BRACKET_W):
        for bx, by in _BOLTS:
            r2 = (cxr - bx) ** 2 + (cyr - by) ** 2
            if r2 <= 2:
                return _q(ramp_shade("stone", 0.96))                # bolt crown (specular)
            if r2 <= 6:
                return _q(ramp_shade("stone", 0.58))                # domed bolt body
            if r2 <= 9:
                return _q(ramp_shade("black", 0.55))                # bolt shadow ring
        if cxr == 0 or cyr == 0:
            return _q(ramp_shade("black", 0.20))                    # iron outer edge
        edge_lit = cxr <= 1 or cyr <= 1
        inner_edge = cxr == _BRACKET_W - 1 or cyr == _BRACKET_W - 1
        it = 0.30 + noise(x, y, 41) * 0.010
        if edge_lit:
            it = 0.60                                               # lit chamfer, top-left
        elif inner_edge:
            it = 0.16                                               # shadowed inner step
        return _q(ramp_shade("stone", it))

    if d == 0:
        return _q(ramp_shade("black", 0.20))                       # outer outline

    lit = (d == left or d == top)                                   # top-left catches light

    # Carved height profile across the border width: raised outer bevel, broad face,
    # a deep routed groove, a gilt inner lip, then a fall to the interior edge.
    b = d / float(FRAME_B - 1)                                      # 0 outer .. 1 inner
    if b < 0.14:
        height = 0.50 + b * 3.0                                     # steep outer bevel rising
    elif b < 0.46:
        height = 0.94 - (b - 0.14) * 0.30                           # broad lit face
    elif b < 0.60:
        height = 0.16                                              # DEEP routed groove (recessed)
    elif b < 0.82:
        height = 0.82                                              # inner lip
    else:
        height = 0.66 - (b - 0.82) * 1.8                           # fall to interior edge

    base_t = height * (1.0 if lit else 0.58)                        # stronger directional contrast

    # Mitred 45° corner joint: a darker seam where two border runs meet.
    if in_corner and abs(min(left, right) - min(top, bottom)) <= 0:
        base_t *= 0.50

    # Wood grain: lengthwise streaks (both rail orientations) + fine speckle, so the
    # timber reads carved and aged, not a flat bevel (Prototype v1).
    base_t += noise(x // 7, y, 22) * 0.014                           # vertical streak (L/R rails)
    base_t += noise(x, y // 7, 23) * 0.014                           # horizontal streak (T/B rails)
    base_t += noise(x, y, 13) * 0.006                                # fine speckle
    col = ramp_shade("wood", max(0.0, min(1.0, base_t)))
    if 0.46 <= b < 0.60:                                            # grime settled in the deep groove
        col = over(col, ramp_shade("black", 0.42), 0.55)
    if b >= 0.82:                                                   # gilded inner liner (Prototype-v1)
        col = ramp_shade("gold", 0.72 if lit else 0.32)
    return _q(col)


# ── Plank backing — 9-slice-safe wood field ──────────────────────────────────
# Near-uniform grain so 9-slice stretch never smears a seam; faint horizontal
# plank grooves + speckle read as boards without a directional stretch artifact.
BACK_W = BACK_H = 48


def backing_px(x, y):
    v = noise(x, y, 7) * 0.6
    groove = -10 if (y % 12) in (0,) else 0                        # subtle horizontal plank line
    return _q((WOOD_BASE[0] + v + groove, WOOD_BASE[1] + v + groove, WOOD_BASE[2] + v + groove))


# ── Hanging placard plaque — 9-slice; text drawn by Godot on top ─────────────
# Dark routed sign; nail holes in the top corners (fixed region). Godot renders
# "PETITIONS BEFORE THE COLLEGIUM" in dim gold via the UI font over the centre.
PLAC_W, PLAC_H = 64, 24
PLAC_MX, PLAC_MY = 14, 8
_NAILS = ((5, 5), (58, 5))


def placard_px(x, y):
    left, top, right, bottom = x, y, PLAC_W - 1 - x, PLAC_H - 1 - y
    d = min(left, top, right, bottom)
    for cx, cy in _NAILS:                                          # nail holes
        dx, dy = x - cx, y - cy
        if dx * dx + dy * dy <= 2:
            return BLACK + (255,)
        if dx * dx + dy * dy <= 5:
            return _q(GOLD_DIM)                                    # brass nail head
    if d == 0:
        return BLACK + (255,)
    lit = (d == left or d == top)
    if d == 1:
        return _q(WOOD_BEVEL if lit else WOOD_EDGE)               # bevel
    if d == 3:
        return _q(GOLD_DIM if lit else WOOD_EDGE)                 # inner routed gold-lined groove
    if d == 4:
        return _q(WOOD_EDGE if lit else WOOD_DEEP)                # carved inner lip below the groove
    # dark plaque field, DEEPENED for the dungeon-dark key (T159) so the gilt title pops
    v = noise(x, y, 11) * 0.4
    field = lerp_rgb(WOOD_DEEP, WOOD_EDGE, 0.30)                  # between deep + edge, darker than before
    return _q((field[0] + v, field[1] + v, field[2] + v))


# ── Stone / mortar surround — tileable, ambient-candlelit ────────────────────
# Recognizable brick+mortar (never black); offset courses; wraps on all edges.
STONE_W, STONE_H = 48, 32
BRICK_H = 8
BRICK_W = 24


def stone_px(x, y):
    row = y // BRICK_H
    off = (BRICK_W // 2) if (row % 2) else 0
    xm = (x + off) % BRICK_W
    ym = y % BRICK_H
    col_id = (x + off) // BRICK_W

    # Deep mortar recess (wrap-safe on all edges): the darkest tone, so bricks
    # read as raised blocks with real gaps between them.
    if ym == 0 or xm == 0:
        return _q(ramp_shade("stone", 0.0))

    # Per-brick tone: each block sits at a slightly different value, with an
    # occasional darker/soot-stained stone — masonry variety, not one flat field.
    brick = noise(col_id, row, 5)                                 # -8..8 per block
    base_t = 0.44 + brick * 0.017
    if noise(col_id, row, 6) > 5:
        base_t -= 0.15                                           # sooted/older stone

    # Beveled brick face: lit toward top-left, occluded toward the mortar gaps.
    chamf = smooth(0.0, 3.0, float(min(min(xm, BRICK_W - xm), min(ym, BRICK_H - ym))))
    dirl = 0.0
    if xm <= 2:            dirl += 0.10                           # left face catches light
    if ym <= 1:            dirl += 0.12                           # top face catches light
    if xm >= BRICK_W - 2:  dirl -= 0.10
    if ym >= BRICK_H - 2:  dirl -= 0.10
    t = base_t + dirl - (1.0 - chamf) * 0.22                     # AO into the mortar
    t += noise(x, y, 51) * 0.010                                 # fine mineral speckle
    return _q(ramp_shade("stone", t))


# ── Torch — grayscale-additive flame frames + glow, on-palette sconce ────────
FLAME_W, FLAME_H, FLAME_N = 16, 24, 4
GLOW_R = 48                                                        # glow source is (2R × 2R)
SCONCE_W, SCONCE_H = 12, 20


def flame_sheet_px(x, y):
    """A horizontal FLAME_N-frame sheet of grayscale-additive flame shapes."""
    f = x // FLAME_W
    fx = x - f * FLAME_W
    cx = FLAME_W / 2.0
    # per-frame flicker: width + tip height wobble
    sway = (0.0, 0.9, -0.7, 0.4)[f % FLAME_N]
    tip = (0, -1, 1, 0)[f % FLAME_N]
    # teardrop: narrow at top, round at base; body height FLAME_H-2 (+tip)
    ny = y / float(FLAME_H - 1)                                   # 0 top .. 1 base
    half = (1.2 + 5.4 * (ny ** 0.7)) * (1.0 - 0.15 * (1 - ny))    # widen toward base
    axis = cx + sway * (1.0 - ny) * 3.0
    if y < 1 + tip:
        return additive(0)
    inside = abs(fx - axis) <= half and y >= 1 + tip
    if not inside:
        return additive(0)
    edge = 1.0 - abs(fx - axis) / max(half, 0.01)                 # 0 edge .. 1 core
    core = 0.35 + 0.65 * ny                                       # brighter, hotter at base
    return additive(int(255 * min(1.0, edge * 0.6 + 0.4) * core))


def glow_px(x, y):
    """Radial grayscale-additive glow source (tinted to the flame ramp at runtime)."""
    dx, dy = x - GLOW_R, y - GLOW_R
    r = (dx * dx + dy * dy) ** 0.5 / GLOW_R
    if r >= 1.0:
        return additive(0)
    a = (1.0 - r) ** 2.2                                          # soft falloff, no hard rim
    return additive(int(220 * a))


# ── Crest — a carved medallion for the top of the frame (the Collegium sigil) ─
# A dark wood oval with a gilded bevel rim and a gold cross-sigil, hung over the
# top-centre of the board frame (the heraldic crest in the reference / Prototype v1).
CREST_W, CREST_H = 46, 36


def crest_px(x, y):
    cx, cy = CREST_W / 2.0, CREST_H / 2.0
    ex = (x - cx) / (CREST_W / 2.0 - 1.0)
    ey = (y - cy) / (CREST_H / 2.0 - 1.0)
    rr = ex * ex + ey * ey
    if rr > 1.0:
        return (0, 0, 0, 0)
    if rr > 0.84:                                                # gilded outer rim, top-left lit
        return _q(ramp_shade("gold", 0.62 if (ex + ey) < 0 else 0.26))
    if rr > 0.72:                                                # recessed shadow ring
        return _q(ramp_shade("black", 0.30))
    field = ramp_shade("wood", 0.26 + noise(x, y, 88) * 0.006)   # dark wood field
    gx, gy = abs(x - cx), abs(y - cy)
    vbar = gx <= 1.0 and gy <= 11.0                             # cross upright
    hbar = abs(y - (cy - 3.0)) <= 1.0 and gx <= 6.0            # cross arm (upper third)
    if vbar or hbar:
        return _q(ramp_shade("gold", 0.74 if x <= cx else 0.46))
    return _q(field)


# ── Vignette — a warm-dark radial overlay for the whole board (ambience) ─────
# Deepest at the corners, clear at the centre, so the wall reads torch-lit: a lit
# pool in the middle falling to near-black at the edges (the Prototype-v1 mood).
# On-palette black (#0A0806) with a radial alpha — stretched over the popup.
VIG_W, VIG_H = 256, 160


def vignette_px(x, y):
    nx = (x - VIG_W / 2.0) / (VIG_W / 2.0)
    ny = (y - VIG_H / 2.0) / (VIG_H / 2.0)
    r = ((nx * nx + ny * ny) ** 0.5) / (2 ** 0.5)             # 0 centre .. 1 corner
    a = smooth(0.30, 1.0, r) * 236                            # clear centre, dark corners
    return ramp_shade("black", 0.0) + (int(a),)              # #0A0806 + radial alpha


def sconce_px(x, y):
    """A small iron wall bracket (on-palette: stone-grey iron + black outline)."""
    left, top, right, bottom = x, y, SCONCE_W - 1 - x, SCONCE_H - 1 - y
    d = min(left, right)
    if y < 3:                                                     # cup rim at the top
        if d == 0 or y == 0:
            return BLACK + (255,)
        return _q(STONE_LIT if left < right else STONE_MID)
    # tapering stem
    half = 2 if y < SCONCE_H - 4 else 3
    if abs(x - SCONCE_W // 2) > half:
        return (0, 0, 0, 0)
    if abs(x - SCONCE_W // 2) == half:
        return BLACK + (255,)
    return _q(STONE_MID if (x <= SCONCE_W // 2) else STONE_DEEP)


# ── Emit + verify ────────────────────────────────────────────────────────────
def _out(name):
    return os.path.join(HERE, "board", name)


if __name__ == "__main__":
    jobs = [
        # board_frame / board_backing / board_placard are NOT emitted (TD-070): the carved
        # frame + plank backing are owned by gen_normals (frame_v1 / backing_v1) and the
        # placard by gen_header (board_header), so emitting these only re-littered dead art.
        ("stone_tile.png",   STONE_W, STONE_H, stone_px, False),
        ("torch_flame.png",  FLAME_W * FLAME_N, FLAME_H, flame_sheet_px, True),
        ("torch_glow.png",   GLOW_R * 2, GLOW_R * 2, glow_px, True),
        # torch_sconce.png is now owned by gen_emblems.make_sconce (T152 redraw) — removed
        # here so a gen_structure run never clobbers the dungeon-dark iron sconce.
    ]
    for name, w, h, fn, is_vfx in jobs:
        assert_on_palette(w, h, fn, name, allow_vfx=is_vfx)       # palette lock, pre-write
        write_png(_out(name), w, h, fn)
        print("  wrote %-18s %dx%d%s" % (name, w, h, "  [VFX grayscale]" if is_vfx else ""))
    print("gen_structure OK — 4 Batch-1 assets, all palette-locked.")
    print("  9-slice margins → frame %d, backing %d, placard %d/%d; stone tiles; flame=%d frames."
          % (FRAME_B + 4, 12, PLAC_MX, PLAC_MY, FLAME_N))
