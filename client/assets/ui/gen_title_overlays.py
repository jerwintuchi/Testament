#!/usr/bin/env python3
"""gen_title_overlays.py — the title scene's god ray (TD-073 T260; trimmed by TD-078).

    title/light_shaft.png      300x360    one god-ray wedge through the clerestory

**Was three sheets; is now one.** `dust_overlay.png` and `smoke_overlay.png` are retired (TD-078):
dust was being drawn TWICE — as that sheet and as `_dust()`'s particles — and the smoke was a plume
rising off an altar that is now cold. The fog sheets that joined them are gone too; the air is a
particle system now and ships as code, not art.

**Careful with this sheet's alpha.** Its peak is 34/255 and only ~9% of it reaches even that. The
rig then multiplies by a further 0.20/0.13/0.10 per placement, which is how the rays became
invisible while remaining the most expensive thing in the frame. Read this number before setting an
opacity against it.

**Alpha carries everything.** RGB is flat white; the image is shaped entirely in the alpha
channel. Under an additive blend that makes the sheet's contribution exactly its alpha, so the
runtime `modulate` is a single honest dimmer and nothing has a colour baked into it.

The centre of the frame is deliberately kept thin. The menu is read there (R245), and atmosphere
that crosses the reading area is the difference between mood and noise.

Run from client/assets/ui/:  python3 gen_title_overlays.py
"""
import math
import os

import ashember as A

FW, FH = 640, 360            # the internal resolution: authored at the size it is shown
SW, SH = 300, 360            # the light shaft's own size


def quiet(fx, fy):
    """1 in the open frame, falling to ~0.25 over the menu's reading area (R245)."""
    dx = max(0.0, 1.0 - abs(fx - 0.5) / 0.30)
    dy = max(0.0, 1.0 - abs(fy - 0.60) / 0.32)
    return 1.0 - 0.75 * dx * dy


# ── Light shaft: one wedge through the clerestory ────────────────────────────

def shaft_px(x, y):
    fx, fy = (x + 0.5) / SW, (y + 0.5) / SH
    # A wedge falling from the upper left, widening as it descends and dying before the floor:
    # a real shaft is only visible where there is dust to catch it.
    axis = 0.30 + 0.46 * fy
    wide = 0.10 + 0.30 * fy
    d = abs(fx - axis) / wide
    if d > 1.0:
        return 0
    body = (1.0 - d * d) ** 2
    body *= A.smooth(0.0, 0.16, fy) * (1.0 - A.smooth(0.55, 1.0, fy)) ** 1.3
    # THREE flat steps, not a falloff: a smooth cone needs dithering to survive, and dithering is
    # what the brief rules out.
    lvl = 0 if body < 0.18 else (1 if body < 0.42 else (2 if body < 0.72 else 3))
    return (0, 14, 24, 34)[lvl]


def main():
    os.makedirs(os.path.join(os.path.dirname(os.path.abspath(__file__)), "title"), exist_ok=True)

    def shaft(x, y):
        return (255, 255, 255, shaft_px(x, y))

    # LITERAL relative paths, run from client/assets/ui/ (canon S5b): tools/asset_map.py derives
    # producer edges from these strings, so an os.path.join here drops the producer silently.
    A.write_png("title/light_shaft.png", SW, SH, shaft)
    print("gen_title_overlays OK — shaft %dx%d (alpha-only, peak 34/255)." % (SW, SH))


if __name__ == "__main__":
    main()
