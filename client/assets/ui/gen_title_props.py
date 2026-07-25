#!/usr/bin/env python3
"""gen_title_props.py — the title hall's furniture: censer, chandelier, candle rack, brazier.

    title/censer.png       140x420   hanging brass censer; the chain runs to the TOP EDGE
    title/chandelier.png   420x300   an iron corona, hung on three chains
    title/candle_rack.png  520x300   a votive rack of tapers at differing heights
    title/brazier.png      300x280   a standing iron brazier, cold

**Why these are Python and not Aseprite.** TD-057 assigns sprites to Aseprite, and it is right —
but that finding was measured at **17x22 px**, where a shape function cannot decide which pixel
carries the crossguard. These props are 140-520px objects in the **painted environment register**
(R242), drawn with a LINEAR filter, exactly like the banners: at that size the job is form —
cylinders, spheres, drip and tarnish — which is Python's half of the split. A hand-placed pixel
would be resampled away.

**Nothing here burns.** The manifest excludes flames on purpose (rule 6): every fire in this scene
is an in-engine additive pool that flickers out of step (TD-043), and a baked hotspot would fight
it. So the candles are wax with cold wicks and the brazier is full of dead coals.

Everything is built as anti-aliased signed-distance parts composited back to front, because a
hard-edged alpha would crawl the moment the rig scales it.

Run from client/assets/ui/:  python3 gen_title_props.py
"""
import math

import ashember as A

# ── Materials. Aged, desaturated, and DIM.
# The first pass authored these at the value a lit object has, and the engine's warm pools then
# added on top and washed the candles to near-white. An unlit asset in a torch-lit hall must be
# dark enough that the FIRE is what brightens it — the same correction the banners needed, and
# what TD-059 spent a spec establishing for the board.
BRASS_DK = (40, 30, 15)
BRASS_MID = (78, 60, 30)
BRASS_HI = (112, 90, 48)
IRON_DK = (15, 14, 15)
IRON_MID = (34, 32, 33)
IRON_HI = (56, 54, 52)
WAX_DK = (78, 72, 58)
WAX_MID = (120, 113, 94)
WAX_HI = (150, 143, 122)
WICK = (28, 24, 20)
RUBY = (78, 20, 18)

LX, LY = -0.55, -0.78          # a soft key from the upper left; form, not a highlight


def _h(x, y, s=0):
    n = (x * 374761393 + y * 668265263 + s * 2654435761) & 0xFFFFFFFF
    n = (n ^ (n >> 13)) * 1274126177 & 0xFFFFFFFF
    return ((n >> 8) % 1000) / 1000.0


# ── Signed distance primitives (negative inside) ─────────────────────────────

def sd_circle(px, py, cx, cy, r):
    return math.hypot(px - cx, py - cy) - r


def sd_ellipse(px, py, cx, cy, rx, ry):
    # Cheap and good enough at these radii: the exact ellipse distance is not worth the cost.
    k = math.hypot((px - cx) / rx, (py - cy) / ry)
    return (k - 1.0) * min(rx, ry)


def sd_box(px, py, cx, cy, hw, hh):
    dx, dy = abs(px - cx) - hw, abs(py - cy) - hh
    return math.hypot(max(dx, 0.0), max(dy, 0.0)) + min(max(dx, dy), 0.0)


def sd_seg(px, py, x0, y0, x1, y1, r):
    """A thick line segment — chains, legs, prickets, anything rod-shaped."""
    vx, vy = x1 - x0, y1 - y0
    wx, wy = px - x0, py - y0
    t = 0.0 if (vx * vx + vy * vy) == 0 else max(0.0, min(1.0, (wx * vx + wy * vy) / (vx * vx + vy * vy)))
    return math.hypot(wx - vx * t, wy - vy * t) - r


# ── Shading helpers ──────────────────────────────────────────────────────────

def round_shade(dark, mid, lit, nx, ny, grime=0.0):
    """Form shading for a rounded body from a fake normal. Low contrast on purpose (rule 6)."""
    d = max(0.0, nx * LX + ny * LY)
    t = 0.30 + 0.70 * d ** 0.8
    c = A.lerp_rgb(dark, lit, t) if t > 0.5 else A.lerp_rgb(dark, mid, t * 2.0)
    return A.lerp_rgb(c, IRON_DK, grime)


def cyl_shade(dark, mid, lit, across, grime=0.0):
    """Form shading across a cylinder: `across` is -1..1 from one silhouette edge to the other."""
    d = math.sqrt(max(0.0, 1.0 - across * across))
    t = 0.26 + 0.74 * (d * 0.72 + max(0.0, -across) * 0.34)
    return A.lerp_rgb(A.lerp_rgb(dark, mid, min(1.0, t * 1.7)), lit, max(0.0, t - 0.62) * 2.2)


# ── The zenith, so a prop can stand in the plate's perspective ───────────────
# The plate's camera is pitched UP 15 degrees, which is three-point perspective: every vertical in
# the hall converges on a zenith ABOVE the frame. Solving the projection for the world up-vector
# (0,1,0) puts that point at fx 0.5, fy -2.046 — roughly two frame heights over the top edge.
#
# So a prop standing left of centre must LEAN RIGHT as it rises, by an amount that depends on where
# it stands. Drawn plumb, it reads as pasted onto the picture rather than standing in it. The lean
# is a shear, not a rotation: the foot stays on the floor where it was placed and only the height
# tilts, which is what perspective actually does to a standing object.
ZENITH_Y = -2.046
FRAME_AR = 16.0 / 9.0


def lean_for(fx, base_fy):
    """Shear in px-per-px for a prop whose foot sits at (fx, base_fy) in viewport fractions."""
    return (0.5 - fx) / (base_fy - ZENITH_Y) * FRAME_AR


class Canvas:
    """Back-to-front compositor. Each part is (sdf, shade); shade(x, y, d) -> rgb.

    Geometry is authored in OBJECT space (0..w, 0..h). If the object leans, the image is padded
    on both sides by enough to hold the shear, so the object's foot stays at the image's centre
    line and nothing clips off the edge — the caller widens its viewport fraction to match.
    """

    def __init__(self, w, h, lean=0.0):
        self.w, self.h, self.parts = w, h, []
        self.lean = lean
        self.pad = int(math.ceil(abs(lean) * h))
        self.img_w = w + 2 * self.pad

    def add(self, sdf, shade):
        self.parts.append((sdf, shade))

    def px(self, x, y):
        py_ = y + 0.5
        px_ = x + 0.5 - self.pad - self.lean * (self.h - py_)
        r = g = b = 0.0
        a = 0.0
        for sdf, shade in self.parts:
            d = sdf(px_, py_)
            if d > 0.75:
                continue
            cov = max(0.0, min(1.0, 0.5 - d))      # ~1px anti-aliased edge
            if cov <= 0.0:
                continue
            c = shade(px_, py_, d)
            r = c[0] * cov + r * (1.0 - cov)
            g = c[1] * cov + g * (1.0 - cov)
            b = c[2] * cov + b * (1.0 - cov)
            a = cov + a * (1.0 - cov)
        if a <= 0.003:
            return (0, 0, 0, 0)
        return (A.clamp(r), A.clamp(g), A.clamp(b), A.clamp(a * 255.0))


# ── The censer: a pierced brass vessel on a long chain ───────────────────────

def censer(w=140, h=420):
    c = Canvas(w, h)
    cx = w * 0.5
    bowl_y, bowl_r = h * 0.70, w * 0.30
    link = w * 0.055

    def chain_shade(x, y, d):
        # Alternating links, read as a value pulse down the run rather than drawn one by one.
        ph = 0.5 + 0.5 * math.sin(y / (link * 1.9) * math.pi)
        return A.lerp_rgb(BRASS_DK, BRASS_MID, 0.25 + 0.55 * ph)

    # The chain must reach the very top edge so the censer hangs from off-screen (manifest rule).
    c.add(lambda x, y: sd_seg(x, y, cx, -4, cx, h * 0.30, link), chain_shade)
    # A suspension ring, then three chains splaying to the vessel's rim.
    c.add(lambda x, y: abs(sd_circle(x, y, cx, h * 0.315, w * 0.085)) - link * 0.75,
          lambda x, y, d: round_shade(BRASS_DK, BRASS_MID, BRASS_HI,
                                      (x - cx) / (w * 0.09), (y - h * 0.315) / (w * 0.09)))
    for sx in (-1.0, 0.0, 1.0):
        c.add(lambda x, y, sx=sx: sd_seg(x, y, cx, h * 0.345,
                                         cx + sx * bowl_r * 0.86, bowl_y - bowl_r * 0.42,
                                         link * 0.62), chain_shade)

    def bowl_shade(x, y, d):
        nx, ny = (x - cx) / bowl_r, (y - bowl_y) / bowl_r
        base = round_shade(BRASS_DK, BRASS_MID, BRASS_HI, nx, ny,
                           grime=0.30 + 0.22 * _h(int(x) // 3, int(y) // 3, 5))
        # Pierced metalwork: a grid of holes that follows the sphere, plus ruby glass in a few.
        u = math.atan2(y - bowl_y, x - bowl_x_off(x, cx)) if False else (x - cx) / bowl_r
        v = (y - bowl_y) / bowl_r
        gu = abs(((u * 3.4) % 1.0) - 0.5)
        gv = abs(((v * 3.0) % 1.0) - 0.5)
        if gu < 0.16 and gv < 0.16 and (u * u + v * v) < 0.74:
            if _h(int(u * 6), int(v * 6), 9) > 0.72:
                return A.lerp_rgb(RUBY, BRASS_DK, 0.30)      # a ruby panel behind the piercing
            return A.lerp_rgb(base, IRON_DK, 0.72)           # a hole into the dark interior
        return base

    # The vessel: a sphere, its domed lid, and the seam where they meet.
    c.add(lambda x, y: sd_circle(x, y, cx, bowl_y, bowl_r), bowl_shade)
    c.add(lambda x, y: max(sd_ellipse(x, y, cx, bowl_y - bowl_r * 0.30, bowl_r * 1.06,
                                      bowl_r * 0.16), 0.0) - 0.0,
          lambda x, y, d: A.lerp_rgb(BRASS_DK, BRASS_MID, 0.34))
    c.add(lambda x, y: sd_seg(x, y, cx, bowl_y - bowl_r * 1.22, cx, bowl_y - bowl_r * 0.96,
                              link * 0.8),
          lambda x, y, d: A.lerp_rgb(BRASS_MID, BRASS_HI, 0.35))    # the lid's finial
    c.add(lambda x, y: sd_circle(x, y, cx, bowl_y - bowl_r * 1.30, link * 1.15),
          lambda x, y, d: round_shade(BRASS_DK, BRASS_MID, BRASS_HI,
                                      (x - cx) / link, (y - (bowl_y - bowl_r * 1.30)) / link))
    # A small foot, so the vessel does not float.
    c.add(lambda x, y: sd_ellipse(x, y, cx, bowl_y + bowl_r * 0.96, bowl_r * 0.30, bowl_r * 0.16),
          lambda x, y, d: A.lerp_rgb(BRASS_DK, BRASS_MID, 0.28))
    return c


def bowl_x_off(x, cx):        # kept for readability of the piercing maths above
    return cx


# ── The chandelier: an iron corona hung on three chains ──────────────────────

def chandelier(w=420, h=300):
    c = Canvas(w, h)
    cx, cy = w * 0.5, h * 0.66
    rx, ry = w * 0.42, h * 0.17            # a ring seen from below: a wide, shallow ellipse
    bar = w * 0.016

    for sx in (-0.72, 0.0, 0.72):
        c.add(lambda x, y, sx=sx: sd_seg(x, y, cx, -4, cx + sx * rx, cy - ry * 0.55, bar * 0.7),
              lambda x, y, d: A.lerp_rgb(IRON_DK, IRON_MID, 0.45))

    def ring_shade(x, y, d):
        across = max(-1.0, min(1.0, d / (bar * 1.9) + 0.55))
        base = cyl_shade(IRON_DK, IRON_MID, IRON_HI, across)
        return A.lerp_rgb(base, IRON_DK, 0.18 * _h(int(x) // 2, int(y) // 2, 3))

    # The ring itself, plus a second, thinner ring below it — a corona, not a hoop.
    c.add(lambda x, y: abs(sd_ellipse(x, y, cx, cy, rx, ry)) - bar * 1.5, ring_shade)
    c.add(lambda x, y: abs(sd_ellipse(x, y, cx, cy + h * 0.055, rx * 0.97, ry * 0.97)) - bar * 0.7,
          lambda x, y, d: A.lerp_rgb(IRON_DK, IRON_MID, 0.30))

    # Prickets around the rim, each holding an unlit taper of its own height.
    for i in range(12):
        th = i / 12.0 * math.tau
        px_ = cx + math.cos(th) * rx
        py_ = cy + math.sin(th) * ry
        tall = h * (0.14 + 0.09 * _h(i, 0, 7))
        front = math.sin(th) > -0.15          # candles on the far side sit behind the ring
        cw = w * 0.011
        c.add(lambda x, y, px_=px_, py_=py_: sd_ellipse(x, y, px_, py_ - h * 0.012,
                                                        cw * 2.4, h * 0.016),
              lambda x, y, d: A.lerp_rgb(IRON_DK, IRON_MID, 0.35))       # the drip pan
        c.add(lambda x, y, px_=px_, py_=py_, tall=tall: sd_box(x, y, px_, py_ - h * 0.02 - tall * 0.5,
                                                               cw, tall * 0.5),
              lambda x, y, d, px_=px_: cyl_shade(WAX_DK, WAX_MID, WAX_HI,
                                                 max(-1.0, min(1.0, (x - px_) / cw))))
        if front:
            c.add(lambda x, y, px_=px_, py_=py_, tall=tall:
                  sd_seg(x, y, px_, py_ - h * 0.02 - tall, px_, py_ - h * 0.02 - tall - h * 0.012,
                         cw * 0.30),
                  lambda x, y, d: WICK)
    return c


# ── The candle rack: an aged iron stand of votive tapers ─────────────────────

def candle_rack(w=520, h=300, seed=0, lean=0.0):
    c = Canvas(w, h, lean)
    tray_y = h * (0.70 + 0.02 * _h(seed, 1, 41))
    leg = w * 0.014
    splay = 0.055 + 0.020 * _h(seed, 2, 43)

    # Frame: two splayed legs, a foot bar, and the tray the tapers stand in.
    for sx in (-1, 1):
        c.add(lambda x, y, sx=sx: sd_seg(x, y, w * (0.5 + sx * 0.36), tray_y,
                                         w * (0.5 + sx * (0.36 + splay)), h * 0.97, leg),
              lambda x, y, d: A.lerp_rgb(IRON_DK, IRON_MID, 0.40))
    c.add(lambda x, y: sd_box(x, y, w * 0.5, h * 0.93, w * 0.40, leg * 0.8),
          lambda x, y, d: A.lerp_rgb(IRON_DK, IRON_MID, 0.32))
    c.add(lambda x, y: sd_box(x, y, w * 0.5, tray_y, w * 0.40, h * 0.028),
          lambda x, y, d: cyl_shade(IRON_DK, IRON_MID, IRON_HI,
                                    max(-1.0, min(1.0, (y - tray_y) / (h * 0.028)))))

    # Two ranks of tapers at wildly differing heights — the irregularity IS the prop, and the
    # counts come off the seed so two racks in one hall are never the same rack twice.
    n0 = 11 + int(4 * _h(seed, 3, 47))
    ranks = ((0.0, 1.0, n0), (-h * 0.05, 0.86, n0 - 1 - int(2 * _h(seed, 4, 53))))
    for rank, (yoff, scale, count) in enumerate(ranks):
        for i in range(count):
            fx = (i + 0.5) / count
            px_ = w * (0.11 + 0.78 * fx) + (rank * w * 0.028)
            tall = h * (0.16 + 0.30 * _h(i, rank, 11 + seed)) * scale
            cw = w * 0.0105 * scale
            base_y = tray_y + yoff - h * 0.012
            c.add(lambda x, y, px_=px_, base_y=base_y, tall=tall, cw=cw:
                  sd_box(x, y, px_, base_y - tall * 0.5, cw, tall * 0.5),
                  lambda x, y, d, px_=px_, cw=cw, base_y=base_y, tall=tall:
                  A.lerp_rgb(cyl_shade(WAX_DK, WAX_MID, WAX_HI,
                                       max(-1.0, min(1.0, (x - px_) / cw))),
                             WAX_DK, 0.30 * max(0.0, 1.0 - (base_y - y) / max(tall, 1e-3))))
            c.add(lambda x, y, px_=px_, base_y=base_y, tall=tall, cw=cw:
                  sd_seg(x, y, px_, base_y - tall, px_, base_y - tall - h * 0.018, cw * 0.30),
                  lambda x, y, d: WICK)

    # Heavy wax runs down the tray and the frame: what actually says "this rack is old".
    def run_shade(x, y, d):
        return A.lerp_rgb(WAX_MID, WAX_DK, 0.35 + 0.30 * _h(int(x) // 4, 0, 13 + seed))

    # They CLING to the tray's lower edge and stop: wax that hangs free in long strands reads as
    # a stalactite, not as decades of drip on an iron lip.
    lip = tray_y + h * 0.028
    for i in range(9 + int(5 * _h(seed, 5, 59))):
        rx_ = w * (0.13 + 0.74 * _h(i, 1, 17 + seed))
        drop = h * (0.018 + 0.055 * _h(i, 2, 19 + seed))
        rw = w * (0.006 + 0.006 * _h(i, 3, 23 + seed))
        c.add(lambda x, y, rx_=rx_, drop=drop, rw=rw:
              min(sd_box(x, y, rx_, lip - h * 0.012 + drop * 0.5, rw, drop * 0.5 + h * 0.012),
                  sd_circle(x, y, rx_, lip + drop, rw * 0.95)), run_shade)
    return c


# ── The brazier: a standing iron bowl of dead coals ──────────────────────────

def brazier(w=300, h=280, seed=0, lean=0.0):
    c = Canvas(w, h, lean)
    cx = w * 0.5
    # The bowl is not turned to the same angle twice, and no two were beaten to the same depth.
    rim_y = h * (0.32 + 0.04 * _h(seed, 1, 61))
    rim_rx = w * (0.375 + 0.045 * _h(seed, 2, 67))
    rim_ry = h * (0.092 + 0.018 * _h(seed, 3, 71))
    leg = w * 0.030
    spin = math.tau * _h(seed, 4, 73) / 3.0        # which way the three legs happen to stand

    for th in (spin + math.tau * 0.08, spin + math.tau * 0.40, spin + math.tau * 0.72):
        px_ = cx + math.cos(th) * rim_rx * 0.72
        c.add(lambda x, y, px_=px_: sd_seg(x, y, px_, rim_y + h * 0.10,
                                           cx + (px_ - cx) * 1.5, h * 0.95, leg),
              lambda x, y, d: cyl_shade(IRON_DK, IRON_MID, IRON_HI,
                                        max(-1.0, min(1.0, d / leg + 0.5))))
    # The bowl: an ellipse rim over a shallow body, riveted.
    def body_shade(x, y, d):
        across = max(-1.0, min(1.0, (x - cx) / (rim_rx * 0.98)))
        base = cyl_shade(IRON_DK, IRON_MID, IRON_HI, across)
        base = A.lerp_rgb(base, IRON_DK, 0.28 * max(0.0, (y - rim_y) / (h * 0.30)))
        # Rivets around the girth, and soot from every fire that ever burned here.
        ang = abs((((x - cx) / (rim_rx * 0.5)) % 1.0) - 0.5)
        if ang < 0.06 and abs(y - (rim_y + h * 0.075)) < h * 0.012:
            base = A.lerp_rgb(base, IRON_HI, 0.30)
        return A.lerp_rgb(base, (10, 9, 9), 0.20 * _h(int(x) // 3, int(y) // 3, 3))

    c.add(lambda x, y: max(sd_ellipse(x, y, cx, rim_y, rim_rx, rim_ry * 3.4),
                           -(y - rim_y)), body_shade)
    c.add(lambda x, y: abs(sd_ellipse(x, y, cx, rim_y, rim_rx, rim_ry)) - w * 0.022,
          lambda x, y, d: cyl_shade(IRON_DK, IRON_MID, IRON_HI,
                                    max(-1.0, min(1.0, d / (w * 0.022)))))

    def coal_shade(x, y, d):
        # Dead coals: broken, ashed over, NOT glowing. The fire is the engine's job.
        n = _h(int(x) // 5, int(y) // 4, 7 + seed)
        ash = _h(int(x) // 9, int(y) // 7, 11 + seed)
        c0 = A.lerp_rgb((16, 13, 12), (44, 38, 34), n)
        return A.lerp_rgb(c0, (78, 72, 66), 0.30 * ash)

    c.add(lambda x, y: sd_ellipse(x, y, cx, rim_y - h * 0.012, rim_rx * 0.86, rim_ry * 0.80),
          coal_shade)
    return c


# Where each floor prop STANDS: (x, centre-y, the object's own width as a viewport fraction).
# Deliberately not mirrored — the right-hand pair stands a little further down the nave, so it is
# smaller and sits higher in the frame. A hall whose two sides match exactly reads as a diagram.
STANDING = {
    "candle_rack":   (0.128, 0.770, 0.150),
    "candle_rack_b": (0.876, 0.762, 0.142),
    "brazier":       (0.318, 0.840, 0.070),
    "brazier_b":     (0.688, 0.831, 0.066),
}


def place(name, obj_w, obj_h):
    """(lean, the rig's width fraction) for a prop standing at STANDING[name].

    The width fraction is the OBJECT's, widened for the shear padding, so the object renders at
    the size asked for however far it leans.
    """
    fx, cy, wf = STANDING[name]
    base_fy = cy + wf * FRAME_AR * (obj_h / obj_w) * 0.5
    lean = lean_for(fx, base_fy)
    img_w = obj_w + 2 * int(math.ceil(abs(lean) * obj_h))
    return lean, wf * img_w / obj_w


def main():
    # LITERAL relative paths, run from client/assets/ui/ (canon S5b): tools/asset_map.py derives
    # producer edges from these strings.
    cen = censer()
    A.write_png("title/censer.png", cen.img_w, cen.h, cen.px)
    cha = chandelier()
    A.write_png("title/chandelier.png", cha.img_w, cha.h, cha.px)

    rl, wl = place("candle_rack", 520, 300)
    rack = candle_rack(seed=1, lean=rl)
    A.write_png("title/candle_rack.png", rack.img_w, rack.h, rack.px)

    rr, wr = place("candle_rack_b", 520, 300)
    rack_b = candle_rack(seed=2, lean=rr)
    A.write_png("title/candle_rack_b.png", rack_b.img_w, rack_b.h, rack_b.px)

    bl, wbl = place("brazier", 300, 280)
    bra = brazier(seed=3, lean=bl)
    A.write_png("title/brazier.png", bra.img_w, bra.h, bra.px)

    br, wbr = place("brazier_b", 300, 280)
    bra_b = brazier(seed=4, lean=br)
    A.write_png("title/brazier_b.png", bra_b.img_w, bra_b.h, bra_b.px)

    print("gen_title_props OK — censer, chandelier, two racks, two braziers (unlit, alpha).")
    print("  VESSELS lines for title_scene.gd (width includes the shear padding):")
    for name, cv, wfrac in (("candle_rack", rack, wl), ("candle_rack_b", rack_b, wr),
                            ("brazier", bra, wbl), ("brazier_b", bra_b, wbr)):
        fx, cy, _ = STANDING[name]
        print('    ["%s.png", Vector3(%.4f, %.4f, %.4f), %.3f],  # lean %+.3f, %dx%d'
              % (name, fx, cy, wfrac, cv.h / cv.img_w, cv.lean, cv.img_w, cv.h))


if __name__ == "__main__":
    main()
