#!/usr/bin/env python3
"""gen_logo.py — the Collegium emblem, lifted from the author's source art.

The order's mark is author-supplied pixel art: a point-DOWN sword (diamond-ring
pommel, patriarchal double crossguard, long blade) flanked by a laurel/wing wreath,
in aged bone-gold with a heavy black outline. It ships on a blurred grey-olive
ground; this generator LIFTS the sigil off that ground with a border flood-fill
(region-grow through the smooth gradient, halt at the steep black outline), crops to
content, and writes `collegium_logo.png` (transparent) at a display-friendly master
size. One reusable mark — the board crest crowns with it, the banner carries it.

Source (in-repo, so the lift is reproducible): art/src/collegium_logo_src.png.
Run FROM client/assets/ui. PIL is sanctioned for generators (CLAUDE.md toolchain).
Brand-new PNGs need `godot --headless --import`.

# @produces collegium_logo.png  — the Collegium emblem (transparent), for the crest + banner
# @why      author sigil (art/src/collegium_logo_src.png) shipped on a blurred ground; a border
#           flood-fill (TOL≈12, neighbour-relative) drops the ground where the outline is a
#           steeper per-pixel ramp than the smooth background, then crop + LANCZOS to master
"""
import os
from collections import deque
from PIL import Image
import ashember as A

SRC = os.path.join(os.path.dirname(__file__), "..", "..", "..", "art", "src", "collegium_logo_src.png")
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "board", "collegium_logo.png")
TOL = 12            # neighbour-relative flood step (sum of |dR|+|dG|+|dB|)
MASTER_H = 220      # emblem is tall+narrow; height drives the master, width follows aspect


def _extract(src_path: str) -> Image.Image:
    im = Image.open(src_path).convert("RGBA")
    W, H = im.size
    px = im.load()
    bg = bytearray(W * H)
    dq = deque()
    # seed every border pixel
    for x in range(W):
        for y in (0, H - 1):
            i = y * W + x
            if not bg[i]:
                bg[i] = 1; dq.append((x, y))
    for y in range(H):
        for x in (0, W - 1):
            i = y * W + x
            if not bg[i]:
                bg[i] = 1; dq.append((x, y))
    # region-grow: expand to a neighbour whose colour is within TOL of THIS pixel (so the
    # flood rides the smooth gradient but stalls at the outline's steep ramp)
    while dq:
        x, y = dq.popleft()
        p = px[x, y]
        pr, pg, pb = p[0], p[1], p[2]
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < W and 0 <= ny < H:
                ni = ny * W + nx
                if not bg[ni]:
                    q = px[nx, ny]
                    if abs(q[0] - pr) + abs(q[1] - pg) + abs(q[2] - pb) <= TOL:
                        bg[ni] = 1; dq.append((nx, ny))
    # apply mask + measure content bbox
    out = Image.new("RGBA", (W, H))
    op = out.load()
    minx, miny, maxx, maxy = W, H, 0, 0
    for y in range(H):
        row = y * W
        for x in range(W):
            if bg[row + x]:
                op[x, y] = (0, 0, 0, 0)
            else:
                op[x, y] = px[x, y]
                if x < minx: minx = x
                if x > maxx: maxx = x
                if y < miny: miny = y
                if y > maxy: maxy = y
    crop = out.crop((minx, miny, maxx + 1, maxy + 1))
    w = max(1, round(MASTER_H * crop.width / crop.height))
    return crop.resize((w, MASTER_H), Image.LANCZOS)


def main() -> None:
    emblem = _extract(SRC)
    w, h = emblem.size
    ep = emblem.load()
    A.write_png(OUT, w, h, lambda x, y: ep[x, y])
    print("wrote %s (%dx%d)" % (OUT, w, h))


if __name__ == "__main__":
    main()
