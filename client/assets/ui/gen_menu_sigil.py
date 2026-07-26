#!/usr/bin/env python3
"""gen_menu_sigil.py — the mark that flanks the selected menu option.

    shared/menu_sigil.png   20x20, points RIGHT (the left-hand copy is mirrored by the UI)

A gilt lozenge with a bar running toward the text it marks, and a pricked centre — the Collegium's
paperwork vocabulary rather than a game-UI arrow: the same family as the Contract Board's ornament
scrollbar (brass line, dot finials, chevroned diamond). It REPLACES the focus ring on the title
menu; a rectangle drawn round gilt lettering turned an image back into a dialog.

Authored at the title hall's grain (one art pixel per device pixel at 720p), hard-edged, on the Ash
& Ember gold ramp — `assert_on_palette` passes.

Run from client/assets/ui/:  python3 gen_menu_sigil.py
"""
import os

import ashember as A

W, H = 20, 20
GOLD_D, GOLD_M, GOLD_L, GOLD_XL = (A.RAMP["gold"][0], A.RAMP["gold"][1],
                                   A.RAMP["gold"][2], A.RAMP["gold"][3])
NONE = (0, 0, 0, 0)

CX, CY, R = 6, 10, 5          # the lozenge
BAR_Y, BAR_X0, BAR_X1 = 10, 12, 19


def px(x, y):
    d = abs(x - CX) + abs(y - CY)                 # a diamond is a Manhattan circle

    if d <= R:
        if d == R:
            return GOLD_M + (255,)                # its edge
        if d == R - 1:
            return GOLD_L + (255,)                # a lit inner bevel
        if d <= 1:
            return GOLD_XL + (255,)               # the prick at the centre
        return GOLD_D + (255,)                    # the field between, deliberately dark

    # The bar runs toward the word it marks, tapering to a point and ending in a finial.
    if y == BAR_Y and BAR_X0 <= x <= BAR_X1:
        return (GOLD_L if x >= BAR_X1 - 1 else GOLD_M) + (255,)
    if y == BAR_Y - 1 and BAR_X0 <= x <= BAR_X0 + 2:
        return GOLD_D + (255,)                    # a spur where the bar leaves the lozenge
    if y == BAR_Y + 1 and BAR_X0 <= x <= BAR_X0 + 2:
        return GOLD_D + (255,)
    return NONE


if __name__ == "__main__":
    os.makedirs(os.path.join(os.path.dirname(os.path.abspath(__file__)), "shared"), exist_ok=True)
    A.assert_on_palette(W, H, px, "shared/menu_sigil.png")
    # A LITERAL relative path, run from client/assets/ui/ (canon S5b).
    A.write_png("shared/menu_sigil.png", W, H, px)
    print("gen_menu_sigil OK — %dx%d, on-palette." % (W, H))
