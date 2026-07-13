#!/usr/bin/env python3
"""Deckled contract parchment using Prototype-v1's actual painted paper (TD-044).

Samples a clean paper band sliced from _proto_board.png (via pngio, no Pillow) as the
paper surface, mirror-wrapped so it tiles seamlessly, then applies a soft warm light,
edge AO, and a torn deckle — so the live cards carry v1's painterly paper instead of
code-generated pixel shading. Rendered LINEAR in Godot to stay soft.
"""
import os
from pngio import read_png
from ashember import write_png, noise, smooth

HERE = os.path.dirname(os.path.abspath(__file__))
PBW, PBH, PB = read_png(os.path.join(HERE, "_slices/paper_band1.png"))
W, H = 200, 168
# Live-tone lift (T156/R136): the raw v1 painted paper is a dim amber (~lum 0.09), so
# against the TD-048 dungeon-dark board the notices sat BELOW the legibility floor
# (ink < 4.5:1). Lift the paper partway toward the live tone — readable ink, but short
# of full cream so the writs stay warm/aged (the user's "lift partway" ruling). Tuned
# against the worst-lit (farthest-from-torch) notice measured off a capture.
LIFT = 1.6
# A small near-flat patch of the band: tiling a flat patch avoids the mirrored-gradient
# arcs a whole-band tile produced. The card's own light (below) supplies the falloff.
PX0, PY0, PSZ = 50, 6, 22


def _mir(i, n):
    p = i % (2 * n)
    return p if p < n else 2 * n - 1 - p


def _paper(x, y):
    return PB(PX0 + _mir(x, PSZ), PY0 + _mir(y, PSZ))


def _snoise(x, y, seed, scale):
    """Bilinear-interpolated value noise (~[-8,8]) — smooth, no blocky cells."""
    fx, fy = x / scale, y / scale
    ix, iy = int(fx), int(fy)
    tx, ty = fx - ix, fy - iy
    n00 = noise(ix, iy, seed); n10 = noise(ix + 1, iy, seed)
    n01 = noise(ix, iy + 1, seed); n11 = noise(ix + 1, iy + 1, seed)
    a = n00 + (n10 - n00) * tx
    b = n01 + (n11 - n01) * tx
    return a + (b - a) * ty


def _tear(pos, seed):
    slow = (noise(pos // 12, 0, seed) + 8) / 16.0
    fine = (noise(pos, 0, seed + 91) + 8) % 4
    return int(2 + slow * 5) + fine


def card(seed):
    def px(x, y):
        l, t, r, b = x, y, W - 1 - x, H - 1 - y
        if (l < _tear(y, seed) or r < _tear(y, seed + 5)
                or t < _tear(x, seed + 11) or b < _tear(x, seed + 17)):
            return (0, 0, 0, 0)
        d = min(l, t, r, b)
        pr, pg, pb, _a = _paper(x, y)
        cx, cy = W * 0.5, H * 0.40
        nx = (x - cx) / (W * 0.60)
        ny = (y - cy) / (H * 0.80)
        light = 1.0 - (nx * nx + ny * ny) * 0.35
        ao = smooth(0.0, 10.0, float(d))
        f = (0.74 + 0.26 * light) * (0.62 + 0.38 * ao)
        # Broad SMOOTH staining: the large-scale aged mottle v1's paper carries, so the
        # flat-patch tile doesn't read too uniform (interpolated noise → no blocky cells).
        mott = _snoise(x, y, seed + 60, 40.0)       # ~[-8,8], smooth
        f *= 1.0 + mott * 0.008                      # ±6% soft staining
        f = max(0.45, min(1.16, f))
        j = noise(x, y, seed + 13) * 0.42           # TD-050: fibre jitter eased — clean-aged, not speckled
        rr, gg, bb = int(pr * f * LIFT + j), int(pg * f * LIFT + j), int(pb * f * LIFT + j)
        if mott < -3.0:                              # warm-brown foxing in the stained pools (TD-050: eased)
            a = (-3.0 - mott) * 0.014
            gg = int(gg * (1.0 - a)); bb = int(bb * (1.0 - a * 1.6))
        if d <= 2:                                   # torn-edge shadow
            rr, gg, bb = int(rr * 0.68), int(gg * 0.68), int(bb * 0.68)
        return (max(0, min(255, rr)), max(0, min(255, gg)), max(0, min(255, bb)), 255)
    return px


if __name__ == "__main__":
    for seed, tag in ((101, "0"), (203, "1")):
        name = "parch_v1_%s.png" % tag
        write_png(os.path.join(HERE, name), W, H, card(seed))
        print("wrote", name, W, "x", H)
    print("gen_parch_v1 OK — deckled cards on v1 painted paper.")
