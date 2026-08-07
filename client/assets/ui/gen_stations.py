#!/usr/bin/env python3
"""gen_stations.py — the Collegium's three prep stations, as objects (TD-081, T313).

    stations/contract_board.png   40x40   the notice wall, against the north wall
    stations/quartermaster.png    40x32   a counter with crates and hanging kit
    stations/deploy_gate.png      40x40   the iron gate the party leaves through

Replaces a 12x12 gold `Polygon2D` and a white sans `Label` — the same marker for all three, which
told the player nothing except that *something* was there.

**Upright objects, not floor decals.** The hall is top-down but its sprites are drawn front-facing
(the Seeker is), so a station is an object standing in the room, seen the way the Seeker is seen.
Each is sized against `STATION_RADIUS = 24` so the thing you see is roughly the thing you can reach.

**Authored at AMBIENT value, with headroom.** T312 learned that art drawn to look right *unlit* is
darkened twice by the `CanvasModulate` and lands nearly black — but the opposite is just as wrong:
drawn at the TOP of the ramp, a lamp standing on the station has nowhere to push and the object
blows to white. Every station has its own lamp, so these sit mid-ramp: bright enough to read in
ambient, with room left for the light to add.

On-palette (`assert_on_palette`), flat tones, no per-pixel noise — the Contract Board's own register.

Run from client/assets/ui/:  python3 gen_stations.py
"""
import os

import ashember as A

NS = A.RAMP["navestone"]
WOOD = A.RAMP["wood"]
PARCH = A.RAMP["parchment"]
GOLD = A.RAMP["gold"]
IRON = A.RAMP["stone"]
NONE = (0, 0, 0, 0)


class Buf:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.px = [[NONE] * w for _ in range(h)]

    def set(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y][x] = c

    def rect(self, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.set(x, y, c)

    def frame(self, x0, y0, x1, y1, c):
        for x in range(x0, x1 + 1):
            self.set(x, y0, c)
            self.set(x, y1, c)
        for y in range(y0, y1 + 1):
            self.set(x0, y, c)
            self.set(x1, y, c)

    def pixel(self):
        def px(x, y):
            c = self.px[y][x]
            return NONE if c == NONE else (c[0], c[1], c[2], 255)
        return px


def contract_board():
    """The notice wall: a dark timber frame, a backing board, and pinned writs. The one station the
    player already knows by sight, because its full-screen version is the game's best asset — so the
    silhouette here quotes it rather than inventing a second look."""
    b = Buf(40, 40)
    b.rect(3, 6, 36, 34, WOOD[0])                 # the carcass
    b.frame(3, 6, 36, 34, WOOD[0])
    b.rect(5, 8, 34, 32, WOOD[1])                 # the backing, lighter
    # Two rows of writs, deliberately uneven — a board with every notice square reads as a menu.
    for (x, y, w, h) in ((7, 10, 8, 9), (17, 11, 9, 8), (28, 10, 5, 10),
                         (7, 22, 7, 8), (16, 21, 10, 9), (28, 23, 5, 7)):
        b.rect(x, y, x + w, y + h, PARCH[1])
        b.rect(x, y, x + w, y, PARCH[2])          # the lit top edge of the paper
        b.set(x + w // 2, y - 1, GOLD[2])         # the tack
    b.rect(3, 35, 36, 36, WOOD[0])                # a shadow where it meets the floor
    return b


def quartermaster():
    """A counter with crates behind it and kit hanging above — the place you are handed things."""
    b = Buf(40, 32)
    b.rect(4, 6, 35, 9, WOOD[1])                  # the shelf above
    for x in (8, 14, 21, 28):                     # kit hanging from it
        b.rect(x, 10, x + 2, 14, IRON[2])
        b.set(x + 1, 15, IRON[3])
    b.rect(2, 17, 37, 27, WOOD[0])                # the counter
    b.rect(2, 17, 37, 18, WOOD[2])                # its lit top surface
    b.frame(2, 17, 37, 27, WOOD[0])
    for (x, y) in ((6, 20), (16, 21), (27, 20)):  # crates stacked behind it
        b.rect(x, y, x + 7, y + 6, WOOD[1])
        b.frame(x, y, x + 7, y + 6, WOOD[0])
        b.rect(x + 1, y + 3, x + 6, y + 3, WOOD[2])
    b.rect(2, 28, 37, 29, WOOD[0])
    return b


def deploy_gate():
    """An iron gate in a stone arch: the way out, and the only station that is a threshold rather
    than a piece of furniture."""
    b = Buf(40, 40)
    b.rect(2, 4, 37, 36, NS[3])                   # the stone surround
    b.frame(2, 4, 37, 36, NS[2])
    for y in range(8, 34, 6):                     # coursing on the surround
        b.rect(3, y, 36, y, NS[2])
    b.rect(7, 9, 32, 36, NS[0])                   # the dark opening
    # The arch's head, stepped rather than curved — a circle at 26px reads as a lumpy ring.
    for i, (x0, x1) in enumerate(((10, 29), (8, 31), (7, 32))):
        b.rect(x0, 9 + i, x1, 9 + i, NS[4])
    # The bars.
    for x in range(9, 32, 4):
        b.rect(x, 12, x + 1, 35, IRON[2])
        b.rect(x, 12, x + 1, 13, IRON[3])         # each catches the light at its head
    b.rect(8, 20, 31, 21, IRON[3])                # a cross-brace
    b.rect(2, 37, 37, 38, NS[1])
    return b


PIECES = [
    ("contract_board.png", contract_board),
    ("quartermaster.png", quartermaster),
    ("deploy_gate.png", deploy_gate),
]


def main():
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "stations")
    os.makedirs(out, exist_ok=True)
    for name, fn in PIECES:
        b = fn()
        px = b.pixel()
        A.assert_on_palette(b.w, b.h, px, "stations/" + name)
        # LITERAL relative paths, run from client/assets/ui/ (canon S5b).
        A.write_png("stations/" + name, b.w, b.h, px)
        print("  %-22s %dx%d" % (name, b.w, b.h))
    print("gen_stations OK — three stations, on-palette, authored at full-light value.")


if __name__ == "__main__":
    main()
