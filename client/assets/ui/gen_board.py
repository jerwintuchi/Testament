#!/usr/bin/env python3
"""Contract Board art: a wooden board 9-slice + a parchment card 9-slice.

Functional greybox on the sanctioned toolchain (pure-stdlib PNG; PIL absent).
9-slice safe: structured detail (studs, aged edge) lives only in the fixed corner/
edge regions; the stretchable centers are near-uniform grain noise, so stretching
does not smear a plank seam or a blotch. Palette: warm wood + aged parchment, with
the red wax accent used elsewhere. Aseprite art replaces these later.

    python3 gen_board.py   # -> board_wood.png (64x64, m16), parchment.png (48x48, m12)
"""
import zlib
import struct


def _noise(x, y, salt=0):
    n = (x * 374761393 + y * 668265263 + salt * 2147483647) & 0xFFFFFFFF
    n = (n ^ (n >> 13)) * 1274126177 & 0xFFFFFFFF
    return (n >> 8) % 17 - 8          # ~[-8, 8]


def _clamp(v):
    return max(0, min(255, int(v)))


def write_png(path, w, h, pixel):
    raw = bytearray()
    for y in range(h):
        raw.append(0)
        for x in range(w):
            r, g, b, a = pixel(x, y)
            raw += bytes((_clamp(r), _clamp(g), _clamp(b), _clamp(a)))

    def chunk(typ, data):
        return (struct.pack(">I", len(data)) + typ + data
                + struct.pack(">I", zlib.crc32(typ + data) & 0xffffffff))

    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        f.write(chunk(b"IEND", b""))


# ── Wooden board (64x64, 9-slice margin 16) ──────────────────────────────────
WOOD_W = WOOD_H = 64
WOOD_BASE = (92, 60, 34)
WOOD_EDGE = (58, 36, 19)
WOOD_BEVEL = (128, 86, 44)
WOOD_OUT = (20, 12, 6)
STUD = (46, 40, 34)
STUD_HI = (120, 108, 92)


def wood_pixel(x, y):
    d = min(x, y, WOOD_W - 1 - x, WOOD_H - 1 - y)
    if d == 0:
        return (*WOOD_OUT, 255)
    if d == 1 or d == 2:
        return (*WOOD_EDGE, 255)
    if d == 3:
        return (*WOOD_BEVEL, 255)
    # iron studs in the fixed corner regions
    for (cx, cy) in ((9, 9), (WOOD_W - 10, 9), (9, WOOD_H - 10), (WOOD_W - 10, WOOD_H - 10)):
        dx, dy = x - cx, y - cy
        if dx * dx + dy * dy <= 5:
            return (*STUD, 255)
        if dx * dx + dy * dy <= 9:
            return (*STUD_HI, 255)
    # plank field: base + vertical grain + speckle (uniform enough to stretch)
    grain = -6 if (x % 15) in (0, 1) else 0
    n = _noise(x, y, 3)
    return (WOOD_BASE[0] + n + grain, WOOD_BASE[1] + n + grain, WOOD_BASE[2] + n + grain, 255)


# ── Torn parchment cards (full card size, NOT 9-slice) ───────────────────────
# Weathered parched paper with ragged, transparent torn edges so the wooden board
# shows through the tears. Drawn at the card's pixel size (no stretch → the tear
# shape is preserved, which 9-slice could not do). Four seeds → four unique tear
# patterns, one per card. Warm tan, darker toward the rim, foxing stains, a singed
# line just inside each tear.
CARD_W, CARD_H = 182, 118
PAPER = (206, 186, 143)


def _hash(a, b):
    n = (a * 374761393 + b * 668265263) & 0xFFFFFFFF
    n = (n ^ (n >> 13)) * 1274126177 & 0xFFFFFFFF
    return n & 0xFFFFFFFF


def _vnoise(t, seed):
    # smooth 1D value noise in [0,1]: interpolate a hash lattice with smoothstep
    i = t // 7
    f = (t % 7) / 7.0
    a = (_hash(i, seed) % 1000) / 1000.0
    b = (_hash(i + 1, seed) % 1000) / 1000.0
    u = f * f * (3 - 2 * f)
    return a + (b - a) * u


def _tear(coord, seed, edge):
    # organic torn margin: a smooth undulating baseline + fine raggedness + the
    # occasional deep bite, so the edge reads as ripped paper, not perforation.
    wave = int(_vnoise(coord, seed * 31 + edge) * 7)      # 0..7 gentle undulation
    jag = _hash(coord // 2, seed * 53 + edge) % 3          # 0..2 fine raggedness
    deep = 5 if (_hash(coord // 9, seed * 17 + edge) % 11 == 0) else 0
    return 2 + wave + jag + deep


def torn_card(seed):
    def px(x, y):
        left = _tear(y, seed, 0)
        right = _tear(y, seed, 1)
        top = _tear(x, seed, 2)
        bottom = _tear(x, seed, 3)
        if x < left or x > CARD_W - 1 - right or y < top or y > CARD_H - 1 - bottom:
            return (0, 0, 0, 0)                       # torn away
        din = min(x - left, (CARD_W - 1 - right) - x, y - top, (CARD_H - 1 - bottom) - y)
        rim = max(0, 5 - din) * 6                     # darker toward the torn rim
        fine = _noise(x, y, seed + 5)
        blotch = _noise(x // 6, y // 6, seed + 9)
        stain = (blotch - 3) if blotch > 3 else 0
        v = -rim + fine - stain
        if din <= 1:
            v -= 26                                    # singed torn edge
        return (PAPER[0] + v, PAPER[1] + v, PAPER[2] + int(v * 0.65) - 4, 255)
    return px


if __name__ == "__main__":
    import os
    here = os.path.dirname(os.path.abspath(__file__))
    write_png(os.path.join(here, "board_wood.png"), WOOD_W, WOOD_H, wood_pixel)
    for i in range(4):
        write_png(os.path.join(here, "parch_card_%d.png" % i), CARD_W, CARD_H, torn_card(i * 101 + 7))
    print("wrote board_wood.png (64x64, m16) + parch_card_0..3.png (182x118, torn)")
