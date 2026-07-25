"""Reference A's camera, from two vanishing points — take 3.

The runner is a dead end: in this picture it is faded and broken up, and per-row red runs pick up
banner reflection on the wet flags more often than carpet. So the NAVE vanishing point comes from
the receding near-horizontal lines instead (arcade cornices, string courses, the vault's ridge),
fitted separately on the left and right halves.

That swap brings a free validity check with it: the hall is symmetric about its axis, so two
correctly-fitted receding lines MUST intersect at fx = 0.5. If they do not, the fit is wrong and
the number is thrown away rather than used.
"""
import math
from PIL import Image

import sys
SRC = sys.argv[1] if len(sys.argv) > 1 else "art/src/collegium_hall_ref_a.jpeg"
im = Image.open(SRC).convert("RGB")
W, H = im.size
SC = 3
sw, sh = W // SC, H // SC
sp = im.convert("L").resize((sw, sh)).load()


def edges(vertical):
    out = []
    for y in range(1, sh - 1):
        for x in range(1, sw - 1):
            gx = sp[x + 1, y] - sp[x - 1, y]
            gy = sp[x, y + 1] - sp[x, y - 1]
            if vertical:
                if abs(gx) > 16 and abs(gx) > abs(gy) * 2.0 and y < sh * 0.62:
                    out.append((x, y, abs(gx)))
            else:
                if abs(gy) > 14 and abs(gy) > abs(gx) * 2.0:
                    out.append((x, y, abs(gy)))
    return out


VERT, HORIZ = edges(True), edges(False)
print("edge points: %d vertical, %d horizontal" % (len(VERT), len(HORIZ)))


def hough_v(pts, x0, x1, want_neg):
    acc = {}
    for x, y, w in pts:
        if not (x0 <= x < x1):
            continue
        for i in range(-34, 35):
            s = i * 0.008
            if (s < 0) != want_neg or abs(s) < 0.02:
                continue
            k = (i, int((x - s * (y - sh / 2.0)) / 2))
            acc[k] = acc.get(k, 0) + w
    (i, xb), v = max(acc.items(), key=lambda kv: kv[1])
    return i * 0.008, xb * 2 + 1, v


def hough_h(pts, x0, x1):
    acc = {}
    for x, y, w in pts:
        if not (x0 <= x < x1):
            continue
        for i in range(-40, 41):
            s = i * 0.010                                  # dy/dx
            if abs(s) < 0.03:
                continue
            k = (i, int((y - s * (x - sw / 2.0)) / 2))
            acc[k] = acc.get(k, 0) + w
    (i, yb), v = max(acc.items(), key=lambda kv: kv[1])
    return i * 0.010, yb * 2 + 1, v


# ── the zenith, from converging verticals ───────────────────────────────────
sl, xl, _ = hough_v(VERT, int(sw * 0.03), int(sw * 0.30), True)
sr, xr, _ = hough_v(VERT, int(sw * 0.70), int(sw * 0.97), False)
y_zen = (xr - xl) / (sl - sr) + sh / 2.0
x_zen = xl + sl * (y_zen - sh / 2.0)
print("zenith:   fx %.3f  fy %.4f   (symmetry wants fx 0.5)" % (x_zen / sw, y_zen / sh))

# ── the nave VP, from receding horizontals ──────────────────────────────────
hl, yl, wl = hough_h(HORIZ, int(sw * 0.04), int(sw * 0.42))
hr, yr, wr = hough_h(HORIZ, int(sw * 0.58), int(sw * 0.96))
print("left  horizontal dy/dx %+.3f (weight %d)" % (hl, wl))
print("right horizontal dy/dx %+.3f (weight %d)" % (hr, wr))
x_vp = (yr - yl) / (hl - hr) + sw / 2.0
y_vp = yl + hl * (x_vp - sw / 2.0)
print("nave VP:  fx %.3f  fy %.4f   (symmetry wants fx 0.5)" % (x_vp / sw, y_vp / sh))

ok = abs(x_vp / sw - 0.5) < 0.06 and abs(x_zen / sw - 0.5) < 0.10
print("\nsymmetry check: %s" % ("PASS" if ok else "FAIL — fit rejected"))
if ok:
    fy_vp, fy_zen = y_vp / sh, y_zen / sh
    d1, d2 = 2 * (fy_vp - 0.5), 2 * (0.5 - fy_zen)
    if d1 > 0 and d2 > 0:
        tan_v = 1.0 / math.sqrt(d1 * d2)
        tan_h = tan_v * (W / float(H))
        print("PITCH  %.1f deg   (ours today 21.0)" % math.degrees(math.atan(math.sqrt(d1 / d2))))
        print("VFOV   %.1f deg" % (2 * math.degrees(math.atan(tan_v))))
        print("HFOV   %.1f deg   (ours today 105.0)" % (2 * math.degrees(math.atan(tan_h))))
    else:
        print("degenerate: VP below centre or zenith below the frame")
