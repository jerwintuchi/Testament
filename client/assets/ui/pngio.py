#!/usr/bin/env python3
"""Minimal stdlib PNG reader (zlib + struct only) — no Pillow dependency.

Handles the common case we need: 8-bit, non-interlaced, colour type 2 (RGB) or
6 (RGBA), which is what our raster sources are. Returns a flat pixel accessor so
slicing/tiling of an authored raster (e.g. _proto_board.png) can be done with the
same toolchain as ashember.write_png, keeping the pipeline dependency-free.
"""
import struct
import zlib


def read_png(path):
    """Return (w, h, px) where px(x, y) -> (r, g, b, a)."""
    with open(path, "rb") as f:
        data = f.read()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", "not a PNG"
    pos = 8
    width = height = bit_depth = color_type = interlace = None
    idat = bytearray()
    while pos < len(data):
        (length,) = struct.unpack(">I", data[pos:pos + 4])
        ctype = data[pos + 4:pos + 8]
        chunk = data[pos + 8:pos + 8 + length]
        pos += 12 + length  # 4 len + 4 type + data + 4 crc
        if ctype == b"IHDR":
            width, height, bit_depth, color_type, _comp, _filt, interlace = \
                struct.unpack(">IIBBBBB", chunk)
        elif ctype == b"IDAT":
            idat += chunk
        elif ctype == b"IEND":
            break
    assert bit_depth == 8, "only 8-bit supported (got %s)" % bit_depth
    assert interlace == 0, "interlaced PNG not supported"
    channels = {2: 3, 6: 4, 0: 1, 4: 2}[color_type]
    raw = zlib.decompress(bytes(idat))
    stride = width * channels
    out = bytearray(height * stride)
    prev = bytearray(stride)
    rp = 0
    for y in range(height):
        ftype = raw[rp]; rp += 1
        line = bytearray(raw[rp:rp + stride]); rp += stride
        if ftype == 1:      # Sub
            for i in range(channels, stride):
                line[i] = (line[i] + line[i - channels]) & 0xFF
        elif ftype == 2:    # Up
            for i in range(stride):
                line[i] = (line[i] + prev[i]) & 0xFF
        elif ftype == 3:    # Average
            for i in range(stride):
                a = line[i - channels] if i >= channels else 0
                line[i] = (line[i] + ((a + prev[i]) >> 1)) & 0xFF
        elif ftype == 4:    # Paeth
            for i in range(stride):
                a = line[i - channels] if i >= channels else 0
                b = prev[i]
                c = prev[i - channels] if i >= channels else 0
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[i] = (line[i] + pr) & 0xFF
        out[y * stride:(y + 1) * stride] = line
        prev = line

    def px(x, y):
        i = (y * width + x) * channels
        if channels == 4:
            return (out[i], out[i + 1], out[i + 2], out[i + 3])
        if channels == 3:
            return (out[i], out[i + 1], out[i + 2], 255)
        if channels == 2:
            return (out[i], out[i], out[i], out[i + 1])
        return (out[i], out[i], out[i], 255)

    return width, height, px


if __name__ == "__main__":
    import sys
    w, h, px = read_png(sys.argv[1])
    print("size", w, h)
    print("sample (0,0)", px(0, 0), "center", px(w // 2, h // 2))
