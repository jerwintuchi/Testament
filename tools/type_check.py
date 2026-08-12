#!/usr/bin/env python3
"""Guard the Quartermaster's readable type floor (TD-117).

Two checks, because the defect had two halves and only one of them was visible in a
still frame.

**The floor.** Almendra below about 10px is cramped to the point of unreadability —
chosen by looking at a specimen (`--type-sheet` in the client), not guessed. Every text
size on the Quartermaster's screens is scanned out of the source and compared against it,
so a future edit cannot quietly drop a label back to 8px.

**Descenders.** The complaint that started this was "the party may" rendering as "the
vartu mau". Contrast measured fine and the glyphs were fine — the ScrollContainer was
slicing the last line in half, taking the tails off p and y. So given a specimen capture,
this also asserts that a word WITH descenders reaches lower than the same word without.
That is the only automatic way to catch a clipped line: it is invisible to any contrast
or size measurement, and it looks exactly like a broken font.

    python3 tools/type_check.py                       # the floor, from source
    python3 tools/type_check.py --sheet <capture.png>  # + descenders, from a specimen
    python3 tools/type_check.py --selftest
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
QM = "client/scripts/stations/quartermaster"

# The readable floor, chosen off the specimen. Body prose wants 11; a short all-caps
# label holds at 10; nothing on this screen may go below that.
FLOOR = 10

# The smallest size the client's `--type-sheet` renders. Bands below FLOOR are shown on
# purpose, as the evidence for where the floor is; they are not asserted.
SHEET_FIRST = 7

# `Widgets.card_label(text, SIZE, ...)` and `add_theme_font_size_override("font_size", N)`
SIZE_CALL = re.compile(r"card_label\(\s*[^,]+,\s*(\d+)\s*,")
SIZE_OVERRIDE = re.compile(r'font_size_override\(\s*"font_size"\s*,\s*(\d+)\s*\)')

GREEN, RED, DIM, OFF = "\033[32m", "\033[31m", "\033[2m", "\033[0m"


def qm_sources():
    d = os.path.join(ROOT, QM)
    return {f: open(os.path.join(d, f)).read()
            for f in sorted(os.listdir(d)) if f.endswith(".gd")}


def offenders(srcs, floor=FLOOR):
    """(file, line, size, snippet) for every declared size under the floor."""
    out = []
    for name, src in srcs.items():
        for i, line in enumerate(src.splitlines(), 1):
            for rx in (SIZE_CALL, SIZE_OVERRIDE):
                for m in rx.finditer(line):
                    size = int(m.group(1))
                    if size < floor:
                        out.append((name, i, size, line.strip()[:72]))
    return out


def descenders(png):
    """(ok, why) — in a specimen capture, does ink reach below the baseline?

    The sheet prints, for each size, a word with descenders beside one without. If the
    two have the same ink bottom, the tails have been cut off.
    """
    sys.path.insert(0, os.path.join(ROOT, "client/assets/ui"))
    from pngio import read_png                       # noqa: E402 (path set above)
    w, h, px = read_png(png)

    rows = []                       # (top, bottom) of each band of lit rows
    lit_prev, start = False, 0
    for y in range(h):
        lit = any(px(x, y)[0] > 90 for x in range(14, min(w, 900), 2))
        if lit and not lit_prev:
            start = y
        elif not lit and lit_prev and y - start > 3:
            rows.append((start, y - 1))
        lit_prev = lit
    if len(rows) < 4:
        return (False, "found %d text rows in the specimen; expected at least 4" % len(rows))

    # The sheet alternates lower-case (with descenders) and CAPS (without) per size,
    # ascending from SHEET_FIRST. Sizes BELOW the floor are expected to fail — that is
    # what the floor is for — so only the ones we actually ship are asserted.
    bad, checked = [], 0
    for i in range(0, len(rows) - 1, 2):
        size = SHEET_FIRST + i // 2
        if size < FLOOR:
            continue
        checked += 1
        low, caps = rows[i], rows[i + 1]
        if low[1] - low[0] <= caps[1] - caps[0]:
            bad.append(size)
    if bad:
        return (False, "descenders clipped at %s (floor is %dpx)"
                % ("px, ".join(str(b) for b in bad) + "px", FLOOR))
    return (True, "descenders survive at every shipped size (%d of %d bands checked)"
            % (checked, len(rows) // 2))


def report(argv):
    srcs = qm_sources()
    bad = offenders(srcs)
    print("Quartermaster type floor%s  (>= %dpx, TD-117)%s" % (DIM, FLOOR, OFF))
    if bad:
        for name, line, size, snippet in bad:
            print("  %s%-16s:%-4d %2dpx  %s%s" % (RED, name, line, size, snippet, OFF))
    else:
        n = sum(len(SIZE_CALL.findall(s)) + len(SIZE_OVERRIDE.findall(s))
                for s in srcs.values())
        print("  %severy declared size is at or above the floor  (%d sizes)%s"
              % (GREEN, n, OFF))

    sheet = None
    if "--sheet" in argv:
        sheet = argv[argv.index("--sheet") + 1]
    if sheet:
        ok, why = descenders(sheet)
        print("  %s%s%s" % (GREEN if ok else RED, why, OFF))
        if not ok:
            bad.append(("specimen", 0, 0, why))
    return 1 if bad else 0


def selftest():
    srcs = qm_sources()
    assert not offenders(srcs), "the shipped screens must pass their own floor"
    # …and the check must BITE: a label one step under the floor has to be caught.
    broken = dict(srcs)
    broken["room.gd"] = srcs["room.gd"].replace(
        'card_label("COLLEGIUM STORES · EXPEDITION ISSUE", 10,',
        'card_label("COLLEGIUM STORES · EXPEDITION ISSUE", 8,', 1)
    assert broken["room.gd"] != srcs["room.gd"], "the substitution did not apply"
    found = offenders(broken)
    assert any(f == "room.gd" and s == 8 for f, _l, s, _t in found), \
        "an 8px label slipped past the floor check"
    # A size at the floor exactly is fine; one below is not.
    assert not offenders(srcs, floor=1)
    print("selftest: OK  (shipped screens pass, and an 8px label is caught)")


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        selftest()
    else:
        sys.exit(report(sys.argv[1:]))
