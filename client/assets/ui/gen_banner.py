#!/usr/bin/env python3
"""gen_banner.py — a clean frayed blood-crimson tapestry (T157 / R138).

Replaces the proto-sliced `banner_v1.png` (which carried scattered stray / off-register
dark pixels — visible as blocky corruption across the cloth) with a freshly GENERATED
raster: a plain crimson drape, vertical fold-drapes baked as VALUE (light-agnostic), a
torn/deckled hem, and a warm glow baked into the lower hem where the torch burns at the
banner's foot. Per the TD-048 dungeon-dark grade the fold relief + torch warmth are
BAKED, not dynamically lit — the banner is a plain `Sprite2D`, so it reads by its own
value against the near-black board (no companion normal map is wired; a dynamic rake
would fight the near-zero cast). No emblem (it never competes with the crest/seals),
no stray pixels (the defect is gone by regeneration, not patching).

Stdlib only (imports `ashember`). Run FROM `client/assets/ui/` (writes a relative path).
Keeps the proto slice's 74x474 footprint so `board_decor.add_torches`' scale math holds.
"""
import math
import ashember as A

W, H = 74, 474

# Crimson cloth ramp (deep fold shadow → lit fold crest), deliberately DIM for the dungeon
# key so it reads as a dim tapestry against the near-black board without a heavy modulate.
C_DEEP = (44, 12, 12)
C_BASE = (94, 22, 22)
C_MID  = (122, 32, 30)
C_HI   = (156, 52, 44)
WARM   = (206, 118, 58)   # torch warmth baked into the hem (the flame burns beneath)


def _clampf(v, a=0.0, b=1.0):
    return max(a, min(b, v))


def _h(x, y, s=0):
    """Deterministic [0,1) hash — stable fine grain / torn edge, never blocky noise."""
    n = (x * 374761393 + y * 668265263 + s * 2654435761) & 0xFFFFFFFF
    n = (n ^ (n >> 13)) * 1274126177 & 0xFFFFFFFF
    return ((n >> 8) % 1000) / 1000.0


def banner_px(x, y):
    fx = x / (W - 1)
    fy = y / (H - 1)

    # ── torn / deckled bottom hem: an irregular lower edge with a few dangling threads ──
    hem_start = 0.90
    if fy > hem_start:
        col = _h(x // 2, 0, 7)
        thread = _h(x, 0, 3)
        edge = hem_start + col * 0.055
        if thread > 0.82:
            edge += 0.035               # a longer dangling thread on some columns
        if fy > edge:
            return (0, 0, 0, 0)         # torn away

    # ── slightly ragged vertical selvage (soft, 1px nibble) ──
    if (fx < 0.02 and _h(0, y, 5) > 0.55) or (fx > 0.98 and _h(0, y, 6) > 0.55):
        return (0, 0, 0, 0)

    # ── folds: three soft vertical drapes as value + finer creases (light-agnostic) ──
    fold = 0.5 + 0.5 * math.sin(fx * math.pi * 3.0 - 0.4) * 0.8
    fold *= 0.85 + 0.15 * (0.5 + 0.5 * math.sin(fx * math.pi * 7.0))
    body = A.lerp_rgb(C_DEEP, C_HI, _clampf(fold))
    body = A.lerp_rgb(body, C_MID, 0.30)

    # fine weave/weathering — subtle, warm-biased, never blocky
    w = (_h(x, y, 1) - 0.5) * 7.0
    body = (body[0] + w, body[1] + w * 0.5, body[2] + w * 0.5)

    # large SOFT age variation — overlapping low-frequency sines (smooth, never a hard
    # rectangular block; the proto slice's blocky corruption is exactly what we avoid).
    age = (math.sin(fx * 5.1 + fy * 8.3) + math.sin(fy * 3.7 - fx * 2.9)) * 0.25  # ~[-0.25,0.25]
    body = A.lerp_rgb(body, C_DEEP, _clampf(age * 0.5 + 0.10))

    # ── warm hem glow: the sconce flame burns at the banner's foot (baked, dungeon-dark) ──
    if fy > 0.80:
        warmth = _clampf((fy - 0.80) / 0.16) * 0.5
        warmth *= 1.0 - abs(fx - 0.5) * 0.8     # concentrated where the flame sits (centre)
        body = A.lerp_rgb(body, WARM, warmth)

    # top: a darker band where the cloth folds over the mounting rod
    if fy < 0.03:
        body = A.lerp_rgb(body, C_DEEP, 0.5)

    return (A.clamp(body[0]), A.clamp(body[1]), A.clamp(body[2]), 255)


def main():
    A.write_png("banner_v1.png", W, H, banner_px)
    print("wrote banner_v1.png (%dx%d) — plain frayed crimson, no stray pixels" % (W, H))


if __name__ == "__main__":
    main()
