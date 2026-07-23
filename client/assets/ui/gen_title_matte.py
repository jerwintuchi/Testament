#!/usr/bin/env python3
"""gen_title_matte.py — the title screen's matte-painted background (TD-073 / R241).

The Collegium's hall is AUTHOR ART, not a procedural reconstruction. It comes in as
`art/src/collegium_hall_src.png` (the author's own, generated via ChatGPT) and this
generator does three jobs and no more:

 1. INPAINT the baked-in UI. The concept art has its title and menu painted into it
    ("TESTAMENT", CONTINUE, NEW EXPEDITION, …). Those must go, or they ghost behind the
    real UI we render on top. The Collegium device above the title and the lit shrine
    device below it are KEPT — they are art, not interface.
 2. CROP to the client's 16:9 without distorting anything (no stretching, ever).
 3. AREA-AVERAGE down to the delivery size.

Deliberately NOT done: quantizing to the Ash & Ember ramps. This is a painted
environment matte and a recorded exception to TD-055 (which governs UI *surfaces*).
Quantizing it would destroy exactly the atmosphere the matte exists to carry.

Run from client/assets/ui/:  python3 gen_title_matte.py  ->  title/collegium_hall.png
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ashember as A          # noqa: E402  (write_png only — no palette work here)
from pngio import read_png    # noqa: E402

SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   "..", "..", "..", "art", "src", "collegium_hall_src.png")

OUT_W, OUT_H = 1280, 720      # a clean 2x of the 640x360 logical frame

# The baked-in UI band, measured off the source by scanning centre-band luminance:
#   y 248..348  the Collegium device      KEEP (art)
#   y 390..432  "TESTAMENT"               remove
#   y 462       the rule beneath it       remove
#   y 508..730  the six menu lines        remove
#   y 800..830  the shrine device         KEEP (art)
UI_X0, UI_X1 = 480, 1200

# The baked text lines, measured off the source. Filling a WIDE glyph from its left/right
# neighbours drags in the dark vault and leaves a dark ghost (tried, rejected). Vertically,
# though, the background barely changes across ~40 rows — so each line is reconstructed by
# interpolating between clean rows just above and just below it, which is why these are narrow
# per-line bands rather than one tall block.
UI_BANDS = [
    # ONLY the interactive menu lines. The painted "TESTAMENT", its cross and rule, and the
    # Collegium device above them are KEPT — they are the reference's own typography and they
    # are better than anything we would redraw. Inpainting them cost twice: an 80-row vertical
    # interpolation smeared visibly down the centre of the frame, and rendering our own emblem
    # on top of the painted one doubled it. Both read as uncanny. Art stays; only the buttons go.
    (478, 506),    # CONTINUE  (+ its flanking diamonds)
    (514, 542),    # NEW EXPEDITION
    (549, 578),    # JOIN EXPEDITION
    (585, 614),    # SETTINGS
    (621, 650),    # CREDITS
    (658, 688),    # QUIT
]
PAD = 14           # clean rows sampled either side of a band


def load_inpainted():
    """Read the source and paint out the baked UI text, returning a row-major buffer.

    The Collegium device above the title (y 248..348) and the lit shrine below it (y 800..830)
    are untouched — they are art, not interface.
    """
    w, h, px = read_png(SRC)
    buf = [[px(x, y)[:3] for x in range(w)] for y in range(h)]

    for (b0, b1) in UI_BANDS:
        top = max(0, b0 - PAD)
        bot = min(h - 1, b1 + PAD)
        span = float(bot - top)
        above, below = list(buf[top]), list(buf[bot])
        for y in range(b0, min(b1, h)):
            t = (y - top) / span
            row = buf[y]
            for x in range(UI_X0, min(UI_X1, w)):
                a, c = above[x], below[x]
                lerped = (a[0] + (c[0] - a[0]) * t,
                          a[1] + (c[1] - a[1]) * t,
                          a[2] + (c[2] - a[2]) * t)
                # Feather the band edges so the seam does not read as a rectangle.
                edge = min(y - b0, b1 - 1 - y)
                f = min(1.0, max(0.0, edge / 5.0))
                o = row[x]
                row[x] = (o[0] + (lerped[0] - o[0]) * f,
                          o[1] + (lerped[1] - o[1]) * f,
                          o[2] + (lerped[2] - o[2]) * f)
    return w, h, buf


def main():
    w, h, buf = load_inpainted()

    # Crop to 16:9 with NO distortion. 1536x1024 -> 1536x864: 160 rows go. Take more off the
    # top than the bottom — the upper vault is empty dark, while the floor carries the runner
    # and the candle reflections that say "this place is used".
    cw = w
    ch = int(round(w * OUT_H / float(OUT_W)))
    y0 = min(max(0, (h - ch) - 55), h - ch)      # 105 off the top, 55 off the bottom
    print("  crop %dx%d -> %dx%d at y0=%d" % (w, h, cw, ch, y0))

    sx = cw / float(OUT_W)
    sy = ch / float(OUT_H)

    def px(ox, oy):
        # Area average of the source footprint for this output pixel — a real box filter, so
        # the downsample keeps the painting's detail instead of point-sampling it away.
        x0 = ox * sx
        x1 = (ox + 1) * sx
        yy0 = y0 + oy * sy
        yy1 = y0 + (oy + 1) * sy
        ix0, ix1 = int(x0), min(int(x1) + 1, cw)
        iy0, iy1 = int(yy0), min(int(yy1) + 1, y0 + ch)
        r = g = b = wsum = 0.0
        for iy in range(iy0, iy1):
            fy = min(yy1, iy + 1) - max(yy0, iy)
            if fy <= 0:
                continue
            row = buf[iy]
            for ix in range(ix0, ix1):
                fx = min(x1, ix + 1) - max(x0, ix)
                if fx <= 0:
                    continue
                a_ = fx * fy
                c = row[ix]
                r += c[0] * a_
                g += c[1] * a_
                b += c[2] * a_
                wsum += a_
        if wsum <= 0:
            return (0, 0, 0, 255)
        return (A.clamp(r / wsum), A.clamp(g / wsum), A.clamp(b / wsum), 255)

    os.makedirs(os.path.join(os.path.dirname(os.path.abspath(__file__)), "title"), exist_ok=True)
    # A LITERAL relative path, run from client/assets/ui/ (canon S5b): tools/asset_map.py
    # derives producer edges from this string.
    A.write_png("title/collegium_hall.png", OUT_W, OUT_H, px)
    print("gen_title_matte OK — collegium_hall.png %dx%d (matte, NOT palette-quantized)."
          % (OUT_W, OUT_H))


if __name__ == "__main__":
    main()
