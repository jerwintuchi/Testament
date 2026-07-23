#!/usr/bin/env python3
"""Notice Board Pass-2 — WEATHERED direction study (throwaway look-lock).

NOT a shipped asset generator. Composites a rich, aged, LIT contract-board mock to
lock the vibe the user asked for (ref: Darkest-Dungeon commission wall): warm
weathered stone, a heavy carved frame gone grimy with age, torn/water-stained
parchment notices, faded frayed banners, and a baked warm light pass (torch pools
+ center fill → dark cool edges) that PREVIEWS the in-engine Light2D/particle look.

Canon note: the strict 15-colour Ash & Ember palette-lock is intentionally RELAXED
here (user-authorized) — smooth 24-bit shading at the native 640×360, upscaled
nearest, i.e. the HD-pixel idiom (Blasphemous/Dead-Cells register), not flat greybox.
The real lighting is Godot's (particles + Light2D + wall/board shader); this bakes a
stand-in so the composition can be judged lit. Text is Godot-rendered → faux bars.

Run: `python3 gen_prototype.py` → writes `_proto_board.png` (×SCALE) beside this.
"""
import os
import math
from ashember import noise, write_png, clamp

HERE = os.path.dirname(os.path.abspath(__file__))
W, H = 640, 360
SCALE = 2

# ── Weathered gothic palette (relaxed lock: rich ramps, warm-biased) ──────────
def hx(h):
    h = h.lstrip("#"); return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))

STONE_D, STONE_M, STONE_L = hx("#14110c"), hx("#2a2620"), hx("#3c362b")
MORTAR = hx("#0d0b07")
MOSS_A, MOSS_B = hx("#37381f"), hx("#4a4a2c")
WOOD_D, WOOD_M, WOOD_L, WOOD_H = hx("#241708"), hx("#432c17"), hx("#6a482a"), hx("#8a6238")
WOOD_WORN = hx("#a07c4e")
IRON_D, IRON_M, IRON_L = hx("#1c1c20"), hx("#43434a"), hx("#6e6e78")
RUST_A, RUST_B = hx("#6b3320"), hx("#8f4a2c")
GOLD_D, GOLD_M, GOLD_L, GOLD_H = hx("#5f471c"), hx("#9a7a34"), hx("#c8a24a"), hx("#ecd07a")
PAR_D, PAR_M, PAR_L, PAR_H = hx("#6f5a37"), hx("#a08a5e"), hx("#c8b284"), hx("#e2d2a4")
STAIN, FOX = hx("#7a5a36"), hx("#5c4426")
WAX_D, WAX_M, WAX_L, WAX_H = hx("#5e211c"), hx("#8f2f2a"), hx("#c05446"), hx("#e08070")
INK, INK_SOFT = hx("#241c11"), hx("#4c3d27")
FLAME_C, FLAME_M, FLAME_H = hx("#e8973c"), hx("#f4bd63"), hx("#ffe1a0")
BLACK = hx("#0a0906")


def lerp(a, b, t):
    t = 0.0 if t < 0 else 1.0 if t > 1 else t
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t)


def addv(c, v):
    return (c[0] + v, c[1] + v, c[2] + v)


# smooth value noise in [-1,1] via bilinear interp of the integer lattice
def snoise(x, y, salt, scale):
    xf, yf = x / scale, y / scale
    x0, y0 = int(math.floor(xf)), int(math.floor(yf))
    tx, ty = xf - x0, yf - y0
    def n(ix, iy): return noise(ix, iy, salt) / 8.0
    a = n(x0, y0) + (n(x0 + 1, y0) - n(x0, y0)) * tx
    b = n(x0, y0 + 1) + (n(x0 + 1, y0 + 1) - n(x0, y0 + 1)) * tx
    return a + (b - a) * ty


# ── tiny RGBA canvas with alpha-over ─────────────────────────────────────────
class Canvas:
    def __init__(self, w, h, fill):
        self.w, self.h = w, h
        self.px = [[fill[0], fill[1], fill[2], 255] for _ in range(w * h)]

    def put(self, x, y, rgb, a=255):
        if not (0 <= x < self.w and 0 <= y < self.h) or a <= 0:
            return
        r, g, b = clamp(rgb[0]), clamp(rgb[1]), clamp(rgb[2])
        i = y * self.w + x
        if a >= 255:
            self.px[i] = [r, g, b, 255]
        else:
            d = self.px[i]; t = a / 255.0
            self.px[i] = [int(r * t + d[0] * (1 - t)), int(g * t + d[1] * (1 - t)),
                          int(b * t + d[2] * (1 - t)), 255]

    def get(self, x, y):
        return self.px[y * self.w + x]

    def rect(self, x0, y0, x1, y1, rgb, a=255):
        for y in range(max(0, y0), min(self.h, y1)):
            for x in range(max(0, x0), min(self.w, x1)):
                self.put(x, y, rgb, a)

    def hline(self, x0, x1, y, rgb, a=255):
        for x in range(x0, x1): self.put(x, y, rgb, a)

    def vline(self, x, y0, y1, rgb, a=255):
        for y in range(y0, y1): self.put(x, y, rgb, a)

    def disc(self, cx, cy, r, rgb, a=255):
        for y in range(cy - r, cy + r + 1):
            for x in range(cx - r, cx + r + 1):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r: self.put(x, y, rgb, a)

    def ring(self, cx, cy, r, rgb, a=255):
        for y in range(cy - r, cy + r + 1):
            for x in range(cx - r, cx + r + 1):
                d = (x - cx) ** 2 + (y - cy) ** 2
                if (r - 1) ** 2 < d <= r * r: self.put(x, y, rgb, a)


# ── layout ────────────────────────────────────────────────────────────────────
BX0, BY0, BX1, BY1 = 66, 16, 574, 344
BB = 16                                  # frame border
GUT_L, GUT_R = BX0 // 2, (W + BX1) // 2
TORCH = [(BX0 - 10, int(H * 0.44)), (BX1 + 9, int(H * 0.44))]


# ── 1. weathered stone wall ──────────────────────────────────────────────────
def draw_wall(c):
    BW, BH = 40, 16
    for y in range(H):
        for x in range(W):
            row = y // BH
            off = (BW // 2) if (row % 2) else 0
            bx = (x + off) // BW                          # which brick (for per-brick tone)
            xm, ym = (x + off) % BW, y % BH
            if xm <= 1 or ym <= 1:                        # recessed mortar
                col = lerp(MORTAR, STONE_D, 0.3 + snoise(x, y, 2, 3) * 0.2)
            else:
                bt = (noise(bx, row, 9) / 8.0)            # per-brick base variation
                col = lerp(STONE_D, STONE_M, 0.5 + bt * 0.4)
                col = addv(col, snoise(x, y, 3, 2) * 6)   # fine grain
                # top bevel catches a little, bottom in shadow (carved relief)
                if ym <= 3: col = lerp(col, STONE_L, 0.25)
                elif ym >= BH - 3: col = lerp(col, STONE_D, 0.4)
            # moss / lichen creeping from bottom + low corners
            m = snoise(x, y, 21, 9)
            damp = max(0.0, (y / H - 0.35)) + max(0.0, (abs(x - W / 2) / W - 0.2)) * 0.6
            if m > 0.35 - damp * 0.5:
                col = lerp(col, lerp(MOSS_A, MOSS_B, (m + 1) / 2), min(0.6, (m - 0.1) * 0.7))
            # long water streaks weeping downward
            s = snoise(x, y * 0.25, 33, 5)
            if s > 0.55 and y > 30:
                col = lerp(col, STONE_D, (s - 0.55) * 1.3)
            # soot grime rising toward the top
            col = lerp(col, BLACK, max(0.0, (1.0 - y / (H * 0.5))) * 0.25)
            c.put(x, y, col)


# ── 2. faded, frayed banners in the gutters ──────────────────────────────────
def draw_banner(c, cx):
    top, w, length = 4, 26, int(H * 0.60)
    for y in range(top, top + length):
        tail = max(0, y - (top + length - 16))
        half = w // 2 - (tail if (abs((y) % 6) < 3) else tail + 2)   # ragged swallowtail
        if half <= 1: continue
        for x in range(cx - half, cx + half):
            edge = (x <= cx - half + 2 or x >= cx + half - 3)
            fold = abs(x - cx) < 2
            shade = 0.5 + 0.5 * math.cos((x - cx) / half * 1.2)      # cylindrical fold light
            base = lerp(WAX_D, WAX_M, shade)
            if edge: base = lerp(base, BLACK, 0.4)
            if fold: base = lerp(base, WAX_L, 0.4)
            base = lerp(base, STONE_D, 0.35)                          # faded/dusty
            base = addv(base, snoise(x, y, 44, 2) * 5)
            # moth holes
            if snoise(x, y, 55, 3) > 0.7 and y > top + 20:
                continue
            # dust on the top curl
            if y < top + 4: base = lerp(base, STONE_L, 0.3)
            c.put(x, y, base)
    c.rect(cx - w // 2 - 3, top - 3, cx + w // 2 + 3, top, lerp(GOLD_D, IRON_M, 0.4))  # tarnished rail
    sy = top + 18                                                     # ghost sword sigil
    c.vline(cx, sy, sy + 30, lerp(PAR_D, WAX_M, 0.4))
    c.hline(cx - 6, cx + 7, sy + 8, lerp(PAR_D, WAX_M, 0.4))


# ── 3. baked torch (Godot particles+Light2D replace this) ────────────────────
def draw_torch(c, cx, cy):
    # rusted iron bracket
    c.rect(cx - 5, cy, cx + 5, cy + 3, IRON_D)
    c.hline(cx - 5, cx + 5, cy, IRON_L)
    for k in range(3, 15):
        c.put(cx, cy + k, lerp(IRON_M, RUST_A, (k / 15))); c.put(cx + 1, cy + k, IRON_D)
    # flame (grayscale-ish warm teardrop) — the shape a particle sheet gives in-engine
    for y in range(cy - 20, cy + 2):
        for x in range(cx - 7, cx + 8):
            ny = (cy + 1 - y) / 22.0
            half = 1.5 + 5.0 * (ny ** 0.6) * (1 - ny * 0.3)
            d = abs(x - cx) / max(half, 0.1)
            if d <= 1.0 and y < cy:
                core = (1 - d) * (0.4 + 0.6 * ny)
                col = lerp(FLAME_C, FLAME_H, core)
                c.put(x, y, col, int(200 * min(1, core + 0.3)))


# ── 4. carved frame gone grimy, drop shadow on the wall ──────────────────────
def draw_frame_shadow(c):
    for y in range(BY0 - 4, BY1 + 8):
        for x in range(BX0 - 4, BX1 + 8):
            inside = (BX0 - 4 <= x < BX1 + 8 and BY0 - 4 <= y < BY1 + 8)
            near = not (BX0 <= x < BX1 and BY0 <= y < BY1)
            if inside and near:
                d = min(abs(x - BX0), abs(x - (BX1 - 1)), abs(y - BY0), abs(y - (BY1 - 1)))
                c.put(x, y, BLACK, int(120 * max(0, 1 - d / 8.0)))


def draw_backing(c):
    for y in range(BY0 + 2, BY1 - 2):
        for x in range(BX0 + 2, BX1 - 2):
            grain = snoise(x * 0.3, y, 71, 3) * 10
            plank = -10 if (y % 15 < 1) else 0
            knot = 0
            kx, ky = (x % 130), (y % 90)
            if (kx - 60) ** 2 + (ky - 40) ** 2 < 30: knot = -14
            col = lerp(WOOD_D, WOOD_M, 0.4)
            col = addv(col, grain + plank + knot)
            # inner shadow under the frame lip
            di = min(x - (BX0 + 2), y - (BY0 + 2), (BX1 - 3) - x, (BY1 - 3) - y)
            if di < 6: col = lerp(col, BLACK, (6 - di) / 6 * 0.5)
            c.put(x, y, col)


def draw_frame(c):
    for y in range(BY0, BY1):
        for x in range(BX0, BX1):
            d = min(x - BX0, y - BY0, BX1 - 1 - x, BY1 - 1 - y)
            if d >= BB: continue
            lit = ((x - BX0) == d or (y - BY0) == d)
            # multi-step molding profile
            if d == 0: col = BLACK
            elif d == 1: col = lerp(WOOD_H, WOOD_D, 0 if lit else 1)
            elif d in (2, 3): col = lerp(WOOD_M, WOOD_L if lit else WOOD_D, 0.6)
            elif d == 5: col = lerp(GOLD_D, GOLD_M, 0.6) if lit else lerp(GOLD_D, BLACK, 0.4)  # gilt line
            elif d in (6, 7): col = lerp(WOOD_D, WOOD_M, 0.3)                                   # routed channel
            elif d == BB - 3: col = WOOD_L if lit else WOOD_D
            elif d == BB - 1: col = lerp(WOOD_D, BLACK, 0.5)
            else: col = lerp(WOOD_M, WOOD_L if lit else WOOD_D, 0.35)
            # grain + grime in the crevices
            col = addv(col, snoise(x, y, 61, 3) * 7)
            if not lit: col = lerp(col, BLACK, 0.18)                # dirt settles on lower faces
            # cracks
            if snoise(x, y * 0.5, 63, 4) > 0.72 and 2 < d < BB - 2:
                col = lerp(col, BLACK, 0.5)
            # worn highlights where hands pass (mid of each rail)
            if 3 < d < BB - 3 and snoise(x, y, 67, 6) > 0.6:
                col = lerp(col, WOOD_WORN, 0.25)
            c.put(x, y, col)
    # rusted iron corner studs
    for (sx, sy) in ((BX0 + 8, BY0 + 8), (BX1 - 9, BY0 + 8), (BX0 + 8, BY1 - 9), (BX1 - 9, BY1 - 9)):
        c.disc(sx, sy, 4, BLACK)
        c.disc(sx, sy, 3, lerp(IRON_M, RUST_A, 0.4))
        c.put(sx - 1, sy - 1, IRON_L)
        c.put(sx + 2, sy + 2, RUST_B)                              # rust weep
        c.put(sx + 2, sy + 3, lerp(RUST_A, BLACK, 0.3))
    draw_crest(c)


def draw_crest(c):
    ccx, ccy = (BX0 + BX1) // 2, BY0 + 2
    rx, ry = 34, 17
    for y in range(ccy - ry, ccy + ry + 2):
        for x in range(ccx - rx, ccx + rx):
            e = ((x - ccx) / rx) ** 2 + ((y - ccy) / ry) ** 2
            if e <= 1.0:
                shell = lerp(WOOD_L, WOOD_D, e)
                if e > 0.78: shell = lerp(GOLD_M, GOLD_D, (e - 0.78) / 0.22)   # gilt rim
                c.put(x, y, addv(shell, snoise(x, y, 81, 2) * 5))
    # tarnished gold sword-and-crossguard emblem with shadow
    c.vline(ccx + 1, ccy - 11, ccy + 13, BLACK)
    c.vline(ccx, ccy - 12, ccy + 12, lerp(GOLD_L, GOLD_H, 0.4))
    c.hline(ccx - 9, ccx + 10, ccy - 3, lerp(GOLD_M, GOLD_L, 0.5))
    c.hline(ccx - 9, ccx + 10, ccy - 2, GOLD_D)
    c.disc(ccx, ccy - 12, 2, GOLD_H)
    c.disc(ccx, ccy + 11, 1, GOLD_D)


# ── 5. placard ────────────────────────────────────────────────────────────────
def draw_placard(c):
    cx = (BX0 + BX1) // 2
    x0, y0, x1, y1 = cx - 122, BY0 + 22, cx + 122, BY0 + 54
    c.rect(x0 + 3, y1, x1 + 3, y1 + 4, BLACK, 110)                 # cast shadow
    for y in range(y0, y1):
        for x in range(x0, x1):
            d = min(x - x0, y - y0, x1 - 1 - x, y1 - 1 - y)
            lit = ((x - x0) == d or (y - y0) == d)
            if d == 0: col = BLACK
            elif d == 1: col = WOOD_L if lit else WOOD_D
            elif d == 3: col = lerp(GOLD_D, GOLD_M, 0.5)
            else: col = lerp(WOOD_D, WOOD_M, 0.4)
            col = addv(col, snoise(x, y, 91, 2) * 5)
            if snoise(x, y, 63, 4) > 0.74: col = lerp(col, BLACK, 0.4)  # cracks
            c.put(x, y, col)
    for nx in (x0 + 6, x1 - 7):
        c.disc(nx, y0 + 6, 2, lerp(GOLD_D, RUST_A, 0.5)); c.put(nx - 1, y0 + 5, GOLD_L)
    faux(c, cx, y0 + 12, 100, 3, GOLD_L, 3)
    faux(c, cx, y0 + 23, 74, 2, GOLD_D, 4)


def faux(c, cx, cy, width, thick, rgb, gap, seed=1, jitter=True):
    x, end = cx - width // 2, cx + width // 2
    while x < end:
        gw = 2 + (noise(x, seed, 3) + 8) % 5
        for yy in range(cy, cy + thick):
            for xx in range(x, min(x + gw, end)):
                c.put(xx, yy, rgb, 235)
        x += gw + gap


# ── 6. verb glyphs, wax seal, pips, vignette ─────────────────────────────────
def g_cross(c, x, y): c.vline(x, y - 5, y + 6, GOLD_L); c.hline(x - 3, x + 4, y - 1, GOLD_L)
def g_relic(c, x, y): c.ring(x, y, 5, GOLD_L); c.disc(x, y, 1, GOLD_L)
def g_hunt(c, x, y):
    for i in range(-4, 5): c.put(x + i, y + i, GOLD_L); c.put(x + i, y - i, GOLD_L)
def g_eye(c, x, y):
    c.ring(x, y, 5, GOLD_L); c.disc(x, y, 2, GOLD_L)
VERBS = [g_cross, g_relic, g_hunt, g_eye]


def draw_seal(c, cx, cy, sigil, r=8):
    c.disc(cx + 1, cy + 2, r, BLACK, 120)                          # shadow
    c.disc(cx, cy, r, WAX_D)
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                sh = 0.5 - ((x - cx) + (y - cy)) / (r * 3.0)       # top-left lit
                c.put(x, y, lerp(WAX_M, WAX_H, max(0, sh)))
    c.ring(cx, cy, r, WAX_D)
    c.rect(cx - 1, cy + r - 1, cx + 2, cy + r + 4, WAX_M)          # drip
    c.put(cx + 1, cy + r + 3, WAX_D)
    p = lerp(WAX_H, PAR_H, 0.6)
    if sigil == 'BELIEF': c.ring(cx, cy, 3, p); c.put(cx, cy, p)
    elif sigil == 'SIN': c.vline(cx, cy - 3, cy + 4, p); c.hline(cx - 2, cx + 3, cy, p)
    else:
        for i in range(4):
            c.put(cx, cy - 3 + i, p); c.put(cx, cy + 3 - i, p)
            c.put(cx - 3 + i, cy, p); c.put(cx + 3 - i, cy, p)


def draw_pips(c, x0, cy, filled, total=5):
    for i in range(total):
        px = x0 + i * 11
        on = i < filled
        for dy in range(-4, 5):
            span = 4 - abs(dy)
            for dx in range(-span, span + 1):
                col = lerp(WAX_M, WAX_H, 0.4) if on else lerp(INK_SOFT, PAR_D, 0.5)
                c.put(px + dx, cy + dy, col)
            c.put(px - span, cy + dy, INK if on else INK_SOFT)
            c.put(px + span, cy + dy, INK if on else INK_SOFT)


def draw_vignette(c, cx, cy, kind):
    ink = INK_SOFT
    if kind == 0:
        c.rect(cx - 9, cy, cx + 9, cy + 11, ink, 80)
        for i in range(7): c.hline(cx - i, cx + i + 1, cy - 6 + i, ink, 110)
        c.vline(cx, cy - 11, cy - 6, ink, 130); c.hline(cx - 2, cx + 3, cy - 9, ink, 130)
    elif kind == 1:
        c.rect(cx - 7, cy, cx + 7, cy + 11, ink, 80)
        for i in range(-6, 7):
            c.put(cx + i, cy - 5 + abs(i) // 2, ink, 100)
            c.put(cx + i, cy - 1 - abs(i) // 2, ink, 100)
    else:
        for i in range(-10, 11): c.put(cx + i, cy + 5 - (5 - abs(i % 10 - 5)), ink, 100)


# ── 7. aged parchment notice card ────────────────────────────────────────────
def draw_card(c, x, y, w, h, verb, sigil, filled, vign, age, hovered=False):
    c.rect(x + 3, y + 4, x + w + 3, y + h + 4, BLACK, 130)         # drop shadow
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            lx, rx2 = xx - x, x + w - 1 - xx
            ty2, by = yy - y, y + h - 1 - yy
            # torn/deckled edges (baked), worse with age
            bite = 1 + int((noise(yy, 1, verb) + 8) % (2 + age))
            biteh = 1 + int((noise(xx, 2, verb) + 8) % 2)
            if lx < bite or rx2 < bite or ty2 < biteh or by < biteh:
                continue
            d = min(lx, rx2, ty2, by)
            cxn, cyn = x + w / 2.0, y + h / 2.0
            rr = ((xx - cxn) / (w / 2)) ** 2 + ((yy - cyn) / (h / 2)) ** 2
            base = lerp(PAR_H, PAR_M, min(0.9, rr * 0.4))
            base = lerp(base, PAR_D, age * 0.18)                  # older = darker/greyer
            base = addv(base, snoise(xx, yy, 9 + verb, 2) * 6)
            # foxing blotches
            f = snoise(xx, yy, 40 + verb, 6)
            if f > 0.5 - age * 0.15: base = lerp(base, FOX, (f - 0.3) * 0.5)
            # brown water stain rings (one per card, seeded)
            sxc, syc = x + 20 + (verb * 37) % (w - 40), y + 30 + (verb * 53) % (h - 50)
            sr = math.hypot(xx - sxc, yy - syc)
            if abs(sr - (16 + age * 4)) < 2: base = lerp(base, STAIN, 0.4)
            elif sr < 16 + age * 4: base = lerp(base, STAIN, 0.12)
            if d <= 1: base = lerp(base, INK_SOFT, 0.4)           # fibre edge shadow
            if hovered: base = lerp(base, PAR_H, 0.4)
            c.put(xx, yy, base)
    # curled top-right corner shadow
    for k in range(6):
        c.hline(x + w - 8 + k, x + w - 2, y + 2 + k, BLACK, 60)
    VERBS[verb % 4](c, x + 13, y + 15)
    draw_seal(c, x + w - 14, y + 14, sigil)
    faux(c, x + w // 2, y + 29, w - 40, 4, INK, 3, verb)
    faux(c, x + w // 2, y + 39, w - 58, 2, INK_SOFT, 4, verb + 7)
    c.hline(x + 12, x + w - 12, y + 47, INK_SOFT, 120)
    draw_pips(c, x + 12, y + 59, filled)
    draw_vignette(c, x + w - 17, y + h - 14, vign)
    # tack (rusty nail head)
    c.disc(x + w // 2, y + 2, 2, IRON_M); c.put(x + w // 2 - 1, y + 1, IRON_L)
    c.put(x + w // 2 + 1, y + 3, RUST_A)
    if hovered:
        for t in range(2):
            col = GOLD_L if t == 0 else GOLD_D
            c.hline(x - 3 + t, x + w + 3 - t, y - 3 + t, col)
            c.hline(x - 3 + t, x + w + 3 - t, y + h + 2 - t, col)
            c.vline(x - 3 + t, y - 3 + t, y + h + 3 - t, col)
            c.vline(x + w + 2 - t, y - 3 + t, y + h + 3 - t, col)


# ── 8. bottom legends + active assignment (ref-faithful) ─────────────────────
def draw_panel(c, x0, y0, x1, y1):
    c.rect(x0 + 2, y0 + 3, x1 + 2, y1 + 3, BLACK, 110)
    for y in range(y0, y1):
        for x in range(x0, x1):
            d = min(x - x0, y - y0, x1 - 1 - x, y1 - 1 - y)
            if d == 0: col = BLACK
            elif d == 1: col = lerp(WOOD_M, WOOD_L, 0.4)
            else: col = lerp(WOOD_D, WOOD_M, 0.3)
            c.put(x, y, addv(col, snoise(x, y, 95, 2) * 4))


def build():
    c = Canvas(W, H, BLACK)
    draw_wall(c)
    draw_banner(c, GUT_L); draw_banner(c, GUT_R)
    draw_frame_shadow(c)
    draw_backing(c)
    draw_frame(c)
    draw_placard(c)

    ix0, ix1 = BX0 + BB + 6, BX1 - BB - 6
    grid_top = BY0 + 60
    legend_h, strip_gap = 40, 8
    grid_bot = BY1 - BB - legend_h - 12
    cols, rows, gap = 4, 2, 8
    cw = (ix1 - ix0 - (cols - 1) * gap) // cols
    ch = (grid_bot - grid_top - (rows - 1) * gap) // rows
    slots = [
        (0, 'SIN', 2, 0, 1), (1, 'RELIC', 3, 1, 3), (3, 'BELIEF', 1, 2, 0), (2, 'SIN', 4, 0, 2),
        (0, 'BELIEF', 1, 2, 2), (1, 'SIN', 3, 1, 1), (3, 'RELIC', 2, 0, 3), None,
    ]
    for i, s in enumerate(slots):
        col, row = i % cols, i // cols
        cx, cy = ix0 + col * (cw + gap), grid_top + row * (ch + gap)
        if s is None:
            c.disc(cx + cw // 2, cy + 3, 2, IRON_D); continue     # empty pin
        verb, sig, fill, vig, age = s
        draw_card(c, cx, cy, cw, ch, verb, sig, fill, vig, age, hovered=(i == 1))

    # bottom row: [left icon legend] [ACTIVE ASSIGNMENT] [right status]
    ly = BY1 - BB - legend_h - 2
    lw = 84
    draw_panel(c, ix0, ly, ix0 + lw, ly + legend_h)               # verb legend
    for k in range(4):
        yy = ly + 6 + k * 8
        VERBS[k](c, ix0 + 10, yy + 2)
        faux(c, ix0 + 46, yy, 40, 2, PAR_M, 3, k)
    draw_panel(c, ix1 - lw, ly, ix1, ly + legend_h)               # status legend
    for k, col in enumerate((WAX_M, lerp(GOLD_M, PAR_M, .4), IRON_M)):
        yy = ly + 8 + k * 10
        c.disc(ix1 - lw + 12, yy, 4, col); faux(c, ix1 - lw + 44, yy - 1, 44, 2, PAR_M, 3, k)
    # active assignment center
    ax0, ax1 = ix0 + lw + 8, ix1 - lw - 8
    draw_panel(c, ax0, ly, ax1, ly + legend_h)
    c.hline(ax0, ax1, ly, GOLD_D)
    faux(c, (ax0 + ax1) // 2, ly + 4, 108, 2, GOLD_D, 4)
    draw_seal(c, ax0 + 18, ly + 22, 'SIN', 7)
    faux(c, ax0 + 90, ly + 16, 96, 3, PAR_H, 3)
    faux(c, ax0 + 78, ly + 28, 66, 2, INK_SOFT, 4)
    draw_vignette(c, ax1 - 16, ly + 26, 0)

    light_pass(c)
    draw_torch(c, *TORCH[0]); draw_torch(c, *TORCH[1])            # flames sit above the light
    return c


# ── 9. baked warm light pass (previews the Godot Light2D + shader) ────────────
def light_pass(c):
    for y in range(H):
        for x in range(W):
            # warm key from the two torches + soft center fill
            key = 0.0
            for (tx, ty) in TORCH:
                key += 0.9 * math.exp(-((x - tx) ** 2 / 2600.0 + (y - ty) ** 2 / 3400.0))
            key += 0.45 * math.exp(-(((x - W / 2) ** 2) / 90000.0 + ((y - H / 2) ** 2) / 34000.0))
            b = 0.42 + min(1.15, key)                             # ambient + key
            # cool falloff at the far edges (vignette)
            nx, ny = (x - W / 2) / (W / 2), (y - H / 2) / (H / 2)
            b -= max(0.0, (nx * nx * 0.55 + ny * ny * 0.7) - 0.35) * 0.7
            b = max(0.16, b)
            d = c.get(x, y)
            warm = (1.0 + 0.16 * min(1.0, key), 1.0, 1.0 - 0.12 * min(1.0, key))  # warm where lit
            c.px[y * c.w + x] = [clamp(d[0] * b * warm[0]), clamp(d[1] * b * warm[1]),
                                 clamp(d[2] * b * warm[2]), 255]
            # ember bloom right at the torch cores
            for (tx, ty) in TORCH:
                dd = (x - tx) ** 2 + (y - (ty - 8)) ** 2
                if dd < 120:
                    a = (1 - dd / 120) * 0.5
                    e = c.px[y * c.w + x]
                    c.px[y * c.w + x] = [clamp(e[0] + FLAME_M[0] * a), clamp(e[1] + FLAME_M[1] * a),
                                         clamp(e[2] + FLAME_C[2] * a), 255]


def emit(c):
    ow, oh = W * SCALE, H * SCALE
    def up(x, y):
        d = c.get(x // SCALE, y // SCALE); return (d[0], d[1], d[2], 255)
    out = os.path.join(HERE, "_src", "_proto_board.png")
    write_png(out, ow, oh, up)
    print("wrote", out, "%dx%d" % (ow, oh))


if __name__ == "__main__":
    emit(build())
