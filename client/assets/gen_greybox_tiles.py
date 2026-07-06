#!/usr/bin/env python3
"""Greybox tile-atlas generator for the walkable-spaces TileMapLayer.

Stdlib-only PNG writer (no PIL dependency yet). Emits a 32x16 atlas of two
16x16 tiles side by side, which the TileSet (assets/tiles.tres) slices:

    tile (0,0)  FLOOR  — muted stone with a subtle grid edge
    tile (1,0)  SOLID  — dark wall with a lit top edge

This is a functional greybox; authored Aseprite/PIL sources replace it later
(art task). Run: `python3 client/assets/gen_greybox_tiles.py`.
"""
import zlib
import struct
import os

W, H, TILE = 32, 16, 16


def pixel(x: int, y: int) -> tuple[int, int, int]:
    tile = x // TILE
    lx, ly = x % TILE, y % TILE
    if tile == 0:  # FLOOR
        if lx == 0 or ly == 0:
            return (44, 41, 51)   # subtle grid line at tile top/left
        return (56, 52, 64)
    else:          # SOLID wall
        if ly == 0:
            return (40, 37, 48)   # lit top edge
        return (26, 24, 32)


def _chunk(tag: bytes, data: bytes) -> bytes:
    return (struct.pack(">I", len(data)) + tag + data
            + struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff))


def main() -> None:
    raw = bytearray()
    for y in range(H):
        raw.append(0)  # PNG filter type 0 (none) per scanline
        for x in range(W):
            raw.extend(pixel(x, y))
    png = (b"\x89PNG\r\n\x1a\n"
           + _chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0))  # 8-bit RGB
           + _chunk(b"IDAT", zlib.compress(bytes(raw), 9))
           + _chunk(b"IEND", b""))
    out = os.path.join(os.path.dirname(__file__), "tiles", "tiles.png")
    with open(out, "wb") as f:
        f.write(png)
    print("wrote", out, len(png), "bytes")


if __name__ == "__main__":
    main()
