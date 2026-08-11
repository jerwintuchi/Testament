#!/usr/bin/env python3
"""The Quartermaster's AUTHOR-PAINTED furniture — cropped and re-scaled for the room.

The author supplied six hand-drawn props (`_src/qm/*.png`). This does not draw them; it
DERIVES the runtime PNGs from them, so the transform is reproducible and lives in one
place rather than as a magic size at a call site.

Three facts about the sources, measured rather than assumed:

1. **They are genuine 1:1 pixel art** — a block-size probe finds no upscaling, and each
   holds 38–57 colours. So they are already in the project's register (TD-046) and are
   NOT the painted concept art TD-055/TD-075 rejected. There is no `assert_on_palette`
   here on purpose: the palette lock is retired, and author art is welcome as authored.

2. **They are all drawn on a 200x200 canvas regardless of the object's real size.** A
   cabinet and an inkwell are both 200px, so the canvas says nothing about scale — the
   OBJECT does. The cabinet (154px tall) and the table (115px) are already consistent
   with each other and with the room, so they ship 1:1. The three small props are hero
   renders at roughly 6x room scale and are reduced.

3. **Reduction is POINT-SAMPLED, not averaged and not a mode filter.** Averaging is the
   LINEAR mush TD-054 recorded. A 3x3 mode filter was tried and is visibly worse — it
   thickened the scale's chains until they broke and ate the seal-stamp's rim bolts —
   because the majority colour in a block is the background wherever a detail is one
   pixel wide. Point sampling keeps the silhouette; it is also just what NEAREST does.

Everything is written to a LITERAL relative path so `tools/asset_map.py` can derive the
producer edge (S5b). Run from `client/assets/ui/`.
"""
import ashember as A
from pngio import read_png

# Content boxes, measured off the alpha of each source. Declared rather than recomputed
# so the runtime size of every piece is visible in one table and cannot drift when a
# source is re-exported with different padding.
#
# The source paths are spelled out in full at every `read_png` call site below rather
# than assembled from a directory constant, for the same reason the generators' OUTPUT
# paths are literal: `tools/asset_map.py` derives its edges from literals, so a computed
# path silently drops the author's art out of the dependency map (S5b).
#           x0   y0    w    h
CABINET = ( 29,  25, 143, 154)
TABLE   = (  6,  46, 188, 115)
FRAME   = ( 19,  18, 161, 164)
SCALE   = ( 29,   9, 146, 182)
QUILL   = ( 11,  11, 170, 177)
STAMP   = ( 43,  13, 112, 171)

PROP_DIV = 3   # the hero props' reduction. /2 is too big for the bench, /4 breaks the
               # scale's stand — this is the largest divisor the forms survive.

# The table's front panel is uniform vertical planking, so the bench is SHORTENED by
# cutting a band out of the middle of it rather than by scaling the whole object. The
# planks' seams run vertically and continue straight across the join; only grain is
# lost, and grain is noise. 115 -> 92, which is the height the room's row already had.
TABLE_CUT_Y = 62
TABLE_CUT_H = 23


def _emit(out, src, box, div=1, cut=None):
    """Crop `box` out of `src`, reduce by `div`, optionally cutting a band of rows."""
    x0, y0, w, h = box
    _sw, _sh, px = src
    ow, oh = w // div, h // div
    if cut is not None:
        oh -= cut[1]

    def pixel(x, y):
        sy = y
        if cut is not None and y >= cut[0]:
            sy = y + cut[1]
        p = px(x0 + x * div, y0 + sy * div)
        return (p[0], p[1], p[2], p[3])

    A.write_png(out, ow, oh, pixel)
    print("  %-40s %dx%d" % (out, ow, oh))


def main():
    print("[gen_qm_furniture] author-painted stores furniture")
    _emit("stations/qm_cabinet.png",
          read_png("_src/qm/qm-open-cabinet.png"), CABINET)
    _emit("stations/qm_table.png",
          read_png("_src/qm/qm-table.png"), TABLE,
          cut=(TABLE_CUT_Y, TABLE_CUT_H))
    _emit("stations/qm_record_frame.png",
          read_png("_src/qm/qm-wooden-description-parchment.png"), FRAME)
    _emit("stations/qm_prop_scale.png",
          read_png("_src/qm/qm-scale.png"), SCALE, PROP_DIV)
    _emit("stations/qm_prop_quill.png",
          read_png("_src/qm/qm-quill-and-ink.png"), QUILL, PROP_DIV)
    _emit("stations/qm_prop_stamp.png",
          read_png("_src/qm/qm-seal-stamp.png"), STAMP, PROP_DIV)


if __name__ == "__main__":
    main()
