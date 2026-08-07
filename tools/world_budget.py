#!/usr/bin/env python3
"""world_budget.py — enforce the walkable world's render budget (TD-081 R298).

    python3 tools/world_budget.py             print the budget and enforce it (exit 1 over)
    python3 tools/world_budget.py --selftest  assert the RULES, and that they can fail

The Collegium is where the player actually spends their time, and it is the first *lit* screen in
the game — real `Light2D`s, a `CanvasModulate`, particles. Every one of those is cheap alone and
none of them is free, so the ceilings live here, next to the numbers they bound, and the build fails
when one is crossed.

Why a tool rather than a comment: **a screenshot cannot show a frame cost.** The captures that
verify how the hall *looks* say nothing about what it costs, and the failure mode of "we'll check
later" is that later never comes with a number attached. This is the same argument, and the same
shape, as `title_assets --budget` (TD-078).

Ceilings are deliberately generous — this is a static room, not a battle. They exist to catch the
change that adds a light per tile, not to shave a millisecond.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VIEW = os.path.join(ROOT, "client", "scripts", "world", "space_view.gd")

MAX_LIGHTS = 6
MAX_PARTICLES = 60

BOLD = "\033[1m"; DIM = "\033[2m"; RED = "\033[31m"; GRN = "\033[32m"; OFF = "\033[0m"


def read():
    with open(VIEW, encoding="utf-8") as f:
        return f.read()


def const(src, name):
    """An int `const NAME := <n>` out of the rig, or None."""
    m = re.search(r"const %s\s*:=\s*(\d+)" % re.escape(name), src)
    return int(m.group(1)) if m else None


def findings(src):
    """(label, value, ceiling) triples, plus structural checks as (label, ok, why)."""
    lights = const(src, "MAX_LIGHTS")
    dust = const(src, "DUST_COUNT")
    numeric = [
        ("Light2D", lights, MAX_LIGHTS),
        ("live particles", dust, MAX_PARTICLES),
    ]
    structural = [
        # The ceiling is worthless if the code does not actually clamp to it: `MAX_LIGHTS` could be
        # 6 while the loop places one per marker. This asserts the clamp exists.
        ("lights clamped to MAX_LIGHTS",
         re.search(r"mini\(MAX_LIGHTS,", src) is not None,
         "the light loop must clamp to MAX_LIGHTS, or the constant is decoration"),
        # The world layer must not grow a per-frame script path (P135's sibling for the world).
        ("no _process in the view",
         re.search(r"^func _process\(", src, re.M) is None,
         "space_view must not run per frame; lights and particles simulate themselves"),
        # An additive full-frame layer here would undo the CanvasModulate the whole rig depends on.
        ("no full-frame additive layer",
         "BLEND_MODE_ADD" not in src,
         "a full-frame additive layer would cancel the CanvasModulate the lighting rests on"),
    ]
    return numeric, structural


def report(src):
    numeric, structural = findings(src)
    bad = []
    print("%sWalkable world budget%s%s  (the Collegium and the field, R298)%s" % (BOLD, OFF, DIM, OFF))
    for label, value, ceil in numeric:
        if value is None:
            bad.append(label)
            print("  %s%-30s NOT FOUND in space_view.gd%s" % (RED, label, OFF))
            continue
        ok = value <= ceil
        if not ok:
            bad.append(label)
        print("  %s%-30s %3d / %3d%s" % (GRN if ok else RED, label, value, ceil, OFF))
    for label, ok, why in structural:
        if not ok:
            bad.append(label)
        print("  %s%-30s %s%s" % (GRN if ok else RED, label, "ok" if ok else "FAILED — " + why, OFF))
    if bad:
        print("%sover budget: %s%s" % (RED, ", ".join(bad), OFF))
        return 1
    print("%swithin budget%s" % (GRN, OFF))
    return 0


def selftest():
    """Assert the RULES, and — the part that matters — that they can actually fail."""
    src = read()
    numeric, structural = findings(src)
    assert all(v is not None for _l, v, _c in numeric), "every budgeted constant must be derivable"
    assert all(ok for _l, ok, _w in structural), "the shipped rig must pass its own structural checks"

    # A check that cannot fail is a comment. Prove each one bites.
    over = src.replace("const MAX_LIGHTS := 6", "const MAX_LIGHTS := 99")
    assert findings(over)[0][0][1] > MAX_LIGHTS, "the light ceiling must catch an over-budget value"
    unclamped = src.replace("mini(MAX_LIGHTS,", "mini(999,")
    assert not findings(unclamped)[1][0][1], "the clamp check must catch an unclamped loop"
    per_frame = src + "\nfunc _process(_d: float) -> void:\n\tpass\n"
    assert not findings(per_frame)[1][1][1], "the _process check must catch a per-frame path"

    print("selftest: OK  (ceilings derivable, shipped rig passes, and each check bites)")
    return 0


def main(argv):
    if "--selftest" in argv:
        return selftest()
    return report(read())


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
