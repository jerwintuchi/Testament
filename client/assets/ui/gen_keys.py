#!/usr/bin/env python3
"""Generate keycap glyphs for interaction hints.

A hint that says "Press E" in prose makes the player translate a sentence into a
key. A drawn keycap IS the key, so it is read rather than parsed. Authored at
display size and shown 1:1 NEAREST like every other UI surface (TD-055).

Shared UI, not a station's own art, so it lives in shared/ (canon S5b).

    cd client/assets/ui && python3 gen_keys.py
      -> shared/key_e.png   11x11
"""
import ashember as A

CAP_EDGE = A.RAMP["stone"][1]
CAP_FACE = A.RAMP["parchment"][2]
CAP_HI = A.RAMP["parchment"][4]
CAP_SHADE = A.RAMP["parchment"][0]
GLYPH = A.RAMP["ink"][0]
CLEAR = (0, 0, 0, 0)

W = H = 11

# 3x5 'E'. Hand-placed: at this size a font rasteriser has no room to be legible,
# which is TD-057's finding about small glyphs applied to one letter.
E_ROWS = ["111", "100", "111", "100", "111"]


def _key(x, y):
    # Rounded corners: clip the four single corner pixels so the cap reads as a key.
    if (x, y) in [(0, 0), (W - 1, 0), (0, H - 1), (W - 1, H - 1)]:
        return CLEAR
    if x == 0 or y == 0 or x == W - 1 or y == H - 1:
        return (CAP_EDGE[0], CAP_EDGE[1], CAP_EDGE[2], 255)
    if y == H - 2:
        return (CAP_SHADE[0], CAP_SHADE[1], CAP_SHADE[2], 255)   # the cap has depth
    # Glyph, centred: 3 wide x 5 tall in an 11x11 cap.
    gx, gy = x - 4, y - 3
    if 0 <= gx < 3 and 0 <= gy < 5 and E_ROWS[gy][gx] == "1":
        return (GLYPH[0], GLYPH[1], GLYPH[2], 255)
    c = CAP_HI if y == 1 else CAP_FACE
    return (c[0], c[1], c[2], 255)


TARGETS = [("shared/key_e.png", W, H, _key)]


def _assert_on_palette():
    for _, w, h, fn in TARGETS:
        for y in range(h):
            for x in range(w):
                r, g, b, a = fn(x, y)
                if a and (r, g, b) not in A.PALETTE_SET:
                    raise AssertionError("off-palette: %r" % ((r, g, b),))


if __name__ == "__main__":
    _assert_on_palette()
    for path, w, h, fn in TARGETS:
        A.write_png(path, w, h, fn)
        print("wrote %s (%dx%d)" % (path, w, h))
