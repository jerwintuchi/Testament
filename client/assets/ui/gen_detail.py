#!/usr/bin/env python3
"""Notice Board Pass-2 — Batch 2 detail assets (T143).

Generates the board's detail layer on the Ash & Ember foundation (ashember.py):
torn/deckled parchment (live + flavor tones, a few pre-rotated tilt variants),
tacks (nail · wax · pin · ribbon), a corner cobweb, a dead votive candle, and a
foxing/aging overlay. Board art is quantized to the locked palette; the cobweb is
a grayscale-additive VFX source (white+alpha), tinted to the flame ramp in Godot.

The wax seal's Origin sigils and the threat pips' outline are Godot-drawn widgets
(wax_seal.gd / threat_pips.gd), refined alongside this generator — not PNGs.

Runnable: `python3 gen_detail.py` → writes the PNGs beside this file and asserts
each is on-palette (VFX sources under allow_vfx). Aseprite finishing after.
"""
import os
from ashember import (
    write_png, quantize, noise, lerp_rgb, additive, assert_on_palette,
    PARCH_SHADOW, PARCH_BASE, PARCH_HI, INK, INK_FADED,
    WAX, WAX_HI, GOLD_DIM, GOLD, STONE_MID, STONE_LIT, BLACK,
)

HERE = os.path.dirname(os.path.abspath(__file__))


def _q(rgb, a=255):
    return quantize(rgb) + (a,)


# ── Deckled parchment ────────────────────────────────────────────────────────
# Torn organic edges (not a clean rect) baked into the pixels so the tears survive
# at the notice's scale (DESIGN § Shapes: "drawn at pixel size, not 9-sliced").
# live  = paper ≥ base tone, warm, its own faint inner light (clickable notice).
# flavor = aged/greyed, darker, foxed (inert scrap). Two tear seeds per tone.
PARCH_W, PARCH_H = 104, 128


def _tear(edge_pos, span, seed):
    """How far the torn edge bites in at position `edge_pos` along a run — 0..4px,
    a slow wobble + fine fray, deterministic per seed so a variant is stable."""
    slow = (noise(edge_pos // 6, 0, seed) + 8) / 16.0        # 0..1 coarse bay/peninsula
    fine = (noise(edge_pos, 0, seed + 91) + 8) % 3           # 0..2 fibre fray
    return int(1 + slow * 3) + fine


def _parch_px(x, y, seed, live):
    left, top, right, bottom = x, y, PARCH_W - 1 - x, PARCH_H - 1 - y
    # deckled boundary: transparent outside the torn edge on every side
    if (left < _tear(y, PARCH_H, seed) or right < _tear(y, PARCH_H, seed + 5)
            or top < _tear(x, PARCH_W, seed + 11) or bottom < _tear(x, PARCH_W, seed + 17)):
        return (0, 0, 0, 0)
    d = min(left, top, right, bottom)
    grain = noise(x, y, seed + 3) * (0.5 if live else 0.6)
    if live:
        # warm sheet with a soft inner light: brighter toward the centre.
        cx, cy = PARCH_W / 2.0, PARCH_H / 2.0
        rr = ((x - cx) / cx) ** 2 + ((y - cy) / cy) ** 2      # 0 centre .. ~2 corner
        base = lerp_rgb(PARCH_HI, PARCH_BASE, min(1.0, rr * 0.6))
    else:
        # aged, greyed-down; foxing blotches speckled through the fibre.
        base = lerp_rgb(PARCH_SHADOW, PARCH_BASE, 0.25)
        blot = noise(x // 3, y // 4, seed + 40)
        if blot > 5 and (noise(x, y, seed + 41) % 4 == 0):
            base = lerp_rgb(base, INK_FADED, 0.5)             # foxing spot
    col = (base[0] + grain, base[1] + grain, base[2] + grain)
    if d <= 1:                                                # torn-fibre edge shadow
        col = lerp_rgb(col, INK_FADED, 0.35)
    return _q(col)


def parch_live(seed):
    return lambda x, y: _parch_px(x, y, seed, True)


def parch_flavor(seed):
    return lambda x, y: _parch_px(x, y, seed, False)


# ── Pixel-safe baked rotation ────────────────────────────────────────────────
# Runtime rotation of a small sprite blurs under any non-integer scale; baking the
# tilt keeps every parchment crisp (DESIGN "Do": pre-baked rotated variants). Nearest
# inverse sample onto a canvas big enough that no torn corner clips.
def rotated(fn, w, h, deg):
    import math
    rad = math.radians(deg)
    c, s = math.cos(rad), math.sin(rad)
    ow = int(abs(w * c) + abs(h * s)) + 2
    oh = int(abs(w * s) + abs(h * c)) + 2
    cx, cy, ocx, ocy = w / 2.0, h / 2.0, ow / 2.0, oh / 2.0

    def px(ox, oy):
        dx, dy = ox - ocx, oy - ocy
        sx = int(round(cx + dx * c + dy * s))
        sy = int(round(cy - dx * s + dy * c))
        if 0 <= sx < w and 0 <= sy < h:
            return fn(sx, sy)
        return (0, 0, 0, 0)
    return ow, oh, px


# ── Tacks — nail · wax · pin · ribbon (seeded per notice) ────────────────────
TACK_W, TACK_H = 12, 14


def tack_nail(x, y):
    cx = TACK_W // 2
    dx, dy = x - cx, y - 4
    r2 = dx * dx + dy * dy
    if r2 <= 1:
        return _q(STONE_LIT)                                  # lit head crown
    if r2 <= 6:
        return _q(STONE_MID)
    if r2 <= 9:
        return BLACK + (255,)                                 # head outline
    if x == cx and 5 <= y < TACK_H:                           # thin shaft
        return _q(STONE_MID)
    return (0, 0, 0, 0)


def tack_wax(x, y):
    cx = TACK_W // 2
    dx, dy = x - cx, y - 4
    r2 = dx * dx + dy * dy
    drip = (x == cx or x == cx - 1) and 4 <= y < TACK_H - 1    # a set drip
    if r2 <= 8 or drip:
        lit = (dx + dy) < 0
        return _q(WAX_HI if lit else WAX["fill"] if False else (0x8F, 0x2F, 0x2A))
    if r2 <= 12:
        return BLACK + (255,)
    return (0, 0, 0, 0)


def tack_pin(x, y):
    cx = TACK_W // 2
    dx, dy = x - cx, y - 3
    if dx * dx + dy * dy <= 2:
        return _q(GOLD)                                       # brass pin head
    if dx * dx + dy * dy <= 4:
        return BLACK + (255,)
    if x == cx and 4 <= y < TACK_H:
        return _q(GOLD_DIM)                                   # thin needle
    return (0, 0, 0, 0)


def tack_ribbon(x, y):
    # a small folded ribbon knot: two crimson lobes over a dark centre
    cx = TACK_W // 2
    for sgn in (-1, 1):
        lx = cx + sgn * 3
        if (x - lx) ** 2 + (y - 6) ** 2 <= 6:
            return _q(WAX_HI if (x - lx) < 0 else (0x8F, 0x2F, 0x2A))
    if abs(x - cx) <= 1 and 4 <= y <= 9:
        return _q(INK)                                        # knot core
    if 3 <= y <= 12 and abs(x - cx) == 2:
        return _q((0x8F, 0x2F, 0x2A))                         # tail hint
    return (0, 0, 0, 0)


# ── Cobweb — grayscale-additive corner strand (VFX) ──────────────────────────
# Thin radial threads from the top-left corner + two catenary cross-threads. White
# + alpha; Godot modulates it to a cold dim tint and adds (same VFX rule as glow).
WEB_W = WEB_H = 40


def cobweb_px(x, y):
    # radials fan from the corner (0,0)
    import math
    ang = math.atan2(y + 0.5, x + 0.5)
    r = ((x + 0.5) ** 2 + (y + 0.5) ** 2) ** 0.5
    if r > WEB_W - 2:
        return additive(0)
    a = 0
    for k in range(5):                                        # 5 anchor threads
        spoke = (k + 0.5) * (math.pi / 2) / 5
        if abs(ang - spoke) < 0.05:
            a = max(a, 150)
    for ring in (12, 22, 32):                                 # cross-threads (arcs)
        if abs(r - ring) < 0.7 and ang < math.pi / 2:
            a = max(a, 110)
    fade = max(0.0, 1.0 - r / (WEB_W - 2))
    return additive(int(a * (0.4 + 0.6 * fade)))


# ── Dead votive candle — spent sacred-decay prop (static) ────────────────────
VOT_W, VOT_H = 14, 22


def votive_px(x, y):
    cx = VOT_W // 2
    left, right = x, VOT_W - 1 - x
    # slumped stub: full-width base, melted lopsided top
    top_y = 6 + (2 if x < cx else 0)
    if y < top_y:
        return (0, 0, 0, 0)
    if x == 0 or x == VOT_W - 1 or y == VOT_H - 1 or y == top_y:
        if 2 <= x <= VOT_W - 3 or y >= top_y:
            return BLACK + (255,)
    wall = (x <= 1 or right <= 1)
    body = lerp_rgb(PARCH_BASE, PARCH_SHADOW, 0.3)            # pale spent wax
    col = body if not wall else lerp_rgb(body, INK_FADED, 0.4)
    if x == cx and top_y <= y <= top_y + 3:                   # dead black wick
        return _q(INK)
    v = noise(x, y, 61) * 0.5
    return _q((col[0] + v, col[1] + v, col[2] + v))


# ── Foxing / curl overlay — aging blotches for flavor scraps (static) ────────
# Sparse on-palette age spots with soft alpha; transparent elsewhere. Laid over a
# flavor scrap to break its flatness (never over a live notice's text — T145).
FOX_W = FOX_H = 64


def foxing_px(x, y):
    blot = noise(x // 4, y // 4, 77)
    spot = noise(x, y, 78)
    if blot > 4 and spot % 5 == 0:
        a = 90 + (spot % 3) * 30
        tone = INK_FADED if (blot % 2) else PARCH_SHADOW
        return quantize(tone) + (a,)
    return (0, 0, 0, 0)


# ── Emit + verify ────────────────────────────────────────────────────────────
def _out(name):
    return os.path.join(HERE, name)


if __name__ == "__main__":
    # flat parchment variants (two tear seeds per tone)
    jobs = [
        ("parch_live_0.png",   PARCH_W, PARCH_H, parch_live(101), False),
        ("parch_live_1.png",   PARCH_W, PARCH_H, parch_live(203), False),
        ("parch_flavor_0.png", PARCH_W, PARCH_H, parch_flavor(305), False),
        ("parch_flavor_1.png", PARCH_W, PARCH_H, parch_flavor(407), False),
        ("tack_nail.png",   TACK_W, TACK_H, tack_nail,   False),
        ("tack_wax.png",    TACK_W, TACK_H, tack_wax,    False),
        ("tack_pin.png",    TACK_W, TACK_H, tack_pin,    False),
        ("tack_ribbon.png", TACK_W, TACK_H, tack_ribbon, False),
        ("cobweb.png",  WEB_W, WEB_H, cobweb_px, True),
        ("votive.png",  VOT_W, VOT_H, votive_px, False),
        ("foxing.png",  FOX_W, FOX_H, foxing_px, False),
    ]
    for name, w, h, fn, is_vfx in jobs:
        assert_on_palette(w, h, fn, name, allow_vfx=is_vfx)
        write_png(_out(name), w, h, fn)
        print("  wrote %-18s %dx%d%s" % (name, w, h, "  [VFX grayscale]" if is_vfx else ""))

    # pre-rotated tilt variants for live parchment (baked, pixel-safe)
    for base_seed, tag in ((101, "0"), (203, "1")):
        for deg, suff in ((-5, "l"), (5, "r")):
            ow, oh, fn = rotated(parch_live(base_seed), PARCH_W, PARCH_H, deg)
            name = "parch_live_%s_%s.png" % (tag, suff)
            assert_on_palette(ow, oh, fn, name)
            write_png(_out(name), ow, oh, fn)
            print("  wrote %-18s %dx%d  [rot %+d°]" % (name, ow, oh, deg))

    print("gen_detail OK — Batch-2 detail assets, all palette-locked "
          "(cobweb VFX grayscale; 4 baked parchment tilts).")
