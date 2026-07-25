#!/usr/bin/env python3
"""gen_title_furniture.py — the hall's cloth and furniture, as PIXEL ART (TD-075).

    title/banner_left.png  banner_right.png  banner_center.png
    title/censer.png  chandelier.png
    title/candle_rack.png  candle_rack_b.png  brazier.png  brazier_b.png

Replaces the painterly props and banners. They were authored at 340-660px and drawn into a 640x360
viewport — a 4:1 downscale that no filter survives. **Everything here is authored at the size it is
displayed**, which for these objects is 20 to 96 pixels across. At that size a prop is drawn the way
a pixel artist draws one: a silhouette, two or three flat tones from a shipped ramp, and a single
highlight where the light is. No form shading, no anti-aliasing, no gradients.

Every pixel is a ramp entry, so `A.assert_on_palette` passes on all nine — the same check the board's
own art passes, and the reason these sit beside it.

Nothing burns: cold wicks, dead coals. The fire is in-engine (TD-043).

Run from client/assets/ui/:  python3 gen_title_furniture.py
"""
import os

import ashember as A
import pngio

EMB_SRC = "board/collegium_logo.png"

# Every colour used here, by name, so the whole set can be read at a glance.
IRON_D, IRON_M, IRON_L = A.RAMP["navestone"][0], A.RAMP["navestone"][2], A.RAMP["navestone"][4]
BRASS_D, BRASS_M, BRASS_L = A.RAMP["gold"][0], A.RAMP["gold"][1], A.RAMP["gold"][2]
WAX_D, WAX_M, WAX_L = A.RAMP["parchment"][0], A.RAMP["parchment"][2], A.RAMP["parchment"][3]
CLOTH_D, CLOTH_M, CLOTH_L = A.RAMP["black"][2], A.RAMP["wax"][0], A.RAMP["wax"][1]
BONE_D, BONE_L = A.RAMP["parchment"][1], A.RAMP["parchment"][3]
COAL_D, COAL_M = A.RAMP["black"][1], A.RAMP["navestone"][1]
NONE = (0, 0, 0, 0)


def h(x, y, s=0):
    n = (x * 374761393 + y * 668265263 + s * 2654435761) & 0xFFFFFFFF
    n = (n ^ (n >> 13)) * 1274126177 & 0xFFFFFFFF
    return ((n >> 8) % 1000) / 1000.0


class Grid:
    """A little pixel canvas. Set pixels; there is no blending, ever."""

    def __init__(self, w, hh):
        self.w, self.h = w, hh
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

    def ellipse(self, cx, cy, rx, ry, c, fill=True):
        for y in range(int(cy - ry), int(cy + ry) + 1):
            for x in range(int(cx - rx), int(cx + rx) + 1):
                d = ((x - cx) / max(rx, .5)) ** 2 + ((y - cy) / max(ry, .5)) ** 2
                if d <= 1.0 and (fill or d > 0.45):
                    self.set(x, y, c)

    def reader(self):
        return lambda x, y: self.px[y][x]


# ── The device, thresholded to two tones ─────────────────────────────────────

def emblem(target_w):
    """The Collegium device at `target_w` px, as 0/1/2 coverage. Thresholded, never resampled:
    a smooth reduction of a big logo hands back grey mush, which TD-054 already paid for once."""
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

def banner(w, hh, seed, with_device=True):
    g = Grid(w, hh)
    g.rect(0, 0, w - 1, 1, IRON_M)                            # the rod it hangs from
    g.hline(0, 0, w - 1, IRON_L)
    top = 3
    # A ragged foot, resolved per COLUMN as whole pixels — cloth wears away a thread at a time.
    for x in range(w):
        hem = hh - 1 - int((0.10 + 0.14 * h(x // 2, 0, 7 + seed)) * hh)
        # Folds: narrow and IRREGULAR. Four equal bands across the width read as a barcode
        # printed on the cloth; real drape is a few close creases and a lot of quiet field.
        col = CLOTH_M
        fold = h(x // 3, 0, 31 + seed)
        if fold > 0.86:
            col = CLOTH_L                                     # the lit crest of a crease
        elif fold < 0.20:
            col = CLOTH_D                                     # the deep of one
        g.vline(x, top, hem, col)
        if x in (0, w - 1):
            g.vline(x, top, hem, CLOTH_D)                     # selvage
        for _ in range(1):                                    # a few loose threads below the hem
            if h(x, 1, 11 + seed) > 0.86:
                g.vline(x, hem + 1, hem + 1 + int(3 * h(x, 2, 13)), CLOTH_D)
    if with_device and w >= 24:
        dev, dw, dh = emblem(int(w * 0.62))
        x0, y0 = (w - dw) // 2, int(hh * 0.20)
        for y in range(dh):
            for x in range(dw):
                v = dev[y][x]
                if v:
                    g.set(x0 + x, y0 + y, BONE_D if v == 1 else BONE_L)
    return g


# ── Hanging props ────────────────────────────────────────────────────────────

def censer(w=20, hh=62):
    g = Grid(w, hh)
    cx = w // 2
    for y in range(0, 30):                                    # the chain, to the very top edge
        g.set(cx, y, BRASS_M if y % 3 else BRASS_D)
    g.ellipse(cx, 31, 3, 2, BRASS_M, fill=False)              # suspension ring
    for dx, y0 in ((-4, 34), (0, 34), (4, 34)):               # three chains to the rim
        for y in range(y0, 41):
            g.set(cx + int(dx * (y - y0) / 7.0), y, BRASS_D)
    g.ellipse(cx, 48, 6, 6, BRASS_D)                          # the vessel
    g.ellipse(cx - 1, 46, 4, 4, BRASS_M)
    g.set(cx - 2, 45, BRASS_L)
    for dx, dy in ((-3, 48), (0, 50), (3, 47), (-1, 52)):     # pierced metalwork
        g.set(cx + dx, dy, IRON_D)
    g.rect(cx - 5, 41, cx + 5, 42, BRASS_M)                   # the lid's seam
    g.vline(cx, 38, 40, BRASS_L)                              # finial
    g.ellipse(cx, 55, 2, 1, BRASS_D)                          # foot
    return g


def chandelier(w=44, hh=30):
    g = Grid(w, hh)
    cx, cy = w // 2, 19
    for dx in (-16, 0, 16):                                   # three chains up out of frame
        for y in range(0, cy - 4):
            g.set(cx + int(dx * y / float(cy - 4)), y, IRON_D)
    g.ellipse(cx, cy, 20, 5, IRON_M, fill=False)              # the corona
    g.ellipse(cx, cy + 2, 19, 4, IRON_D, fill=False)
    for i in range(7):                                        # unlit tapers around the rim
        t = (i + 0.5) / 7.0
        x = int(cx - 19 + 38 * t)
        y = cy + int(4.5 * (1.0 - abs(t - 0.5) * 2.0) ** 0.5) - 3
        tall = 4 + int(3 * h(i, 0, 5))
        g.vline(x, y - tall, y, WAX_M)
        g.set(x, y - tall, WAX_L)
        g.set(x, y - tall - 1, IRON_D)                        # a cold wick
    return g


# ── Floor vessels ────────────────────────────────────────────────────────────

def candle_rack(w=96, hh=55, seed=0):
    g = Grid(w, hh)
    tray = hh - 14
    g.hline(tray, 4, w - 5, IRON_M)                           # the tray
    g.hline(tray + 1, 4, w - 5, IRON_D)
    g.vline(6, tray, hh - 2, IRON_M)                          # splayed legs
    g.vline(w - 7, tray, hh - 2, IRON_M)
    g.hline(hh - 2, 5, w - 6, IRON_D)
    n = 13 + int(4 * h(seed, 0, 17))
    for i in range(n):
        x = 6 + int((w - 13) * (i + 0.5) / n)
        tall = 8 + int((hh - 26) * h(i, seed, 11))
        g.vline(x, tray - tall, tray - 1, WAX_M)
        g.vline(x - 1, tray - tall + 1, tray - 1, WAX_D)      # the shaded side of the taper
        g.set(x, tray - tall, WAX_L)
        g.set(x, tray - tall - 1, IRON_D)                     # cold wick
    for i in range(5):                                        # wax run down the tray's lip
        x = 8 + int((w - 16) * h(i, seed, 23))
        g.vline(x, tray + 2, tray + 2 + int(3 * h(i, seed, 29)), WAX_D)
    return g


def brazier(w=45, hh=42, seed=0):
    g = Grid(w, hh)
    cx, rim = w // 2, 14
    for dx in (-11, 0, 11):                                   # three legs
        for y in range(rim + 6, hh - 1):
            g.set(cx + int(dx * (y - rim - 6) / float(hh - rim - 7)), y, IRON_M)
    g.ellipse(cx, rim + 4, 16, 8, IRON_M)                     # the bowl
    g.ellipse(cx, rim + 6, 15, 7, IRON_D)
    g.ellipse(cx, rim, 17, 5, IRON_L, fill=False)             # the rim, catching what light there is
    for y in range(rim - 3, rim + 3):                         # dead coals, banked in the bowl
        for x in range(cx - 14, cx + 15):
            d = ((x - cx) / 14.0) ** 2 + ((y - rim) / 3.2) ** 2
            if d <= 1.0:
                v = h(x // 2, y, 7 + seed)
                g.set(x, y, COAL_M if v > 0.62 else COAL_D)
    return g


def emit(name, g):
    A.assert_on_palette(g.w, g.h, g.reader(), name)
    return g


def main():
    os.makedirs(os.path.join(os.path.dirname(os.path.abspath(__file__)), "title"), exist_ok=True)
    bl = emit("banner_left", banner(66, 168, 1))
    A.write_png("title/banner_left.png", bl.w, bl.h, bl.reader())
    br = emit("banner_right", banner(66, 162, 2))
    A.write_png("title/banner_right.png", br.w, br.h, br.reader())
    bc = emit("banner_center", banner(26, 62, 3, with_device=False))
    A.write_png("title/banner_center.png", bc.w, bc.h, bc.reader())

    ce = emit("censer", censer())
    A.write_png("title/censer.png", ce.w, ce.h, ce.reader())
    ch = emit("chandelier", chandelier())
    A.write_png("title/chandelier.png", ch.w, ch.h, ch.reader())

    r1 = emit("candle_rack", candle_rack(seed=1))
    A.write_png("title/candle_rack.png", r1.w, r1.h, r1.reader())
    r2 = emit("candle_rack_b", candle_rack(w=88, hh=51, seed=2))
    A.write_png("title/candle_rack_b.png", r2.w, r2.h, r2.reader())
    b1 = emit("brazier", brazier(seed=3))
    A.write_png("title/brazier.png", b1.w, b1.h, b1.reader())
    b2 = emit("brazier_b", brazier(w=42, hh=39, seed=4))
    A.write_png("title/brazier_b.png", b2.w, b2.h, b2.reader())

    print("gen_title_furniture OK — 3 banners, censer, chandelier, 2 racks, 2 braziers, on-palette.")
    print("  widths as viewport fractions (640 wide): "
          + ", ".join("%s %.4f" % (n, g.w / 640.0) for n, g in
                      (("banner", bl), ("banner_c", bc), ("censer", ce), ("chandelier", ch),
                       ("rack", r1), ("rack_b", r2), ("brazier", b1), ("brazier_b", b2))))


if __name__ == "__main__":
    main()
