#!/usr/bin/env python3
"""Land title-scene art, and referee the asset contract while doing it (TD-073, T260).

The title rig loads its art BY EXACT FILENAME and skips whatever is absent — which is what lets
art arrive one piece at a time (`specs/title-scene/tasks.md` T260), and is also a trap: a file
named `hall_plate.png` when the rig wants `pier_left.png` does not error, it silently never
appears. That already happened once — the manifest asked for a plate the rig had no slot for.

So the slot list is DERIVED from `client/scripts/ui/title_scene.gd` (the only thing that actually
loads anything) and the expected sizes are DERIVED from the manifest. This tool is the referee
between them, and the installer that puts a validated file where the rig will find it.

    python3 tools/title_assets.py             install art/src/title/*.png -> client/assets/ui/title/
    python3 tools/title_assets.py --check     report only; exit 1 on a contract violation
    python3 tools/title_assets.py --selftest  assert the parsing rules (the named test)
    python3 tools/title_assets.py --import    install, then run Godot's importer over the client

Nothing here generates art: painted source art is copied byte-for-byte, because re-encoding a
painted matte through a pixel-art generator is exactly the register mistake TD-055 warns about.
"""
import os
import re
import shutil
import struct
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RIG = os.path.join(ROOT, "client", "scripts", "ui", "title_scene.gd")
MANIFEST = os.path.join(ROOT, "specs", "title-scene", "asset-manifest.md")
SRC = os.path.join(ROOT, "art", "src", "title")
DST = os.path.join(ROOT, "client", "assets", "ui", "title")

GODOT = os.environ.get("GODOT", "/mnt/d/Godot_v4.7-stable_win64.exe")
CLIENT_UNC = r"\\wsl.localhost\Ubuntu-24.04\home\jerwin\projects\Testament\client"

RE_PNG = re.compile(r'"([A-Za-z0-9_]+\.png)"')

# A manifest row: | `name.png` | 1920x1080 | opaque |   (x is the multiplication sign in the doc)
RE_MD_ROW = re.compile(
    r"\|\s*`([A-Za-z0-9_]+\.png)`\s*\|\s*(\d+)\s*[x\u00d7]\s*(\d+)\s*\|\s*(\w+)")

BOLD = "\033[1m"; DIM = "\033[2m"; RED = "\033[31m"; GRN = "\033[32m"
YEL = "\033[33m"; OFF = "\033[0m"


# ── The two sources of truth ─────────────────────────────────────────────────

def rig_slots():
    """Every filename `title_scene.gd` will actually try to load, in file order."""
    with open(RIG, encoding="utf-8") as f:
        src = f.read()
    seen, out = set(), []
    for name in RE_PNG.findall(src):
        if name not in seen:
            seen.add(name)
            out.append(name)
    return out


def manifest_specs():
    """{filename: (w, h, alpha_word)} for every asset ROW, and the set of names those rows request.

    Only table rows count, never prose: the manifest has to be able to discuss a retired name
    (`chain.png`) in a sentence without that reading as a request to author it. The cost is that
    an asset row MUST carry a size, or it is invisible here."""
    with open(MANIFEST, encoding="utf-8") as f:
        src = f.read()
    sized = {m[0]: (int(m[1]), int(m[2]), m[3]) for m in RE_MD_ROW.findall(src)}
    return sized, set(sized)


# ── PNG inspection (IHDR only — no decode, no Pillow) ────────────────────────

COLOR_TYPE = {0: "grey", 2: "RGB", 3: "indexed", 4: "grey+A", 6: "RGBA"}
HAS_ALPHA = (4, 6)


def probe(path):
    """(w, h, bit_depth, color_type, interlace) from the IHDR, or raise ValueError."""
    with open(path, "rb") as f:
        head = f.read(33)
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    if head[12:16] != b"IHDR":
        raise ValueError("no IHDR chunk")
    w, h, depth, ctype, _comp, _filt, interlace = struct.unpack(">IIBBBBB", head[16:29])
    return w, h, depth, ctype, interlace


# ── The report ───────────────────────────────────────────────────────────────

def audit():
    """Returns (rows, errors, warnings). An error is a contract violation; a missing asset is
    NOT an error — a blockout is the designed state until the art exists."""
    slots = rig_slots()
    sized, named = manifest_specs()
    errors, warnings, rows = [], [], []

    # 1. Contract: the manifest must name exactly what the rig loads. This is the check that
    #    would have caught `hall_plate.png` having no slot, and `chain.png` having no loader.
    for name in sorted(set(slots) - named):
        errors.append("rig loads %s but the manifest never names it — nobody will author it" % name)
    for name in sorted(named - set(slots)):
        errors.append("manifest asks for %s but the rig has no slot — it would silently vanish"
                      % name)

    # 2. Every file staged or dropped, against its slot.
    for name in slots:
        installed = os.path.join(DST, name)
        source = os.path.join(SRC, name)
        path = installed if os.path.exists(installed) else source
        if not os.path.exists(path):
            rows.append((name, "blockout", ""))
            continue
        where = "installed" if path == installed else "staged"
        try:
            w, h, depth, ctype, interlace = probe(path)
        except (ValueError, OSError) as exc:
            errors.append("%s: %s" % (name, exc))
            rows.append((name, "BAD", str(exc)))
            continue
        note = "%dx%d %s" % (w, h, COLOR_TYPE.get(ctype, "?%d" % ctype))
        # Alpha is load-bearing for everything but the plate: a prop exported as RGB arrives with
        # its background baked in and renders as a rectangle over the scene.
        if name != plate_name(slots) and ctype not in HAS_ALPHA:
            errors.append("%s has no alpha channel (%s) — it will render as a solid rectangle"
                          % (name, COLOR_TYPE.get(ctype, ctype)))
        # No complaint about alpha ON the plate: `ashember.write_png` only ever emits colour type
        # 6, so a generated plate is RGBA with a=255 everywhere — opaque in every way that counts.
        if interlace:
            warnings.append("%s is interlaced" % name)
        want = sized.get(name)
        if want and (w, h) != (want[0], want[1]):
            # Not an error: the rig sizes by WIDTH FRACTION and takes the art's own aspect, so a
            # different size composites fine. Worth saying, because a wildly different aspect
            # means the piece was drawn for a different camera.
            warnings.append("%s is %dx%d, manifest says %dx%d" % (name, w, h, want[0], want[1]))
        rows.append((name, where, note))
    return rows, errors, warnings


def plate_name(slots):
    return "hall_plate.png" if "hall_plate.png" in slots else None


def unknown_sources(slots):
    if not os.path.isdir(SRC):
        return []
    return sorted(f for f in os.listdir(SRC)
                  if f.lower().endswith(".png") and f not in slots)


# ── Actions ──────────────────────────────────────────────────────────────────

def install():
    """Copy validated source art into the client. Byte-for-byte: painted art is not re-encoded."""
    slots = rig_slots()
    os.makedirs(DST, exist_ok=True)
    landed = []
    for name in slots:
        src = os.path.join(SRC, name)
        if not os.path.exists(src):
            continue
        dst = os.path.join(DST, name)
        if os.path.exists(dst) and os.path.getmtime(dst) >= os.path.getmtime(src):
            continue
        shutil.copyfile(src, dst)
        landed.append(name)
    return landed


def run_import():
    cmd = [GODOT, "--headless", "--path", CLIENT_UNC, "--import"]
    print(DIM + " ".join(cmd) + OFF)
    return subprocess.call(cmd)


def report(rows, errors, warnings, slots):
    print(BOLD + "Title scene assets" + OFF + DIM + "  (slots derived from title_scene.gd)" + OFF)
    filled = 0
    for name, state, note in rows:
        if state == "blockout":
            print("  %s%-22s blockout%s" % (DIM, name, OFF))
        elif state == "BAD":
            print("  %s%-22s %s%s" % (RED, name, note, OFF))
        else:
            filled += 1
            print("  %s%-22s%s %-9s %s" % (GRN, name, OFF, state, note))
    print(DIM + "  %d of %d slots filled" % (filled, len(rows)) + OFF)

    for f in unknown_sources(slots):
        warnings.append("art/src/title/%s matches no slot — the rig will never load it" % f)
    for w in warnings:
        print("%swarn%s  %s" % (YEL, OFF, w))
    for e in errors:
        print("%serror%s %s" % (RED, OFF, e))
    return filled


def fog_headroom():
    """The fog banks are the only layers that MOVE, so they are the only ones that can walk their
    own edge into the frame. Each sheet is wider than the viewport by `FOG_OVERHANG`, and half that
    overhang sits on each side; a bank may drift up to that half and no further.

    Checked here rather than trusted, because the failure is invisible in a still capture and only
    shows up as a hard vertical seam sliding across the hall some seconds after the screen loads —
    and the obvious future edit (raise the drift so the parallax reads more) is exactly what breaks
    it. Returns (logical_frame_width, half_overhang_px, [(name, drift), ...]).
    """
    src = open(RIG, encoding="utf-8").read()
    m = re.search(r"const FOG_OVERHANG\s*:=\s*([0-9.]+)", src)
    if not m:
        return None
    overhang = float(m.group(1))
    block = re.search(r"const FOG\s*:=\s*\[(.*?)\n\]", src, re.S)
    banks = []
    if block:
        for line in block.group(1).splitlines():
            row = re.search(r'"([A-Za-z0-9_]+\.png)"[^]]*?\]', line)
            if not row:
                continue
            nums = re.findall(r"(-?\d+\.\d+)", line[row.end(1):])
            if len(nums) >= 4:
                banks.append((row.group(1), float(nums[-3])))   # drift, period, breath
    frame = 640.0                       # the internal resolution (TD-042)
    return frame, frame * overhang * 0.5, banks


def selftest():
    """Assert the RULES, not any particular finding — the spec_status.py convention."""
    slots = rig_slots()
    assert "hall_plate.png" in slots, "the plate slot must be derivable from the rig"
    assert "banner_left.png" in slots and "brazier.png" in slots, "prop slots must be derivable"
    assert len(slots) == len(set(slots)), "slots must be de-duplicated"
    sized, named = manifest_specs()
    assert sized, "the manifest must yield sized rows"
    assert named >= set(slots), "every rig slot must be named in the manifest"
    assert set(slots) >= named, "the manifest must not name a slot the rig lacks"
    w, h, depth, ctype, interlace = probe(os.path.join(
        ROOT, "client", "assets", "ui", "board", "board_header.png"))
    assert (w, h) == (204, 38) and depth == 8 and ctype == 6 and interlace == 0, \
        "probe() must read a known PNG's IHDR: got %dx%d depth=%d type=%d" % (w, h, depth, ctype)
    fog = fog_headroom()
    assert fog is not None, "FOG_OVERHANG must be derivable from the rig"
    frame, half, banks = fog
    assert len(banks) == 3, "three fog banks expected, parsed %d" % len(banks)
    for name, drift in banks:
        assert drift <= half, (
            "%s drifts %.1fpx but only %.1fpx of overhang sits on each side — its edge would "
            "enter the frame. Widen the sheets in gen_title_fog.py (and FOG_OVERHANG) or cut the "
            "drift." % (name, drift, half))
    assert rig_slots() == slots, "parsing must be deterministic"
    print("selftest: OK  (fog headroom %.0fpx; drifts %s)"
          % (half, ", ".join("%s %.0f" % (n.split("_")[1][:-4], d) for n, d in banks)))
    return 0


def main(argv):
    if "--selftest" in argv:
        return selftest()
    check = "--check" in argv
    slots = rig_slots()
    if not check:
        landed = install()
        for name in landed:
            print("%sinstalled%s %s" % (GRN, OFF, name))
    rows, errors, warnings = audit()
    report(rows, errors, warnings, slots)
    if not check and "--import" in argv:
        return run_import()
    if errors:
        print(RED + "contract violated" + OFF)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
