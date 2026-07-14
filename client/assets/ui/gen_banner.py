#!/usr/bin/env python3
"""gen_banner.py — a proper crimson standard, imprinted with the Collegium emblem (TD-052 / R166,R167).

Replaces the narrow frayed strip with a real HANGING BANNER: clean woven crimson with baked
vertical fold value + AO (light-agnostic, dungeon-dark key — the banner is a plain Sprite2D that
reads by its own value), a baked TOP HEM (the pole sleeve — no separate iron rod anymore), a
defined SWALLOWTAIL bottom (a central V-notch between two tails, not a torn deckle), and a selvage
border tracing the silhouette. The Collegium emblem is IMPRINTED into the upper cloth as a pale
BONE-DYE device — the emblem recolored to bone (its alpha as the mask, its luminance for internal
relief) at reduced opacity so the crimson weave reads through: a printed look, color-shifted from
the source gilt, BAKED into the PNG so it drapes + dims with the cloth (P97).

PIL is sanctioned for generators (CLAUDE.md toolchain) — used to read + recolor the emblem; the
banner is still written via ashember.write_png so the asset-map producer edge holds. Run FROM
client/assets/ui/. Brand-new PNGs need `godot --headless --import`.

# @produces banner_v1.png  — the flanking Collegium standard (crimson + bone-dye imprint)
# @consumes collegium_logo.png  — the emblem, recolored to bone and printed into the cloth
# @why      the imprint is BAKED at gen time (one source of truth) so it lights/drapes with the
#           cloth; this INPUT edge is invisible to the text-static asset-map scanner (py tracks
#           only write_png), hence recorded here
"""
import math
from PIL import Image
import ashember as A

W, H = 180, 360

# Crimson cloth ramp (deep fold shadow → lit fold crest), dim for the dungeon key.
C_DEEP = (44, 12, 12)
C_MID  = (122, 32, 30)
C_HI   = (156, 52, 44)

# Bone-dye imprint ramp: the emblem's dark linework → BONE_DK, its lit fills → BONE_LT.
BONE_DK = (120, 110, 90)
BONE_LT = (236, 228, 206)
IMPRINT_A = 0.86        # < 1 so the crimson weave shows through — a dye, not a decal
EMB_SRC = "collegium_logo.png"

SWTOP = 0.82            # swallowtail: cloth is full-length at the sides, notched up to here at centre
HEM = 0.055            # top hem (pole sleeve) fraction


def _clampf(v, a=0.0, b=1.0):
    return max(a, min(b, v))


def _h(x, y, s=0):
    """Deterministic [0,1) hash — stable fine grain, never blocky."""
    n = (x * 374761393 + y * 668265263 + s * 2654435761) & 0xFFFFFFFF
    n = (n ^ (n >> 13)) * 1274126177 & 0xFFFFFFFF
    return ((n >> 8) % 1000) / 1000.0


def _build_imprint():
    """The bone-dye emblem, recolored + scaled + seated, as a W×H RGBA overlay buffer."""
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
    tw = int(0.62 * W)
    th = round(tw * im.height / im.width)
    bone = bone.resize((tw, th), Image.LANCZOS)
    buf = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    buf.alpha_composite(bone, ((W - tw) // 2, int(H * 0.115)))   # centred, in the upper cloth
    return buf.load()


IMP = _build_imprint()


def _bottom(fx):
    """Swallowtail silhouette: full-length (1.0) at the edges, notched up to SWTOP at the centre."""
    return SWTOP + (1.0 - SWTOP) * (2.0 * abs(fx - 0.5))


def banner_px(x, y):
    fx = x / (W - 1)
    fy = y / (H - 1)

    bottom = _bottom(fx)
    if fy > bottom:
        return (0, 0, 0, 0)                     # outside the swallowtail

    # ── folds: soft vertical drapes as value + finer creases (light-agnostic) ──
    fold = 0.5 + 0.5 * math.sin(fx * math.pi * 3.0 - 0.4) * 0.8
    fold *= 0.85 + 0.15 * (0.5 + 0.5 * math.sin(fx * math.pi * 7.0))
    body = A.lerp_rgb(C_DEEP, C_HI, _clampf(fold))
    body = A.lerp_rgb(body, C_MID, 0.30)

    # fine weave — subtle, warm-biased, never blocky
    wv = (_h(x, y, 1) - 0.5) * 6.0
    body = (body[0] + wv, body[1] + wv * 0.5, body[2] + wv * 0.5)

    # soft low-frequency age + a gentle top→bottom AO
    age = (math.sin(fx * 5.1 + fy * 8.3) + math.sin(fy * 3.7 - fx * 2.9)) * 0.25
    body = A.lerp_rgb(body, C_DEEP, _clampf(age * 0.4 + 0.08 + fy * 0.10))

    # ── top hem: the baked pole sleeve (darker band + a thin lit lower lip) ──
    if fy < HEM:
        body = A.lerp_rgb(body, C_DEEP, 0.55)
    elif fy < HEM + 0.018:
        body = A.lerp_rgb(body, C_HI, 0.35)

    # ── selvage: a darker border tracing the whole silhouette (sides + swallowtail edge) ──
    edge = min(fx, 1.0 - fx, bottom - fy)
    if edge < 0.013:
        body = A.lerp_rgb(body, C_DEEP, _clampf((0.013 - edge) / 0.013) * 0.7)

    # ── imprint: composite the baked bone-dye emblem over the cloth ──
    ir, ig, ib, ia = IMP[x, y]
    if ia > 0:
        t = ia / 255.0
        body = (body[0] * (1 - t) + ir * t,
                body[1] * (1 - t) + ig * t,
                body[2] * (1 - t) + ib * t)

    return (A.clamp(body[0]), A.clamp(body[1]), A.clamp(body[2]), 255)


def main():
    A.write_png("banner_v1.png", W, H, banner_px)
    print("wrote banner_v1.png (%dx%d) — crimson standard, bone-dye Collegium imprint" % (W, H))


if __name__ == "__main__":
    main()
