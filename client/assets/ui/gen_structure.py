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
    STONE_DEEP, STONE_MID, STONE_LIT, WOOD_EDGE, WOOD_BASE, WOOD_BEVEL,
    GOLD_DIM, GOLD, BLACK,
)

HERE = os.path.dirname(os.path.abspath(__file__))


def _q(rgb, a=255):
    return quantize(rgb) + (a,)


# ── Carved frame — 9-slice border, mitred corners, iron studs ────────────────
# 64×64, border B; the interior is transparent so the backing shows through.
# Light reads from top-left (bevel-lit top/left faces, shadowed bottom/right).
FRAME_W = FRAME_H = 64
FRAME_B = 12
_STUDS = ((6, 6), (57, 6), (6, 57), (57, 57))


def frame_px(x, y):
    left, top, right, bottom = x, y, FRAME_W - 1 - x, FRAME_H - 1 - y
    d = min(left, top, right, bottom)

    # iron studs (fixed corner regions — 9-slice-safe)
    for cx, cy in _STUDS:
        dx, dy = x - cx, y - cy
        r2 = dx * dx + dy * dy
        if r2 <= 3:
            return _q(STONE_LIT if (dx + dy) < 0 else STONE_MID)   # lit rivet head
        if r2 <= 6:
            return _q(STONE_DEEP)                                   # rivet shadow ring

    if d >= FRAME_B:
        return (0, 0, 0, 0)                                         # hollow interior
    if d == 0:
        return BLACK + (255,)                                       # outer outline

    lit = (d == left or d == top)                                   # top-left catches light
    # mitred corner joint: a darker 45° seam where two border runs meet
    in_corner = (left < FRAME_B and top < FRAME_B) or (right < FRAME_B and top < FRAME_B) \
        or (left < FRAME_B and bottom < FRAME_B) or (right < FRAME_B and bottom < FRAME_B)
    if in_corner:
        cdx = min(left, right)
        cdy = min(top, bottom)
        if abs(cdx - cdy) <= 0:
            return _q(WOOD_EDGE)                                    # the joint seam

    if d == 1:
        return _q(WOOD_BEVEL if lit else WOOD_EDGE)                # outer bevel
    if d == FRAME_B - 2:
        return _q(WOOD_EDGE)                                       # routed inner groove
    if d == FRAME_B - 1:
        return _q(WOOD_BEVEL if lit else WOOD_BASE)               # inner lip
    return _q(lerp_rgb(WOOD_BASE, WOOD_BEVEL if lit else WOOD_EDGE, 0.15), )  # frame flat


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
    # dark plaque field (reads behind gold lettering)
    v = noise(x, y, 11) * 0.4
    return _q((WOOD_EDGE[0] + v, WOOD_EDGE[1] + v, WOOD_EDGE[2] + v))


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
    if ym == 0 or xm == 0:                                        # mortar lines (wrap-safe)
        return _q(STONE_DEEP)
    v = noise(x, y, 5) * 0.7
    lit = 6 if ((x + y) % 7 == 0) else 0                          # faint ambient sparkle
    base = STONE_MID
    return _q((base[0] + v + lit, base[1] + v + lit, base[2] + v + lit))


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
    return os.path.join(HERE, name)


if __name__ == "__main__":
    jobs = [
        ("board_frame.png",  FRAME_W, FRAME_H, frame_px, False),
        ("board_backing.png", BACK_W, BACK_H, backing_px, False),
        ("board_placard.png", PLAC_W, PLAC_H, placard_px, False),
        ("stone_tile.png",   STONE_W, STONE_H, stone_px, False),
        ("torch_flame.png",  FLAME_W * FLAME_N, FLAME_H, flame_sheet_px, True),
        ("torch_glow.png",   GLOW_R * 2, GLOW_R * 2, glow_px, True),
        ("torch_sconce.png", SCONCE_W, SCONCE_H, sconce_px, False),
    ]
    for name, w, h, fn, is_vfx in jobs:
        assert_on_palette(w, h, fn, name, allow_vfx=is_vfx)       # palette lock, pre-write
        write_png(_out(name), w, h, fn)
        print("  wrote %-18s %dx%d%s" % (name, w, h, "  [VFX grayscale]" if is_vfx else ""))
    print("gen_structure OK — 7 Batch-1 assets, all palette-locked.")
    print("  9-slice margins → frame %d, backing %d, placard %d/%d; stone tiles; flame=%d frames."
          % (FRAME_B + 4, 12, PLAC_MX, PLAC_MY, FLAME_N))
