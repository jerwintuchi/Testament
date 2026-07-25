#!/usr/bin/env python3
"""gen_title_arch.py — the title hall's architecture, cut into layers (TD-073, T260).

    title/pier_left.png  title/pier_right.png      the near frame,  z < 14m
    title/arcade_left.png  title/arcade_right.png  the arcade,      z >= 14m
    title/vault.png  title/apse.png  title/floor.png

**These are slices of the plate, not a second drawing of it.** Every pixel comes from
`gen_title_plate.plate_px` — the identical shading — and each layer keeps only the pixels whose
ray strikes its own surface, writing transparent everywhere else. Composite all seven and you get
the plate back, pixel for pixel. That is the point: `design.md`'s P128 says every architecture
layer is emitted from ONE camera with a different depth range, so perspective agreement is
structural rather than eyeballed. Seven separately *drawn* pieces would have seven vanishing
points and could never be re-aligned by hand.

**Placement is derived, not authored.** Each layer is cropped to its own bounding box and this
script prints the box back as viewport fractions, which is exactly what `title_scene.gd`'s ARCH
table wants. Hand-tuned constants would drift the moment any of the hall's metres changed.

So what are they FOR, given the plate already exists? Two things: a layer can be repainted or
replaced on its own (the rig prefers a piece over the plate wherever one exists), and the near
frame is separable from the distance — which is the precondition for parallax, should R246's
condition ever be met. Until then the plate alone is the cheaper path and stays the default.

Run from client/assets/ui/:
    python3 gen_title_arch.py            cut the seven layers   (~3 min: two ray casts per pixel)
    python3 gen_title_arch.py --verify   the named test, below  (~30s, no ray casting)

`--verify` reassembles the seven committed layers **at the placement `title_scene.gd` actually
uses** — parsed out of its ARCH table, not restated here — and compares the result to the committed
plate. It must come back with every pixel covered and none mismatched. That single check proves
three things at once: the layers tile the frame with no gap, they carry the plate's own shading,
and the rig's placement numbers still match the crops they were derived from.
"""
import os
import re
import sys

import ashember as A
import pngio
from gen_nave import hit, ray
from gen_title_plate import W, H, plate_px

RIG = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   "..", "..", "scripts", "ui", "title_scene.gd")
RE_ARCH = re.compile(r'\["([a-z_]+\.png)",\s*Vector3\(([\d.]+),\s*([\d.]+),\s*([\d.]+)\)')

NEAR_Z = 14.0          # design.md's split: the near frame vs the working arcade behind it

LAYERS = ("pier_left", "pier_right", "arcade_left", "arcade_right", "vault", "apse", "floor")


def classify(fx, fy):
    """Which layer owns this pixel — surface kind first, then depth, then side."""
    kind, _a, _b, dist = hit(fx, fy)
    if kind == "wall":
        left = ray(fx, fy)[0] < 0.0
        if dist < NEAR_Z:
            return "pier_left" if left else "pier_right"
        return "arcade_left" if left else "arcade_right"
    return kind if kind in ("vault", "apse", "floor") else "apse"


def main():
    # One pass over the frame: colour from the plate's own shading, plus the owning layer.
    print("sampling %dx%d ..." % (W, H))
    rgb = [None] * (W * H)
    owner = bytearray(W * H)
    index = {name: i for i, name in enumerate(LAYERS)}
    box = {name: [W, H, -1, -1] for name in LAYERS}      # x0, y0, x1, y1

    for y in range(H):
        row = y * W
        for x in range(W):
            name = classify((x + 0.5) / W, (y + 0.5) / H)
            owner[row + x] = index[name]
            rgb[row + x] = plate_px(x, y, W, H)
            b = box[name]
            if x < b[0]:
                b[0] = x
            if y < b[1]:
                b[1] = y
            if x > b[2]:
                b[2] = x
            if y > b[3]:
                b[3] = y

    for name in LAYERS:
        x0, y0, x1, y1 = box[name]
        if x1 < x0:
            print("  %-13s EMPTY — no pixel in frame" % name)
            continue
        w, h = x1 - x0 + 1, y1 - y0 + 1
        mine = index[name]

        def px(x, y, x0=x0, y0=y0, mine=mine):
            i = (y + y0) * W + (x + x0)
            if owner[i] != mine:
                return (0, 0, 0, 0)
            r, g, b, _a = rgb[i]
            return (r, g, b, 255)

        # LITERAL relative paths, run from client/assets/ui/ (canon S5b): tools/asset_map.py
        # derives producer edges from these strings.
        if name == "pier_left":
            A.write_png("title/pier_left.png", w, h, px)
        elif name == "pier_right":
            A.write_png("title/pier_right.png", w, h, px)
        elif name == "arcade_left":
            A.write_png("title/arcade_left.png", w, h, px)
        elif name == "arcade_right":
            A.write_png("title/arcade_right.png", w, h, px)
        elif name == "vault":
            A.write_png("title/vault.png", w, h, px)
        elif name == "apse":
            A.write_png("title/apse.png", w, h, px)
        else:
            A.write_png("title/floor.png", w, h, px)

        # The placement `title_scene.gd` needs, in viewport fractions — derived from where the
        # camera actually put this surface, so ARCH can never drift from the geometry.
        cx = (x0 + w * 0.5) / W
        cy = (y0 + h * 0.5) / H
        print('  ["%s.png", Vector3(%.4f, %.4f, %.4f), %.3f],   # %dx%d'
              % (name, cx, cy, w / W, h / w, w, h))
    print("gen_title_arch OK — seven layers, one camera (P128).")


def verify():
    """Reassemble the layers at the rig's own placement and diff against the plate."""
    with open(RIG, encoding="utf-8") as f:
        arch = {m[0]: (float(m[1]), float(m[2]), float(m[3])) for m in RE_ARCH.findall(f.read())}
    pw, ph, plate = pngio.read_png("title/hall_plate.png")
    if (pw, ph) != (W, H):
        print("plate is %dx%d, generator emits %dx%d" % (pw, ph, W, H))
        return 1

    canvas = {}
    for name in LAYERS:
        file = "%s.png" % name
        if file not in arch:
            print("  %-13s NOT IN the rig's ARCH table" % name)
            return 1
        w, h, px = pngio.read_png("title/" + file)
        cx, cy, _fw = arch[file]
        x0, y0 = round(cx * W - w / 2.0), round(cy * H - h / 2.0)
        for y in range(h):
            for x in range(w):
                r, g, b, a = px(x, y)
                if a > 0:
                    canvas[(x0 + x, y0 + y)] = (r, g, b)

    uncovered = mismatched = 0
    for y in range(H):
        for x in range(W):
            pr, pg, pb, _ = plate(x, y)
            c = canvas.get((x, y))
            if c is None:
                uncovered += 1
            elif c != (pr, pg, pb):
                mismatched += 1
    print("verify: %d px, uncovered %d, mismatched %d" % (W * H, uncovered, mismatched))
    if uncovered or mismatched:
        print("VERIFY FAILED — the layers no longer reconstruct the plate")
        return 1
    print("verify: OK — the seven layers reconstruct the plate exactly (P128)")
    return 0


if __name__ == "__main__":
    sys.exit(verify() if "--verify" in sys.argv[1:] else (main() or 0))
