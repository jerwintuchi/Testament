#!/usr/bin/env python3
"""gen_heraldry.py — the Contract Board's heraldic header (TD-049 / board-heraldry).

Emits two hand-painted raster PNGs (canonical register, TD-046), run FROM this dir
(relative filenames):

  crest_v1.png       150x132  ornate gilded-bronze emblem: an upright SWORD set against a
                              broken RING, flanked by a LAUREL wreath, crowned with FILIGREE
                              scrolls. Origin-neutral (the Collegium's blade-and-laurel).
  board_nameplate.png 112x48  a carved plank sign, 9-slice-safe, with IRON CORNER BRACKETS +
                              bolts, a beveled plank field, and a recessed title panel.

Layered back-to-front, each component a coverage mask shaded as relief by an upper-left key
(LX,LY) on the bronze/gold ramp — so it reads as metalwork, not flat fill. Supersampled AA.
Stdlib only (imports ashember). Brand-new PNGs need `godot --headless --import`.
"""
import math
import ashember as A

SS = 4
LX, LY = -0.60, -0.66          # upper-left key (points toward the light)

# Gilded-bronze metal ramp — DIM (dungeon-dark, TD-048): the emblem catches the eye by
# ornament + gilt EDGES, not by being a bright gold blob. Body reads as dim bronze; only
# light-facing lips take the bright rim.
G_DEEP = (28, 21, 10)
G_BASE = (76, 57, 28)
G_HI   = (150, 120, 70)
G_RIM  = (208, 172, 110)       # bright light-facing lip (edges only)
# Iron for the nameplate corner fittings — near-black warm, like the sconce (dungeon-dark).
IRON_D = (14, 13, 11)
IRON_B = (30, 27, 22)
IRON_H = (78, 68, 52)          # dim lit iron edge (NOT a light grey frame)


def _cl(v, a=0.0, b=1.0):
    return max(a, min(b, v))


def metal(lit, rim=0.0):
    """Bronze value at brightness `lit` (0..1), pushed toward the bright rim by `rim`."""
    c = A.lerp_rgb(G_DEEP, G_HI, _cl(lit))
    c = A.lerp_rgb(c, G_BASE, 0.26)
    if rim > 0.0:
        c = A.lerp_rgb(c, G_RIM, _cl(rim))
    return c


def _seg(px, py, ax, ay, bx, by):
    """Distance from (px,py) to segment a-b, plus param t along it."""
    vx, vy = bx - ax, by - ay
    L2 = vx * vx + vy * vy
    t = 0.0 if L2 == 0 else _cl(((px - ax) * vx + (py - ay) * vy) / L2)
    ex, ey = ax + t * vx, ay + t * vy
    return math.hypot(px - ex, py - ey), t


# ── Crest geometry (150x132) ───────────────────────────────────────────────────
CW, CH = 150, 132                  # DESIGN space (all crest geometry is defined here)
# Output/display size (TD-050): the crest is rendered DOWN to ~display resolution with baked AA,
# then shown 1:1 NEAREST in-engine — no LINEAR downscale mush, and smaller so it stops crowding
# the top notice row. Sword/laurel strokes are thickened in design space to survive the shrink.
CREST_OW, CREST_OH = 80, 70
CX = 75.0
RING_CY, RING_R, RING_BAND = 60.0, 30.0, 3.6

# Laurel leaves: precompute per-side positions along an arc just outside the ring.
def _laurel_leaves():
    leaves = []
    for s in (-1, 1):
        # A wreath hugging the ring's LOWER flanks: the branch sweeps from the base (near the
        # pommel) up the outer side to about shoulder height. Leaves are big + overlapping,
        # tilted tangent-to-the-branch (they lie along it, fanning up — not radiating as spikes).
        for k in range(5):
            u = k / 4.0
            ang = math.radians(-108.0 + 96.0 * u)          # -108°(low base) → -12°(upper side)
            rad = RING_R + 4.5
            lx = CX + s * math.cos(ang) * rad
            ly = RING_CY - math.sin(ang) * rad
            leaf_ang = ang + math.radians(90.0)             # long axis TANGENT to the branch
            size = 9.5 - 3.2 * u                            # BIGGER, fewer leaves so they read small
            leaves.append((lx, ly, leaf_ang, size, s))
    return leaves


LAUREL = _laurel_leaves()


def _crest_layers(fx, fy):
    """Return a back-to-front list of (alpha, rgb) for the pixel."""
    out = []
    dx, dy = fx - CX, fy - RING_CY

    # 1) FILIGREE scrolls (top) — two C-curls crowning the ring, dim bronze behind.
    for s in (-1, 1):
        ccx, ccy, cr = CX + s * 15.0, 20.0, 8.5
        d = abs(math.hypot(fx - ccx, fy - ccy) - cr)
        ang = math.atan2(fy - ccy, fx - ccx)               # keep ~3/4 of the ring (open inner)
        open_ok = not (-0.5 < ang < 0.9 if s > 0 else 2.2 < abs(ang))
        if d < 2.6 and open_ok:
            lit = _cl(0.5 + (-(fx - ccx) * LX - (fy - ccy) * LY) / cr * 0.4)
            out.append((_cl((2.6 - d) / 1.4), metal(lit * 0.85, rim=_cl((1.3 - d)) * 0.3)))

    # 2) RING — bronze annulus behind the sword, broken at the very top (blade passes through).
    rr = math.hypot(dx, dy)
    dband = abs(rr - RING_R)
    top_gap = (fy < RING_CY) and (abs(dx) < 6.0)           # gap where the blade crosses
    if dband < RING_BAND and not top_gap:
        nlit = _cl(0.45 + (-(dx) * LX - (dy) * LY) / RING_R * 0.55)   # outer up-left bright
        rimf = _cl((RING_BAND - dband) / RING_BAND) * (0.5 if nlit > 0.6 else 0.0)
        out.append((_cl((RING_BAND - dband) / 1.3), metal(nlit, rim=rimf)))

    # 3) LAUREL wreath — leaves along each side arc.
    for (lx, ly, la, size, s) in LAUREL:
        # rotate into the leaf's frame; an ellipse (long axis along the branch)
        ca, sa = math.cos(-la), math.sin(-la)
        ox, oy = fx - lx, fy - ly
        rxp = ox * ca - oy * sa
        ryp = ox * sa + oy * ca
        e = (rxp / size) ** 2 + (ryp / (size * 0.42)) ** 2
        if e < 1.0:
            lit = _cl(0.44 + (-rxp * 0.4 - ryp * 0.2) / size * 0.5 + s * 0.06)
            rimf = _cl((1.0 - e) * 1.4) * 0.25
            out.append((_cl((1.0 - e) * 2.0), metal(lit, rim=rimf)))

    # 4) SWORD (front, upright, centred) — blade / crossguard / grip / pommel.
    ax = abs(fx - CX)
    # blade: tip y=16 → guard y=64, BOLDER half-width (1.8→7.0) so it survives the shrink + a
    # clear bright centre ridge so the sword reads as the hero inside the ring.
    if 16.0 <= fy <= 64.0:
        bhw = 1.8 + (fy - 16.0) / 48.0 * 5.2
        if ax < bhw:
            ridge = 1.0 - ax / bhw                          # centre ridge highlight
            lit = _cl(0.36 + ridge * 0.52 + (CX - fx) / max(bhw, 1.0) * 0.12)
            rimf = _cl(ridge - 0.6) * 1.0
            out.append((1.0, metal(lit, rim=rimf)))
    # crossguard: a wider bar at y≈66 with tips curving slightly down
    gy = 66.0 + 0.010 * (fx - CX) ** 2
    if abs(fy - gy) < 3.6 and ax < 26.0:
        lit = _cl(0.42 + (66.0 - fy) * 0.13 + (CX - fx) * 0.004)
        out.append((_cl((3.6 - abs(fy - gy)) * 1.4), metal(lit, rim=_cl((66.0 - fy)) * 0.4)))
    # grip (thicker)
    if 69.0 <= fy <= 84.0 and ax < 3.2:
        lit = _cl(0.3 + (3.2 - ax) / 3.2 * 0.3)
        out.append((1.0, metal(lit * 0.8)))
    # pommel: domed disc
    pd = math.hypot(fx - CX, fy - 88.0)
    if pd < 5.2:
        lit = _cl(0.4 + (-(fx - CX) * LX - (fy - 88.0) * LY) / 5.2 * 0.6)
        out.append((_cl((5.2 - pd) * 1.5), metal(lit, rim=_cl(0.9 - pd / 5.2) * 0.5)))

    # 5) central BOSS — a small domed rivet where guard meets ring.
    bd = math.hypot(dx, dy + 6.0)
    if bd < 6.0:
        lit = _cl(0.45 + (-dx * LX - (dy + 6.0) * LY) / 6.0 * 0.6)
        out.append((_cl((6.0 - bd) * 1.4), metal(lit, rim=_cl(0.85 - bd / 6.0) * 0.5)))

    return out


def crest_px(fx, fy):
    layers = _crest_layers(fx, fy)
    if not layers:
        return (0, 0, 0, 0)
    r = g = b = 0.0
    a = 0.0
    for al, col in layers:                                 # back-to-front over-composite
        r = r * (1 - al) + col[0] * al
        g = g * (1 - al) + col[1] * al
        b = b * (1 - al) + col[2] * al
        a = a + al * (1 - a)
    return (A.clamp(r), A.clamp(g), A.clamp(b), A.clamp(a * 255))


# ── Carved nameplate (112x48, 9-slice with iron corner brackets) ────────────────
NW, NH = 112, 36                   # TD-050: shorter plate for a single-line title (was 48, two lines)
NMX, NMY_T, NMY_B = 22, 15, 11     # 9-slice patch margins (keep the corner plates un-stretched)


def _wood(fx, fy):
    base = A.ramp_shade("wood", 0.45)
    grain = math.sin(fy * 1.7) * 0.5 + A.noise(int(fx), int(fy), 3) * 0.4
    return (base[0] + grain, base[1] + grain * 0.7, base[2] + grain * 0.5)


def nameplate_px(fx, fy):
    left, top = fx, fy
    right, bot = NW - 1 - fx, NH - 1 - fy
    d = min(left, top, right, bot)
    # ── iron corner FITTINGS: a small dark plate hugging each corner with a brass bolt ──
    cl = min(left, right)
    ct = min(top, bot)
    if cl < 13 and ct < 13:
        edge = min(cl, ct)
        lit = 0.26 + (12.0 - max(cl, ct)) / 12.0 * 0.10        # subtle plate face gradient
        if edge <= 1:                                          # outer plate rim catches the key
            lit += 0.34
        if cl >= 11 or ct >= 11:                               # inner edge (toward the wood) shades down
            lit -= 0.14
        body = A.lerp_rgb(IRON_D, IRON_H, _cl(lit))
        bd = math.hypot(cl - 6.5, ct - 6.5)                    # domed brass bolt near the plate centre
        if bd < 3.0:
            blit = _cl(0.35 + (3.0 - bd) / 3.0 * 0.6)
            body = A.lerp_rgb(A.lerp_rgb(IRON_B, IRON_H, blit), G_BASE, 0.30)
            if (cl - 6.5) > 0.8 and (ct - 6.5) > 0.8:          # bolt lower-right shadow
                body = A.lerp_rgb(body, IRON_D, 0.4)
        return (A.clamp(body[0]), A.clamp(body[1]), A.clamp(body[2]), 255)
    # ── bevel border: lit top chamfer, dark bottom ──
    if d == 0:
        return A.clamp_rgb(A.RAMP["wood"][0]) + (255,)
    if d <= 2:
        lit = (top <= left and top <= right)                    # top edge catches the key
        tone = "wood"
        v = 0.62 if lit else 0.22
        c = A.ramp_shade(tone, v)
        return A.clamp_rgb(c) + (255,)
    # ── recessed title panel: an inset field (darker) with a thin lit upper lip ──
    inset = (NMX - 4 < fx < NW - NMX + 4) and (12 < fy < NH - 8)
    c = _wood(fx, fy)
    if inset:
        if fy < 15:                                             # upper lip catches a little light
            c = A.lerp_rgb(c, A.RAMP["wood"][4], 0.3)
        else:
            c = A.lerp_rgb(c, A.RAMP["wood"][0], 0.42)          # recessed → darker for gilt contrast
    return A.clamp_rgb(c) + (255,)


# ── Supersample → averaged downsample ───────────────────────────────────────────
def _supersample(W, H, sample):
    grid = {}
    for Y in range(H * SS):
        for X in range(W * SS):
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


def _ascii(W, H, pixel):
    chars = " .:-=+*#%@"
    rows = []
    for y in range(0, H, 2):
        row = ""
        for x in range(0, W, 1):
            _, _, _, a = pixel(x, y)
            row += chars[min(9, a * 10 // 256)] if a > 0 else " "
        rows.append(row)
    return "\n".join(rows)


# Render the crest at OUTPUT resolution, sampling the 150×132 DESIGN space — so the emblem is
# authored small with baked AA (crisp when shown 1:1 NEAREST), not downscaled by the engine.
def _crest_out():
    sx, sy = CW / float(CREST_OW), CH / float(CREST_OH)
    return _supersample(CREST_OW, CREST_OH, lambda ox, oy: crest_px(ox * sx, oy * sy))


def main(ascii_only=False):
    crest = _crest_out()
    plate = _supersample(NW, NH, nameplate_px)
    if ascii_only:
        print("=== crest_v1 ===\n" + _ascii(CREST_OW, CREST_OH, crest))
        print("\n=== board_nameplate ===\n" + _ascii(NW, NH, plate))
        return
    A.write_png("crest_v1.png", CREST_OW, CREST_OH, crest)
    print("wrote crest_v1.png (%dx%d)" % (CREST_OW, CREST_OH))
    A.write_png("board_nameplate.png", NW, NH, plate)
    print("wrote board_nameplate.png (%dx%d)" % (NW, NH))


if __name__ == "__main__":
    import sys
    main(ascii_only=("--ascii" in sys.argv))
