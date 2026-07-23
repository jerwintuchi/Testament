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
BRAZIERS = [(side * (HALF_W - 1.35), 0.85, z)
            for z in (7.0, 10.5, 15.0, 21.0, 30.0, 43.0, 62.0) for side in (-1, 1)]
# Sconces on the piers at triforium height: the light that actually reaches the upper wall.
SCONCES = [(side * (HALF_W - 0.35), 14.0, z)
           for z in (13.5, 20.5, 30.5, 45.5) for side in (-1, 1)]
BZ = [(pr[0], pr[1], pr[2]) for pr in
      (project(bx, by, bz) for bx, by, bz in BRAZIERS) if pr is not None]
FIRE_Z = sorted(set([bz for _, _, bz in BRAZIERS] + [sz for _, _, sz in SCONCES]))
SC = [(pr[0], pr[1], pr[2]) for pr in
      (project(sx_, sy_, sz_) for sx_, sy_, sz_ in SCONCES) if pr is not None]


def _firelight(fx, fy):
    """Summed warm falloff from every brazier — the image's key light."""
    tot = 0.0
    for bx, by, inv in BZ:
        rx_ = 2.2 * inv / (2.0 * TAN_H)                  # a rack of candles, ~2m of light
        ry_ = 2.0 * inv / (2.0 * TAN_V)
        dxs = (fx - bx) / max(rx_, 1e-5)
        dys = (fy - by) / max(ry_, 1e-5)
        d2 = dxs * dxs + dys * dys
        if d2 < 1.0:
            tot += min(0.85, inv * 6.0) * (1.0 - d2) ** 2
    for sx_, sy_, inv in SC:
        rx_ = 3.4 * inv / (2.0 * TAN_H)
        ry_ = 4.2 * inv / (2.0 * TAN_V)                  # sconce light spills UP the wall
        dxs = (fx - sx_) / max(rx_, 1e-5)
        dys = (fy - sy_) / max(ry_, 1e-5)
        d2 = dxs * dxs + dys * dys
        if d2 < 1.0:
            tot += min(0.95, inv * 8.0) * (1.0 - d2) ** 2
    return min(1.6, tot)


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
        base = A.ramp_shade("navestone", 0.14)
        light = abs(b) < 5.4 and 7.0 < a < lancet(abs(b) % 1.8, 0.9, 22.0)
        if light:
            mull = abs((abs(b) / 1.8) % 1.0 - 0.5)
            base = A.lerp_rgb(A.RAMP["stone"][3], A.RAMP["parchment"][3], 0.55)
            if mull > 0.40:
                base = A.over(base, A.RAMP["stone"][0], 0.75)     # the stone between lights
    elif kind == "floor":
        base = A.ramp_shade("navestone", 0.07 + 0.12 * near)
        worn = max(0.0, 1.0 - abs(b) / 3.0)              # the processional path, rubbed smooth
        jw = 0.455 + 0.022 * worn                        # its joints have worn shallow
        if abs(((a / 1.9) % 1.0) - 0.5) > jw or abs(((b / 1.9) % 1.0) - 0.5) > jw:
            base = A.over(base, BLACK, 0.55 - 0.22 * worn)   # flag joints
        else:
            base = A.over(base, A.RAMP["navestone"][4], 0.13 * worn)
        # The runner: deep red cloth down the centre of the nave, worn pale along its spine.
        if abs(b) < 2.15:
            edge = A.smooth(2.15, 1.75, abs(b))
            base = A.lerp_rgb(A.RAMP["wax"][0], A.RAMP["wax"][1], 0.16 * edge)
            base = A.over(base, BLACK, 0.40 - 0.12 * edge)
            if abs(abs(b) - 1.85) < 0.13:
                base = A.over(base, A.RAMP["gold"][0], 0.40)     # a dulled gold border
        # Ledger slabs: a few flags near the aisles are incised memorials, sunk darker.
        if abs(b) > 3.4 and (A.noise(int(a / 1.9), int(b / 1.9), 33) + 8) > 13:
            base = A.over(base, A.RAMP["navestone"][1], 0.30)
        else:
            base = A.over(base, A.RAMP["navestone"][1], 0.07 * (A.noise(x // 2, y // 2, 11) + 8) / 16.0)
    elif kind == "vault":
        # Ribbed quadripartite bays: diagonals crossing at a boss, transverse ribs, sunk webs.
        cross = b / HALF_W
        loc = (a / BAY) % 1.0
        base = A.ramp_shade("navestone", 0.05 + 0.10 * near)
        base = A.over(base, BLACK, 0.34)
        rw = 0.085
        diag = abs(abs(cross) - abs(2.0 * loc - 1.0))
        if diag < rw or min(loc, 1.0 - loc) < rw * 0.45:
            base = A.over(base, A.RAMP["navestone"][4], 0.30)
            if diag < rw * 0.5 and abs(loc - 0.5) < 0.10:
                base = A.over(base, A.RAMP["navestone"][5], 0.28)     # the boss
        elif abs(cross) < rw * 0.4:
            base = A.over(base, A.RAMP["navestone"][3], 0.24)         # ridge rib
        else:
            # The webs are laid courses too, running with the vault's curve.
            if abs(((a / 1.15) % 1.0) - 0.5) > 0.44:
                base = A.over(base, A.RAMP["navestone"][0], 0.26)
            # Centuries of smoke have gathered along the crown.
            base = A.over(base, BLACK, 0.26 * max(0.0, 1.0 - abs(cross) / 0.55))
    else:
        # ── Side wall: compound piers, three storeys of pointed openings ──
        h = b                                            # metres up the wall
        loc = (a / BAY) % 1.0
        dp = abs(loc - 0.5) * BAY                        # metres from the bay's centre
        base = A.ramp_shade("navestone", 0.10 + 0.20 * near)
        in_arc = dp < ARC_HALF and ARC_SPRING is not None and h < lancet(dp, ARC_HALF, ARC_SPRING)
        in_clr = dp < CLR_HALF and CLR_SPRING < h < lancet(dp, CLR_HALF, CLR_SPRING)
        in_tri = dp < TRI_HALF and TRI_LO < h < TRI_HI
        if in_arc and h > 0.4:
            base = A.lerp_rgb(BLACK, A.RAMP["navestone"][1], 0.16 * near)   # into the dark aisle
        elif in_clr:
            mull = abs(((dp / (CLR_HALF * 0.42)) % 1.0) - 0.5)
            base = A.lerp_rgb(BLACK, A.RAMP["stone"][3], 0.34 + 0.26 * near)
            if mull > 0.40:
                base = A.over(base, A.RAMP["stone"][1], 0.60)           # mullions
        elif in_tri:
            base = A.lerp_rgb(BLACK, A.RAMP["navestone"][1], 0.30)
        else:
            # Pier face quantised into colonnettes, each shaded as a half-round: a flat wall
            # becomes a BUNDLE OF SHAFTS, which is the whole Gothic read.
            sp = (dp / 0.95) % 1.0
            base = A.over(base, A.RAMP["navestone"][4], 0.26 * math.sin(sp * math.pi))
            if sp < 0.07 or sp > 0.93:
                base = A.over(base, BLACK, 0.26)                         # seam between shafts
            if abs(h - ARC_SPRING) < 0.55 or abs(h - TRI_HI) < 0.35 or abs(h - CLR_SPRING) < 0.40:
                base = A.over(base, A.RAMP["navestone"][5], 0.44)            # capitals, string-course
            base = A.over(base, A.RAMP["navestone"][1], 0.07 * (A.noise(x, y // 3, 7) + 8) / 16.0)
            # Coursed ashlar: 0.85m beds with staggered perpends, so the wall reads as laid
            # blocks rather than poured surface — the single biggest "built by hand" cue.
            course = h / 0.85
            bed = abs((course % 1.0) - 0.5)
            perp = abs(((a / 1.7 + 0.5 * (int(course) % 2)) % 1.0) - 0.5)
            if bed > 0.455 or perp > 0.478:
                base = A.over(base, A.RAMP["navestone"][0], 0.34 * min(1.0, near * 1.6))
            # Weathering: pale salts have run down from the sills over centuries.
            if CLR_SPRING - 5.0 < h < CLR_SPRING and (A.noise(int(a * 3.0), 0, 21) + 8) > 11:
                base = A.over(base, A.RAMP["navestone"][5],
                              0.16 * (1.0 - (CLR_SPRING - h) / 5.0))
            # The Collegium's standards hang between the bays. Oxblood, worn, the same cloth
            # the Contract Board flies — this hall is a bastion that is still garrisoned.
            if a < 15.0 and ARC_HALF + 0.10 < dp < ARC_HALF + 1.20 and 3.4 < h < 12.4:
                fold = abs((((dp - ARC_HALF) / 0.34) % 1.0) - 0.5)
                base = A.lerp_rgb(A.RAMP["wax"][0], A.RAMP["wax"][1], 0.10 + 0.30 * fold)
                base = A.over(base, BLACK, 0.34)              # centuries have dulled the dye
                if h > 11.9:
                    base = A.RAMP["navestone"][2]                    # the rod it hangs from
                elif 6.6 < h < 8.8 and abs(dp - (ARC_HALF + 0.65)) < 0.34:
                    base = A.over(base, A.RAMP["parchment"][0], 0.42)  # a pale device on the cloth
                base = A.over(base, BLACK, 0.30 * (1.0 - min(1.0, near * 1.3)))

    if kind == "wall":
        # Soot plumes above the fires — the wall remembers every flame that ever stood here.
        for fz in FIRE_Z:
            dz_ = abs(a - fz)
            if dz_ < 3.4 and h > 1.0:
                plume = (1.0 - dz_ / 3.4) * math.exp(-(h - 1.0) / 7.0)
                base = A.over(base, BLACK, 0.42 * plume)

    # ── Light: fire is the key, the apse opens the distance. ──
    glow = _apseglow(fx, fy)
    base = A.over(base, A.lerp_rgb(A.RAMP["stone"][3], A.RAMP["parchment"][2], 0.40),
                  min(0.66, glow * 0.66))
    fire = _firelight(fx, fy)
    if fire > 0.0:
        warm = A.RAMP["flame"][1] if fire > 0.55 else A.RAMP["gold"][2]
        base = A.over(base, warm, min(0.74, fire * 0.60))

    for bx, by, inv in BZ:
        cw = min(0.0032, 0.16 * inv / (2.0 * TAN_H))     # one taper, capped at ~2px
        ch = min(0.024, 0.42 * inv / (2.0 * TAN_V))      # …and ~8px tall
        rank = min(0.030, 0.9 * inv / (2.0 * TAN_H))     # spread across the rack
        if abs(fx - bx) < rank and -ch * 2.2 < (by - fy) < ch * 0.4:
            k = int((fx - bx + rank) / max(cw * 2.6, 1e-6))
            hgt = ch * (1.0 + 0.55 * ((A.noise(k, 0, 5) + 8) / 16.0))
            off = cw * 2.6 * k - rank + cw * 1.3
            if abs(fx - bx - off) < cw and -hgt < (by - fy) < 0.0:
                # pale wax below, a bright tip above
                base = A.FLAME_PALE if (by - fy) < -hgt * 0.72 else A.RAMP["parchment"][2]

    v_ = max(abs(fx - 0.5) / 0.5, abs(fy - 0.5) / 0.5)
    base = A.lerp_rgb(base, BLACK, 0.70 * A.smooth(0.46, 1.06, v_))
    r, g, b_ = A.quantize(_dither(base, x, y))
    return (r, g, b_, 255)


if __name__ == "__main__":
    os.makedirs(os.path.join(os.path.dirname(os.path.abspath(__file__)), "title"), exist_ok=True)
    A.assert_on_palette(W, H, nave_px, "title/nave.png")
    # A LITERAL relative path, run from client/assets/ui/ (canon S5b): tools/asset_map.py derives
    # producer edges from this string, so an os.path.join here silently drops nave.png's producer.
    A.write_png("title/nave.png", W, H, nave_px)
    print("gen_nave OK — the empty nave, %dx%d, existing ramps only." % (W, H))
