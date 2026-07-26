#!/usr/bin/env python3
"""gen_title_furniture.py — the hall's cloth and furniture, at the HALL'S OWN GRAIN (TD-076).

    title/banner_left.png  banner_right.png  banner_center.png
    title/censer.png  chandelier.png
    title/candle_rack.png  candle_rack_b.png  brazier.png  brazier_b.png

**Re-authored at twice the pixel count, at the same display size.** The hall is now a 1280x720 plate
that lands one art pixel per device pixel at 720p; these props were authored for the 640 grain, so
each of their pixels covered a 2x2 block and they read as chunkier than the hall they stood in.

That is fixed by drawing MORE, not by scaling up. A NEAREST upscale would preserve the 2x2 blocks
exactly — the mismatch is a detail-density problem, not a size one. So every piece here is redrawn
with detail that only exists at the finer grain: chain links with gaps, tapers with a lit and a
shaded side, a rim on the censer's bowl, wax runs of varying width, iron with a highlight edge.

The rig's viewport fractions are UNCHANGED and need no edit: display size is `fraction x 640`
logical, and one art pixel per device pixel means `art_width = 1280 x fraction`. Doubling the art
while holding the fraction is exactly what puts them on the hall's grain.

Every pixel is an Ash & Ember ramp entry — `A.assert_on_palette` passes on all nine.
Nothing burns: cold wicks, dead coals. The fire is in-engine (TD-043).

Run from client/assets/ui/:  python3 gen_title_furniture.py
"""
import os

import ashember as A
import pngio

EMB_SRC = "board/collegium_logo.png"

IRON_D, IRON_M, IRON_L = A.RAMP["navestone"][0], A.RAMP["navestone"][2], A.RAMP["navestone"][4]
IRON_XL = A.RAMP["navestone"][5]
BRASS_D, BRASS_M, BRASS_L = A.RAMP["gold"][0], A.RAMP["gold"][1], A.RAMP["gold"][2]
BRASS_XL = A.RAMP["gold"][3]
WAX_D, WAX_M, WAX_L = A.RAMP["parchment"][0], A.RAMP["parchment"][2], A.RAMP["parchment"][3]
WAX_XL = A.RAMP["parchment"][4]
CLOTH_XD, CLOTH_D, CLOTH_M, CLOTH_L = (A.RAMP["black"][1], A.RAMP["black"][2],
                                       A.RAMP["wax"][0], A.RAMP["wax"][1])
BONE_D, BONE_M, BONE_L = A.RAMP["parchment"][1], A.RAMP["parchment"][2], A.RAMP["parchment"][4]
COAL_D, COAL_M, COAL_L = A.RAMP["black"][1], A.RAMP["navestone"][1], A.RAMP["navestone"][3]
NONE = (0, 0, 0, 0)


def h(x, y, s=0):
    n = (x * 374761393 + y * 668265263 + s * 2654435761) & 0xFFFFFFFF
    n = (n ^ (n >> 13)) * 1274126177 & 0xFFFFFFFF
    return ((n >> 8) % 1000) / 1000.0


# The hall's zenith, MEASURED off the base itself (tools/measure_reference.py: verticals converge
# at fy -6.768, and that fit passed its own symmetry check — the nave VP landed at fx 0.500 exactly).
# Every vertical in the picture leans toward it, so a prop drawn plumb reads as pasted onto the
# image rather than standing in it. This lean existed once (TD-073 T264) and was lost when the props
# were re-authored as pixel art; restoring it is the point of this pass.
ZENITH_FY = -6.768
FRAME_AR = 16.0 / 9.0


def lean_for(fx, foot_fy):
    """Shear in px-per-px for a prop whose foot sits at (fx, foot_fy) in viewport fractions."""
    return (0.5 - fx) / (foot_fy - ZENITH_FY) * FRAME_AR


class Grid:
    """A pixel canvas. Set pixels; there is no blending, ever.

    A `lean` shears the readout: the foot stays where it was placed and only the height tilts,
    which is what perspective does to a standing object. The offset is rounded to a WHOLE pixel per
    row, so the edge stair-steps — which is how pixel art draws a near-vertical line anyway, and
    keeps every pixel hard.
    """

    def __init__(self, w, hh, lean=0.0):
        self.w, self.h = w, hh
        self.lean = lean
        self.pad = int(abs(lean) * hh + 0.999)
        self.img_w = w + 2 * self.pad
        self.px = [[NONE] * w for _ in range(hh)]

    def set(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y][x] = (c[0], c[1], c[2], 255)

    def vline(self, x, y0, y1, c):
        for y in range(min(y0, y1), max(y0, y1) + 1):
            self.set(x, y, c)

    def hline(self, y, x0, x1, c):
        for x in range(min(x0, x1), max(x0, x1) + 1):
            self.set(x, y, c)

    def rect(self, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            self.hline(y, x0, x1, c)

    def ellipse(self, cx, cy, rx, ry, c, fill=True, thick=1.0):
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                d = ((x - cx) / max(rx, .5)) ** 2 + ((y - cy) / max(ry, .5)) ** 2
                if d <= 1.0 and (fill or d > 1.0 - 0.42 * thick):
                    self.set(x, y, c)

    def reader(self):
        if not self.lean:
            return lambda x, y: self.px[y][x]

        def read(x, y):
            ox = x - self.pad - int(round(self.lean * (self.h - 1 - y)))
            return self.px[y][ox] if 0 <= ox < self.w else NONE
        return read


def emblem(target_w):
    """The Collegium device, thresholded to three levels. Never smoothly resampled (TD-054)."""
    w, hh, px = pngio.read_png(EMB_SRC)
    sc = w / float(target_w)
    th = int(hh / sc)
    out = []
    for y in range(th):
        row = []
        for x in range(target_w):
            x0, x1 = int(x * sc), max(int(x * sc) + 1, int((x + 1) * sc))
            y0, y1 = int(y * sc), max(int(y * sc) + 1, int((y + 1) * sc))
            tot = n = 0.0
            for yy in range(y0, min(y1, hh)):
                for xx in range(x0, min(x1, w)):
                    r, g, b, a = px(xx, yy)
                    if a > 96:
                        tot += (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
                        n += 1
            cover = n / max(1.0, (x1 - x0) * (y1 - y0))
            row.append(0 if cover < 0.40 else (1 if (tot / max(n, 1.0)) < 0.5 else 2))
        out.append(row)
    return out, target_w, th


# ── Banners ──────────────────────────────────────────────────────────────────

def banner(w, hh, seed, with_device=True, lean=0.0):
    g = Grid(w, hh, lean)
    # The rod: iron with a lit top edge and two brackets, which only resolve at this grain.
    g.rect(0, 2, w - 1, 4, IRON_M)
    g.hline(1, 0, w - 1, IRON_L)
    g.hline(5, 0, w - 1, IRON_D)
    for bx in (int(w * 0.18), int(w * 0.82)):
        g.rect(bx - 1, 0, bx + 1, 7, IRON_L)
    top = 7

    for x in range(w):
        # A ragged foot resolved per column, in whole pixels, at twice the resolution of before.
        hem = hh - 1 - int((0.09 + 0.13 * h(x // 3, 0, 7 + seed)) * hh)
        # Folds: four tones now, so a crease has a lit face, a body, a deep and a core shadow.
        fold = h(x // 5, 0, 31 + seed)
        col = CLOTH_M
        if fold > 0.90:
            col = CLOTH_L
        elif fold < 0.08:
            col = CLOTH_XD
        elif fold < 0.24:
            col = CLOTH_D
        g.vline(x, top, hem, col)
        # A one-pixel highlight down the lit side of each crease — pure finer-grain detail.
        if fold > 0.88 and h(x // 5, 1, 41 + seed) > 0.4:
            g.vline(x, top + 2, hem - 3, CLOTH_L)
        if x <= 1 or x >= w - 2:
            g.vline(x, top, hem, CLOTH_XD)                      # selvage, two pixels now
        if h(x, 1, 11 + seed) > 0.88:                           # loose threads below the hem
            g.vline(x, hem + 1, hem + 1 + int(6 * h(x, 2, 13)), CLOTH_D)
        if h(x, 3, 17 + seed) > 0.955:                          # a worn-through pinhole
            g.set(x, hem - int(10 + 30 * h(x, 4, 19)), CLOTH_XD)

    if with_device and w >= 48:
        dev, dw, dh = emblem(int(w * 0.64))
        x0, y0 = (w - dw) // 2, int(hh * 0.19)
        for y in range(dh):
            for x in range(dw):
                v = dev[y][x]
                if v:
                    g.set(x0 + x, y0 + y, BONE_D if v == 1 else BONE_L)
    return g


# ── Hanging props ────────────────────────────────────────────────────────────

def censer(w=40, hh=124, lean=0.0):
    g = Grid(w, hh, lean)
    cx = w // 2
    # A chain with actual LINKS: two lit pixels, a gap, a dark pixel. At the old grain this was a
    # dotted line; here it reads as forged links.
    for y in range(0, 60):
        m = y % 4
        if m == 0:
            g.set(cx - 1, y, BRASS_M); g.set(cx, y, BRASS_L)
        elif m == 1:
            g.set(cx - 1, y, BRASS_D); g.set(cx, y, BRASS_M)
        elif m == 2:
            g.set(cx, y, BRASS_D)
    g.ellipse(cx, 63, 6, 4, BRASS_M, fill=False, thick=1.4)     # suspension ring
    g.set(cx - 3, 61, BRASS_L)
    for dx in (-8, 0, 8):                                       # three chains to the rim
        for y in range(68, 82):
            t = (y - 68) / 14.0
            g.set(cx + int(dx * t), y, BRASS_M if y % 3 else BRASS_D)
    g.rect(cx - 11, 82, cx + 11, 85, BRASS_M)                   # the lid's flange
    g.hline(82, cx - 11, cx + 11, BRASS_L)
    g.hline(85, cx - 11, cx + 11, BRASS_D)
    g.ellipse(cx, 96, 12, 12, BRASS_D)                          # the vessel
    g.ellipse(cx - 2, 93, 8, 8, BRASS_M)
    g.ellipse(cx - 3, 91, 4, 4, BRASS_L)                        # its lit shoulder
    for dx, dy in ((-6, 96), (-1, 100), (5, 94), (2, 104), (-4, 103), (7, 99)):
        g.set(cx + dx, dy, IRON_D)                              # pierced metalwork
        g.set(cx + dx + 1, dy, BRASS_D)                         # and the lip of each piercing
    g.vline(cx, 74, 81, BRASS_L)                                # finial spike
    g.set(cx, 73, BRASS_XL)
    g.ellipse(cx, 110, 5, 3, BRASS_D)                           # foot
    g.hline(109, cx - 3, cx + 3, BRASS_M)
    return g


def chandelier(w=88, hh=60, lean=0.0):
    g = Grid(w, hh, lean)
    cx, cy = w // 2, 38
    for dx in (-32, 0, 32):
        for y in range(0, cy - 8):
            x = cx + int(dx * y / float(cy - 8))
            g.set(x, y, BRASS_M if y % 3 else BRASS_D)          # links, not a dotted line
    g.ellipse(cx, cy, 40, 10, IRON_M, fill=False, thick=1.6)    # the corona
    g.ellipse(cx, cy - 1, 40, 10, IRON_L, fill=False, thick=0.5)
    g.ellipse(cx, cy + 4, 38, 9, IRON_D, fill=False, thick=1.2)
    for i in range(9):
        t = (i + 0.5) / 9.0
        x = int(cx - 38 + 76 * t)
        y = cy + int(9.0 * (1.0 - abs(t - 0.5) * 2.0) ** 0.5) - 6
        tall = 8 + int(6 * h(i, 0, 5))
        g.rect(x - 2, y - 2, x + 2, y, IRON_D)                  # the pricket's pan
        g.hline(y - 2, x - 2, x + 2, IRON_L)
        g.vline(x - 1, y - tall, y - 3, WAX_D)                  # taper: shaded side
        g.vline(x, y - tall, y - 3, WAX_M)                      # ...and lit side
        g.set(x, y - tall, WAX_XL)
        g.set(x, y - tall - 2, IRON_D)                          # a cold wick
    return g


# ── Floor vessels ────────────────────────────────────────────────────────────

def candle_rack(w=192, hh=110, seed=0, lean=0.0):
    g = Grid(w, hh, lean)
    tray = hh - 28
    g.rect(8, tray, w - 9, tray + 2, IRON_M)                    # the tray
    g.hline(tray, 8, w - 9, IRON_L)
    g.hline(tray + 3, 8, w - 9, IRON_D)
    for lx in (12, w - 13):                                     # legs, with a lit inner edge
        g.rect(lx - 1, tray, lx + 1, hh - 4, IRON_M)
        g.vline(lx - 1, tray, hh - 4, IRON_D)
        g.vline(lx + 1, tray, hh - 4, IRON_L)
        g.rect(lx - 4, hh - 4, lx + 4, hh - 2, IRON_D)          # foot
    g.rect(10, hh - 8, w - 11, hh - 7, IRON_D)                  # the stretcher bar

    n = 13 + int(4 * h(seed, 0, 17))
    for i in range(n):
        x = 14 + int((w - 30) * (i + 0.5) / n)
        tall = 16 + int((hh - 52) * h(i, seed, 11))
        # A taper is now four pixels across: shade, body, light, and a rim — where at the old
        # grain it was a single bright column.
        g.vline(x - 1, tray - tall, tray - 1, A.RAMP["navestone"][2])
        g.vline(x, tray - tall, tray - 1, A.RAMP["navestone"][6])
        g.vline(x + 1, tray - tall + 1, tray - 1, A.RAMP["parchment"][1])
        g.set(x, tray - tall, WAX_M)
        g.set(x + 1, tray - tall, A.RAMP["navestone"][6])
        g.vline(x, tray - tall - 3, tray - tall - 1, IRON_D)    # cold wick
        if h(i, seed, 31) > 0.6:                                # wax welded to its neighbour
            g.vline(x + 2, tray - int(tall * 0.3), tray - 1, WAX_D)

    for i in range(7):                                          # runs down the tray's lip
        x = 16 + int((w - 32) * h(i, seed, 23))
        drop = 3 + int(9 * h(i, seed, 29))
        g.vline(x, tray + 3, tray + 3 + drop, A.RAMP["navestone"][3])
        g.vline(x + 1, tray + 3, tray + 2 + drop, A.RAMP["navestone"][5])
        g.set(x, tray + 3 + drop, WAX_D)                        # the bead at the bottom
    return g


def brazier(w=90, hh=84, seed=0, lean=0.0):
    g = Grid(w, hh, lean)
    cx, rim = w // 2, 28
    for dx in (-22, 0, 22):                                     # three legs, tapering
        for y in range(rim + 12, hh - 3):
            t = (y - rim - 12) / float(hh - rim - 15)
            x = cx + int(dx * (0.55 + 0.45 * t))
            g.set(x, y, IRON_M)
            g.set(x + 1, y, IRON_D)
            if y % 7 == 0:
                g.set(x, y, IRON_L)                             # a rivet down the leg
        g.hline(hh - 3, cx + int(dx * 1.0) - 2, cx + int(dx * 1.0) + 2, IRON_D)
    g.ellipse(cx, rim + 8, 32, 16, IRON_M)                      # the bowl
    g.ellipse(cx, rim + 11, 30, 14, IRON_D)
    g.ellipse(cx - 6, rim + 6, 18, 9, IRON_L, fill=False, thick=0.7)   # its lit flank
    g.ellipse(cx, rim, 34, 10, IRON_L, fill=False, thick=1.5)   # the rim
    g.ellipse(cx, rim - 1, 34, 10, IRON_XL, fill=False, thick=0.5)
    for y in range(rim - 6, rim + 6):                           # dead coals, three tones
        for x in range(cx - 28, cx + 29):
            d = ((x - cx) / 28.0) ** 2 + ((y - rim) / 6.4) ** 2
            if d <= 1.0:
                v = h(x // 3, y // 2, 7 + seed)
                g.set(x, y, COAL_L if v > 0.88 else (COAL_M if v > 0.55 else COAL_D))
    return g


def emit(name, g):
    A.assert_on_palette(g.img_w, g.h, g.reader(), name)
    return g


def write(path, g):
    A.assert_on_palette(g.img_w, g.h, g.reader(), path)
    return g


# Where each piece stands, in viewport fractions: (fx, centre-y, the rig's width fraction). The
# lean falls out of these — a prop's tilt is a consequence of where it is, not a style choice.
STANDING = {
    "banner_left":   (0.158, 0.330, 0.1031),
    "banner_right":  (0.842, 0.322, 0.1031),
    "banner_center": (0.500, 0.090, 0.0406),
    "censer":        (0.300, 0.285, 0.0312),
    "chandelier":    (0.500, 0.140, 0.0688),
    "candle_rack":   (0.170, 0.880, 0.1500),
    "candle_rack_b": (0.835, 0.872, 0.1375),
    "brazier":       (0.340, 0.915, 0.0703),
    "brazier_b":     (0.662, 0.908, 0.0656),
}


def lean_of(name, art_w, art_h):
    fx, cy, wf = STANDING[name]
    foot = cy + wf * FRAME_AR * (art_h / float(art_w)) * 0.5
    return lean_for(fx, foot)


def main():
    os.makedirs(os.path.join(os.path.dirname(os.path.abspath(__file__)), "title"), exist_ok=True)
    out = []

    def put(name, path, g):
        emit(name, g)
        out.append((name, g))
        return g

    bl = put("banner_left", "x", banner(132, 336, 1, lean=lean_of("banner_left", 132, 336)))
    A.write_png("title/banner_left.png", bl.img_w, bl.h, bl.reader())
    br = put("banner_right", "x", banner(132, 324, 2, lean=lean_of("banner_right", 132, 324)))
    A.write_png("title/banner_right.png", br.img_w, br.h, br.reader())
    bc = put("banner_center", "x", banner(52, 124, 3, with_device=False))
    A.write_png("title/banner_center.png", bc.img_w, bc.h, bc.reader())

    ce = put("censer", "x", censer(lean=lean_of("censer", 40, 124)))
    A.write_png("title/censer.png", ce.img_w, ce.h, ce.reader())
    ch = put("chandelier", "x", chandelier())
    A.write_png("title/chandelier.png", ch.img_w, ch.h, ch.reader())

    r1 = put("candle_rack", "x", candle_rack(seed=1, lean=lean_of("candle_rack", 192, 110)))
    A.write_png("title/candle_rack.png", r1.img_w, r1.h, r1.reader())
    r2 = put("candle_rack_b", "x",
             candle_rack(w=176, hh=102, seed=2, lean=lean_of("candle_rack_b", 176, 102)))
    A.write_png("title/candle_rack_b.png", r2.img_w, r2.h, r2.reader())
    b1 = put("brazier", "x", brazier(seed=3, lean=lean_of("brazier", 90, 84)))
    A.write_png("title/brazier.png", b1.img_w, b1.h, b1.reader())
    b2 = put("brazier_b", "x", brazier(w=84, hh=78, seed=4, lean=lean_of("brazier_b", 84, 78)))
    A.write_png("title/brazier_b.png", b2.img_w, b2.h, b2.reader())

    print("gen_title_furniture OK — 9 pieces, leaning to the hall's measured zenith, on-palette.")
    print("  RIG FRACTIONS (art_width / 1280 — the shear padding widens them):")
    for name, g in out:
        print("    %-15s %3dx%-4d lean %+.4f   %.4f" % (name, g.img_w, g.h, g.lean, g.img_w / 1280.0))


if __name__ == "__main__":
    main()
