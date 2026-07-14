#!/usr/bin/env python3
"""gen_logo.py — the Collegium emblem (blade-and-laurel), authored to the author's reference:
a point-DOWN SWORD (pommel + grip + crossguard crowning the top, blade dropping to a point)
set within a LAUREL wreath and a faint broken ring, in aged gilded bronze on transparent
ground. NO shield (not in the reference). A single reusable logo — the board crest crowns
with it and the banner carries it. Run FROM client/assets/ui. Imports ashember + gen_heraldry's
bronze relief helpers. Stdlib only. Brand-new PNGs need `godot --headless --import`.
"""
import math
import ashember as A
import gen_heraldry as GH

SS = 4
LX, LY = GH.LX, GH.LY
metal = GH.metal
_cl = GH._cl

# ── Design space (portrait, matches the reference's ~0.82 aspect) ────────────────
W, H = 122, 150
CX = 61.0
OW, OH = 92, 113                        # output size (baked AA, shown 1:1 NEAREST)


def _bez(p0, p1, p2, u):
    """Quadratic bezier point + unit tangent at u."""
    mu = 1.0 - u
    x = mu * mu * p0[0] + 2 * mu * u * p1[0] + u * u * p2[0]
    y = mu * mu * p0[1] + 2 * mu * u * p1[1] + u * u * p2[1]
    tx = 2 * mu * (p1[0] - p0[0]) + 2 * u * (p2[0] - p1[0])
    ty = 2 * mu * (p1[1] - p0[1]) + 2 * u * (p2[1] - p1[1])
    tl = math.hypot(tx, ty) or 1.0
    return x, y, tx / tl, ty / tl


# Laurel branch control points per side (s=±1): base near the pommel, bulge OUT, curl IN at top.
def _branch(s):
    return ((CX, 128.0), (CX + s * 54.0, 96.0), (CX + s * 20.0, 34.0))


# Precompute leaves along each branch (position, angle, size), plus stem samples.
def _laurel():
    leaves, stem = [], []
    for s in (-1, 1):
        p0, p1, p2 = _branch(s)
        for k in range(120):
            x, y, tx, ty = _bez(p0, p1, p2, k / 119.0)
            stem.append((x, y))
        n = 8
        for k in range(n):
            u = 0.06 + 0.88 * (k / float(n - 1))
            x, y, tx, ty = _bez(p0, p1, p2, u)
            # outward normal (away from centre) so leaves sit on the branch's OUTER edge and
            # splay up-and-out from it — the classic laurel fan, not slivers along the stem.
            nx, ny = -ty, tx
            if nx * s < 0:
                nx, ny = -nx, -ny
            x += nx * 2.2
            y += ny * 2.2
            ang = math.atan2(ty, tx) + s * math.radians(46.0)   # long axis splayed off the branch
            size = 11.5 - 5.2 * (k / float(n - 1))
            leaves.append((x, y, ang, size, s))
    return leaves, stem


LEAVES, STEM = _laurel()


def _leaf(fx, fy):
    best = None
    for (lx, ly, la, size, s) in LEAVES:
        ca, sa = math.cos(-la), math.sin(-la)
        ox, oy = fx - lx, fy - ly
        rxp = ox * ca - oy * sa
        ryp = ox * sa + oy * ca
        e = (rxp / size) ** 2 + (ryp / (size * 0.46)) ** 2
        if e < 1.0:
            lit = _cl(0.44 + (-rxp * 0.4 - ryp * 0.2) / size * 0.5 + s * 0.05)
            cand = (_cl((1.0 - e) * 2.0), metal(lit, rim=_cl((1.0 - e) * 1.4) * 0.25))
            if best is None or cand[0] > best[0]:
                best = cand
    return best


def _stem(fx, fy):
    dmin = 99.0
    for (sx, sy) in STEM:
        d = math.hypot(fx - sx, fy - sy)
        if d < dmin:
            dmin = d
    if dmin < 1.6:
        return (_cl((1.6 - dmin) / 1.2), metal(0.5, rim=_cl(1.0 - dmin) * 0.25))
    return None


def _sword(fx, fy):
    # POINT-DOWN (reference): pommel + grip + crossguard crown the top, the blade drops to a point.
    ax = abs(fx - CX)
    out = []
    # pommel disc at the top
    pd = math.hypot(fx - CX, fy - 26.0)
    if pd < 5.8:
        lit = _cl(0.4 + (-(fx - CX) * LX - (fy - 26.0) * LY) / 5.8 * 0.6)
        out.append((_cl((5.8 - pd) * 1.5), metal(lit, rim=_cl(0.9 - pd / 5.8) * 0.5)))
    # grip
    if 29.0 <= fy <= 45.0 and ax < 3.3:
        out.append((1.0, metal(_cl(0.3 + (3.3 - ax) / 3.3 * 0.3) * 0.8)))
    # crossguard: a near-straight wide bar at y≈48, far tips easing UP a hair
    gy = 48.0 - 0.0032 * (fx - CX) ** 2
    if abs(fy - gy) < 3.4 and ax < 27.0:
        taper = 1.0 if ax < 22.0 else _cl((27.0 - ax) / 5.0)   # rounded tips
        lit = _cl(0.42 + (48.0 - fy) * 0.13 + (CX - fx) * 0.004)
        out.append((_cl((3.4 - abs(fy - gy)) * 1.4) * taper, metal(lit, rim=_cl((48.0 - fy)) * 0.4)))
    # blade: guard y=51 → tip y=138, tapering DOWN to a point, bright centre ridge
    if 51.0 <= fy <= 138.0:
        bhw = 7.4 - (fy - 51.0) / 87.0 * 5.9
        if ax < bhw:
            ridge = 1.0 - ax / bhw
            lit = _cl(0.36 + ridge * 0.52 + (CX - fx) / max(bhw, 1.0) * 0.12)
            out.append((1.0, metal(lit, rim=_cl(ridge - 0.6))))
    return out


def _ring(fx, fy):
    """A faint broken ring behind the emblem — the reference's circular arcs (no shield)."""
    dx, dy = fx - CX, fy - 84.0
    RR, BAND = 44.0, 1.9
    rr = math.hypot(dx, dy)
    dband = abs(rr - RR)
    top_gap = (fy < 84.0) and (abs(dx) < 8.0)     # open at top where the hilt crosses
    if dband < BAND and not top_gap:
        lit = _cl(0.42 + (-dx * LX - dy * LY) / RR * 0.5)
        return (_cl((BAND - dband) / 1.3) * 0.85, metal(lit * 0.8, rim=_cl((BAND - dband) - 0.6) * 0.3))
    return None


def logo_px(fx, fy):
    layers = []
    rg = _ring(fx, fy)
    if rg:
        layers.append(rg)
    st = _stem(fx, fy)
    if st:
        layers.append(st)
    lf = _leaf(fx, fy)
    if lf:
        layers.append(lf)
    layers += _sword(fx, fy)
    if not layers:
        return (0, 0, 0, 0)
    r = g = b = a = 0.0
    for al, col in layers:
        r = r * (1 - al) + col[0] * al
        g = g * (1 - al) + col[1] * al
        b = b * (1 - al) + col[2] * al
        a = a + al * (1 - a)
    return (A.clamp(r), A.clamp(g), A.clamp(b), A.clamp(a * 255))


def _supersample(w, h, sample):
    grid = {}
    for Y in range(h * SS):
        for X in range(w * SS):
            grid[(X, Y)] = sample((X + 0.5) / SS, (Y + 0.5) / SS)

    def pixel(x, y):
        r = g = b = a = 0
        for j in range(SS):
            for i in range(SS):
                pr, pg, pb, pa = grid[(x * SS + i, y * SS + j)]
                r += pr * pa; g += pg * pa; b += pb * pa; a += pa
        n = SS * SS
        if a == 0:
            return (0, 0, 0, 0)
        return (r // a, g // a, b // a, a // n)
    return pixel


def _out():
    sx, sy = W / float(OW), H / float(OH)
    return _supersample(OW, OH, lambda ox, oy: logo_px(ox * sx, oy * sy))


def _ascii(w, h, pixel):
    chars = " .:-=+*#%@"
    rows = []
    for y in range(0, h, 2):
        row = ""
        for x in range(w):
            _, _, _, a = pixel(x, y)
            row += chars[min(9, a * 10 // 256)] if a > 0 else " "
        rows.append(row)
    return "\n".join(rows)


def main(ascii_only=False):
    px = _out()
    if ascii_only:
        print(_ascii(OW, OH, px))
        return
    A.write_png("collegium_logo.png", OW, OH, px)
    print("wrote collegium_logo.png (%dx%d)" % (OW, OH))


if __name__ == "__main__":
    import sys
    main(ascii_only=("--ascii" in sys.argv))
