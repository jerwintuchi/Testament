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
    ramp_shade, warm, cool, over, smooth,
    PARCH_SHADOW, PARCH_BASE, PARCH_HI, PARCH_DEEP, PARCH_RIM, INK, INK_FADED,
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
# Authored at 2x (208x256) so the enlarged READER (~486px) and the grid cards both stay
# crisp under Nearest — the old 104x128 stretched ~4x in the reader and read chunky.
PARCH_W, PARCH_H = 208, 256


def _tear(edge_pos, span, seed):
    """How far the torn edge bites in at position `edge_pos` along a run — a slow
    wobble + fine fray, deterministic per seed so a variant is stable (2x scale)."""
    slow = (noise(edge_pos // 12, 0, seed) + 8) / 16.0       # 0..1 coarse bay/peninsula
    fine = (noise(edge_pos, 0, seed + 91) + 8) % 5           # 0..4 fibre fray
    return int(2 + slow * 6) + fine


def _parch_px(x, y, seed, live):
    left, top, right, bottom = x, y, PARCH_W - 1 - x, PARCH_H - 1 - y
    # deckled boundary: transparent outside the torn edge on every side
    if (left < _tear(y, PARCH_H, seed) or right < _tear(y, PARCH_H, seed + 5)
            or top < _tear(x, PARCH_W, seed + 11) or bottom < _tear(x, PARCH_W, seed + 17)):
        return (0, 0, 0, 0)
    d = min(left, top, right, bottom)

    # 1. Baked directional light — a warm source high of centre. The sheet is
    #    brightest under it and falls toward the lower corners; the bottom hangs a
    #    touch further into shadow, so the paper reads lit, not evenly flat.
    cx, cy = PARCH_W * 0.5, PARCH_H * 0.34
    nx = (x - cx) / (PARCH_W * 0.60)
    ny = (y - cy) / (PARCH_H * 0.80)
    light = 1.0 - (nx * nx + ny * ny) * 0.50
    light -= (y / float(PARCH_H)) * 0.10

    # 2. Edge ambient occlusion — the deckled rim sits in the board's shadow;
    #    darken within ~16px (2x scale), deepest at the tear. This is the depth cue
    #    the flat version lacked (paper looks like it lifts off the wall).
    ao = smooth(0.0, 16.0, float(d))
    light *= 0.52 + 0.48 * ao

    # 3. Laid-fibre grain: coarse vertical streaks (the mould lines) + fine flecks.
    light += noise(x // 4, y, seed + 3) * 0.010
    light += noise(x, y, seed + 9) * 0.006

    if live:
        t = 0.30 + light * 0.52                               # warm mid, not bleached at the crown
    else:
        t = 0.08 + light * 0.50                               # aged, greyed, darker
    base = ramp_shade("parchment", t)

    # 4. Light temperature — ember-warm the lit crown, cold-sink the shadowed rim; plus a
    #    strong standing amber cast over the whole live sheet (aged tallow-lit paper, v1),
    #    slowly modulated so the warmth pools unevenly like real aged stock.
    if live:
        amber = 0.20 + (noise(x // 20, y // 24, seed + 70) + 8) / 16.0 * 0.10
        base = warm(base, amber)
    if light > 0.56:
        base = warm(base, (light - 0.56) * (0.66 if live else 0.34))
    elif light < 0.40:
        base = cool(base, (0.40 - light) * 0.28)

    # 5a. Broad tea-stain blooms: large soft sepia washes (the big age-marks in v1).
    #     Big, low-contrast cells so the aging reads as washes, not a checkerboard grid.
    stain = noise(x // 34, y // 40, seed + 60)
    if stain > 4:
        base = over(base, ramp_shade("foxing", 0.24), (stain - 4) * (0.040 if live else 0.052))
    # 5b. Foxing specks: clustered sepia spots — TD-050 levelled DOWN (fewer + fainter) so the
    #     aging reads as clean-aged washes, not a speckle-storm outlier against the carved frame.
    bloom = noise(x // 9, y // 11, seed + 40)
    grit = noise(x, y, seed + 41)
    if bloom > (3 if not live else 4) and grit % (4 if not live else 4) == 0:
        fa = (0.26 if not live else 0.18) + (grit % 3) * 0.05
        base = over(base, ramp_shade("foxing", 0.30 + (bloom % 3) * 0.16), fa)

    # 6. Torn-fibre edge shadow, softened a couple pixels inward (2x scale).
    if d <= 2:
        base = over(base, INK_FADED, 0.42)
    elif d <= 4:
        base = over(base, INK_FADED, 0.18)
    return _q(base)


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
