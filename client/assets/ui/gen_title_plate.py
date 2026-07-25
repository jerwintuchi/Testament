#!/usr/bin/env python3
"""gen_title_plate.py — the title screen's architecture plate: `title/hall_plate.png` (TD-073).

An EMPTY High Gothic nave, painted by ray-casting the hall's planes through the camera TD-072
measured off the author's reference (hfov 105°, pitched up 15°, Chartres' 16m x 37m proportions).
That camera is imported from `gen_nave.py` rather than re-derived — it was the one part of the
single-plate attempt that was correct, and re-measuring it would only introduce drift.

**This deliberately retries what TD-072 recorded as a failure**, and the retry is narrower in the
two places that failed:

  * *"Small props at small scale."* A drawn flame failed four times there. Here the plate carries
    NO props at all — no flames, no candles, no censers, no banners. Every one of them is a
    separate animated layer over this image (`title_scene.gd`), which is what the asset manifest
    asks for. The failure mode is not present because the content is not present.
  * *"Light as arithmetic."* TD-072 baked falloff over a stepped ramp and it banded. Here the
    plate is lit only by AMBIENT and by the distant apse; all seven fires are in-engine additive
    pools that flicker (TD-043). Nothing baked has to pretend to be a light source, the surface
    stays in the painted register (R242 — no palette quantisation), and an ordered dither keeps
    the long gradients smooth.

What remains of TD-072's third finding — *"symmetry and uniformity"* — is answered directly: every
bay is seeded, the two side walls weather differently, the clerestory's glass varies panel to
panel with some lights blocked, and the ashlar's course height drifts per bay. An analytic wall
repeating exactly is the tell that reads as generated.

Run from client/assets/ui/:
    python3 gen_title_plate.py                    -> title/hall_plate.png (1920x1080)
    python3 gen_title_plate.py --preview          -> a fast 480x270 look, to $PLATE_OUT
"""
import math
import os
import sys

import ashember as A
from gen_nave import (ARC_HALF, ARC_SPRING, BAY, CLR_HALF, CLR_SPRING, HALF_W, TRI_HALF, TRI_HI,
                      TRI_LO, Z_FAR, hit, lancet, project, ray)

W, H = 1920, 1080            # the manifest's plate size; 16:9, the same aspect gen_nave measured

BLACK = (7, 6, 8)
# A warm distance haze: centuries of candle smoke hanging in the air. This is what makes depth
# read as LUMINANCE — the near piers fall to silhouette against a distance that opens into light.
HAZE = A.lerp_rgb(A.RAMP["navestone"][3], A.RAMP["gold"][0], 0.34)
GLASS = A.lerp_rgb(A.RAMP["stone"][3], A.RAMP["parchment"][3], 0.52)


def bay_seed(i, salt):
    """0..1, stable per bay. The whole answer to TD-072's 'analytic bays repeat exactly'."""
    return (A.noise(int(i), 91, int(salt)) + 8) / 16.0


def _apseglow(fx, fy):
    """The lit east end — the plate's only light source, and deliberately gentle: the menu is
    read over the middle of this image (R245), so the distance opens rather than blazes."""
    pr = project(0.0, 12.0, Z_FAR - 2.0)
    if pr is None:
        return 0.0
    ax, ay, _ = pr
    dxs = (fx - ax) / 0.190
    dys = (fy - ay) / 0.150
    return max(0.0, 1.0 - A.smooth(0.0, 1.0, math.sqrt(dxs * dxs + dys * dys))) ** 1.5


_DITHER = ((0, 8, 2, 10), (12, 4, 14, 6), (3, 11, 1, 9), (15, 7, 13, 5))


def _dither(base, x, y):
    """Break the long falloffs so they cannot contour. Cheaper and truer than adding noise."""
    k = (_DITHER[y & 3][x & 3] / 16.0 - 0.5) * 5.0
    return (base[0] + k, base[1] + k, base[2] + k)


def _wall(fx, a, b, near, side, x, y):
    """One point on a side wall: three storeys of pointed openings between compound piers."""
    h = b                                            # metres up the wall
    loc = (a / BAY) % 1.0
    dp = abs(loc - 0.5) * BAY                        # metres from the bay's centre
    bi = int(a / BAY)
    # The two walls are NOT mirrors. The left has taken the weather and the smoke; the right is
    # drier and paler. In the reference this asymmetry is the first thing that says "real place".
    grime = 0.34 + 0.30 * bay_seed(bi, side * 3) + (0.16 if side < 0 else 0.0)

    base = A.ramp_shade("navestone", 0.11 + 0.17 * near)
    # The openings are not identical, and the two walls are not mirrors of each other. A hall
    # whose every bay is the same width is the giveaway TD-072 could not shake; ±6% is invisible
    # as a measurement and decisive as a texture.
    arc_half = ARC_HALF * (0.94 + 0.12 * bay_seed(bi, side * 23))
    clr_half = CLR_HALF * (0.95 + 0.10 * bay_seed(bi, side * 29))
    in_arc = dp < arc_half and h < lancet(dp, arc_half, ARC_SPRING)
    in_clr = dp < clr_half and CLR_SPRING < h < lancet(dp, clr_half, CLR_SPRING)
    in_tri = dp < TRI_HALF and TRI_LO < h < TRI_HI and bay_seed(bi, side * 31) > 0.18

    if in_arc and h > 0.4:
        # Through into the aisle. Not a flat black hole: the far bays catch the haze, so the
        # arcade reads as a row of openings into a space, which is the arch's whole job.
        base = A.lerp_rgb(BLACK, HAZE, 0.05 + 0.26 * (1.0 - near))
    elif in_clr:
        # The glazed storey. Panel brightness varies bay to bay, and a few lights are blocked or
        # boarded — a cathedral that has stood for centuries does not have a perfect clerestory.
        lit = 0.34 + 0.66 * bay_seed(bi, side * 7)
        if bay_seed(bi, side * 11) < 0.20:
            lit *= 0.20                              # boarded, or simply dark on this side
        # Stained glass, so the panels are not one colour: each bay leans amber or rose or cold.
        tint = bay_seed(bi, side * 17)
        pane = A.lerp_rgb(A.RAMP["gold"][3], A.RAMP["wax"][2], max(0.0, tint - 0.55) * 2.0)
        if tint < 0.28:
            pane = A.lerp_rgb(pane, A.RAMP["stone"][4], 0.55)      # a cold light on this bay
        mull = abs(((dp / (clr_half * 0.42)) % 1.0) - 0.5)
        # The glazed storey is the plate's own light — the brief's "stained glass high on both
        # walls" — so it glows on its own terms, and unlike a prop hotspot it cannot fight the
        # in-engine fires: they burn far below it.
        base = A.lerp_rgb(BLACK, pane, 0.34 + 0.52 * lit)
        if mull > 0.40:
            base = A.over(base, A.RAMP["stone"][0], 0.70)          # stone mullions
    elif in_tri:
        base = A.lerp_rgb(BLACK, A.RAMP["navestone"][1], 0.28)
    else:
        # Pier face quantised into colonnettes, each shaded as a half-round, so a flat wall reads
        # as a BUNDLE OF SHAFTS — the whole Gothic tell.
        sp = (dp / 0.95) % 1.0
        base = A.over(base, A.RAMP["navestone"][4], 0.25 * math.sin(sp * math.pi))
        if sp < 0.07 or sp > 0.93:
            base = A.over(base, BLACK, 0.25)                       # seam between shafts
        if abs(h - ARC_SPRING) < 0.55 or abs(h - TRI_HI) < 0.35 or abs(h - CLR_SPRING) < 0.40:
            base = A.over(base, A.RAMP["navestone"][5], 0.42)      # capitals, string-course
        base = A.over(base, A.RAMP["navestone"][1], 0.07 * (A.noise(x, y // 3, 7) + 8) / 16.0)
        # Coursed ashlar: ~0.85m beds with staggered perpends. The bed height DRIFTS per bay,
        # because a hand-laid wall does not hold one course height for 100 metres.
        ch = 0.85 * (0.93 + 0.15 * bay_seed(bi, 5))
        course = h / ch
        bed = abs((course % 1.0) - 0.5)
        perp = abs(((a / 1.7 + 0.5 * (int(course) % 2)) % 1.0) - 0.5)
        if bed > 0.455 or perp > 0.478:
            base = A.over(base, A.RAMP["navestone"][0], 0.32 * min(1.0, near * 1.6))
        # Pale salts have run down from the sills over centuries, unevenly.
        if CLR_SPRING - 5.0 < h < CLR_SPRING and (A.noise(int(a * 3.0), 0, 21) + 8) > 11:
            base = A.over(base, A.RAMP["navestone"][5], 0.15 * (1.0 - (CLR_SPRING - h) / 5.0))

    # Soot: gathered thickest low on the wall where the fires have always stood, and it is the
    # per-bay grime that keeps the arcade from repeating.
    base = A.over(base, BLACK, grime * 0.30 * math.exp(-max(0.0, h - 1.0) / 9.0))
    return base


def _vault(a, b, near):
    """Ribbed quadripartite bays: diagonals crossing at a boss, transverse ribs, sunk webs."""
    cross = b / HALF_W
    loc = (a / BAY) % 1.0
    bi = int(a / BAY)
    base = A.ramp_shade("navestone", 0.05 + 0.09 * near)
    # The vault directly overhead is the closest surface in the frame and the furthest from any
    # fire, so it is very nearly black; only the far bays are read at all. Ribs picked out at
    # full contrast the whole way down the nave were TD-072's loudest "generated" tell.
    base = A.over(base, BLACK, 0.30 + 0.46 * near)
    rw = 0.085
    diag = abs(abs(cross) - abs(2.0 * loc - 1.0))
    rib = 0.30 * (1.0 - 0.72 * near)
    if diag < rw or min(loc, 1.0 - loc) < rw * 0.45:
        base = A.over(base, A.RAMP["navestone"][4], rib)
        if diag < rw * 0.5 and abs(loc - 0.5) < 0.10:
            base = A.over(base, A.RAMP["navestone"][5], rib * 0.9)  # the boss
    elif abs(cross) < rw * 0.4:
        base = A.over(base, A.RAMP["navestone"][3], rib * 0.7)      # ridge rib
    else:
        if abs(((a / 1.15) % 1.0) - 0.5) > 0.44:
            base = A.over(base, A.RAMP["navestone"][0], 0.24)      # the webs are laid courses too
        # Centuries of smoke along the crown, heavier over some bays than others.
        smoke = 0.20 + 0.22 * bay_seed(bi, 13)
        base = A.over(base, BLACK, smoke * max(0.0, 1.0 - abs(cross) / 0.55))
    return base


def _floor(a, b, near, x, y):
    """Worn flags, a processional runner rubbed pale, and sunk ledger slabs along the aisles."""
    base = A.ramp_shade("navestone", 0.07 + 0.11 * near)
    worn = max(0.0, 1.0 - abs(b) / 3.0)
    jw = 0.455 + 0.022 * worn
    if abs(((a / 1.9) % 1.0) - 0.5) > jw or abs(((b / 1.9) % 1.0) - 0.5) > jw:
        base = A.over(base, BLACK, 0.55 - 0.22 * worn)             # flag joints
    else:
        base = A.over(base, A.RAMP["navestone"][4], 0.12 * worn)
    if abs(b) < 2.15:
        # The runner: deep red cloth down the centre, faded along the line everyone walks.
        edge = A.smooth(2.15, 1.75, abs(b))
        tread = max(0.0, 1.0 - abs(b) / 1.30)
        base = A.lerp_rgb(A.RAMP["wax"][0], A.RAMP["wax"][1], 0.14 * edge)
        base = A.over(base, BLACK, 0.52 - 0.13 * edge)
        base = A.over(base, A.RAMP["parchment"][0], 0.13 * tread)  # worn threadbare down the spine
        if abs(abs(b) - 1.85) < 0.13:
            base = A.over(base, A.RAMP["gold"][0], 0.34)           # a dulled gold border
    if abs(b) > 3.4 and (A.noise(int(a / 1.9), int(b / 1.9), 33) + 8) > 13:
        base = A.over(base, A.RAMP["navestone"][1], 0.28)          # incised memorial slabs
    else:
        base = A.over(base, A.RAMP["navestone"][1],
                      0.07 * (A.noise(x // 2, y // 2, 11) + 8) / 16.0)
    return base


def _apse(a, b):
    """The far end: three tall lancets standing in the light, and a rose above them. The
    composition's destination — the eye is walked down the nave to here.

    Held DOWN deliberately. This is the brightest thing in the frame and it sits dead centre,
    where the menu's last option is read; at a second integer scale that put "Quit" on the one
    bright patch in the hall. R245 asks the composition's centre to stay quiet, and the honest
    fix is the environment answering for itself, not a scrim behind the UI."""
    base = A.ramp_shade("navestone", 0.13)
    # Three lancets, 1.5m apart, springing high: tall and narrow, so the far end reads as a
    # window and not as a lit doorway.
    if abs(b) < 2.4 and 9.0 < a < lancet(abs((b + 2.4) % 1.6 - 0.8), 0.62, 20.5):
        mull = abs(((b + 2.4) / 1.6) % 1.0 - 0.5)
        base = A.lerp_rgb(A.lerp_rgb(GLASS, A.RAMP["parchment"][3], 0.32), BLACK, 0.34)
        if mull > 0.38:
            base = A.over(base, A.RAMP["stone"][0], 0.74)          # the stone between lights
    else:
        rose = math.hypot(b / 1.30, (a - 27.0) / 1.30)
        if rose < 1.0:
            base = A.lerp_rgb(A.lerp_rgb(GLASS, A.RAMP["gold"][2], 0.34), BLACK, 0.30)
            spoke = abs((math.atan2(a - 27.0, b) / math.pi * 6.0) % 1.0 - 0.5)
            if spoke > 0.34 or rose > 0.86:
                base = A.over(base, A.RAMP["stone"][0], 0.70)      # tracery
    return base


def plate_px(x, y, w, h):
    fx, fy = (x + 0.5) / w, (y + 0.5) / h
    kind, a, b, dist = hit(fx, fy)
    near = min(1.0, 14.0 / max(dist, 1.0))               # 1 close, -> 0 far

    if kind == "apse":
        base = _apse(a, b)
    elif kind == "floor":
        base = _floor(a, b, near, x, y)
    elif kind == "vault":
        base = _vault(a, b, near)
    else:
        side = -1 if ray(fx, fy)[0] < 0.0 else 1
        base = _wall(fx, a, b, near, side, x, y)

    # ── Light. AMBIENT ONLY: every flame in this scene is an in-engine layer (TD-043), so the
    #    plate must not carry a hotspot that would fight a real one (asset-manifest rule 6).
    #    Which settles the direction of the gradient: the NEAR falls to silhouette, because in
    #    the finished scene the near is lit by real fires that are not in this image. A plate
    #    that pre-lights its own foreground would be lit twice.
    if kind != "apse":
        base = A.lerp_rgb(base, BLACK, 0.66 * near ** 1.05)
    depth = min(1.0, max(0.0, (dist - 18.0) / 70.0))
    base = A.over(base, HAZE, 0.31 * depth ** 1.5)       # aerial perspective, warm with smoke
    glow = _apseglow(fx, fy)
    base = A.over(base, A.lerp_rgb(GLASS, A.RAMP["parchment"][2], 0.35), min(0.30, glow * 0.30))

    # Deep shadow at the frame's edge, so the eye is driven down the nave and the corners stay
    # quiet under the UI.
    v = max(abs(fx - 0.5) / 0.5, abs(fy - 0.5) / 0.5)
    base = A.lerp_rgb(base, BLACK, 0.66 * A.smooth(0.44, 1.08, v))
    r, g, b_ = A.clamp_rgb(_dither(base, x, y))
    return (int(r), int(g), int(b_), 255)


def main(argv):
    preview = "--preview" in argv
    w, h = (480, 270) if preview else (W, H)

    def px(x, y):
        return plate_px(x, y, w, h)

    if preview:
        out = os.environ.get("PLATE_OUT", "/tmp/hall_plate_preview.png")
        A.write_png(out, w, h, px)                # a variable path: a dev aid, not a shipped edge
        print("gen_title_plate preview %dx%d -> %s" % (w, h, out))
        return 0
    os.makedirs(os.path.join(os.path.dirname(os.path.abspath(__file__)), "title"), exist_ok=True)
    # A LITERAL relative path, run from client/assets/ui/ (canon S5b): tools/asset_map.py derives
    # producer edges from this string, so an os.path.join here silently drops the producer.
    A.write_png("title/hall_plate.png", w, h, px)
    print("gen_title_plate OK — the empty nave plate, %dx%d, ambient-lit, no props." % (w, h))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
