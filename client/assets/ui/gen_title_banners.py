#!/usr/bin/env python3
"""gen_title_banners.py — the title scene's hanging standards (TD-073, T260).

Three Collegium banners for the title hall, in the **painted environment register** (R242) rather
than the board's pixel one: they hang at 340px and 260px wide and are drawn with a LINEAR filter,
so smooth drape shading is correct here where it would be wrong on a 64px board banner.

    title/banner_left.png    340x760
    title/banner_right.png   340x760
    title/banner_center.png  260x620   smaller, deeper in the nave

This is `gen_banner.py`'s idiom re-cut for the hall — woven crimson, baked folds, a ragged worn
foot resolved per column as ALPHA, worn-through holes, loose threads, and the Collegium device
imprinted as a pale **bone dye** the weave still shows through (PIL reads the emblem; every output
still goes through `ashember.write_png`, so the asset-map producer edges hold).

Three things are deliberate:

* **Each banner is seeded differently.** The manifest asks for the right one to be "mirror-ish, not
  identical" — same cloth, different history. Fold phase, hem wear, holes and threads all come off
  the banner's own seed, so nothing reads as a flipped copy.
* **The iron rod is in the image.** The rig sways each banner from its TOP CENTRE, which is exactly
  where the rod is, so cloth and rod swing as one object.
* **Nothing is lit.** Folds are *form*, not light: low contrast, dim, no hotspot. The scene's seven
  fires are in-engine (TD-043) and a banner with a baked highlight would fight them.

Run from client/assets/ui/:  python3 gen_title_banners.py
"""
import math

from PIL import Image

import ashember as A

# Dim crimson, in the hall's key: darker than the board's cloth because these hang high on the
# near piers, which the plate keeps in near-silhouette. Faded twice on purpose — the first pass
# still read as the loudest thing in the frame, and cloth that out-saturates its own hall is the
# 'pasted on' failure TD-059 spent a whole spec fixing for the board's banners.
C_DEEP = (34, 10, 10)
C_MID = (70, 22, 20)
C_HI = (92, 32, 27)

BONE_DK = (84, 78, 66)
BONE_LT = (156, 148, 128)
IMPRINT_A = 0.50
EMB_SRC = "board/collegium_logo.png"

IRON_DK = (22, 21, 22)
IRON_MID = (54, 52, 52)
IRON_HI = (86, 83, 80)

ROD = 0.028            # the iron rod occupies the top of the image
SLEEVE = 0.052         # the cloth's pole sleeve, just under it
SOLID = 0.87           # cloth is full down to here; the tatter lives below


def _clampf(v, a=0.0, b=1.0):
    return max(a, min(b, v))


def _h(x, y, s=0):
    """Deterministic [0,1) hash — stable fine grain, never blocky."""
    n = (x * 374761393 + y * 668265263 + s * 2654435761) & 0xFFFFFFFF
    n = (n ^ (n >> 13)) * 1274126177 & 0xFFFFFFFF
    return ((n >> 8) % 1000) / 1000.0


class Banner:
    """One standard. Everything that varies between the three lives on the seed."""

    def __init__(self, w, h, seed):
        self.w, self.h, self.seed = w, h, seed
        # Fold train: 3-5 soft vertical drapes, phase and count off the seed.
        self.folds = 3.0 + 2.0 * _h(seed, 1, 5)
        self.phase = _h(seed, 2, 5) * math.pi * 2.0
        # Worn-through holes near the foot, placed by the seed rather than shared between banners.
        # Small, low, and few: wear comes up from the foot. Big round voids mid-cloth read as
        # ink blots, not as a banner that has hung in a hall for two centuries.
        self.holes = [(0.16 + 0.68 * _h(seed, i, 7),
                       0.68 + 0.22 * _h(seed, i, 11),
                       0.022 + 0.034 * _h(seed, i, 13),
                       0.010 + 0.018 * _h(seed, i, 17))
                      for i in range(1 + int(2 * _h(seed, 3, 19)))]
        self.alpha = [[self._alpha(x, y) for x in range(w)] for y in range(h)]

    # ── shape ────────────────────────────────────────────────────────────────
    def hem_depth(self, x):
        """The ragged foot for column x, as an fy fraction. Worn in low-frequency steps and
        interpolated, so the edge is ragged cloth and not per-pixel confetti."""
        xs = x / (self.w / 44.0)
        x0 = int(math.floor(xs))
        t = xs - x0
        a = _h(x0, 0, 11 + self.seed)
        b = _h(x0 + 1, 0, 11 + self.seed)
        worn = a + (b - a) * (t * t * (3.0 - 2.0 * t))
        return SOLID + (0.985 - SOLID) * (worn * worn * (3.0 - 2.0 * worn))

    def in_hole(self, fx, fy):
        for hx, hy, rx, ry in self.holes:
            dx, dy = (fx - hx) / rx, (fy - hy) / ry
            # The rim is eaten away rather than cut: the further out, the likelier a thread
            # still holds, so the hole dissolves into the weave instead of ending at a curve.
            d2 = dx * dx + dy * dy
            if d2 < 1.0 and _h(int(fx * self.w), int(fy * self.h), 23) > d2 * 0.72:
                return True
        return False

    def is_thread(self, x):
        return _h(x, 0, 31 + self.seed) > 0.84

    def thread_depth(self, x):
        hem = self.hem_depth(x)
        return hem + (0.998 - hem) * _h(x, 0, 37 + self.seed)

    def _alpha(self, x, y):
        fx, fy = x / (self.w - 1), y / (self.h - 1)
        if fy < ROD:
            # The rod runs the full width and a touch past the cloth, so it reads as a bar the
            # banner hangs FROM rather than a border drawn around it.
            return True
        # The cloth's top edge sags a little between the rod's ends.
        top = ROD + 0.010 * math.sin(fx * math.pi)
        if fy < top:
            return False
        # Cloth narrows very slightly toward the foot — a hanging standard is not a rectangle.
        inset = 0.018 * (fy - top)
        if fx < inset or fx > 1.0 - inset:
            return False
        hem = self.hem_depth(x)
        if fy <= hem:
            return not self.in_hole(fx, fy)
        return self.is_thread(x) and fy <= self.thread_depth(x)

    # ── shading ──────────────────────────────────────────────────────────────
    def fold(self, fx, fy):
        """0..1 across the drape. Folds wander as they fall — a perfectly vertical fold train is
        the tell that this was drawn by a sine wave, which it was."""
        wander = 0.10 * math.sin(fy * 3.4 + self.phase)
        f = 0.5 + 0.5 * math.sin((fx + wander) * math.pi * self.folds + self.phase)
        f = 0.5 + (f - 0.5) * 0.86
        f += 0.09 * math.sin((fx + wander) * math.pi * (self.folds * 2.7) + 1.1)
        # The cloth hangs slacker near the foot, so the folds soften as they descend.
        return _clampf(0.5 + (f - 0.5) * (1.0 - 0.30 * fy))

    def px(self, x, y, imp):
        if not self.alpha[y][x]:
            return (0, 0, 0, 0)
        fx, fy = x / (self.w - 1), y / (self.h - 1)

        if fy < ROD:                                   # ── the iron rod ──
            t = fy / ROD
            body = A.lerp_rgb(IRON_MID, IRON_DK, abs(t - 0.42) * 1.7)
            if 0.30 < t < 0.44:
                body = A.lerp_rgb(body, IRON_HI, 0.55)  # one thin lit edge along the top
            g = (_h(x, y, 3) - 0.5) * 9.0               # forged iron is pitted, never smooth
            return (A.clamp(body[0] + g), A.clamp(body[1] + g), A.clamp(body[2] + g), 255)

        f = self.fold(fx, fy)
        body = A.lerp_rgb(C_DEEP, C_HI, f)
        body = A.lerp_rgb(body, C_MID, 0.34)

        wv = (_h(x, y, 1 + self.seed) - 0.5) * 5.5      # fine weave
        body = (body[0] + wv, body[1] + wv * 0.5, body[2] + wv * 0.5)

        # Dust and age gather down the cloth; the foot is the dirtiest part of any hanging thing.
        body = A.lerp_rgb(body, C_DEEP, _clampf(0.08 + fy * 0.28))

        if fy < SLEEVE:                                 # the pole sleeve, in the rod's shadow
            body = A.lerp_rgb(body, C_DEEP, 0.62)
        elif fy < SLEEVE + 0.014:
            body = A.lerp_rgb(body, C_HI, 0.24)         # the lit lip just under it

        # Selvage: a darker edge tracing the sides and the ragged foot.
        w, h = self.w, self.h
        if x <= 0 or x >= w - 1 or not self.alpha[y][min(x + 1, w - 1)] \
                or not self.alpha[y][max(x - 1, 0)] or (y + 1 < h and not self.alpha[y + 1][x]):
            body = A.lerp_rgb(body, C_DEEP, 0.58)

        ir, ig, ib, ia = imp[x, y]                      # the bone-dye device
        if ia > 0:
            t = ia / 255.0
            body = (body[0] * (1 - t) + ir * t,
                    body[1] * (1 - t) + ig * t,
                    body[2] * (1 - t) + ib * t)
        return (A.clamp(body[0]), A.clamp(body[1]), A.clamp(body[2]), 255)


def imprint(w, h, scale=0.62, seat=0.20):
    """The dim bone-dye emblem, recoloured, scaled and seated, as a w×h RGBA overlay."""
    im = Image.open(EMB_SRC).convert("RGBA")
    sp = im.load()
    bone = Image.new("RGBA", im.size)
    bp = bone.load()
    for yy in range(im.height):
        for xx in range(im.width):
            r, g, b, a = sp[xx, yy]
            if a == 0:
                bp[xx, yy] = (0, 0, 0, 0)
                continue
            lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
            c = A.lerp_rgb(BONE_DK, BONE_LT, lum)
            bp[xx, yy] = (int(c[0]), int(c[1]), int(c[2]), int(a * IMPRINT_A))
    tw = int(scale * w)
    th = round(tw * im.height / im.width)
    bone = bone.resize((tw, th), Image.LANCZOS)
    buf = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    buf.alpha_composite(bone, ((w - tw) // 2, int(h * seat)))
    return buf.load()


def emit(w, h, seed, seat=0.20):
    """Build one banner and hand back the pixel callback `write_png` wants."""
    b = Banner(w, h, seed)
    imp = imprint(w, h, seat=seat)
    return lambda x, y: b.px(x, y, imp)


def main():
    # LITERAL relative paths, run from client/assets/ui/ (canon S5b): tools/asset_map.py derives
    # producer edges from these strings.
    A.write_png("title/banner_left.png", 340, 760, emit(340, 760, 1))
    A.write_png("title/banner_right.png", 340, 760, emit(340, 760, 2))
    A.write_png("title/banner_center.png", 260, 620, emit(260, 620, 3, seat=0.22))
    print("gen_title_banners OK — three seeded standards, 340x760 / 340x760 / 260x620.")


if __name__ == "__main__":
    main()
