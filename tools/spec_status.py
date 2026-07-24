#!/usr/bin/env python3
"""Derive the status of every spec in `specs/` — so a stale one cannot hide.

Why this exists (TD-074): specs are written in one session and the code moves on in
another. Two failure modes have already cost real time, and they look nothing alike:

  * `specs/notice-board/` carried unchecked boxes for work that HAD shipped, describing
    a board redesigned three times underneath it. Finishing the "tail" meant verifying a
    board that no longer existed.
  * `specs/station-ui/` had the reverse: CLAUDE.md announced a "Stipend-priced
    Quartermaster" as shipped, while `price`, `STARTING_STIPEND` and `stipend` exist
    nowhere in `src/`. The boxes were open and honest; the summary was wrong.

Neither is visible by reading a task list, because a task list only ever describes its
own intent. So this scans the repo and reports the DISAGREEMENTS:

  DANGLING   a spec names a file that is not in the tree (the strongest rot signal —
             `threat_pips.tscn` would have flagged notice-board AND station-ui)
  CLAIM      CLAUDE.md calls a spec complete/shipped while its boxes are open
  STALE      open boxes, and nothing has touched the spec in a long while
  BLOCKED    open boxes that say so themselves

Stdlib only, same discipline as `tools/asset_map.py`. Read-only: it never edits a spec.

    python3 tools/spec_status.py                # write docs/technical/spec-status.md
    python3 tools/spec_status.py --check        # exit 1 if the committed report is stale
    python3 tools/spec_status.py --json         # machine-readable, for the HTML view
    python3 tools/spec_status.py --selftest     # assert known findings + determinism
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPECS = os.path.join(ROOT, "specs")
OUT = os.path.join(ROOT, "docs", "technical", "spec-status.md")
CLAUDE_MD = os.path.join(ROOT, "CLAUDE.md")

# A spec with open boxes and no activity in this long is worth a look.
STALE_DAYS = 45

RE_TASK = re.compile(r"^\s*-\s*\[( |x|~|X)\]\s*(T\d+[a-z]?)", re.M)
RE_BANNER = re.compile(r"\*\*STATUS:\s*(CLOSED|SUPERSEDED|PAUSED|BLOCKED)", re.I)
RE_SUPERSEDED = re.compile(r"\*\*(SUPERSEDED|CLOSED)\b", re.I)
# Backticked paths/filenames. Extension-anchored so prose stays out of the results.
# `.md` is deliberately absent: a task naming its own playtest.md says nothing about
# whether the CODE shipped, and it produced a false LIKELY-SHIPPED on every "full pass" task.
RE_PATH = re.compile(r"`([A-Za-z0-9_./\-]+\.(?:gd|tscn|tres|ts|py|png|gdshader|lua))`")
# Paths that are patterns/templates rather than literals, or deliberately historical.
IGNORE_PATH = re.compile(r"[%*{]|^archive/|/archive/|^docs/|^specs/")


def sh(*args: str) -> str:
    try:
        return subprocess.run(
            args, cwd=ROOT, capture_output=True, text=True, check=False
        ).stdout.strip()
    except Exception:
        return ""


def repo_files() -> tuple[set[str], dict[str, list[str]]]:
    """Every tracked file, by full path and by basename."""
    out = sh("git", "ls-files")
    paths = set(p for p in out.split("\n") if p)
    by_base: dict[str, list[str]] = {}
    for p in paths:
        by_base.setdefault(os.path.basename(p), []).append(p)
    return paths, by_base


def last_touch(rel: str) -> tuple[str, int]:
    """(iso date, days ago) of the last commit touching a path."""
    iso = sh("git", "log", "-1", "--format=%cI", "--", rel)
    if not iso:
        return ("—", 10**6)
    when = datetime.fromisoformat(iso)
    days = (datetime.now(timezone.utc) - when.astimezone(timezone.utc)).days
    return (when.date().isoformat(), days)


def claude_context() -> dict[str, dict]:
    """What CLAUDE.md says about each spec: is it @-included, and how is it labelled?

    The label is read from the line that first mentions `specs/<name>/`, which is where
    the active-work block states Active / Completed / Paused / CLOSED.
    """
    try:
        text = open(CLAUDE_MD, encoding="utf-8").read()
    except OSError:
        return {}
    included = set(re.findall(r"^@specs/([^/]+)/", text, re.M))
    out: dict[str, dict] = {}
    for line in text.split("\n"):
        for name in re.findall(r"`?specs/([a-z0-9\-]+)/", line):
            if name in out:
                continue
            low = line.lower()
            # Negation wins. A corrected block reads "PARTLY shipped … NOT BUILT", and the bare
            # keyword scan called that "completed" — the tool flagging its own correction.
            if re.search(r"\bnot built\b|\bpartly\b|\bdoes not exist\b|\bnot implemented\b", low):
                label = "partial"
            elif "closed" in low:
                label = "closed"
            elif "completed" in low or "shipped" in low or "complete" in low:
                label = "completed"
            elif "paused" in low:
                label = "paused"
            elif "active spec" in low:
                label = "active"
            else:
                continue
            out[name] = {"label": label, "line": line.strip()}
    for name in included:
        out.setdefault(name, {"label": "active", "line": "@-included in CLAUDE.md"})
        out[name]["included"] = True
    return out


def scan_spec(name: str, files: set[str], by_base: dict[str, list[str]]) -> dict:
    d = os.path.join(SPECS, name)
    tasks_path = os.path.join(d, "tasks.md")
    text = open(tasks_path, encoding="utf-8").read() if os.path.isfile(tasks_path) else ""

    done = open_ = superseded = 0
    open_ids: list[str] = []
    for mark, tid in RE_TASK.findall(text):
        if mark == " ":
            open_ += 1
            open_ids.append(tid)
        elif mark == "~":
            superseded += 1
        else:
            done += 1

    # Open tasks that declare their own blocker.
    blocked = [
        tid
        for mark, tid in RE_TASK.findall(text)
        if mark == " "
        and re.search(
            r"\*\*" + re.escape(tid) + r"\b.*?BLOCKED",
            text[text.index(tid) : text.index(tid) + 400],
            re.S | re.I,
        )
    ]
    if not blocked:
        blocked = [t for t in open_ids if re.search(r"\[ \]\s*" + t + r"\b[^\n]*(\n(?!\s*-\s*\[).*){0,8}BLOCKED", text)]

    def exists(p: str) -> bool:
        # A bare basename counts if the tree holds it anywhere: TD-069 relocated a lot,
        # and a spec written before the move still names the old path honestly.
        return p in files or bool(by_base.get(os.path.basename(p)))

    def named_in(body: str) -> set[str]:
        out = set()
        for m in RE_PATH.finditer(body):
            p = m.group(1)
            if IGNORE_PATH.search(p):
                continue
            # A file named inside a block already marked superseded is history, not rot.
            para_start = body.rfind("\n\n", 0, m.start())
            if RE_SUPERSEDED.search(body[max(0, para_start) : m.start()]):
                continue
            out.add(p)
        return out

    # ── Per-OPEN-task resolution. This is the pair of signals that matter, and they
    #    point in opposite directions:
    #      every named file missing  -> the design was probably replaced (rot)
    #      every named file present  -> the work probably shipped and nobody ticked it
    #    The second is how `specs/collegium-client/` sat at 0/7 while its code ran fine.
    blocks = list(RE_TASK.finditer(text))
    missing: list[str] = []
    shipped_hint: list[str] = []
    for i, m in enumerate(blocks):
        if m.group(1) != " ":
            continue
        tid = m.group(2)
        body = text[m.end() : blocks[i + 1].start() if i + 1 < len(blocks) else len(text)]
        paths = named_in(body)
        if not paths:
            continue
        here = [p for p in sorted(paths) if not exists(p)]
        missing += [p for p in here if p not in missing]
        # Evidence of shipping must be an IMPLEMENTATION file. `gear.test.ts` exists and always
        # did; it proved nothing about whether the Stipend inside it was ever built, and it made
        # station-ui's T125/T126 read as shipped when they are the biggest real gap in the repo.
        impl = [p for p in paths if not p.endswith((".test.ts", ".test.tsx", "_test.py"))]
        if not here and impl and tid not in blocked:
            shipped_hint.append(tid)

    banner = RE_BANNER.search(text)
    when, days = last_touch(os.path.relpath(d, ROOT))
    return {
        "name": name,
        "done": done,
        "open": open_,
        "superseded": superseded,
        "open_ids": open_ids,
        "blocked": sorted(set(blocked)),
        "missing": missing,
        "shipped_hint": shipped_hint,
        "banner": banner.group(1).upper() if banner else None,
        "last": when,
        "days": days,
    }


def classify(s: dict, ctx: dict) -> dict:
    c = ctx.get(s["name"], {})
    label = c.get("label")
    flags: list[dict] = []

    if s["banner"] in ("CLOSED", "SUPERSEDED"):
        status = "closed"
    elif s["open"] == 0 and s["done"] > 0:
        status = "done"
    elif s["open"] and s["blocked"] and len(s["blocked"]) >= s["open"]:
        status = "blocked"
    elif c.get("included") or label == "active":
        status = "active"
    elif s["open"]:
        status = "dormant"
    else:
        status = "unknown"

    # Only meaningful while work is open. A finished spec naming a since-retired asset is
    # history, not rot — flagging those buried the two real findings under 20 false ones.
    if s["missing"] and status in ("active", "dormant", "blocked"):
        flags.append({
            "kind": "MISSING",
            "detail": "open tasks name %d file(s) not in the tree: %s"
            % (len(s["missing"]), ", ".join(s["missing"][:4])),
        })
    if s["shipped_hint"] and status in ("active", "dormant"):
        flags.append({
            "kind": "LIKELY-SHIPPED",
            "detail": "%d open task(s) name only files that already exist — check whether "
            "the work shipped and the box was never ticked: %s"
            % (len(s["shipped_hint"]), ", ".join(s["shipped_hint"][:6])),
        })
    if label in ("completed", "closed") and s["open"] and status != "closed":
        unblocked = [t for t in s["open_ids"] if t not in s["blocked"]]
        if unblocked:
            flags.append({
                "kind": "CLAIM",
                "detail": 'CLAUDE.md calls this "%s" but %d task(s) are open: %s'
                % (label, len(unblocked), ", ".join(unblocked[:6])),
            })
    if s["open"] and s["days"] > STALE_DAYS and status not in ("closed", "blocked"):
        flags.append({
            "kind": "STALE",
            "detail": "%d open task(s), untouched for %d days" % (s["open"], s["days"]),
        })
    return {**s, "status": status, "claude": label, "flags": flags}


ORDER = {"active": 0, "blocked": 1, "dormant": 2, "done": 3, "closed": 4, "unknown": 5}


def collect() -> list[dict]:
    files, by_base = repo_files()
    ctx = claude_context()
    rows = [
        classify(scan_spec(n, files, by_base), ctx)
        for n in sorted(os.listdir(SPECS))
        if os.path.isdir(os.path.join(SPECS, n))
    ]
    rows.sort(key=lambda r: (not r["flags"], ORDER[r["status"]], r["name"]))
    return rows


BADGE = {
    "active": "🟢 active",
    "blocked": "⛔ blocked",
    "dormant": "🟡 dormant",
    "done": "✅ done",
    "closed": "⚪ closed",
    "unknown": "❔ unknown",
}


def render(rows: list[dict]) -> str:
    L: list[str] = []
    A = L.append
    A("# Spec status — derived, do not hand-edit")
    A("")
    A("> Generated by `tools/spec_status.py`. Regenerate after any spec change;")
    A("> `--check` fails if this file has drifted. Rationale in DECISION_LOG **TD-074**.")
    A("")
    flagged = [r for r in rows if r["flags"]]
    A("**%d specs** — %d flagged for review." % (len(rows), len(flagged)))
    A("")

    if flagged:
        A("## ⚠ Needs attention")
        A("")
        A("These are disagreements between what a spec says and what the tree contains.")
        A("")
        for r in flagged:
            A("### `specs/%s/` — %s" % (r["name"], BADGE[r["status"]]))
            A("")
            for f in r["flags"]:
                A("- **%s** — %s" % (f["kind"], f["detail"]))
            A("")

    A("## All specs")
    A("")
    A("| spec | status | done | open | superseded | last touched | flags |")
    A("|---|---|---:|---:|---:|---|---|")
    for r in rows:
        A(
            "| `%s` | %s | %d | %d | %d | %s | %s |"
            % (
                r["name"],
                BADGE[r["status"]],
                r["done"],
                r["open"],
                r["superseded"],
                r["last"],
                ", ".join(f["kind"] for f in r["flags"]) or "—",
            )
        )
    A("")
    A("## What the statuses mean")
    A("")
    A("- **active** — open tasks, and CLAUDE.md points at it as current work.")
    A("- **blocked** — every open task declares its own blocker (missing tool, missing asset).")
    A("- **dormant** — open tasks, but nothing in CLAUDE.md claims it is being worked on.")
    A("- **done** — every task ticked.")
    A("- **closed** — a `**STATUS: CLOSED/SUPERSEDED**` banner; kept for the record.")
    A("")
    A("## What the flags mean")
    A("")
    A("- **MISSING** — an OPEN task names a file that is not in the tree. Either the design")
    A("  was replaced underneath it, or the file is the task's own unbuilt deliverable.")
    A("  Only raised while work is open: a finished spec naming a retired asset is history.")
    A("- **LIKELY-SHIPPED** — an open task names only files that already exist. Strong hint")
    A("  the work landed in another session and the box was never ticked. This is exactly")
    A("  how `specs/collegium-client/` sat at 0 of 7 while its code ran fine every day.")
    A("- **CLAIM** — CLAUDE.md calls the spec complete while unblocked tasks are open.")
    A("  Either the summary overstates, or the boxes were never ticked. Both have happened.")
    A("- **STALE** — open tasks, untouched for over %d days." % STALE_DAYS)
    return "\n".join(L) + "\n"


def selftest(rows: list[dict]) -> int:
    """Assert the MECHANISM on synthetic rows, plus a couple of durable live invariants.

    Deliberately NOT pinned to specific live findings. The first version asserted that
    `station-ui` raises CLAIM — then CLAIM was resolved by correcting CLAUDE.md and the
    selftest went red for doing its job. `asset_map.py` made exactly this mistake and sat
    red from TD-058 to TD-069. A finding is transient; the rule that produces it is not.
    """
    ok = True

    def check(cond: bool, msg: str) -> None:
        nonlocal ok
        if not cond:
            ok = False
            print("FAIL:", msg)

    def synth(**kw) -> dict:
        base = dict(
            name="synthetic", done=1, open=0, superseded=0, open_ids=[], blocked=[],
            missing=[], shipped_hint=[], banner=None, last="2026-01-01", days=0,
        )
        base.update(kw)
        return base

    def kinds(row: dict, ctx: dict) -> set[str]:
        return {f["kind"] for f in classify(row, ctx)["flags"]}

    # ── CLAIM: "completed" in CLAUDE.md while unblocked tasks are open.
    claim = synth(open=2, open_ids=["T1", "T2"])
    check(
        "CLAIM" in kinds(claim, {"synthetic": {"label": "completed"}}),
        "CLAIM must fire when CLAUDE.md says completed and unblocked tasks are open",
    )
    check(
        "CLAIM" not in kinds(claim, {"synthetic": {"label": "partial"}}),
        'CLAIM must NOT fire on a "partly shipped / NOT BUILT" block (negation wins)',
    )
    blocked_only = synth(open=1, open_ids=["T9"], blocked=["T9"])
    check(
        "CLAIM" not in kinds(blocked_only, {"synthetic": {"label": "completed"}}),
        "CLAIM must NOT fire when every open task declares its own blocker",
    )

    # ── MISSING / LIKELY-SHIPPED: opposite signals, both open-work only.
    miss = synth(open=1, open_ids=["T1"], missing=["gone.gd"])
    check("MISSING" in kinds(miss, {}), "MISSING must fire for an open task naming an absent file")
    check(
        "MISSING" not in kinds(synth(missing=["gone.gd"]), {}),
        "MISSING must NOT fire on a finished spec — a retired asset is history, not rot",
    )
    ship = synth(open=1, open_ids=["T1"], shipped_hint=["T1"])
    check("LIKELY-SHIPPED" in kinds(ship, {}), "LIKELY-SHIPPED must fire when named files all exist")

    # ── STALE
    old = synth(open=1, open_ids=["T1"], days=STALE_DAYS + 1)
    check("STALE" in kinds(old, {}), "STALE must fire past the threshold")

    # ── Durable live invariants (structural, not finding-specific).
    by = {r["name"]: r for r in rows}
    check(len(rows) > 10, "the scan must find the spec folders")
    check(
        by.get("notice-board", {}).get("status") == "closed",
        "a **STATUS: CLOSED** banner must classify as closed (notice-board carries one)",
    )
    check(all(r["status"] in ORDER for r in rows), "every spec must classify to a known status")
    check(collect() == rows, "collect() must be deterministic")
    print("selftest:", "OK" if ok else "FAILED")
    return 0 if ok else 1


def main() -> int:
    args = sys.argv[1:]
    rows = collect()
    if "--selftest" in args:
        return selftest(rows)
    if "--json" in args:
        print(json.dumps(rows, indent=2))
        return 0
    text = render(rows)
    if "--check" in args:
        cur = open(OUT, encoding="utf-8").read() if os.path.isfile(OUT) else ""
        if cur != text:
            print("spec-status.md is STALE — run: python3 tools/spec_status.py")
            return 1
        print("spec-status.md is current.")
        return 0
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write(text)
    print("wrote", os.path.relpath(OUT, ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
