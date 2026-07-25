#!/usr/bin/env python3
"""hall_geometry.py — the Collegium's Great Hall as SHAPE. No colour lives here (TD-076).

The title hall read flat because it *was* flat: the previous model cast rays at a horizontal plane
for the vault and vertical planes for the walls, then painted ribs and colonnettes onto them. A
plane has one normal everywhere, so nothing could ever turn away from the light.

This module replaces that with the surfaces the architecture actually has:

  * a **groin vault** — the intersection of a transverse barrel across the nave and a longitudinal
    barrel along each bay. The lower of the two IS the ceiling, and where they meet is the groin,
    which is exactly where a diagonal rib belongs. The rib stops being a drawn line and becomes a
    place the geometry already has.
  * **piers as vertical cylinders**, engaged in the wall. A shaft's lit side, its turn and its
    shadow all fall out of `n·L`.
  * **aisles behind the arcade**, so an arch opens into a space instead of onto black. That void was
    most of why the hall read shallow.

Everything is analytic — quadratics, not marching. A ray-march at this resolution would be millions
of evaluations for an identical answer.

`trace(fx, fy) -> Hit(kind, p, n, dist, u, v)` and nothing else. Keeping colour out is what lets the
geometry carry its own tests: `python3 hall_geometry.py --selftest`.
"""
import math
import sys
from collections import namedtuple

Hit = namedtuple("Hit", "kind p n dist u v")

# ── The camera ───────────────────────────────────────────────────────────────
# The zenith measured off Reference A (verticals converge at fy −2.916, symmetry-checked) fixes the
# relation cot(P) = 6.832·TAN_V. That leaves one degree of freedom, closed here by choosing a
# NARROWER lens than the old 105°: a long lens reads monumental, where an ultra-wide one fisheyes
# the near piers and makes the hall feel like a corridor.
ASPECT = 16.0 / 9.0
HFOV = math.radians(76.0)
TAN_H = math.tan(HFOV * 0.5)
TAN_V = TAN_H / ASPECT
PITCH = math.atan(1.0 / (6.832 * TAN_V))        # ≈18.4° — from the measured zenith, not by eye
SINP, COSP = math.sin(PITCH), math.cos(PITCH)
EYE_Y = 1.6

# ── The hall, in metres ──────────────────────────────────────────────────────
HALF_W = 9.0           # nave 18m across; height/width ≈ 1.6 with the vault at 29m
BAY = 6.0
Z_FAR = 52.0
SPRING = 20.0          # the vault springs from here
CROWN = SPRING + HALF_W
ARC_SPRING, ARC_HALF = 7.6, 2.55    # the arcade openings into the aisles
TRI_LO, TRI_HI = 12.4, 14.6         # triforium band
CLR_LO, CLR_HI, CLR_HALF = 16.0, 19.4, 1.85   # the glazed storey
PIER_R = 0.62
AISLE_W = 5.5
AISLE_CEIL = 9.4
NBAYS = int(Z_FAR / BAY) + 1
EPS = 1e-6


def ray(fx, fy):
    """Unit direction for a pixel, through the pitched camera."""
    sx = (fx - 0.5) * 2.0 * TAN_H
    sy = (0.5 - fy) * 2.0 * TAN_V
    dx, dy, dz = sx, sy * COSP + SINP, -sy * SINP + COSP
    m = math.sqrt(dx * dx + dy * dy + dz * dz)
    return dx / m, dy / m, dz / m


def _quad(a, b, c):
    """Real roots of a quadratic, ascending. Empty when it does not cross."""
    if abs(a) < EPS:
        return () if abs(b) < EPS else (-c / b,)
    disc = b * b - 4 * a * c
    if disc < 0:
        return ()
    s = math.sqrt(disc)
    return sorted(((-b - s) / (2 * a), (-b + s) / (2 * a)))


def arch_top(dp, half, spring):
    """Height of a two-centred arch at |dp| from the opening's centre."""
    k = 0.55
    r = half * (1.0 + k)
    dxs = dp + half * k
    return spring + math.sqrt(max(0.0, r * r - dxs * dxs))


def in_arcade(z, y):
    """Is this point on the nave wall inside an arcade opening (i.e. see-through)?"""
    if y <= 0.35 or z < 0.0:
        return False
    dp = abs((z / BAY) % 1.0 - 0.5) * BAY
    return dp < ARC_HALF and y < arch_top(dp, ARC_HALF, ARC_SPRING)


# ── The vault ────────────────────────────────────────────────────────────────

def _h_trans(x):
    return SPRING + math.sqrt(max(0.0, HALF_W * HALF_W - x * x))


def _h_long(z, zc):
    """The longitudinal barrel is STILTED into an ellipse, and that is not a liberty — it is the
    fix the problem demands. A semicircular barrel rises by its half-span, so over a 13m nave the
    transverse crowns at 6.5m while a 6m bay's longitudinal reaches only 3m: one barrel swallows
    the other and no groin ever forms. Gothic solved this with the pointed arch; the author chose
    semicircular, so the Romanesque answer applies instead — stilt the short barrel until both
    crown together. Semi-axes (BAY/2, HALF_W)."""
    r = BAY * 0.5
    k = 1.0 - ((z - zc) / r) ** 2
    return SPRING + HALF_W * math.sqrt(max(0.0, k))


def _vault(ox, oy, oz, dx, dy, dz):
    """Nearest hit on the groin vault, or None. The surface is the LOWER of the two barrels, so a
    candidate is accepted only when the other barrel is higher there — which is what makes the
    groins fall out of the geometry instead of being drawn on."""
    best = None
    yo = oy - SPRING

    # transverse barrel: x² + (y−SPRING)² = HALF_W²
    for t in _quad(dx * dx + dy * dy,
                   2.0 * (ox * dx + yo * dy),
                   ox * ox + yo * yo - HALF_W * HALF_W):
        if t <= EPS or (best and t >= best[0]):
            continue
        x, y, z = ox + dx * t, oy + dy * t, oz + dz * t
        if y < SPRING or z < 0 or z > Z_FAR or abs(x) > HALF_W:
            continue
        zc = (int(z / BAY) + 0.5) * BAY
        if _h_trans(x) <= _h_long(z, zc) + 0.02:
            m = math.sqrt(x * x + (y - SPRING) ** 2) or 1.0
            best = (t, "vault", (-x / m, -(y - SPRING) / m, 0.0), x, z)

    # longitudinal barrels, one per bay — ellipses with semi-axes (r, HALF_W):
    #   ((z−zc)/r)² + ((y−SPRING)/HALF_W)² = 1
    r = BAY * 0.5
    R2, r2 = HALF_W * HALF_W, r * r
    for bi in range(NBAYS):
        zc = (bi + 0.5) * BAY
        zo = oz - zc
        for t in _quad(R2 * dz * dz + r2 * dy * dy,
                       2.0 * (R2 * zo * dz + r2 * yo * dy),
                       R2 * zo * zo + r2 * yo * yo - r2 * R2):
            if t <= EPS or (best and t >= best[0]):
                continue
            x, y, z = ox + dx * t, oy + dy * t, oz + dz * t
            if y < SPRING or abs(x) > HALF_W or abs(z - zc) > r or z > Z_FAR:
                continue
            if _h_long(z, zc) <= _h_trans(x) + 0.02:
                # gradient of the ellipse, not of a circle
                gy, gz = (y - SPRING) / R2, (z - zc) / r2
                m = math.sqrt(gy * gy + gz * gz) or 1.0
                best = (t, "vault", (0.0, -gy / m, -gz / m), x, z)
    return best


# ── Piers ────────────────────────────────────────────────────────────────────

def _piers(ox, oy, oz, dx, dy, dz):
    """Nearest hit on a pier cylinder. Engaged in the wall at every bay boundary, both sides."""
    best = None
    for side in (-1, 1):
        xc = side * HALF_W
        for bi in range(1, NBAYS + 1):     # never one at z=0, on top of the camera
            zc = bi * BAY
            x0, z0 = ox - xc, oz - zc
            for t in _quad(dx * dx + dz * dz,
                           2.0 * (x0 * dx + z0 * dz),
                           x0 * x0 + z0 * z0 - PIER_R * PIER_R):
                if t <= EPS or (best and t >= best[0]):
                    continue
                x, y, z = ox + dx * t, oy + dy * t, oz + dz * t
                if y < 0.0 or y > SPRING + 1.2 or z < -1.0 or z > Z_FAR:
                    continue
                if abs(x) > HALF_W + PIER_R:        # only the half standing proud into the nave
                    continue
                m = math.sqrt((x - xc) ** 2 + (z - zc) ** 2) or 1.0
                best = (t, "pier", ((x - xc) / m, 0.0, (z - zc) / m), y, z)
    return best


# ── Everything else: planes ──────────────────────────────────────────────────

def _plane_hits(ox, oy, oz, dx, dy, dz):
    out = []
    if dy < -EPS:                                    # floor
        t = -oy / dy
        if t > EPS:
            x, z = ox + dx * t, oz + dz * t
            if 0.0 <= z <= Z_FAR and abs(x) <= HALF_W + AISLE_W:
                out.append((t, "floor", (0.0, 1.0, 0.0), x, z))
    if dz > EPS:                                     # the apse closes the nave
        t = Z_FAR / dz
        if t > EPS:
            x, y = ox + dx * t, oy + dy * t
            if abs(x) <= HALF_W + AISLE_W and 0.0 <= y <= CROWN:
                out.append((t, "apse", (0.0, 0.0, -1.0), x, y))
    for side in (-1, 1):                             # nave wall, unless the arcade opens there
        if dx * side > EPS:
            t = (side * HALF_W - ox) / dx
            if t > EPS:
                y, z = oy + dy * t, oz + dz * t
                if 0.0 <= y <= CROWN and 0.0 <= z <= Z_FAR and not in_arcade(z, y):
                    out.append((t, "wall", (-side, 0.0, 0.0), z, y))
        if dx * side > EPS:                          # aisle outer wall, seen through the arcade
            t = (side * (HALF_W + AISLE_W) - ox) / dx
            if t > EPS:
                y, z = oy + dy * t, oz + dz * t
                if 0.0 <= y <= AISLE_CEIL and 0.0 <= z <= Z_FAR:
                    out.append((t, "aisle_wall", (-side, 0.0, 0.0), z, y))
    if dy > EPS:                                     # aisle ceiling
        t = (AISLE_CEIL - oy) / dy
        if t > EPS:
            x, z = ox + dx * t, oz + dz * t
            if HALF_W < abs(x) <= HALF_W + AISLE_W and 0.0 <= z <= Z_FAR:
                out.append((t, "aisle_ceil", (0.0, -1.0, 0.0), x, z))
    return out


def trace(fx, fy):
    """The nearest surface a pixel's ray strikes."""
    dx, dy, dz = ray(fx, fy)
    ox, oy, oz = 0.0, EYE_Y, 0.0
    best = None
    for cand in _plane_hits(ox, oy, oz, dx, dy, dz):
        if best is None or cand[0] < best[0]:
            best = cand
    for f in (_vault, _piers):
        cand = f(ox, oy, oz, dx, dy, dz)
        if cand and (best is None or cand[0] < best[0]):
            best = cand
    if best is None:
        return Hit("void", (0.0, 0.0, Z_FAR), (0.0, 0.0, -1.0), Z_FAR, 0.0, 0.0)
    t, kind, n, u, v = best
    return Hit(kind, (ox + dx * t, oy + dy * t, oz + dz * t), n, t, u, v)


# ── The named tests (P129: curvature is geometric) ───────────────────────────

def selftest():
    """P129: curvature must be GEOMETRIC. A plane hands back one normal; a curved shell cannot."""
    W, H = 640, 360
    trans, longi, nxs, pier_nx, kinds = 0, 0, [], [], set()
    for y in range(0, H, 3):
        for x in range(0, W, 3):
            h = trace((x + 0.5) / W, (y + 0.5) / H)
            kinds.add(h.kind)
            if h.kind == "vault":
                if abs(h.n[0]) > 1e-9:
                    trans += 1
                    nxs.append(h.n[0])
                else:
                    longi += 1
            elif h.kind == "pier":
                pier_nx.append(h.n[0])

    # 1. The vault carries BOTH barrel families — that is what a groin vault is.
    assert trans > 100 and longi > 100, \
        "only one barrel family is ever the lower surface (transverse %d, longitudinal %d) — " \
        "the two barrels do not crown together and no groin forms" % (trans, longi)
    # 2. Its normal SWINGS. A flat ceiling gives one constant normal, so this is the whole test.
    assert min(nxs) < -0.5 and max(nxs) > 0.5, \
        "vault normal does not swing (%.3f..%.3f) — the ceiling is flat" % (min(nxs), max(nxs))
    # 3. Piers are ROUND: the normal sweeps through the full turn, not a stripe's constant.
    assert pier_nx and max(pier_nx) - min(pier_nx) > 1.0, \
        "pier normal barely varies (%.3f) — it is a stripe, not a cylinder" \
        % ((max(pier_nx) - min(pier_nx)) if pier_nx else 0.0)
    # 4. The arcade opens into a space rather than onto black.
    assert "aisle_wall" in kinds or "aisle_ceil" in kinds, \
        "the arcade never opens into the aisle"
    print("selftest: OK")
    print("  vault: %d transverse + %d longitudinal, normal swings %.2f..%.2f"
          % (trans, longi, min(nxs), max(nxs)))
    print("  piers: normal sweeps %.2f" % (max(pier_nx) - min(pier_nx)))
    print("  kinds visible: %s" % ", ".join(sorted(kinds)))
    return 0


if __name__ == "__main__":
    sys.exit(selftest() if "--selftest" in sys.argv[1:] else selftest())
