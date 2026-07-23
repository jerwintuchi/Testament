#!/usr/bin/env python3
"""Generate a 9-slice popup panel for the Collegium UI (functional greybox art).

Gothic ecclesiastical dark fantasy: a dark-stone field inside an aged-gold beveled
frame with corner rivets. Concentric frame rings tile cleanly for 9-slice, so the
`texture_margins` in the StyleBoxTexture can stretch the center without distorting
the border. Palette-locked to the game's charcoal-and-gold register.

Pure-stdlib PNG writer (no PIL in this env). Sanctioned generator role per the
closed toolchain; a hand-authored Aseprite panel replaces this later.

    python3 gen_panel.py   # -> panel.png (48x48, 12px 9-slice margins)
"""
import zlib
import struct

W = H = 48
MARGIN = 12  # matches the StyleBoxTexture texture_margins in main.gd

# Palette (r,g,b) ------------------------------------------------------------
OUTLINE   = (8, 6, 12)       # near-black edge + inner line
GOLD_HI   = (224, 192, 114)  # bright bevel highlight (outer)
GOLD_MID  = (184, 145, 47)   # gold face
GOLD_LO   = (122, 92, 36)    # dark bevel (inner)
RIVET     = (210, 178, 96)
RIVET_DK  = (60, 44, 18)
STONE_TOP = (32, 27, 44)     # fill gradient, lit top
STONE_BOT = (18, 15, 26)     # fill gradient, shadowed bottom


def _dither(x, y):
    # cheap ordered-ish noise so the stone fill isn't a flat block
    return ((x * 7 + y * 13) % 5) - 2


def _lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def _rivet(x, y):
    # 3x3 gold rivets tucked in each corner (inside the 9-slice corner region)
    for (cx, cy) in ((8, 8), (W - 9, 8), (8, H - 9), (W - 9, H - 9)):
        if abs(x - cx) <= 1 and abs(y - cy) <= 1:
            return RIVET_DK if (x == cx and y == cy) else RIVET
    return None


def pixel(x, y):
    d = min(x, y, W - 1 - x, H - 1 - y)  # ring distance from the nearest edge
    if d == 0:
        return (*OUTLINE, 255)
    if d == 1:
        return (*GOLD_HI, 255)
    if d == 2:
        return (*GOLD_MID, 255)
    if d == 3:
        return (*GOLD_LO, 255)
    if d == 4:
        return (*OUTLINE, 255)
    r = _rivet(x, y)
    if r is not None:
        return (*r, 255)
    t = (y - 5) / max(1, (H - 10))          # vertical gradient across the fill
    base = _lerp(STONE_TOP, STONE_BOT, t)
    n = _dither(x, y)
    return (max(0, min(255, base[0] + n)),
            max(0, min(255, base[1] + n)),
            max(0, min(255, base[2] + n)), 255)


def write_png(path, w, h):
    raw = bytearray()
    for y in range(h):
        raw.append(0)  # filter type 0 (none) per scanline
        for x in range(w):
            raw += bytes(pixel(x, y))

    def chunk(typ, data):
        return (struct.pack(">I", len(data)) + typ + data
                + struct.pack(">I", zlib.crc32(typ + data) & 0xffffffff))

    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        f.write(chunk(b"IEND", b""))


if __name__ == "__main__":
    import os
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "shared", "panel.png")
    write_png(out, W, H)
    print("wrote", out, f"({W}x{H}, 9-slice margin {MARGIN})")
