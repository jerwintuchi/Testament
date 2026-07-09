#!/usr/bin/env python3
"""Ash & Ember — the Notice Board Pass-2 generator foundation (T140).

The shared, dependency-free toolkit every reskin generator imports: the locked
Ash & Ember palette, a pure-stdlib RGBA PNG writer, per-pixel helpers, the
grayscale-additive VFX source convention, and a quantize-to-ramp + palette
membership check that ENFORCES the palette lock (DESIGN.md § Colors / `pipeline`).

Toolchain: stdlib only (no Pillow — settled; the env has no pip). Sanctioned per
CLAUDE.md "Python/PIL generators". Aseprite finishing happens on the emitted PNGs.

    from ashember import PALETTE, RAMP, write_png, quantize, on_palette, additive
    python3 ashember.py            # runs the self-test (palette lock + quantize)
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


RAMP = {
    "stone":     [_hex("#2B2F33"), _hex("#3C4248"), _hex("#4C545A")],
    "wood":      [_hex("#3A2617"), _hex("#5A3D28"), _hex("#7A5334")],
    "parchment": [_hex("#A8946A"), _hex("#CBB583"), _hex("#E0CF9F")],
    "ink":       [_hex("#2A2115"), _hex("#5A4A34")],
    "wax":       [_hex("#8F2F2A"), _hex("#C65A4E")],
    "gold":      [_hex("#8C6C30"), _hex("#B08A3E")],
    "flame":     [_hex("#E8973C"), _hex("#F0B25F")],
    "black":     [_hex("#12100C")],
}

# Convenience named accessors (the tones the spec cites by name).
STONE_DEEP, STONE_MID, STONE_LIT = RAMP["stone"]
WOOD_EDGE, WOOD_BASE, WOOD_BEVEL = RAMP["wood"]
PARCH_SHADOW, PARCH_BASE, PARCH_HI = RAMP["parchment"]
INK, INK_FADED = RAMP["ink"]
WAX, WAX_HI = RAMP["wax"]
GOLD_DIM, GOLD = RAMP["gold"]
FLAME_EMBER, FLAME_GLOW = RAMP["flame"]
BLACK = RAMP["black"][0]

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


# ── Palette lock: quantize + membership ──────────────────────────────────────
def quantize(rgb):
    """Snap an arbitrary RGB to the nearest locked palette colour.

    Perceptually-weighted squared distance (eyes are most sensitive to green).
    Everything an authored board sprite emits should pass through this so no
    off-ramp pixel ever reaches the board (DESIGN.md: palette-lock is absolute).
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
    assert len(PALETTE) == 3 + 3 + 3 + 2 + 2 + 2 + 2 + 1, "unexpected palette size"

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

    print("ashember self-test OK — %d locked colours; quantize + palette-lock enforced." % len(PALETTE))


if __name__ == "__main__":
    _selftest()
