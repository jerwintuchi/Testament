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
    python3 tools/title_assets.py --budget    compute + enforce the atmosphere budget (R272)
    python3 tools/title_assets.py --import    install, then run Godot's importer over the client

Nothing here generates art: painted source art is copied byte-for-byte, because re-encoding a
painted matte through a pixel-art generator is exactly the register mistake TD-055 warns about.
"""
import math
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


MATTE = os.path.join(ROOT, "client", "assets", "ui", "gen_title_matte.py")

# The measured nave vanishing point, on the UNCROPPED source (tools/measure_reference.py).
VP_SRC_FY = 0.8651
SRC_H = 1024

# Budget ceilings (R272, mobile-first). They live here, beside the numbers they bound, so the
# check cannot be satisfied by editing a comment.
MAX_PARTICLES = 120
MAX_FULLFRAME = 3
MAX_FILL_SCREENS = 2.5
LOGICAL_W, LOGICAL_H = 640.0, 360.0        # TD-042; fill is a RATIO, so it holds at any device res


def check_vp():
    """Re-derive the nave VP from the plate's crop box and assert the rig agrees (T289/P137).

    The measurement is taken on the uncropped source; `gen_title_matte.py` crops before scaling, so
    the rig's fraction is NOT the measured one. Getting this wrong puts the vanishing point ~24
    logical px off — invisible in a still, and visibly wrong the moment the air moves along it. A
    future re-crop of the plate must therefore fail here rather than quietly skew the air.
    """
    m = re.search(r"\.crop\(\((\d+),\s*(\d+),\s*(\d+),\s*(\d+)\)\)",
                  open(MATTE, encoding="utf-8").read())
    assert m, "could not read the plate's crop box out of gen_title_matte.py"
    top, bottom = int(m.group(2)), int(m.group(4))
    want = (VP_SRC_FY * SRC_H - top) / float(bottom - top)
    got = re.search(r"const NAVE_VP\s*:=\s*Vector2\(([0-9.]+),\s*([0-9.]+)\)",
                    open(RIG, encoding="utf-8").read())
    assert got, "NAVE_VP must be derivable from the rig"
    have = float(got.group(2))
    assert abs(have - want) < 0.002, (
        "NAVE_VP.y is %.4f but the plate's crop (%d..%d of %d) puts the measured nave VP at %.4f. "
        "Either the plate was re-cropped and the rig was not updated, or the constant was set by "
        "eye." % (have, top, bottom, SRC_H, want))
    return want


def budget():
    """Compute and enforce the atmosphere budget (R272, performance canon P3).

    Fill is the fraction of the screen covered by additive blending each frame, summed over every
    particle and overlay. It is a RATIO, so it is computed in logical units and holds identically at
    720p and 1080p — which is the point: the cost is paid at device resolution, but the ratio is not.
    A still capture cannot show a frame cost, so if this is not a test it is a comment.
    """
    src = open(RIG, encoding="utf-8").read()
    screen = LOGICAL_W * LOGICAL_H
    rows, particles, fill, fullframe = [], 0, 0.0, 0

    block = re.search(r"const BANKS\s*:=\s*\[(.*?)\n\]", src, re.S)
    assert block, "BANKS must be derivable from the rig"
    for line in block.group(1).splitlines():
        n = re.findall(r"(-?\d+\.?\d*)", line.split("Color")[0])
        if len(n) < 2 or not line.strip().startswith("["):
            continue
        count, radius = int(float(n[0])), float(n[1])
        area = math.pi * radius * radius
        particles += count
        fill += count * area / screen
        rows.append(("bank r=%.0f" % radius, count, count * area / screen))

    d = re.search(r"_particles\(root,\s*(\d+),.*?scale_amount_max\s*=\s*([0-9.]+)", src, re.S)
    if d:
        count, smax = int(d.group(1)), float(d.group(2))
        area = math.pi * (smax * 128.0 * 0.5) ** 2
        particles += count
        fill += count * area / screen
        rows.append(("dust", count, count * area / screen))

    rays = re.search(r"const RAYS\s*:=\s*\[(.*?)\n\]", src, re.S)
    if rays:
        for line in rays.group(1).splitlines():
            v = re.search(r"Vector3\(([0-9.]+),\s*([0-9.]+),\s*([0-9.]+)\)", line)
            if not v:
                continue
            w = float(v.group(3)) * LOGICAL_W
            h = w * 1.20                      # the ray sheet's aspect, as the rig builds it
            fill += (w * h) / screen
            rows.append(("god ray w=%.0f" % w, 1, (w * h) / screen))

    for lit in re.findall(r'\["([a-z_]+\.png)",\s*Vector3\([0-9.]+,\s*[0-9.]+,\s*([0-9.]+)\)', src):
        if float(lit[1]) >= 1.0:
            fullframe += 1
            fill += 1.0
            rows.append((lit[0], 1, 1.0))

    print("%sAtmosphere budget%s%s  (mobile-first, R272)%s" % (BOLD, OFF, DIM, OFF))
    for name, count, f in rows:
        print("  %-18s x%-4d %6.3f screens" % (name, count, f))
    bad = []
    def line(label, got, ceil, fmt="%d"):
        ok = got <= ceil
        if not ok:
            bad.append(label)
        print("  %s%-22s %s / %s%s" % (GRN if ok else RED, label,
              fmt % got, fmt % ceil, OFF))
    print()
    line("live particles", particles, MAX_PARTICLES)
    line("full-frame additive", fullframe, MAX_FULLFRAME)
    line("additive fill", fill, MAX_FILL_SCREENS, "%.2f")
    if bad:
        print("%sover budget: %s%s" % (RED, ", ".join(bad), OFF))
        return 1
    print("%swithin budget%s" % (GRN, OFF))
    return 0


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
    vp = check_vp()
    assert rig_slots() == slots, "parsing must be deterministic"
    print("selftest: OK  (nave VP fy %.4f, re-derived from the plate's crop)" % vp)
    return 0


def main(argv):
    if "--selftest" in argv:
        return selftest()
    if "--budget" in argv:
        return budget()
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
