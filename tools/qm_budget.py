#!/usr/bin/env python3
"""qm_budget.py — enforce the Quartermaster room's render budget (TD-101 R361).

    python3 tools/qm_budget.py             print the budget and enforce it (exit 1 over)
    python3 tools/qm_budget.py --selftest  assert the RULES, and that they can fail

The stores are the second screen a player spends real time in, and the first one made
of dozens of small objects: ten instruments, ~60 pieces of dressing, a counter, a
record and a pack. Each is cheap and none is free.

Why a tool rather than a comment: **a screenshot cannot show a frame cost.** The
captures that verify how the room *looks* say nothing about what it costs, and
"we'll check later" never arrives with a number attached. Same argument and same
shape as `world_budget.py` (TD-081) and `title_assets --budget` (TD-078).

The node count itself is measured at RUN time — the room prints
`qm nodes=<n>/<budget>` once at build — because a static count of `.new()` calls
would miss every loop. What this tool enforces is that the ceiling exists, that the
room checks itself against it, and the four structural rules that a number cannot
express.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
QM = os.path.join(ROOT, "client", "scripts", "stations", "quartermaster")
FILES = ["register.gd", "room.gd", "shelf.gd", "counter.gd", "pack.gd", "record.gd"]
GEAR = os.path.join(ROOT, "src", "shared", "src", "gear.ts")
ICONS = os.path.join(ROOT, "client", "assets", "ui", "stations", "gear_icons.png")
LORE = os.path.join(QM, "lore.gd")

# Ceilings. Generous on purpose: these catch the change that adds an emitter per
# shelf or a per-frame path, not a wasted millisecond.
MAX_NODES = 260
MAX_PARTICLES = 20

BOLD = "\033[1m"; DIM = "\033[2m"; RED = "\033[31m"; GRN = "\033[32m"; OFF = "\033[0m"


def read(name):
    with open(os.path.join(QM, name), encoding="utf-8") as f:
        return f.read()


def read_all():
    return {n: read(n) for n in FILES}


def const(src, name):
    m = re.search(r"const %s\s*:=\s*(\d+)" % re.escape(name), src)
    return int(m.group(1)) if m else None


def catalog_ids():
    """Item ids from the shared catalog — the authority both sides read."""
    with open(GEAR, encoding="utf-8") as f:
        return re.findall(r"\{\s*id:\s*'([a-z0-9-]+)'", f.read())


def lore_ids():
    """Ids the client's record table actually answers for."""
    with open(LORE, encoding="utf-8") as f:
        body = f.read().split("const RECORDS := {", 1)[-1]
    return re.findall(r'^\t"([a-z0-9-]+)":', body, re.M)


def coverage():
    """Instruments with no record, and records for instruments that do not exist.

    The seam neither side's tests reach: the catalog is TypeScript, the prose is
    GDScript. `Record.show_item` falls back to an EMPTY entry, so a missing record is
    a silently blank ledger on a real instrument — the same shape of hole
    `lexicon_check.py` closes for signs.
    """
    cat, lore = set(catalog_ids()), set(lore_ids())
    return sorted(cat - lore), sorted(lore - cat)


# P177: gold is the order's colour — selection, headings, the insignia, the seal, the
# ready state. An instrument may CATCH gold light on a brass fitting; it may not be
# MADE of gold. The line is a proportion, not zero: TD-102's audit asserted zero, which
# was right while the icons were flat fills and wrong the moment brass earned speculars
# (TD-110). A highlight is a few pixels; a field is a face.
GOLD_FIELD_MAX = 0.08          # of an instrument's opaque pixels
BRIGHT_GOLD = ((0xB0, 0x8A, 0x3E), (0xD6, 0xAE, 0x5C))


def gold_load():
    """(name, gold_fraction) per instrument, worst first. Empty if the sheet is absent."""
    try:
        sys.path.insert(0, os.path.join(ROOT, "client", "assets", "ui"))
        from pngio import read_png            # noqa: PLC0415  (tool-only import)
        w, h, px = read_png(ICONS)
    except Exception:
        return []
    names = [i for i in catalog_ids()]
    out = []
    for i, name in enumerate(names):
        opaque = gold = 0
        for y in range(h):
            for x in range(i * h, (i + 1) * h):
                if x >= w:
                    break
                r, g, b, a = px(x, y)
                if a == 0:
                    continue
                opaque += 1
                if (r, g, b) in BRIGHT_GOLD:
                    gold += 1
        if opaque:
            out.append((name, gold / float(opaque)))
    out.sort(key=lambda t: -t[1])
    return out


def findings(srcs):
    """(label, value, ceiling) numerics, plus (label, ok, why) structural checks."""
    reg = srcs["register.gd"]
    joined = "\n".join(srcs.values())

    numeric = [
        ("node budget", const(reg, "NODE_BUDGET"), MAX_NODES),
        ("particle budget", const(reg, "PARTICLE_BUDGET"), MAX_PARTICLES),
        # The live emitter, not just the ceiling: a budget nobody spends against is a
        # number in a comment.
        ("dust motes emitted", const(srcs["room.gd"], "DUST_COUNT"), MAX_PARTICLES),
    ]

    structural = [
        # A ceiling nothing compares against is decoration. The room must count itself.
        ("room checks its own node count",
         re.search(r"if n > NODE_BUDGET", reg) is not None,
         "register.gd must compare its measured node count against NODE_BUDGET"),

        # …and say the number out loud, so a capture run carries the measurement.
        ("node count is printed",
         re.search(r"qm nodes=", reg) is not None,
         "the count must be printed, or nobody can read it from a run"),

        # No per-frame script path anywhere in the feature. Everything animates on a
        # tween, which frees with its node and costs no frame callback.
        ("no _process in the feature",
         re.search(r"^func _process\(", joined, re.M) is None,
         "the stores must not run per frame; tweens animate without a frame callback"),

        # A full-frame additive layer is how this project has repeatedly made a screen
        # expensive (TD-078 found five of them on the title screen against a ceiling of
        # three). The room's vignette is a plain alpha ColorRect.
        ("no full-frame additive layer",
         "BLEND_MODE_ADD" not in joined,
         "a full-frame additive layer is paid at device resolution, not at 640x360"),

        # Particles must stay declared rather than sprinkled: if an emitter ever
        # appears it has to be counted against PARTICLE_BUDGET, not added silently.
        # An emitter may exist, but only a DECLARED one: its amount must come from a
        # named constant the budget can read, never a literal at the call site.
        ("emitter amount comes from a constant",
         "CPUParticles" not in joined or re.search(r"\.amount\s*=\s*DUST_COUNT", joined) is not None,
         "a particle amount must be a named constant, or the budget cannot see it"),

        # THE ONE THIS PROJECT KEEPS RELEARNING. TD-064, TD-065 and TD-068 are three
        # separate fixes for a local change rebuilding a whole screen. Selecting an
        # instrument must not re-enter build().
        ("selection does not rebuild the room",
         re.search(r"static func _select\(.*?\n(?:\t.*\n|\n)*", reg) is not None
         and "build(" not in (re.search(r"static func _select\(.*?(?=\nstatic func )",
                                        reg, re.S).group(0) if re.search(
                                            r"static func _select\(.*?(?=\nstatic func )", reg, re.S) else ""),
         "_select must update the record and the moved object only, never rebuild"),
    ]
    return numeric, structural


def report(srcs):
    numeric, structural = findings(srcs)
    bad = []
    print("%sQuartermaster room budget%s%s  (the Collegium's stores, TD-101)%s" % (BOLD, OFF, DIM, OFF))
    for label, value, ceil in numeric:
        if value is None:
            bad.append(label)
            print("  %s%-34s NOT FOUND in register.gd%s" % (RED, label, OFF))
            continue
        ok = value <= ceil
        if not ok:
            bad.append(label)
        print("  %s%-34s %3d / %3d%s" % (GRN if ok else RED, label, value, ceil, OFF))
    for label, ok, why in structural:
        if not ok:
            bad.append(label)
        print("  %s%-34s %s%s" % (GRN if ok else RED, label, "ok" if ok else "FAILED — " + why, OFF))

    loads = gold_load()
    over = [(n, f) for n, f in loads if f > GOLD_FIELD_MAX]
    gold_ok = not over
    if not gold_ok:
        bad.append("gold discipline")
    gdetail = ("ok (worst %s at %.1f%%)" % (loads[0][0], loads[0][1] * 100) if loads
               else "SKIPPED — icon sheet unreadable")
    if over:
        gdetail = "FAILED — gold as a field on: %s" % ", ".join(
            "%s %.1f%%" % (n, f * 100) for n, f in over)
    print("  %s%-34s %s%s" % (GRN if gold_ok else RED, "gold is a highlight, not a field", gdetail, OFF))

    missing, orphan = coverage()
    cov_ok = not missing and not orphan
    if not cov_ok:
        bad.append("record coverage")
    detail = "ok (%d instruments)" % len(catalog_ids())
    if missing:
        detail = "FAILED — no record for: %s" % ", ".join(missing)
    elif orphan:
        detail = "FAILED — record for unknown item: %s" % ", ".join(orphan)
    print("  %s%-34s %s%s" % (GRN if cov_ok else RED, "every instrument has a record", detail, OFF))

    if bad:
        print("%sover budget: %s%s" % (RED, ", ".join(bad), OFF))
        return 1
    print("%swithin budget%s  %s(node count itself is measured at run time: `qm nodes=`)%s"
          % (GRN, OFF, DIM, OFF))
    return 0


def selftest():
    """Assert the RULES, and — the part that matters — that each one can actually fail."""
    srcs = read_all()
    numeric, structural = findings(srcs)
    assert all(v is not None for _l, v, _c in numeric), "every budgeted constant must be derivable"
    for label, ok, why in structural:
        assert ok, "the shipped room must pass its own check: %s (%s)" % (label, why)

    # A check that cannot fail is a comment. Prove each one bites against a broken copy.
    over = dict(srcs)
    over["register.gd"] = srcs["register.gd"].replace("const NODE_BUDGET     := 220",
                                                      "const NODE_BUDGET     := 9999")
    assert findings(over)[0][0][1] > MAX_NODES, "the node ceiling must catch an over-budget value"

    unchecked = dict(srcs)
    unchecked["register.gd"] = srcs["register.gd"].replace("if n > NODE_BUDGET", "if false")
    assert not findings(unchecked)[1][0][1], "the self-check rule must catch a room that never checks"

    unprinted = dict(srcs)
    unprinted["register.gd"] = srcs["register.gd"].replace("qm nodes=", "qm silent=")
    assert not findings(unprinted)[1][1][1], "the print rule must catch a silent measurement"

    dusty = dict(srcs)
    dusty["room.gd"] = srcs["room.gd"].replace("const DUST_COUNT := 14", "const DUST_COUNT := 500")
    assert findings(dusty)[0][2][1] > MAX_PARTICLES, "the dust ceiling must catch an over-budget emitter"

    literal = dict(srcs)
    literal["room.gd"] = srcs["room.gd"].replace("p.amount = DUST_COUNT", "p.amount = 500")
    assert not findings(literal)[1][4][1], "the emitter rule must catch a literal amount"

    per_frame = dict(srcs)
    per_frame["room.gd"] = srcs["room.gd"] + "\nfunc _process(_d: float) -> void:\n\tpass\n"
    assert not findings(per_frame)[1][2][1], "the _process rule must catch a per-frame path"

    additive = dict(srcs)
    additive["room.gd"] = srcs["room.gd"] + "\n# BLEND_MODE_ADD\n"
    assert not findings(additive)[1][3][1], "the additive rule must catch a full-frame add layer"

    rebuilt = dict(srcs)
    rebuilt["register.gd"] = srcs["register.gd"].replace(
        "\tvar prev := String(view[\"sel\"])",
        "\tbuild(null, null, [], Callable(), Callable(), false)\n\tvar prev := String(view[\"sel\"])")
    assert not findings(rebuilt)[1][5][1], "the rebuild rule must catch a _select that rebuilds"

    missing, orphan = coverage()
    assert not missing, "every catalog instrument must have a record: %r" % missing
    assert not orphan, "the record table must invent no instrument: %r" % orphan
    assert len(catalog_ids()) == 10, "the catalog should still hold ten instruments"

    loads = gold_load()
    assert loads, "the icon sheet must be readable"
    assert all(f <= GOLD_FIELD_MAX for _n, f in loads), \
        "no instrument may wear gold as a field: %r" % [(n, round(f, 3)) for n, f in loads if f > GOLD_FIELD_MAX]

    print("selftest: OK  (ceilings derivable, shipped room passes, and each check bites)")
    return 0


def main(argv):
    if "--selftest" in argv:
        return selftest()
    return report(read_all())


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
