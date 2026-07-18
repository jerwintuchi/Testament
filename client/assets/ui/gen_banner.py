#!/usr/bin/env python3
"""gen_banner.py — the flanking Collegium standard: a crisp, dim, heavily-tattered crimson banner
that the torch rig LIGHTS (TD-059 / board-blend).

Rewrites the TD-052 banner on every axis the author's review flagged: it was too bright, smooth
(LINEAR), too wide (spilling off-screen), and a FLAT baked sprite the torchlight never touched. Now:

  banner_v1.png    64x176  the DIFFUSE — authored at ~display size (crisp NEAREST 1:1; the internal
                           resolution is a fixed 640x360, so the on-screen size is deterministic —
                           TD-050). A DIM, lower-contrast crimson (the shader supplies fold warmth
                           now, so the diffuse no longer bakes bright crests), a gentle baked fold
                           value + fine weave, a kept top hem (pole sleeve), the Collegium emblem
                           imprinted SUBDUED (dim/desaturated bone dye, low alpha — a faint printed
                           device, never a bright sigil), and a HEAVILY TATTERED foot: a ragged
                           per-column worn hem, a few worn-through holes, and sparse loose threads.
  banner_v1_n.png  64x176  the NORMAL map — tangent-space, from the banner's OWN height field (fold +
                           creases + hem bump), so board_surface.gdshader gives the cloth real fold
                           relief (warm where the foot sconce reaches, dark up top). Flat where the
                           cloth is transparent (outside / holes / between threads) so torn gaps
                           don't rake light. gen_normals convention: flat = (128,128,255).

@produces banner_v1.png, banner_v1_n.png
@consumes collegium_logo.png  — the emblem, recolored to a DIM bone and printed faintly into the cloth
@why      the imprint is BAKED at gen time (one source of truth) so it drapes + dims with the cloth;
          this INPUT edge is invisible to the text-static asset-map scanner (py tracks only
          write_png), hence recorded here. The normal is derived from the generator's OWN height
          field (not luminance) so the relief is independent of how dim the diffuse is (P103).

PIL is sanctioned for generators (CLAUDE.md toolchain) — used to read + recolor the emblem; both PNGs
are written via ashember.write_png so the asset-map producer edges hold. Run FROM client/assets/ui/.
Brand-new PNGs need `godot --headless --import`.
"""
import math
from PIL import Image
import ashember as A

W, H = 64, 176

# Dim crimson cloth ramp (deep fold shadow -> lit fold crest). Lower-contrast + darker than the
# TD-052 banner: the torch shader now lifts the foot, so the diffuse stays below the parchment/frame
# key and reads receded even unlit (P103).
C_DEEP = (40, 12, 11)
C_MID  = (98, 30, 26)
C_HI   = (124, 44, 36)

# Subdued bone-dye imprint: much dimmer + more desaturated than TD-052 (was 236,228,206 @ a=0.86),
# so the emblem is a faint printed device the weave shows through, never a bright sigil (R178).
BONE_DK = (86, 80, 68)
BONE_LT = (150, 142, 122)
IMPRINT_A = 0.46
EMB_SRC = "collegium_logo.png"

HEM = 0.055            # top hem (pole sleeve) fraction
SOLID = 0.80           # cloth is full down to here; the ragged/holed/threaded tatter lives below


def _clampf(v, a=0.0, b=1.0):
    return max(a, min(b, v))


def _h(x, y, s=0):
    """Deterministic [0,1) hash — stable fine grain, never blocky."""
    n = (x * 374761393 + y * 668265263 + s * 2654435761) & 0xFFFFFFFF
    n = (n ^ (n >> 13)) * 1274126177 & 0xFFFFFFFF
    return ((n >> 8) % 1000) / 1000.0


# ── Tatter (R177): the heavily worn foot, resolved per column, as alpha ──────────────
def _hem_depth(x):
    """The ragged worn hem for column x, as a fy fraction in ~[SOLID, 0.95]. Low-frequency (worn in
    ~3px steps, interpolated) so the edge is ragged, not per-pixel confetti."""
    xs = x / 3.0
    x0 = int(math.floor(xs))
    t = xs - x0
    a = _h(x0, 0, 11)
    b = _h(x0 + 1, 0, 11)
    worn = a + (b - a) * t
    return SOLID + (0.95 - SOLID) * worn


# A few worn-through holes near the foot: seeded ellipse centres (fx, fy, rx, ry).
_HOLES = [(0.34, 0.70, 0.10, 0.045), (0.66, 0.78, 0.085, 0.05), (0.50, 0.63, 0.06, 0.035)]


def _in_hole(fx, fy):
    for hx, hy, rx, ry in _HOLES:
        dx = (fx - hx) / rx
        dy = (fy - hy) / ry
        if dx * dx + dy * dy < 1.0:
            # soft, ragged rim: nibble the edge so holes aren't clean ellipses
            if dx * dx + dy * dy < 0.7 or _h(int(fx * W), int(fy * H), 23) > 0.4:
                return True
    return False


def _is_thread(x):
    """Sparse columns (~1px) whose strand survives below the ragged hem — loose threads."""
    return _h(x, 0, 31) > 0.80


def _thread_depth(x):
    """How deep a thread column's strand hangs — down toward the very foot, unevenly."""
    return _hem_depth(x) + (0.995 - _hem_depth(x)) * _h(x, 0, 37)


def _alpha(x, y):
    fx = x / (W - 1)
    fy = y / (H - 1)
    hem = _hem_depth(x)
    if fy <= hem:
        return not _in_hole(fx, fy)          # solid cloth, minus the worn holes
    if _is_thread(x) and fy <= _thread_depth(x):
        return True                          # a loose strand hanging past the hem
    return False


# ── Height field (R179): fold drape + creases + hem bump, for the normal map ─────────
def _height(x, y):
    fx = x / (W - 1)
    fy = y / (H - 1)
    # three soft vertical drapes + a finer crease train (folds run vertically -> normal tilts in x)
    fold = 0.5 + 0.5 * math.sin(fx * math.pi * 3.0 - 0.4) * 0.8
    fold += 0.10 * math.sin(fx * math.pi * 7.0)
    h = 0.5 + 0.28 * (fold - 0.5) * 2.0
    if fy < HEM:                              # the pole-sleeve hem stands a little proud
        h += 0.18 * (1.0 - fy / HEM)
    return _clampf(h)


# Precompute grids once (write_png calls back per pixel).
ALPHA = [[_alpha(x, y) for x in range(W)] for y in range(H)]
HF = [[_height(x, y) for x in range(W)] for y in range(H)]


def _build_imprint():
    """The dim bone-dye emblem, recolored + scaled + seated, as a W×H RGBA overlay buffer."""
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
    tw = int(0.60 * W)
    th = round(tw * im.height / im.width)
    bone = bone.resize((tw, th), Image.LANCZOS)
    buf = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    buf.alpha_composite(bone, ((W - tw) // 2, int(H * 0.135)))   # centred, in the upper cloth
    return buf.load()


IMP = _build_imprint()


def banner_px(x, y):
    if not ALPHA[y][x]:
        return (0, 0, 0, 0)
    fx = x / (W - 1)
    fy = y / (H - 1)

    # ── folds: gentle baked value (the shader adds the rest), from the same height field ──
    fold = HF[y][x]
    body = A.lerp_rgb(C_DEEP, C_HI, fold)
    body = A.lerp_rgb(body, C_MID, 0.35)

    # fine weave — subtle, never blocky
    wv = (_h(x, y, 1) - 0.5) * 5.0
    body = (body[0] + wv, body[1] + wv * 0.5, body[2] + wv * 0.5)

    # a gentle top->bottom AO so the cloth isn't a flat rectangle unlit
    body = A.lerp_rgb(body, C_DEEP, _clampf(0.06 + fy * 0.12))

    # ── top hem: the baked pole sleeve (darker band + a thin lit lower lip) ──
    if fy < HEM:
        body = A.lerp_rgb(body, C_DEEP, 0.55)
    elif fy < HEM + 0.018:
        body = A.lerp_rgb(body, C_HI, 0.30)

    # ── selvage: a darker border tracing the sides + the ragged foot ──
    if x <= 0 or x >= W - 1 or not ALPHA[y][min(x + 1, W - 1)] or not ALPHA[y][max(x - 1, 0)] \
            or (y + 1 < H and not ALPHA[y + 1][x]):
        body = A.lerp_rgb(body, C_DEEP, 0.6)

    # ── imprint: composite the dim bone-dye emblem over the cloth ──
    ir, ig, ib, ia = IMP[x, y]
    if ia > 0:
        t = ia / 255.0
        body = (body[0] * (1 - t) + ir * t,
                body[1] * (1 - t) + ig * t,
                body[2] * (1 - t) + ib * t)

    return (A.clamp(body[0]), A.clamp(body[1]), A.clamp(body[2]), 255)


# ── Normal map (gen_normals convention: tangent-space, flat = 128,128,255) ───────────
FLIP_G = False
NRM_STRENGTH = 3.2


def _Hc(x, y):
    x = 0 if x < 0 else (W - 1 if x >= W else x)
    y = 0 if y < 0 else (H - 1 if y >= H else y)
    return HF[y][x]


def normal_px(x, y):
    if not ALPHA[y][x]:
        return (128, 128, 255, 0)            # flat + transparent: torn gaps don't rake light
    dx = _Hc(x + 1, y) - _Hc(x - 1, y)
    dy = _Hc(x, y + 1) - _Hc(x, y - 1)
    nx = -dx * NRM_STRENGTH
    ny = -dy * NRM_STRENGTH * (-1.0 if FLIP_G else 1.0)
    nz = 1.0
    inv = 1.0 / math.sqrt(nx * nx + ny * ny + nz * nz)
    return (A.clamp((nx * inv * 0.5 + 0.5) * 255),
            A.clamp((ny * inv * 0.5 + 0.5) * 255),
            A.clamp((nz * inv * 0.5 + 0.5) * 255),
            255)


def main():
    A.write_png("banner_v1.png", W, H, banner_px)
    print("wrote banner_v1.png (%dx%d) — dim tattered crimson standard, subdued imprint" % (W, H))
    A.write_png("banner_v1_n.png", W, H, normal_px)
    print("wrote banner_v1_n.png (%dx%d) — fold-relief normal for board_surface.gdshader" % (W, H))


if __name__ == "__main__":
    main()
