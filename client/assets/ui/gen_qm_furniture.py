#!/usr/bin/env python3
"""The Quartermaster's AUTHOR-PAINTED furniture — cropped, graded and re-scaled.

The author supplied hand-drawn pieces (`_src/qm/*.png`). This does not draw them; it
DERIVES the runtime PNGs from them, so every transform is reproducible and lives in one
place rather than as a magic size or a magic colour at a call site.

Four facts about the sources, measured rather than assumed:

1. **They are genuine 1:1 pixel art** — a block-size probe finds no upscaling, and each
   holds 20-57 colours. So they are already in the project's register (TD-046) and are
   NOT the painted concept art TD-055/TD-075 rejected.

2. **They are all drawn on a 200x200 canvas regardless of the object's real size.** A
   cabinet and an inkwell are both 200px, so the canvas says nothing about scale — the
   OBJECT does. The cabinet and the bench are already consistent with the room and ship
   1:1. The three small props are hero renders at roughly 6x room scale and are reduced.

3. **Reduction is POINT-SAMPLED, not averaged and not a mode filter.** Averaging is the
   LINEAR mush TD-054 recorded. A 3x3 mode filter was tried and is visibly worse — it
   thickened the scale's chains until they broke and ate the seal-stamp's rim bolts,
   because the majority colour in a block is the background wherever a detail is one
   pixel wide. Point sampling keeps the silhouette; it is also what NEAREST does.

4. **They were hue-shifted away from the room, and the fix is a GAIN, not a rotation**
   (TD-114). Measured on screen rather than in the source files, because the room's
   generated surfaces are lit by a warm candle shader and their PNGs are not what the
   eye compares: the room renders at hue 25-27 with saturation 0.41-0.45, the author's
   furniture at hue 0-7 with saturation 0.26-0.34. It is duller AS WELL AS redder.

   Three transforms were tried and rejected by looking at them:
     - HSL hue rotation to 27 deg: turned everything khaki. Hue 25 reads as rich brown
       only at high saturation; at 0.27 it reads olive.
     - rotation + a saturation boost: brassy mustard.
     - a gain fitted PER ASSET: correct on the wooden pieces, but it pushed the scale
       copper and the seal-stamp sickly yellow, because a gain fitted to *wood* is wrong
       for a brass object and no gain at all can fix the stamp's plum.
   What works is what a colour grade actually is: ONE gain for everything, so the
   materials keep their relationship to each other, derived by matching the wooden
   pieces' body tone to the room's own timber. The stamp's plum additionally gets a
   partial hue pull, being a genuine outlier rather than a cast.

Everything is written to a LITERAL relative path so `tools/asset_map.py` can derive the
producer edge (S5b). Run from `client/assets/ui/`.
"""
import colorsys
from collections import Counter

import ashember as A
from pngio import read_png

# The room's own body timber, and the hue the grade pulls outliers toward.
ROOM_WOOD = A.RAMP["wood"][2]          # #5A3D28
PULL_HUE = 30.0

# Content boxes, measured off the alpha of each source. Declared rather than recomputed
# so the runtime size of every piece is visible in one table and cannot drift when a
# source is re-exported with different padding.
#
# The source paths are spelled out in full at every `read_png` call site below rather
# than assembled from a directory constant, for the same reason the generators' OUTPUT
# paths are literal: `tools/asset_map.py` derives its edges from literals, so a computed
# path silently drops the author's art out of the dependency map (S5b).
#            x0   y0    w    h
CABINET = ( 17,  17, 166, 166)
TABLE   = (  6,  46, 188, 115)
FRAME   = ( 19,  18, 161, 164)
SCALE   = ( 29,   9, 146, 182)
QUILL   = ( 11,  11, 170, 177)
STAMP   = ( 43,  13, 112, 171)
OPEN_CAB = (29, 25, 143, 154)          # retired as shelving; still the source of stock

PROP_DIV = 3   # the hero props' reduction. /2 is too big for the bench, /4 breaks the
               # scale's stand — this is the largest divisor the forms survive.

# The table's front panel is uniform vertical planking, so the bench is SHORTENED by
# cutting a band out of the middle of it rather than by scaling the whole object. The
# planks' seams run vertically and continue straight across the join; only grain is
# lost, and grain is noise. 115 -> 92, which is the height the room's row already had.
TABLE_CUT_Y = 62
TABLE_CUT_H = 23

# The stock crates, lifted from the alcoves of the retired open cabinet so the dressing
# is the author's own art at the author's own resolution rather than something redrawn
# to sit beside it. Each entry is a search box; the crate's real bounds are found inside
# it, so these only have to be roughly right.
CRATE_BOXES = [(27, 44, 16, 38), (51, 65, 16, 38), (18, 30, 45, 72), (35, 50, 45, 72),
               (56, 68, 45, 72), (73, 89, 45, 72), (94, 119, 45, 72)]


def _sub(src, box):
    """A reader for one content box of a source file."""
    x0, y0, _w, _h = box
    _sw, _sh, px = src
    return lambda x, y: px(x0 + x, y0 + y)


def _body_tone(read, w, h):
    """The dominant MID-TONE colour: the object's body material, not its shadows or its
    highlights. Shadows are near-neutral and highlights clip, so neither describes what
    the material IS — which is the thing being matched to the room."""
    c = Counter()
    for y in range(h):
        for x in range(w):
            p = read(x, y)
            if p[3] < 200:
                continue
            _hh, ll, ss = colorsys.rgb_to_hls(p[0] / 255, p[1] / 255, p[2] / 255)
            if 0.15 <= ll <= 0.45 and ss >= 0.12:
                c[p[:3]] += 1
    return c.most_common(1)[0][0] if c else (128, 128, 128)


def derive_gain():
    """The one gain, fitted on the WOODEN pieces only.

    They are the room's timber; everything else must keep its relationship to them
    rather than be matched separately (see the module docstring for what that cost).
    The gain is normalised to leave overall brightness alone — this is a colour match,
    not an exposure change, and the art's own baked lighting has to survive it.
    """
    acc = [0.0, 0.0, 0.0]
    woods = [("_src/qm/qm-closed-cabinet.png", CABINET),
             ("_src/qm/qm-open-cabinet.png", OPEN_CAB),
             ("_src/qm/qm-table.png", TABLE)]
    for path, box in woods:
        read = _sub(read_png(path), box)
        b = _body_tone(read, box[2], box[3])
        g = [ROOM_WOOD[i] / max(b[i], 1) for i in range(3)]
        m = sum(g) / 3.0
        for i in range(3):
            acc[i] += g[i] / m
    return [a / len(woods) for a in acc]


GAIN = derive_gain()


def _grade(p, pull=0.0):
    """Apply the gain, optionally pulling a far-off hue home first."""
    if p[3] == 0:
        return (0, 0, 0, 0)
    r, g, b = p[0], p[1], p[2]
    if pull > 0.0:
        hh, ll, ss = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
        t = PULL_HUE / 360.0
        d = ((hh - t + 0.5) % 1.0) - 0.5        # signed shortest way round the wheel
        fr, fg, fb = colorsys.hls_to_rgb((t + d * (1.0 - pull)) % 1.0, ll, ss)
        r, g, b = fr * 255, fg * 255, fb * 255
    return (min(255, round(r * GAIN[0])), min(255, round(g * GAIN[1])),
            min(255, round(b * GAIN[2])), p[3])


def _emit(out, path, box, div=1, cut=None, pull=0.0, graded=True):
    """Crop `box` out of `path`, grade it, reduce by `div`, optionally cut a row band."""
    read = _sub(read_png(path), box)
    _x0, _y0, w, h = box
    ow, oh = w // div, h // div
    if cut is not None:
        oh -= cut[1]

    def pixel(x, y):
        sy = y + cut[1] if (cut is not None and y >= cut[0]) else y
        p = read(x * div, sy * div)
        return _grade(p, pull) if graded else (p[0], p[1], p[2], p[3])

    A.write_png(out, ow, oh, pixel)
    print("  %-40s %dx%d" % (out, ow, oh))


def _emit_stock(out):
    """The dressing atlas: the author's own crates, cropped out of the open cabinet.

    Uniform cells, bottom-aligned, because these stand on a shelf — a centred cell
    would hang the short ones in mid-air.
    """
    src = read_png("_src/qm/qm-open-cabinet.png")
    read = _sub(src, OPEN_CAB)
    found = []
    for (xa, xb, ya, yb) in CRATE_BOXES:
        bx0 = by0 = 999
        bx1 = by1 = -1
        for y in range(ya, yb + 1):
            for x in range(xa, xb + 1):
                p = read(x, y)
                if p[3] > 8 and (p[0] + p[1] + p[2]) / 3 > 42:
                    bx0, bx1 = min(bx0, x), max(bx1, x)
                    by0, by1 = min(by0, y), max(by1, y)
        found.append((bx0, by0, bx1 - bx0 + 1, by1 - by0 + 1))
    cw = max(c[2] for c in found) + 2
    ch = max(c[3] for c in found) + 2

    def pixel(x, y):
        i, lx = x // cw, x % cw
        if i >= len(found):
            return (0, 0, 0, 0)
        cx, cy, w, h = found[i]
        ox, oy = (cw - w) // 2, ch - h
        if not (ox <= lx < ox + w and oy <= y < oy + h):
            return (0, 0, 0, 0)
        p = read(cx + lx - ox, cy + y - oy)
        return _grade(p) if p[3] > 8 else (0, 0, 0, 0)

    A.write_png(out, cw * len(found), ch, pixel)
    print("  %-40s %dx%d  (%d cells of %dx%d)"
          % (out, cw * len(found), ch, len(found), cw, ch))
    return cw, ch, len(found)


def main():
    print("[gen_qm_furniture] author-painted stores furniture")
    print("  grade: gain R%.4f G%.4f B%.4f (fitted on the wooden pieces)" % tuple(GAIN))
    _emit("stations/qm_cabinet.png", "_src/qm/qm-closed-cabinet.png", CABINET)
    _emit("stations/qm_table.png", "_src/qm/qm-table.png", TABLE,
          cut=(TABLE_CUT_Y, TABLE_CUT_H))
    # The record board is the ONE piece that is left alone: measured at hue 29.9, it is
    # already the room's own warmth. Grading it would move a piece that is correct.
    _emit("stations/qm_record_frame.png",
          "_src/qm/qm-wooden-description-parchment.png", FRAME, graded=False)
    _emit("stations/qm_prop_scale.png", "_src/qm/qm-scale.png", SCALE, PROP_DIV)
    _emit("stations/qm_prop_quill.png", "_src/qm/qm-quill-and-ink.png", QUILL, PROP_DIV)
    # The stamp's body is plum (#3E213B), which is a hue error rather than a cast, so it
    # gets a half pull toward the room before the same gain everything else takes.
    _emit("stations/qm_prop_stamp.png", "_src/qm/qm-seal-stamp.png", STAMP, PROP_DIV,
          pull=0.50)
    _emit_stock("stations/qm_stock.png")


if __name__ == "__main__":
    main()
