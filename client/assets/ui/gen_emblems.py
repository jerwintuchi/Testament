#!/usr/bin/env python3
"""gen_emblems.py — hand-painted raster wax seals + verb badges (TD-046).

Replaces the runtime-drawn `wax_seal.gd` / `verb_badge.gd` vector primitives with
authored raster PNGs, per the single canonical register (hand-painted raster 2D pixel
art). Stdlib only (imports `ashember` for the PNG writer + ramps), so the user can
regenerate; new files are imported headlessly (`godot --headless --import`).

Light convention (board-wide): a single soft KEY from the UPPER-LEFT. Every emblem is
lit top-left, shadowed bottom-right, with a contact drop-shadow down-right — so all
props agree on one light. The torches remain a warm additive FILL (no hard shadow).

Emits:
  seal_collegium.png                               48x48  the ONE generic wax seal — oxblood
                                                          wax, the Collegium device debossed
                                                          (@consumes collegium_logo.png). The
                                                          leader's stamp (TD-060); Origin seals
                                                          are RETIRED → art/archive/.
  badge_investigate/eliminate/capture/banish.png   24x24  pale sigil on transparent
                                                          (tinted ink/gilt at runtime)
"""
import math
from PIL import Image
import ashember as A

SS = 3  # supersample factor for painterly (anti-aliased) edges

# The Collegium's wax (deep shadow, base, highlight, rim): OXBLOOD — the order's colour,
# deliberately not any Origin hue (those seals are archived, TD-060). The debossed device
# is the canonical Collegium emblem, read from collegium_logo.png (gen_logo.py output).
COLLEGIUM_WAX = {"deep": (52, 18, 16), "base": (104, 38, 32), "hi": (172, 102, 84), "rim": (30, 11, 10)}
EMB_SRC = "collegium_logo.png"

LX, LY = -0.66, -0.66   # key-light direction (points toward the light: upper-left)


def _clampf(v, a=0.0, b=1.0):
    return max(a, min(b, v))


# The Origin sigil masks + make_seal(origin) that painted seal_belief/sin/relic.png are
# ARCHIVED at art/archive/gen_origin_seals.py (TD-060), beside the PNGs they emitted.


def make_collegium_seal():
    # The ONE generic seal: oxblood wax, the Collegium device pressed into it. The device
    # mask is the canonical emblem's alpha (PIL to READ, ashember to EMIT — the gen_banner
    # producer-edge pattern), pre-scaled so the deboss keeps the blade/laurel legible at 48px.
    W = H = 48
    pal = COLLEGIUM_WAX
    cx, cy = 23.0, 22.0     # seal centre (a little high; drop-shadow lives at the base)
    R = 18.5
    scx, scy = cx + 2.2, cy + 3.0   # drop-shadow centre (down-right, one light)

    # Emblem mask, supersampled: fit the (portrait) device inside ~72% of the seal face.
    im = Image.open(EMB_SRC).convert("RGBA")
    eh = int(R * 2 * 0.84 * SS)
    ew = max(1, int(im.width * eh / im.height))
    emb = im.resize((ew, eh), Image.LANCZOS).getchannel("A").load()

    def device(dx, dy):
        # dx/dy in px from the seal centre → emblem-alpha lookup (supersampled grid).
        ex = int(dx * SS + ew / 2)
        ey = int(dy * SS + eh / 2)
        if 0 <= ex < ew and 0 <= ey < eh:
            return emb[ex, ey] > 110
        return False

    def sample(fx, fy):
        dx, dy = fx - cx, fy - cy
        d = math.hypot(dx, dy)
        # contact drop-shadow (under the wax, down-right) — soft, translucent black.
        sd = math.hypot(fx - scx, fy - scy)
        shadow_a = _clampf((R + 3.0 - sd) / 6.0) * 0.5 if sd < R + 3.0 else 0.0
        if d > R + 1.2:
            if shadow_a > 0.0:
                return (10, 8, 6, int(shadow_a * 255))
            return (0, 0, 0, 0)
        # domed wax: lambert-ish term from the upper-left key.
        nx, ny = dx / R, dy / R
        lit = _clampf(0.5 + 0.5 * (nx * LX + ny * LY) + (1.0 - d / R) * 0.18)
        body = A.lerp_rgb(pal["deep"], pal["hi"], lit)
        body = A.lerp_rgb(body, pal["base"], 0.35)     # keep it reading as the base hue
        # grain
        g = A.noise(int(fx), int(fy), 7) * 0.5
        body = (body[0] + g, body[1] + g, body[2] + g)
        # outer rim (the wax edge) — darkens the last ~1.5px, holds contrast on parchment.
        if d > R - 1.6:
            body = A.lerp_rgb(body, pal["rim"], _clampf((d - (R - 1.6)) / 1.6))
        # debossed device: recessed (toward deep), a lit lip where the recess catches the
        # key on its far (lower-right) wall — same relief language as the carved surfaces.
        if d < R * 0.94 and device(dx, dy):
            body = A.lerp_rgb(body, pal["deep"], 0.82)          # cut into the wax
            if device(dx - 0.7, dy - 0.7) and not device(dx + 0.6, dy + 0.6):
                body = A.lerp_rgb(body, pal["hi"], 0.55)
        return (A.clamp(body[0]), A.clamp(body[1]), A.clamp(body[2]), 255)

    return _supersample(W, H, sample)


def _badge_stroke(nx, ny, verb):
    """Signed coverage for a verb glyph in unit space (~[-1,1]); returns 0..1 ink."""
    def line(px, py, qx, qy, half):
        # distance from point (nx,ny) to segment p-q, as coverage inside `half` width.
        vx, vy = qx - px, qy - py
        L2 = vx * vx + vy * vy
        t = 0.0 if L2 == 0 else _clampf(((nx - px) * vx + (ny - py) * vy) / L2)
        ex, ey = px + t * vx, py + t * vy
        return _clampf((half - math.hypot(nx - ex, ny - ey)) / (half * 0.6))

    def ring(cx, cy, rad, half):
        d = abs(math.hypot(nx - cx, ny - cy) - rad)
        return _clampf((half - d) / (half * 0.6))

    def disc(cx, cy, rad):
        return _clampf((rad - math.hypot(nx - cx, ny - cy)) / 0.10)

    if verb == "investigate":          # an open eye
        r = math.hypot(nx, ny)
        lens = _clampf((0.16 - abs(r - 0.66)) / 0.10) if abs(ny) < 0.52 else 0.0
        return max(lens, disc(0, 0, 0.20))
    if verb == "eliminate":            # a skull
        cran = disc(0, -0.10, 0.52)
        jaw = 1.0 if (abs(nx) < 0.30 and 0.30 < ny < 0.62) else 0.0
        eyes = max(disc(-0.22, -0.14, 0.16), disc(0.22, -0.14, 0.16))
        return _clampf(max(cran, jaw) - eyes * 1.3)
    if verb == "capture":              # two shackle rings
        return max(ring(-0.34, 0, 0.34, 0.13), ring(0.34, 0, 0.34, 0.13))
    if verb == "banish":               # a cross
        return max(line(0, -0.72, 0, 0.72, 0.13), line(-0.42, -0.22, 0.42, -0.22, 0.13))
    return 0.0


def make_badge(verb):
    W = H = 24
    cx, cy, rad = 11.5, 11.5, 9.5

    def sample(fx, fy):
        nx, ny = (fx - cx) / rad, (fy - cy) / rad
        ink = _badge_stroke(nx, ny, verb)
        if ink <= 0.0:
            return (0, 0, 0, 0)
        # PALE sigil (near-white) with a faint painted value falloff, so runtime modulate
        # can tint it ink-on-parchment (cards) OR gilt-on-dark (legend) and keep its form.
        v = 236 + A.noise(int(fx), int(fy), 3)
        shade = 1.0 - _clampf((ny + 1.0) * 0.10)     # a touch darker toward the bottom
        v = A.clamp(v * (0.86 + 0.14 * shade))
        return (v, v, v, A.clamp(ink * 255))

    return _supersample(W, H, sample)


# ── Iron wall-sconce (T152) ──────────────────────────────────────────────────────
# A redrawn iron torch-holder: a shallow BOWL/cup at the top (holds the flame), an
# iron STEM hanging below it, and a WALL PLATE + rivet bolting the whole to the
# masonry. Lit top-left to match the board's one-key convention (gen_emblems header);
# the bowl's inner lip carries a faint warm underglow so it reads as holding fire even
# before the CPUParticles2D flame (T153) seats in its cup. 12x20 so `board_decor`'s
# existing seating math ("12x20 @1.4 -> 28h") is unchanged.
# Dungeon-dark iron (TD-048): near-black, WARM-neutral (firelit iron catches ember, not
# steel-blue). The sconce reads as a dark silhouette with only a faint warm rim where the
# flame above rakes its top-left edge — never a bright pale shape competing with the flame.
IRON_DEEP = (12, 11, 10)     # near-black warm iron (down-right, body)
IRON_BASE = (24, 21, 18)     # body mid
IRON_HI   = (58, 48, 36)     # dim warm top-left catch
IRON_RIM  = (98, 74, 44)     # warm ember rim on the up-left lip
EMBER_LO  = (120, 52, 18)    # dark ember (bowl interior floor)


def _seg_cov(nx, ny, px, py, qx, qy, half):
    """Coverage (0..1) of point (nx,ny) inside a rounded segment p-q of radius `half`."""
    vx, vy = qx - px, qy - py
    L2 = vx * vx + vy * vy
    t = 0.0 if L2 == 0 else _clampf(((nx - px) * vx + (ny - py) * vy) / L2)
    ex, ey = px + t * vx, py + t * vy
    return _clampf((half - math.hypot(nx - ex, ny - ey)) / 0.9)


def make_sconce():
    W, H = 12, 20
    cx = 6.0

    def sample(fx, fy):
        # Region coverages (in pixel space) --------------------------------------
        # POST: a thick vertical iron column (brazier stem, NOT a wine-glass stem) from
        # under the bowl to the wall plate — thickness is what stops the goblet read.
        stem = _seg_cov(fx, fy, cx, 6.8, cx, 14.5, 2.2)
        # WALL PLATE: a squat horizontal foot bolted to the masonry.
        plate = _seg_cov(fx, fy, cx - 3.0, 16.0, cx + 3.0, 16.0, 1.9)
        # BOWL: two iron walls sloping up-and-out from the post to a rim, with a cavity
        # between them the flame sits in. A tighter rim (less martini-flare) + thicker walls.
        wall_l = _seg_cov(fx, fy, cx - 3.6, 1.8, cx - 1.2, 6.4, 1.3)
        wall_r = _seg_cov(fx, fy, cx + 3.6, 1.8, cx + 1.2, 6.4, 1.3)
        rim = _seg_cov(fx, fy, cx - 3.7, 1.9, cx + 3.7, 1.9, 1.1)
        bowl = max(wall_l, wall_r, rim)
        iron = max(stem, plate, bowl)
        # CAVITY: interior of the bowl (above the post, between the walls) — warm.
        cav = 0.0
        if 2.1 < fy < 6.2:
            span = 3.5 - (fy - 2.1) * 0.66          # narrows downward
            cav = _clampf((span - abs(fx - cx)) / 1.0) * _clampf((fy - 2.1) / 0.8)
        if iron <= 0.02 and cav <= 0.02:
            return (0, 0, 0, 0)

        # Lighting: top-left key, but DIM (dungeon-dark) — the body stays near-black; only
        # the up-left edges catch a faint warm value. Deep shadow down-right.
        leftness = _clampf((cx - fx) / 6.0 + 0.5)
        topness = _clampf((14.0 - fy) / 14.0)
        lit = _clampf(0.12 + leftness * 0.22 + topness * 0.16)
        body = A.lerp_rgb(IRON_DEEP, IRON_HI, lit)
        body = A.lerp_rgb(body, IRON_BASE, 0.30)
        # silhouette rim catch on the extreme up-left of any iron edge
        edge = 1.0 - max(stem, plate, bowl)
        if iron > 0.35 and leftness > 0.62 and topness > 0.35:
            body = A.lerp_rgb(body, IRON_RIM, _clampf((leftness - 0.62) * 1.4))
        g = A.noise(int(fx), int(fy), 5) * 0.4
        body = (body[0] + g, body[1] + g, body[2] + g)

        # The warm cavity (fuel bed) reads over the iron where it's exposed.
        if cav > 0.02:
            floor = _clampf((fy - 2.0) / 3.6)       # brighter (higher) near the rim
            warmc = A.lerp_rgb(EMBER_LO, A.warm(EMBER_LO, 0.6), floor)
            a_iron = iron
            body = A.lerp_rgb(body, warmc, cav * (1.0 - a_iron * 0.4))

        a = max(iron, cav)
        return (A.clamp(body[0]), A.clamp(body[1]), A.clamp(body[2]), A.clamp(a * 255))

    return _supersample(W, H, sample)


# ── Collegium crest medallion (T158 / R139) — regenerated, Origin-neutral ─────────
# A bronze oval medallion crowning the board, re-authored as consistent generated raster
# (replacing the proto slice + its Origin-suggestive cross). The device is a RADIANT STAR
# — illumination / the Watcher / "we seek truth" — deliberately Origin-neutral (not the
# eye/inverted-cross/diamond of Belief/Sin/Relic). Domed bronze lit top-left; the sigil is
# debossed with a lit far lip. Tonally matched to the dungeon-dark board. `board_crest`
# draws the mounted cast shadow, so this is just the medallion face (alpha 0 outside).
BRONZE = {"deep": (40, 28, 13), "base": (92, 68, 35), "hi": (176, 142, 82), "rim": (26, 18, 9)}


# ── spark.png — CPUParticles2D flame particle (T153) ─────────────────────────────
# A tiny soft round grayscale-additive dot (white + radial alpha), tinted to the
# flame ramp at runtime by the particle system's color_ramp. VFX source (exempt from
# the palette lock by convention).
def make_spark():
    W = H = 8
    cx = cy = 3.5

    def sample(fx, fy):
        d = math.hypot(fx - cx, fy - cy) / 3.5
        a = _clampf(1.0 - d)
        a = a * a                                   # soft round falloff
        return (255, 255, 255, int(a * 255))

    return _supersample(W, H, sample)


# ── Supersampled render → averaged downsample (painterly AA edges) ───────────────
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


def main():
    A.write_png("seal_collegium.png", 48, 48, make_collegium_seal())
    print("wrote seal_collegium.png")
    for v in ("investigate", "eliminate", "capture", "banish"):
        A.write_png("badge_%s.png" % v, 24, 24, make_badge(v))
        print("wrote badge_%s.png" % v)
    A.write_png("torch_sconce.png", 12, 20, make_sconce())
    print("wrote torch_sconce.png")
    A.write_png("spark.png", 8, 8, make_spark())
    print("wrote spark.png")
    # No crest here: the board's emblem is the bronze seal struck by gen_header.py (TD-053).
    # The old radiant-star medallion (make_crest/_sig_star) went when its double-producer with
    # gen_heraldry.py surfaced (TD-051); gen_heraldry.py itself is retired with TD-053.


if __name__ == "__main__":
    main()
