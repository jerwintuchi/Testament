#!/usr/bin/env python3
"""Ash & Ember — the Notice Board reskin generator foundation (T140).

The shared, dependency-free toolkit every reskin generator imports: the curated
Ash & Ember palette, smooth multi-stop shading (`ramp_shade`) + light-temperature
helpers, a pure-stdlib RGBA PNG writer, per-pixel helpers, the grayscale-additive
VFX source convention, and a quantize-to-ramp + palette membership check.

Art-rebrand (2026-07-11): the palette is a CURATED expanded set (~34 colours), not
the old 15/18-colour lock. Ash & Ember stays the named identity — every generator's
output still resolves to these defined ramps, so the board reads cohesive — but each
ramp now carries shadow/rim stops so `ramp_shade` can render weathered, torch-lit
gradients (baked directional light, edge AO, foxing) instead of flat fills. So
`assert_on_palette` checks COHESION (output ∈ the curated set), not a hard 24-bit ban.

Toolchain: stdlib only (no Pillow — settled; the env has no pip). Generators are the
primary pipeline; hand-authored Aseprite finishing on the emitted PNGs is supplementary.

    from ashember import RAMP, ramp_shade, warm, cool, write_png, quantize, additive
    python3 ashember.py            # runs the self-test (palette cohesion + quantize)
"""
import zlib
import struct

# ── Locked palette: Direction A "Ash & Ember" ────────────────────────────────
# (DESIGN.md § Colors, chosen from mockups/palette-candidates.html). Ramps are
# dark -> light. These are the ONLY colours allowed on authored board art; any
# blended/lit output must be quantize()'d back to one of these before export.
def _hex(h):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


# Expanded curated set (~34 colours) per the 2026-07-11 art rebrand: Ash & Ember
# stays the named identity, but each ramp gains shadow/rim stops so `ramp_shade`
# can render smooth, weathered, torch-lit gradients that still resolve to a DEFINED
# palette (cohesion kept; the lock relaxed from 15/18 → curated ramps, not open
# 24-bit). Every historical named stop below keeps its exact hex — extending the
# ramps never moves an existing colour, so prior generators/tests are unaffected.
# Each ramp is ordered dark → light.
RAMP = {
    "black":     [_hex("#0A0806"), _hex("#12100C"), _hex("#1C1813")],
    "stone":     [_hex("#22242A"), _hex("#2B2F33"), _hex("#3C4248"),
                  _hex("#4C545A"), _hex("#616A72")],
    "wood":      [_hex("#2A1B10"), _hex("#3A2617"), _hex("#5A3D28"),
                  _hex("#7A5334"), _hex("#916339")],
    "parchment": [_hex("#8A7A54"), _hex("#A8946A"), _hex("#CBB583"),
                  _hex("#E0CF9F"), _hex("#F1E4BE")],
    "foxing":    [_hex("#5E3F22"), _hex("#6B4A2A"), _hex("#83603A")],
    "ink":       [_hex("#2A2115"), _hex("#5A4A34")],
    "wax":       [_hex("#5E1D1A"), _hex("#8F2F2A"), _hex("#C65A4E"), _hex("#E1897B")],
    "gold":      [_hex("#6E5426"), _hex("#8C6C30"), _hex("#B08A3E"), _hex("#D6AE5C")],
    "flame":     [_hex("#E8973C"), _hex("#F0B25F"), _hex("#F9DCA6")],
    # Warm ashlar for the Hall of Petitions' nave (TD-072). DERIVED FROM OUR OWN RAMPS, not
    # transcribed from a photograph: each step is roughly the midpoint of `stone` and `wood`,
    # which is how the board's masonry already reads once torchlight lands on it. `stone` stays
    # as-is for the field tiles and everything cool.
    "navestone": [_hex("#14100D"), _hex("#241D19"), _hex("#332A24"), _hex("#473A31"),
                  _hex("#5C4C40"), _hex("#75624F"), _hex("#8F7A63")],
}

# Convenience named accessors (the tones the spec/generators cite by name). These
# resolve to the SAME hexes as before the ramp expansion, so existing code is stable.
STONE_DEEP, STONE_MID, STONE_LIT = RAMP["stone"][1], RAMP["stone"][2], RAMP["stone"][3]
WOOD_EDGE, WOOD_BASE, WOOD_BEVEL = RAMP["wood"][1], RAMP["wood"][2], RAMP["wood"][3]
PARCH_SHADOW, PARCH_BASE, PARCH_HI = RAMP["parchment"][1], RAMP["parchment"][2], RAMP["parchment"][3]
INK, INK_FADED = RAMP["ink"]
WAX, WAX_HI = RAMP["wax"][1], RAMP["wax"][2]
GOLD_DIM, GOLD = RAMP["gold"][1], RAMP["gold"][2]
FLAME_EMBER, FLAME_GLOW = RAMP["flame"][0], RAMP["flame"][1]
BLACK = RAMP["black"][1]
# New stops the richer renderers reach for directly.
STONE_SHADOW, STONE_HI = RAMP["stone"][0], RAMP["stone"][4]
WOOD_DEEP, WOOD_HI = RAMP["wood"][0], RAMP["wood"][4]
PARCH_DEEP, PARCH_RIM = RAMP["parchment"][0], RAMP["parchment"][4]
FLAME_PALE = RAMP["flame"][2]

# Flat set of every locked colour, for the membership check.
PALETTE = [c for ramp in RAMP.values() for c in ramp]
PALETTE_SET = set(PALETTE)


# ── Per-pixel helpers ────────────────────────────────────────────────────────
def clamp(v):
    return max(0, min(255, int(v)))


def clamp_rgb(rgb):
    return (clamp(rgb[0]), clamp(rgb[1]), clamp(rgb[2]))


def noise(x, y, salt=0):
    """Deterministic value noise in ~[-8, 8] (from Pass-1 gen_board)."""
    n = (x * 374761393 + y * 668265263 + salt * 2147483647) & 0xFFFFFFFF
    n = (n ^ (n >> 13)) * 1274126177 & 0xFFFFFFFF
    return (n >> 8) % 17 - 8


def lerp_rgb(a, b, t):
    t = max(0.0, min(1.0, t))
    return (a[0] + (b[0] - a[0]) * t,
            a[1] + (b[1] - a[1]) * t,
            a[2] + (b[2] - a[2]) * t)


def ramp_shade(name, t):
    """Sample a continuous position 0..1 along a named ramp (dark→light).

    This is the smooth-shading primitive: drive it with a baked lighting term and
    the result rides the full expanded ramp, so a lit gradient reads as rendered
    (many tonal steps) yet still snaps to the defined palette under `quantize`.
    Returns a float RGB — quantize() it before writing.
    """
    r = RAMP[name]
    if len(r) == 1:
        return r[0]
    t = max(0.0, min(1.0, t)) * (len(r) - 1)
    i = int(t)
    if i >= len(r) - 1:
        return r[-1]
    return lerp_rgb(r[i], r[i + 1], t - i)


def warm(rgb, amt):
    """Push a colour toward ember warmth (baked torch-light). amt 0..1."""
    return lerp_rgb(rgb, FLAME_PALE, max(0.0, min(1.0, amt)))


def cool(rgb, amt):
    """Sink a colour toward cold shadow. amt 0..1."""
    return lerp_rgb(rgb, RAMP["stone"][0], max(0.0, min(1.0, amt)))


def over(base, top, alpha):
    """Composite `top` onto `base` at `alpha` (0..1) — for stains/foxing/AO."""
    return lerp_rgb(base, top, max(0.0, min(1.0, alpha)))


def smooth(a, b, x):
    """Smoothstep of x from edge a to edge b → 0..1."""
    if b == a:
        return 0.0 if x < a else 1.0
    t = max(0.0, min(1.0, (x - a) / float(b - a)))
    return t * t * (3 - 2 * t)


# ── Palette lock: quantize + membership ──────────────────────────────────────
def quantize(rgb):
    """Snap an arbitrary RGB to the nearest locked palette colour.

    Perceptually-weighted squared distance (eyes are most sensitive to green).
    Everything an authored board sprite emits passes through this so the board
    stays cohesive — every pixel lands on a curated Ash & Ember ramp entry, even
    when it was computed as a smooth lit gradient (art-rebrand 2026-07-11).
    """
    r, g, b = clamp_rgb(rgb)
    best, best_d = PALETTE[0], None
    for (pr, pg, pb) in PALETTE:
        d = 2 * (r - pr) ** 2 + 4 * (g - pg) ** 2 + 3 * (b - pb) ** 2
        if best_d is None or d < best_d:
            best, best_d = (pr, pg, pb), d
    return best


def on_palette(rgb):
    return clamp_rgb(rgb) in PALETTE_SET


def assert_on_palette(w, h, pixel, name="<image>", allow_vfx=False, quiet=False):
    """Assert every opaque pixel of a pixel(x,y)->(r,g,b,a) image is locked.

    A fully-transparent pixel (a==0) is exempt (torn-away paper). A grayscale
    additive VFX source is exempt only when allow_vfx=True (its RGB is white by
    convention; it is tinted to the flame ramp at runtime, then quantized).
    """
    bad = 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixel(x, y)
            if a == 0:
                continue
            rgb = clamp_rgb((r, g, b))
            if allow_vfx and rgb == (255, 255, 255):
                continue
            if rgb not in PALETTE_SET:
                bad += 1
                if not quiet and bad <= 5:
                    print("  off-palette %s at (%d,%d): #%02X%02X%02X" % ((name, x, y) + rgb))
    if bad:
        raise AssertionError("%s: %d off-palette pixel(s)" % (name, bad))
    return True


# ── Grayscale-additive VFX source convention ─────────────────────────────────
# Canon (CLAUDE.md): grayscale ADD-blend VFX. A glow / cobweb source PNG is white
# RGB with per-pixel alpha = intensity; Godot modulates it to the flame ramp and
# adds. So the SOURCE is grayscale (exempt from the palette check via allow_vfx);
# the RENDERED result is on-palette after the runtime tint + quantize.
def additive(intensity):
    """A grayscale-additive VFX pixel: white RGB, alpha = intensity (0..255)."""
    return (255, 255, 255, clamp(intensity))


# ── Pure-stdlib RGBA PNG writer ──────────────────────────────────────────────
def write_png(path, w, h, pixel):
    """Write an 8-bit RGBA PNG. `pixel(x, y) -> (r, g, b, a)`."""
    raw = bytearray()
    for y in range(h):
        raw.append(0)  # filter type 0 (None) per scanline
        for x in range(w):
            r, g, b, a = pixel(x, y)
            raw += bytes((clamp(r), clamp(g), clamp(b), clamp(a)))

    def chunk(typ, data):
        return (struct.pack(">I", len(data)) + typ + data
                + struct.pack(">I", zlib.crc32(typ + data) & 0xffffffff))

    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        f.write(chunk(b"IEND", b""))


# ── Self-test (the T140 named test) ──────────────────────────────────────────
def _selftest():
    # 1. Ramps are all distinct and well-formed.
    assert len(PALETTE) == len(PALETTE_SET), "duplicate palette colours"
    assert len(PALETTE) == 3 + 5 + 5 + 5 + 3 + 2 + 4 + 4 + 3 + 7 == 41, "unexpected palette size"

    # 1b. ramp_shade rides the ramp and is monotone-ish at the ends.
    assert ramp_shade("parchment", 0.0) == PARCH_DEEP
    assert ramp_shade("parchment", 1.0) == PARCH_RIM
    assert quantize(ramp_shade("wood", 0.5)) in PALETTE_SET

    # 2. quantize() is identity on locked colours.
    for c in PALETTE:
        assert quantize(c) == c, "quantize moved a locked colour: %r" % (c,)

    # 3. quantize() snaps a near-colour to the intended ramp entry.
    assert quantize((0x2B, 0x2F, 0x34)) == STONE_DEEP        # +1 blue -> stone deep
    assert quantize((0xB0, 0x8B, 0x40)) == GOLD              # ~gold bright
    assert quantize((0x2A, 0x21, 0x16)) == INK               # ~ink body

    # 4. A quantized gradient image is 100% on-palette (the palette-lock proof).
    def grad(x, y):
        raw = lerp_rgb(WOOD_EDGE, WOOD_BEVEL, x / 31.0)      # off-ramp intermediates
        return quantize(raw) + (255,)                        # ...snapped back
    assert_on_palette(32, 8, grad, "quantized-gradient")

    # 5. A grayscale additive source is exempt only under allow_vfx.
    def glow(x, y):
        return additive(255 - (x * 8))
    assert_on_palette(32, 8, glow, "vfx-glow", allow_vfx=True)
    try:
        assert_on_palette(32, 8, glow, "vfx-glow-strict", quiet=True)  # must fail without the flag
        raise SystemExit("FAIL: white VFX pixel passed the strict palette check")
    except AssertionError:
        pass

    # 6. The PNG writer round-trips to a real file header.
    import os
    tmp = os.path.join(os.path.dirname(os.path.abspath(__file__)), "_ashember_selftest.png")
    write_png(tmp, 8, 8, lambda x, y: quantize(lerp_rgb(PARCH_SHADOW, PARCH_HI, x / 7.0)) + (255,))
    with open(tmp, "rb") as f:
        assert f.read(8) == b"\x89PNG\r\n\x1a\n", "bad PNG signature"
    os.remove(tmp)

    print("ashember self-test OK — %d curated colours; quantize + ramp_shade cohesion." % len(PALETTE))


if __name__ == "__main__":
    _selftest()
