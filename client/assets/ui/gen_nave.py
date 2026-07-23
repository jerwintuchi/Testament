#!/usr/bin/env python3
"""gen_nave.py — the title screen's held image: THE EMPTY NAVE (TD-071 / TD-072).

A High Gothic nave seen from the floor, looking up: compound piers rising as bundles of
colonnettes, three storeys of pointed openings (arcade / triforium / clerestory), a ribbed
quadripartite vault whose bosses chain away overhead, and a far end that glows.

STRUCTURE is taken from the author's Chartres reference — the angle, the verticality, the
bones. The LOOK is the design bible's, not the photograph's (TD-072): warm, weathered, aged,
and dramatically torch-lit, authored from the shipped Ash & Ember ramps with no additions.
Chartres is a daylight building whose drama is sun through glass; ours is a firelit one, so
FIRE is the key here and the cold shaft is only TD-043's warm/cool counterpoint.

Deliberately EMPTY. No character, creature, weapon, effect or furniture ever enters this
image — a title screen showing an Incarnate would leak the mystery the whole game is built on
(Pillar 3), and combat imagery would advertise the failure state. The reference's chairs are
not reproduced: they clutter the frame and date the space.

Geometry is a real CAMERA, not a painted fake: an ultra-wide lens (hfov 105°, a ~14mm
equivalent) at floor height, tilted UP 15°, ray-cast per pixel against the hall's planes. The
tilt is the point — it makes verticals CONVERGE toward the top of frame (three-point
perspective), which is what turns a corridor into a soaring space. The camera was recovered
from the reference by measuring where its nave axis vanishes: at ≈0.68 of frame height, i.e.
BELOW centre, which only happens when the camera is pitched up.

Everything is in metres, at Chartres' proportions (16m wide, 37m to the vault), so the
storeys sit where a real elevation puts them and the perspective follows for free.

Run from client/assets/ui/:  python3 gen_nave.py  ->  title/nave.png
"""
import math
import os

import ashember as A

W, H = 640, 360

# ── The camera, recovered from the reference (R238) ──────────────────────────
HFOV = math.radians(105.0)        # ultra-wide: near piers fill the frame's sides and corners
PITCH = math.radians(15.0)        # tilted UP — this is what converges the verticals
EYE_Y = 1.5                       # standing on the flags, not floating
TAN_H = math.tan(HFOV * 0.5)
TAN_V = TAN_H / (W / H)
SINP, COSP = math.sin(PITCH), math.cos(PITCH)

# ── The hall, in metres (Chartres' proportions) ──────────────────────────────
HALF_W = 8.0                      # 16m across the nave
VAULT_Y = 37.0                    # …and 37m to the vault: a height/width of 2.3
Z_FAR = 115.0                     # the apse closes the view
BAY = 7.0                         # bay length — the arcade's rhythm

# ── The three storeys, in metres up the wall ─────────────────────────────────
ARC_SPRING, ARC_HALF = 9.0, 2.55        # main arcade (apex ≈ 12.7m)
TRI_LO, TRI_HI, TRI_HALF = 15.2, 18.4, 0.95   # triforium band
CLR_SPRING, CLR_HALF = 22.0, 2.10       # clerestory, the glazed storey (apex ≈ 25.0m)
PIER_HALF = 1.75                        # half the solid pier between openings

K_LANCET = 0.55                   # two-centred arch: a lancet, not a wide Tudor arch
BLACK = (7, 6, 8)


def lancet(dp, half, springing):
    """Apex height of a two-centred pointed arch at |dp| from the opening's centre, in metres.

    Each half is an arc struck from the OPPOSITE springing point, so the two meet at a point
    instead of closing as a semicircle.
    """
    r = half * (1.0 + K_LANCET)
    dx = dp + half * K_LANCET
    return springing + math.sqrt(max(0.0, r * r - dx * dx))


def ray(fx, fy):
    """World-space direction for a pixel, through the pitched ultra-wide camera."""
    sx = (fx - 0.5) * 2.0 * TAN_H
    sy = (0.5 - fy) * 2.0 * TAN_V
    return (sx, sy * COSP + SINP, -sy * SINP + COSP)


def project(px, py, pz):
    """World point -> (fx, fy, inv_depth), or None behind the camera. Used to place fires."""
    ry_, rz = py - EYE_Y, pz
    df = ry_ * SINP + rz * COSP
    if df <= 0.05:
        return None
    du = ry_ * COSP - rz * SINP
    return (0.5 + px / df / (2.0 * TAN_H), 0.5 - du / df / (2.0 * TAN_V), 1.0 / df)


def hit(fx, fy):
    """Nearest plane the pixel's ray strikes: ("floor"|"vault"|"wall"|"apse", a, b, dist).

    `a` runs down the hall (metres), `b` is across the surface — cross-hall on floor/vault,
    height up the wall on a wall.
    """
    dx, dy, dz = ray(fx, fy)
    best = None
    if dy < -1e-6:                                   # floor, y = 0
        t = -EYE_Y / dy
        if t > 0:
            best = (t, "floor")
    if dy > 1e-6:                                    # vault, y = VAULT_Y
        t = (VAULT_Y - EYE_Y) / dy
        if t > 0 and (best is None or t < best[0]):
            best = (t, "vault")
    if abs(dx) > 1e-6:                               # side walls, x = ±HALF_W
        t = (math.copysign(HALF_W, dx)) / dx
        if t > 0 and (best is None or t < best[0]):
            best = (t, "wall")
    if dz > 1e-6:                                    # the apse closes the far end
        t = Z_FAR / dz
        if t > 0 and (best is None or t < best[0]):
            best = (t, "apse")
    if best is None:
        return ("apse", 0.0, 0.0, Z_FAR)
    t, kind = best
    wx, wy, wz = dx * t, EYE_Y + dy * t, dz * t
    if kind == "floor" or kind == "vault":
        return (kind, wz, wx, wz)
    if kind == "wall":
        return (kind, wz, wy, wz)
    return (kind, wy, wx, wz)


# ── Fire (R236). Braziers stand along the aisles: the KEY light. ─────────────
BRAZIERS = [(side * (HALF_W - 1.1), 0.9, z)
            for z in (13.0, 20.0, 30.0, 45.0, 66.0) for side in (-1, 1)]
BZ = [(pr[0], pr[1], pr[2]) for pr in
      (project(bx, by, bz) for bx, by, bz in BRAZIERS) if pr is not None]


def _firelight(fx, fy):
    """Summed warm falloff from every brazier — the image's key light."""
    tot = 0.0
    for bx, by, inv in BZ:
        rx_ = 4.0 * inv / (2.0 * TAN_H)                  # a real 4m pool, in perspective
        ry_ = 2.2 * inv / (2.0 * TAN_V)                  # pools wider than tall on the flags
        dxs = (fx - bx) / max(rx_, 1e-5)
        dys = (fy - by) / max(ry_, 1e-5)
        d2 = dxs * dxs + dys * dys
        if d2 < 1.0:
            tot += min(0.85, inv * 6.0) * (1.0 - d2) ** 2
    return min(1.4, tot)


def _apseglow(fx, fy):
    """The lit east end. Depth reads as LUMINANCE: the near is darkest and the distance opens
    into light, so the near piers fall to silhouette against it."""
    pr = project(0.0, 12.0, Z_FAR - 2.0)
    if pr is None:
        return 0.0
    ax, ay, _ = pr
    dxs = (fx - ax) / 0.135
    dys = (fy - ay) / 0.105
    return max(0.0, 1.0 - A.smooth(0.0, 1.0, math.sqrt(dxs * dxs + dys * dys))) ** 1.4


_DITHER = ((0, 8, 2, 10), (12, 4, 14, 6), (3, 11, 1, 9), (15, 7, 13, 5))


def _dither(base, x, y):
    """Break a smooth falloff so a stepped ramp does not band it into contour rings."""
    k = (_DITHER[y & 3][x & 3] / 16.0 - 0.5) * 8.0
    return (base[0] + k, base[1] + k, base[2] + k)


def nave_px(x, y):
    fx, fy = (x + 0.5) / W, (y + 0.5) / H
    kind, a, b, dist = hit(fx, fy)
    near = min(1.0, 14.0 / max(dist, 1.0))               # 1 close, → 0 far

    if kind == "apse":
        base = A.ramp_shade("stone", 0.16)
        light = abs(b) < 5.4 and 7.0 < a < lancet(abs(b) % 1.8, 0.9, 22.0)
        if light:
            mull = abs((abs(b) / 1.8) % 1.0 - 0.5)
            base = A.lerp_rgb(A.RAMP["stone"][3], A.RAMP["parchment"][3], 0.55)
            if mull > 0.40:
                base = A.over(base, A.RAMP["stone"][0], 0.75)     # the stone between lights
    elif kind == "floor":
        base = A.ramp_shade("stone", 0.06 + 0.10 * near)
        if abs(((a / 1.9) % 1.0) - 0.5) > 0.455 or abs(((b / 1.9) % 1.0) - 0.5) > 0.455:
            base = A.over(base, BLACK, 0.55)             # flag joints
        else:
            base = A.over(base, A.RAMP["stone"][0], 0.05 * (A.noise(x // 2, y // 2, 11) + 8) / 16.0)
    elif kind == "vault":
        # Ribbed quadripartite bays: diagonals crossing at a boss, transverse ribs, sunk webs.
        cross = b / HALF_W
        loc = (a / BAY) % 1.0
        base = A.ramp_shade("stone", 0.05 + 0.09 * near)
        base = A.over(base, BLACK, 0.34)
        rw = 0.085
        diag = abs(abs(cross) - abs(2.0 * loc - 1.0))
        if diag < rw or min(loc, 1.0 - loc) < rw * 0.45:
            base = A.over(base, A.RAMP["stone"][2], 0.26)
            if diag < rw * 0.5 and abs(loc - 0.5) < 0.10:
                base = A.over(base, A.RAMP["stone"][3], 0.24)     # the boss
        elif abs(cross) < rw * 0.4:
            base = A.over(base, A.RAMP["stone"][1], 0.22)         # ridge rib
    else:
        # ── Side wall: compound piers, three storeys of pointed openings ──
        h = b                                            # metres up the wall
        loc = (a / BAY) % 1.0
        dp = abs(loc - 0.5) * BAY                        # metres from the bay's centre
        base = A.ramp_shade("stone", 0.10 + 0.15 * near)
        in_arc = dp < ARC_HALF and ARC_SPRING is not None and h < lancet(dp, ARC_HALF, ARC_SPRING)
        in_clr = dp < CLR_HALF and CLR_SPRING < h < lancet(dp, CLR_HALF, CLR_SPRING)
        in_tri = dp < TRI_HALF and TRI_LO < h < TRI_HI
        if in_arc and h > 0.4:
            base = A.lerp_rgb(BLACK, A.RAMP["stone"][0], 0.10 * near)   # into the dark aisle
        elif in_clr:
            mull = abs(((dp / (CLR_HALF * 0.42)) % 1.0) - 0.5)
            base = A.lerp_rgb(BLACK, A.RAMP["stone"][3], 0.34 + 0.26 * near)
            if mull > 0.40:
                base = A.over(base, A.RAMP["stone"][1], 0.60)           # mullions
        elif in_tri:
            base = A.lerp_rgb(BLACK, A.RAMP["stone"][0], 0.24)
        else:
            # Pier face quantised into colonnettes, each shaded as a half-round: a flat wall
            # becomes a BUNDLE OF SHAFTS, which is the whole Gothic read.
            sp = (dp / 0.95) % 1.0
            base = A.over(base, A.RAMP["stone"][2], 0.20 * math.sin(sp * math.pi))
            if sp < 0.07 or sp > 0.93:
                base = A.over(base, BLACK, 0.26)                         # seam between shafts
            if abs(h - ARC_SPRING) < 0.55 or abs(h - TRI_HI) < 0.35 or abs(h - CLR_SPRING) < 0.40:
                base = A.over(base, A.RAMP["stone"][3], 0.42)            # capitals, string-course
            base = A.over(base, A.RAMP["stone"][0], 0.05 * (A.noise(x, y // 3, 7) + 8) / 16.0)

    # ── Light: fire is the key, the apse opens the distance. ──
    glow = _apseglow(fx, fy)
    base = A.over(base, A.lerp_rgb(A.RAMP["stone"][3], A.RAMP["parchment"][2], 0.40),
                  min(0.66, glow * 0.66))
    fire = _firelight(fx, fy)
    if fire > 0.0:
        warm = A.RAMP["flame"][1] if fire > 0.55 else A.RAMP["gold"][2]
        base = A.over(base, warm, min(0.58, fire * 0.44))

    v_ = max(abs(fx - 0.5) / 0.5, abs(fy - 0.5) / 0.5)
    base = A.lerp_rgb(base, BLACK, 0.55 * A.smooth(0.62, 1.10, v_))
    r, g, b_ = A.quantize(_dither(base, x, y))
    return (r, g, b_, 255)


if __name__ == "__main__":
    os.makedirs(os.path.join(os.path.dirname(os.path.abspath(__file__)), "title"), exist_ok=True)
    A.assert_on_palette(W, H, nave_px, "title/nave.png")
    # A LITERAL relative path, run from client/assets/ui/ (canon S5b): tools/asset_map.py derives
    # producer edges from this string, so an os.path.join here silently drops nave.png's producer.
    A.write_png("title/nave.png", W, H, nave_px)
    print("gen_nave OK — the empty nave, %dx%d, existing ramps only." % (W, H))
