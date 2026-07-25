#!/usr/bin/env python3
"""gen_title_hall.py — the Great Hall, shaded from real geometry (TD-076).

    title/hall_plate.png   640x360, on-palette, drawn 1:1 through NEAREST

Shape comes from `hall_geometry.trace()`, which returns a surface NORMAL. That is the whole
difference from the version this replaces: the vault curves and the piers are round because the
geometry says so, not because a gradient was painted onto a plane.

The register is the Contract Board's, unchanged and not negotiable (the author's ruling): authored
at 640x360, shown 1:1 through NEAREST, every colour an Ash & Ember ramp entry, light in flat
integer steps. Grandeur comes from composition, lighting and atmosphere — never from pixel density
or painterly detail. Large, simple forms, because the architecture is large and simple.

Detail is DENSE, though (R257). The version before this suppressed coursing on anything nearer than
12m, which left the biggest surfaces in the frame blank; here stone is coursed wherever a course is
thick enough to see.

Run from client/assets/ui/:  python3 gen_title_hall.py
"""
import math
import os

import ashember as A
import hall_geometry as G

W, H = 640, 360


def ramp(name, i):
    r = A.RAMP[name]
    return r[max(0, min(len(r) - 1, int(i)))]


CRIMSON = (A.RAMP["black"][1], A.RAMP["black"][2], A.RAMP["wax"][0], A.RAMP["wax"][1])


def blk(i, j, salt=0):
    n = A.noise(int(i), int(j), salt)
    return -1 if n < -5 else (1 if n > 5 else 0)


# ── Light, in world space (R253) ─────────────────────────────────────────────
# (x, y, z, radius, strength). A candle stand lights the pier beside it and the floor under it —
# and nothing across the hall, which is what world-space placement buys over screen-space blobs.
LIGHTS = [(0.0, 4.0, G.Z_FAR - 3.0, 26.0, 2.6)]                      # the altar
for _z in (7.0, 15.0, 25.0, 37.0):
    for _s in (-1, 1):
        LIGHTS.append((_s * (G.HALF_W - 0.7), 1.3, _z, 9.5, 2.0))     # stands along the arcade
for _z in (11.0, 21.0, 33.0):
    for _s in (-1, 1):
        LIGHTS.append((_s * (G.HALF_W + 3.0), 1.2, _z, 7.5, 1.5))     # and in the aisles beyond
# The clerestory: the vault's own light, and the only thing that reaches 29m. Cool and broad, so
# the ceiling reads as a lit shell rather than disappearing into the frame's black.
for _z in (9.0, 19.0, 29.0, 39.0):
    for _s in (-1, 1):
        LIGHTS.append((_s * (G.HALF_W - 1.0), G.CLR_HI, _z, 17.0, 1.9))


def light(p, n):
    """Integer ramp steps this point is lifted. Flat rings, never a falloff (P131)."""
    tot = 0.0
    for lx, ly, lz, r, k in LIGHTS:
        vx, vy, vz = lx - p[0], ly - p[1], lz - p[2]
        d2 = vx * vx + vy * vy + vz * vz
        if d2 > r * r:
            continue
        d = math.sqrt(d2) or 1e-3
        ndl = max(0.0, (n[0] * vx + n[1] * vy + n[2] * vz) / d)
        tot += k * ndl * (1.0 - d / r) ** 1.5
    return 0 if tot < 0.30 else (1 if tot < 0.85 else (2 if tot < 1.7 else 3))


def ambient(n):
    """Two steps from orientation alone, so nothing is ever a pure silhouette."""
    return 1 if n[1] > 0.35 else (0 if n[1] > -0.75 else -1)


def depth(dist):
    return 0 if dist < 11 else (1 if dist < 22 else (2 if dist < 38 else 3))


def vignette(fx, fy):
    v = max(abs(fx - 0.5) / 0.5, abs(fy - 0.5) / 0.5)
    return 2 if v > 0.97 else (1 if v > 0.80 else 0)


def coursed(dist, m_per_course=0.9):
    """Is a course thick enough on screen to be worth drawing? The previous generator gated this
    at 12m and left the near piers blank — the largest surfaces in frame, carrying nothing."""
    return (m_per_course / max(dist, 0.2)) * (H / (2.0 * G.TAN_V)) > 1.8


def px(x, y):
    fx, fy = (x + 0.5) / W, (y + 0.5) / H
    h = G.trace(fx, fy)
    p, n, d = h.p, h.n, h.dist
    lit = light(p, n)
    idx = 2 + ambient(n) + lit - depth(d) - vignette(fx, fy)

    if h.kind == "vault":
        idx = 2 + ambient(n) + lit - min(2, depth(d)) - vignette(fx, fy)
        # The groin is where the two barrels meet — a place the geometry HAS, so the rib is a
        # moulding sitting on it rather than a line drawn across a ceiling.
        zc = (int(p[2] / G.BAY) + 0.5) * G.BAY
        if abs(G._h_trans(p[0]) - G._h_long(p[2], zc)) < 0.16:
            idx += 2
        elif coursed(d, 1.1):
            u = math.atan2(p[1] - G.SPRING, p[0]) * 3.0
            if abs((u % 1.0) - 0.5) > 0.42:
                idx -= 1                                    # the webs are laid courses too

    elif h.kind == "pier":
        idx += 1                                            # a shaft catches more than a flat wall
        if coursed(d, 1.8):
            if abs(((h.u / 1.8) % 1.0) - 0.5) > 0.47:
                idx -= 1                                    # drum joints up the shaft
        if abs(h.u - G.ARC_SPRING) < 0.5 or abs(h.u - G.TRI_HI) < 0.35:
            idx += 1                                        # capital, string-course

    elif h.kind == "wall":
        z, hh = h.u, h.v
        dp = abs((z / G.BAY) % 1.0 - 0.5) * G.BAY
        if G.CLR_LO < hh < G.CLR_HI and dp < G.CLR_HALF:
            mull = abs(((dp / (G.CLR_HALF * 0.8)) % 1.0) - 0.5)
            if mull > 0.40:
                return ramp("navestone", 1) + (255,)
            t = blk(int(z / G.BAY), 0, 17)
            if t < 0:
                return ramp("wax", 2) + (255,)
            if t > 0:
                return ramp("parchment", 4 - min(2, depth(d))) + (255,)
            return ramp("gold", 3 - min(2, depth(d))) + (255,)
        if G.TRI_LO < hh < G.TRI_HI and dp < 1.0:
            idx -= 1                                        # the triforium band
        elif coursed(d):
            course = hh / 0.9
            if abs((course % 1.0) - 0.5) > 0.45 or abs(((z / 1.6) % 1.0) - 0.5) > 0.47:
                idx -= 1
            else:
                idx += blk(int(course), int(z / 1.6), 7)
        if hh < 3.0:
            idx -= 1                                        # soot at the foot of the wall

    elif h.kind in ("aisle_wall", "aisle_ceil"):
        idx = 1 + ambient(n) + lit - min(2, depth(d)) - vignette(fx, fy)
        if h.kind == "aisle_wall" and coursed(d):
            if abs(((h.v / 0.9) % 1.0) - 0.5) > 0.45:
                idx -= 1

    elif h.kind == "floor":
        xw, zw = h.u, h.v
        if abs(xw) < 1.5:
            ci = 2 + lit - vignette(fx, fy)
            if abs(abs(xw) - 1.34) < 0.10 and lit > 0:
                return ramp("gold", 1) + (255,)
            return CRIMSON[max(0, min(3, ci))] + (255,)
        if coursed(d, 1.5):
            if abs(((xw / 1.5) % 1.0) - 0.5) > 0.45 or abs(((zw / 1.5) % 1.0) - 0.5) > 0.45:
                idx -= 1
            elif blk(int(xw / 1.5), int(zw / 1.5), 33) < 0:
                idx -= 1

    elif h.kind == "apse":
        xw, hh = h.u, h.v
        # The sanctuary reads LOW: a lit altar table and its steps at the foot of the far wall,
        # with the wall above it left dark. The tall lancets that used to stand here sat exactly
        # behind the menu, and dimming them twice never fixed what was a placement problem.
        if abs(xw) < 3.2 and 1.1 < hh < 2.0:
            return ramp("gold", 2 if abs(((xw / 0.5) % 1.0) - 0.5) > 0.3 else 3) + (255,)
        if hh <= 1.1:
            idx = 3 + int(hh / 0.4) - vignette(fx, fy)       # the altar steps, worn pale
        elif hh < 9.0:
            idx = 1 + lit - vignette(fx, fy)                 # dark wall behind the sanctuary

    elif h.kind == "void":
        return ramp("black", 0) + (255,)

    return ramp("navestone", idx) + (255,)


if __name__ == "__main__":
    os.makedirs(os.path.join(os.path.dirname(os.path.abspath(__file__)), "title"), exist_ok=True)
    A.assert_on_palette(W, H, px, "title/hall_plate.png")
    A.write_png("title/hall_plate.png", W, H, px)
    print("gen_title_hall OK — the Great Hall from curved geometry, %dx%d, on-palette." % (W, H))
