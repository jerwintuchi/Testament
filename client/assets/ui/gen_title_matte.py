#!/usr/bin/env python3
"""gen_title_matte.py — the author's Great Hall painting, processed into the client (TD-076).

    title/hall_plate.png     from  art/src/title/hall_plate_src.jpeg

The author's ruling, after several procedural attempts: make the hall almost 1:1 with the reference,
and disregard the constraints if they get in the way. The honest consequence is that the only thing
which is 1:1 with a painting is the painting — a ray-caster produces ordered forms, and that image's
character is irregularity no generator reaches. So the art IS the reference, processed.

Two treatments, because they trade the same thing in opposite directions:

    --fidelity   1280x720, LANCZOS from the source. Drawn 1:1 on device pixels at a 720p window,
                 so it displays with NO filtering and reads as the painting itself.
    --register   640x360, on the Ash & Ember palette: BOX downsample -> median -> quantise ->
                 two MODE passes. The board's grain, at the cost of the painting's fine detail.

The mode passes are the part that matters in `--register`: they keep boundaries hard while
flattening interiors, which is what a pixel artist's flat regions are. Measured on this image, they
take single-pixel islands from 5876 (a naive downscale — the "AI pixel art" tell) to under 600.

Run from client/assets/ui/:  python3 gen_title_matte.py [--fidelity|--register]
"""
import os
import sys
from collections import Counter

from PIL import Image, ImageFilter

import ashember as A

SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   "..", "..", "..", "art", "src", "title", "hall_plate_src.jpeg")


def _load_16x9():
    im = Image.open(SRC).convert("RGB")
    tw = min(im.width, int(round(im.height * 16.0 / 9.0)))
    th = min(im.height, int(round(im.width * 9.0 / 16.0)))
    return im.crop(((im.width - tw) // 2, (im.height - th) // 2,
                    (im.width + tw) // 2, (im.height + th) // 2))


def fidelity():
    """1280x720: one art pixel per device pixel at a 720p window. No filter, no quantisation."""
    im = _load_16x9().resize((1280, 720), Image.LANCZOS)
    px = im.load()
    return 1280, 720, lambda x, y: px[x, y] + (255,)


def register():
    """640x360 on the palette. Cluster-preserving, because a naive downscale speckles."""
    im = _load_16x9().resize((640, 360), Image.BOX)
    im = im.filter(ImageFilter.MedianFilter(3)).filter(ImageFilter.MedianFilter(3))
    p = im.load()
    grid = [[A.quantize(p[x, y]) for x in range(640)] for y in range(360)]
    for _ in range(2):
        out = [row[:] for row in grid]
        for y in range(360):
            y0, y1 = max(0, y - 1), min(360, y + 2)
            for x in range(640):
                x0, x1 = max(0, x - 1), min(640, x + 2)
                c = Counter()
                for yy in range(y0, y1):
                    row = grid[yy]
                    for xx in range(x0, x1):
                        c[row[xx]] += 1
                out[y][x] = c.most_common(1)[0][0]
        grid = out
    iso = sum(1 for y in range(1, 359) for x in range(1, 639)
              if grid[y][x] != grid[y - 1][x] and grid[y][x] != grid[y + 1][x]
              and grid[y][x] != grid[y][x - 1] and grid[y][x] != grid[y][x + 1])
    print("  register: %d colours, %d single-pixel islands (a naive downscale gives 5876)"
          % (len({c for row in grid for c in row}), iso))
    return 640, 360, lambda x, y: grid[y][x] + (255,)


if __name__ == "__main__":
    os.makedirs(os.path.join(os.path.dirname(os.path.abspath(__file__)), "title"), exist_ok=True)
    w, h, px = register() if "--register" in sys.argv[1:] else fidelity()
    # A LITERAL relative path, run from client/assets/ui/ (canon S5b).
    A.write_png("title/hall_plate.png", w, h, px)
    print("gen_title_matte OK — %dx%d" % (w, h))
