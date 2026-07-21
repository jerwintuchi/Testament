#!/usr/bin/env python3
"""ARCHIVED (TD-060) — the Origin-keyed wax seals (seal_belief/sin/relic.png).

Cut verbatim from `client/assets/ui/gen_emblems.py` when the asserted-Origin wax seal was
retired from every contract surface: the petition-type badge is the writ's only corner mark,
the reader's Origin row is text-only, and the seal MECHANIC survives as the one generic
Collegium seal (`seal_collegium.png`, still emitted by gen_emblems.py). The emitted PNGs are
archived beside this file. Not wired to any build; kept as source history. To resurrect, move
this back into gen_emblems.py (it expects `ashember` + the module's `_supersample`/`LX`/`LY`).
"""
import math

# Per-Origin wax palette (deep shadow, base, highlight, rim). Distinct hues so the three
# read apart at a glance; the debossed SIGIL SHAPE is the primary Origin cue regardless.
WAX = {
    "belief": {"deep": (30, 34, 68),  "base": (58, 64, 116), "hi": (120, 128, 188), "rim": (18, 20, 44)},
    "sin":    {"deep": (74, 20, 18),  "base": (150, 40, 38), "hi": (208, 96, 84),  "rim": (44, 10, 10)},
    "relic":  {"deep": (60, 46, 18),  "base": (122, 96, 40), "hi": (188, 156, 84), "rim": (36, 27, 10)},
}


# ── Origin sigil masks (unit space, cx/cy at 0, radius ~1) ───────────────────────
def _sig_belief(nx, ny):
    # An open eye — corrupted thought, watched.
    r = math.hypot(nx, ny)
    on_lens = abs(r - 0.62) < 0.12 and abs(ny) < 0.5      # almond arcs
    pupil = math.hypot(nx, ny) < 0.20
    return on_lens or pupil


def _sig_sin(nx, ny):
    # An INVERTED cross — corrupted deed (crossbar LOW on the shaft, ny+ is down).
    shaft = abs(nx) < 0.14 and -0.75 < ny < 0.75
    bar = abs(ny - 0.30) < 0.14 and abs(nx) < 0.44
    return shaft or bar


def _sig_relic(nx, ny):
    # A diamond reliquary — corrupted matter.
    d = abs(nx) / 0.66 + abs(ny) / 0.78
    return 0.72 < d < 1.04


SIGILS = {"belief": _sig_belief, "sin": _sig_sin, "relic": _sig_relic}


def make_seal(origin, A, _supersample, LX, LY, _clampf):
    W = H = 48
    pal = WAX[origin]
    sig = SIGILS[origin]
    cx, cy = 23.0, 22.0     # seal centre (a little high; drop-shadow lives at the base)
    R = 18.5
    scx, scy = cx + 2.2, cy + 3.0   # drop-shadow centre (down-right, one light)

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
        # debossed sigil: recessed (toward deep), with a lit rim on the lower-right lip.
        sr = d / R
        snx, sny = dx / (R * 0.82), dy / (R * 0.82)
        if sr < 0.92 and sig(snx, sny):
            body = A.lerp_rgb(body, pal["deep"], 0.72)          # cut into the wax
            # a thin highlight where the recess catches the key on its far (lower-right) wall
            if sig(snx - 0.06, sny - 0.06) and not sig(snx + 0.05, sny + 0.05):
                body = A.lerp_rgb(body, pal["hi"], 0.55)
        return (A.clamp(body[0]), A.clamp(body[1]), A.clamp(body[2]), 255)

    return _supersample(W, H, sample)
