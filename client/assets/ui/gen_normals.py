#!/usr/bin/env python3
"""gen_normals.py — normal maps + restored-colour frame diffuse for board dynamic lighting.

Board Dynamic Lighting (DECISION_LOG TD-047 → re-graded TD-048, spec specs/board-lighting/,
T148/R129 → T160/R143). Each surround surface gets a companion tangent-space **normal map**.
The frame diffuse is **re-authored from the preserved painted source** to read as carved warm
wood in its OWN colour (baked, legible even unlit) — the dungeon-dark re-grade (TD-048) reverses
the earlier TD-047 neutralisation, where the frame was flattened so the torchlight supplied its
colour; that washed out the mood, so colour is baked back in and the light is now only a whisper.
Stdlib only (pngio read + ashember write), so the user can regenerate; new PNGs are imported with
`godot --headless --path <UNC> --import`.

Idempotent: the painted frame source is preserved as `_frame_v1_src.png` and every run
derives from it (never from the already-processed `frame_v1.png`).

Emits:
  _frame_v1_src.png   (first run only — a copy of the original painted frame, kept as source)
  frame_v1.png        (RE-AUTHORED carved warm wood: source hue kept, baked hotspots softened,
                       value darkened modestly for the dungeon key; TD-048/T160/R143)
  frame_v1_n.png      (strong carved-relief normal, derived from the painted source's luminance)
  backing_v1_n.png    (gentle plank normal; diffuse unchanged)
  wall_v1_n.png       (gentle brick normal; diffuse unchanged)

Normal convention: tangent-space, flat = (128,128,255). If V1 shows the torch raking the
WRONG way, flip FLIP_G (Godot 2D vs OpenGL green-channel sign).
"""
import math
import os
import shutil
import pngio
import ashember as A

FLIP_G = False   # set True if the relief lights inverted in the V1 capture


def _load_luma(path):
    """Read a PNG → (w, h, lum[list 0..1], alpha[list], px)."""
    w, h, px = pngio.read_png(path)
    lum = [0.0] * (w * h)
    for y in range(h):
        for x in range(w):
            r, g, b, _a = px(x, y)
            lum[y * w + x] = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
    return w, h, lum, px


def _normal_pixel(w, h, lum, strength):
    """A pixel(x,y)->(r,g,b,a) that Sobels the height field into a packed normal."""
    def H(x, y):
        x = 0 if x < 0 else (w - 1 if x >= w else x)
        y = 0 if y < 0 else (h - 1 if y >= h else y)
        return lum[y * w + x]

    gy_sign = -1.0 if FLIP_G else 1.0

    def pixel(x, y):
        dx = H(x + 1, y) - H(x - 1, y)
        dy = H(x, y + 1) - H(x, y - 1)
        nx = -dx * strength
        ny = -dy * strength * gy_sign
        nz = 1.0
        inv = 1.0 / math.sqrt(nx * nx + ny * ny + nz * nz)
        return (A.clamp((nx * inv * 0.5 + 0.5) * 255),
                A.clamp((ny * inv * 0.5 + 0.5) * 255),
                A.clamp((nz * inv * 0.5 + 0.5) * 255),
                255)
    return pixel


DARKEN = 0.82              # modest value pull-down for the dungeon key (keeps hue)
HIGHLIGHT_COMPRESS = 0.65  # soften baked hotspots so nothing reads as a fake light


def _restore_frame_pixel(px):
    """A pixel that RESTORES the painted frame's own carved-wood colour (TD-048/R143).

    Per-channel scaling keeps the wood's hue; baked highlights above mid are compressed
    (so a painted hotspot never reads as a light the scene doesn't have), then the whole
    frame is darkened modestly for the dungeon key. The carved FORM is still carried by the
    companion normal map for the tight per-sconce halo. Transparent interior stays transparent.
    """
    def pixel(x, y):
        r, g, b, a = px(x, y)
        if a == 0:
            return (0, 0, 0, 0)
        L = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
        # Soften only the highlights (L>0.5), leave shadows; per-channel scale preserves hue.
        scale = 1.0
        if L > 0.5:
            f = 0.5 + (L - 0.5) * HIGHLIGHT_COMPRESS
            scale = f / L
        scale *= DARKEN
        return (A.clamp(r * scale), A.clamp(g * scale), A.clamp(b * scale), a)
    return pixel


def main():
    # Frame: preserve the painted original as the source, derive normal + neutral from it.
    if not os.path.exists("_frame_v1_src.png"):
        shutil.copyfile("frame_v1.png", "_frame_v1_src.png")
        print("kept painted source -> _frame_v1_src.png")
    fw, fh, flum, fpx = _load_luma("_frame_v1_src.png")
    A.write_png("frame_v1_n.png", fw, fh, _normal_pixel(fw, fh, flum, 8.0))
    print("wrote frame_v1_n.png (%dx%d)" % (fw, fh))
    A.write_png("frame_v1.png", fw, fh, _restore_frame_pixel(fpx))
    print("re-authored frame_v1.png carved warm wood (TD-048/T160)")

    # Backing + wall: diffuse UNCHANGED, gentle luminance-bump normals only.
    for name, strength in (("backing_v1", 4.0), ("wall_v1", 4.0)):
        w, h, lum, _px = _load_luma("%s.png" % name)
        A.write_png("%s_n.png" % name, w, h, _normal_pixel(w, h, lum, strength))
        print("wrote %s_n.png (%dx%d)" % (name, w, h))


if __name__ == "__main__":
    main()
