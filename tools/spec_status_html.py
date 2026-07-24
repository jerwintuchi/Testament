#!/usr/bin/env python3
"""Render `tools/spec_status.py`'s findings as a single self-contained HTML page.

Kept beside the scanner, and fed from it, so the page can never disagree with the report
(TD-074's whole point: a hand-maintained status page is the thing that rots).

    python3 tools/spec_status_html.py            # -> docs/technical/spec-status.html
    python3 tools/spec_status_html.py --out X    # somewhere else (e.g. an artifact file)
"""
from __future__ import annotations

import json
import os
import sys
from datetime import date

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from spec_status import collect, STALE_DAYS  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_OUT = os.path.join(ROOT, "docs", "technical", "spec-status.html")

PAGE = r"""<title>Testament — Spec Registry</title>
<style>
/* ── Tokens ────────────────────────────────────────────────────────────────
   Palette lifted from the game's own constants so the tool belongs to the
   project: Widgets.INK #2A2115, TONE_FLOOR #CBB583 (the writ paper floor), the
   engraved-title gilt (0.86,0.72,0.42), the wax oxblood, the torch ember.
   Semantic colours are deliberately separate from the gilt accent.          */
:root {
  --ground:#EDE4CC; --surface:#F6F0DF; --raised:#E4D8B8;
  --rule:#C6B489; --rule-soft:#D8CBA8;
  --text:#2A2115; --text-dim:#5C503A; --text-faint:#7C705B;
  --gilt:#8A6A22; --gilt-bright:#A5822F;
  --oxblood:#8E3229; --amber:#9A6416; --moss:#4E6E3C; --iron:#7C705B;
  --shadow:0 1px 2px rgba(42,33,21,.10), 0 6px 18px rgba(42,33,21,.07);
  --plaque:#241D14; --plaque-text:#D8B46A;
}
@media (prefers-color-scheme: dark) {
  :root {
    --ground:#15120D; --surface:#1D1810; --raised:#251E15;
    --rule:#3B3123; --rule-soft:#2C2519;
    --text:#E7DCC2; --text-dim:#AFA083; --text-faint:#83765E;
    --gilt:#D8B46A; --gilt-bright:#EFCC85;
    --oxblood:#C4574B; --amber:#D2933E; --moss:#8CB06B; --iron:#8B7E66;
    --shadow:0 1px 0 rgba(0,0,0,.5), 0 10px 26px rgba(0,0,0,.42);
    --plaque:#0F0C08; --plaque-text:#D8B46A;
  }
}
:root[data-theme="dark"] {
  --ground:#15120D; --surface:#1D1810; --raised:#251E15;
  --rule:#3B3123; --rule-soft:#2C2519;
  --text:#E7DCC2; --text-dim:#AFA083; --text-faint:#83765E;
  --gilt:#D8B46A; --gilt-bright:#EFCC85;
  --oxblood:#C4574B; --amber:#D2933E; --moss:#8CB06B; --iron:#8B7E66;
  --shadow:0 1px 0 rgba(0,0,0,.5), 0 10px 26px rgba(0,0,0,.42);
  --plaque:#0F0C08; --plaque-text:#D8B46A;
}
:root[data-theme="light"] {
  --ground:#EDE4CC; --surface:#F6F0DF; --raised:#E4D8B8;
  --rule:#C6B489; --rule-soft:#D8CBA8;
  --text:#2A2115; --text-dim:#5C503A; --text-faint:#7C705B;
  --gilt:#8A6A22; --gilt-bright:#A5822F;
  --oxblood:#8E3229; --amber:#9A6416; --moss:#4E6E3C; --iron:#7C705B;
  --shadow:0 1px 2px rgba(42,33,21,.10), 0 6px 18px rgba(42,33,21,.07);
  --plaque:#241D14; --plaque-text:#D8B46A;
}

/* Display: an inscriptional serif if the viewer has one (the project sets its own
   titles in Cinzel), falling back through Palatino-class faces. No webfont URL —
   the artifact CSP blocks font CDNs and a silent fallback is worse than a stack. */
* { box-sizing:border-box; }
body {
  margin:0; background:var(--ground); color:var(--text);
  font:15px/1.6 ui-sans-serif,system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;
  -webkit-font-smoothing:antialiased;
}
.wrap { max-width:1120px; margin:0 auto; padding:0 20px 72px; }
.disp {
  font-family:"Trajan Pro","Cinzel",Optima,"Palatino Linotype",Palatino,"Book Antiqua",Georgia,serif;
  text-transform:uppercase; letter-spacing:.14em; font-weight:600;
}
code, .mono { font-family:ui-monospace,SFMono-Regular,"SF Mono",Menlo,Consolas,monospace; }
.num { font-variant-numeric:tabular-nums; }

/* ── The plaque. Echoes the Contract Board's engraved sign — the project's most
      characteristic object, and honest here: this IS its registry.            */
header.plaque {
  background:var(--plaque); color:var(--plaque-text);
  border-bottom:1px solid var(--rule); margin-bottom:34px;
}
header.plaque .inner {
  max-width:1120px; margin:0 auto; padding:30px 20px 26px;
  display:flex; align-items:flex-end; justify-content:space-between;
  flex-wrap:wrap; gap:16px;
}
header.plaque h1 { margin:0; font-size:clamp(20px,3.4vw,30px); text-wrap:balance; }
header.plaque .sub {
  margin:7px 0 0; font-size:12.5px; letter-spacing:.05em;
  color:color-mix(in srgb, var(--plaque-text) 62%, transparent);
  font-family:ui-sans-serif,system-ui,sans-serif; text-transform:none;
}
.rule-pair { height:0; border-top:1px solid color-mix(in srgb,var(--plaque-text) 42%,transparent);
  border-bottom:1px solid color-mix(in srgb,var(--plaque-text) 18%,transparent);
  padding-top:2px; margin:0 0 14px; }

/* ── Summary ledger ───────────────────────────────────────────────────────── */
.ledger { display:grid; grid-template-columns:repeat(auto-fit,minmax(132px,1fr)); gap:1px;
  background:var(--rule); border:1px solid var(--rule); border-radius:3px; overflow:hidden; margin-bottom:10px; }
.cell { background:var(--surface); padding:14px 16px; }
.cell .k { font-size:10.5px; letter-spacing:.13em; text-transform:uppercase; color:var(--text-faint); }
.cell .v { font-size:26px; line-height:1.15; margin-top:3px; font-weight:600; }
.cell.alert .v { color:var(--oxblood); }
.strip { display:flex; height:8px; border-radius:2px; overflow:hidden; border:1px solid var(--rule); margin-bottom:32px; }
.strip span { display:block; }

/* ── Attention cards ──────────────────────────────────────────────────────── */
h2.sect { font-size:12px; letter-spacing:.16em; color:var(--text-faint);
  margin:0 0 14px; padding-bottom:8px; border-bottom:1px solid var(--rule-soft); }
.cards { display:grid; gap:14px; margin-bottom:40px; }
.card { background:var(--surface); border:1px solid var(--rule); border-left:4px solid var(--iron);
  border-radius:3px; padding:16px 18px; box-shadow:var(--shadow); }
.card.sev-critical { border-left-color:var(--oxblood); }
.card.sev-warn     { border-left-color:var(--amber); }
.card.sev-good     { border-left-color:var(--moss); }
.card h3 { margin:0 0 3px; font-size:16px; }
.card h3 code { font-size:15px; }
.card .meta { font-size:12px; color:var(--text-faint); margin-bottom:12px; }
.finding { display:grid; grid-template-columns:auto 1fr; gap:10px; align-items:start;
  padding:9px 0; border-top:1px solid var(--rule-soft); font-size:13.5px; }
.finding p { margin:0; color:var(--text-dim); }
.finding p .lead { color:var(--text); }

/* ── Chips & pills ────────────────────────────────────────────────────────── */
.chip { display:inline-block; font-size:10px; letter-spacing:.09em; text-transform:uppercase;
  font-weight:700; padding:3px 7px; border-radius:2px; white-space:nowrap;
  border:1px solid currentColor; }
.chip.CLAIM          { color:var(--oxblood); }
.chip.MISSING        { color:var(--amber); }
.chip.LIKELY         { color:var(--moss); }
.chip.STALE          { color:var(--iron); }
.pill { display:inline-flex; align-items:center; gap:6px; font-size:11.5px; white-space:nowrap; }
.pill::before { content:""; width:7px; height:7px; border-radius:50%; background:currentColor; flex:none; }
.pill.active  { color:var(--gilt); }
.pill.blocked { color:var(--oxblood); }
.pill.dormant { color:var(--iron); }
.pill.done    { color:var(--moss); }
.pill.closed  { color:var(--text-faint); }

/* ── Registry table ───────────────────────────────────────────────────────── */
.filters { display:flex; flex-wrap:wrap; gap:7px; margin:0 0 14px; }
.filters button { font:inherit; font-size:11.5px; letter-spacing:.05em; cursor:pointer;
  background:var(--surface); color:var(--text-dim); border:1px solid var(--rule);
  border-radius:2px; padding:5px 11px; }
.filters button:hover { color:var(--text); border-color:var(--text-faint); }
.filters button[aria-pressed="true"] { background:var(--raised); color:var(--text); border-color:var(--text-faint); }
.filters button:focus-visible { outline:2px solid var(--gilt-bright); outline-offset:2px; }
.tw { overflow-x:auto; border:1px solid var(--rule); border-radius:3px; background:var(--surface); }
table { border-collapse:collapse; width:100%; min-width:720px; font-size:13.5px; }
th { text-align:left; font-size:10.5px; letter-spacing:.13em; text-transform:uppercase;
  color:var(--text-faint); font-weight:600; padding:11px 14px; border-bottom:1px solid var(--rule);
  background:var(--raised); white-space:nowrap; }
td { padding:10px 14px; border-bottom:1px solid var(--rule-soft); vertical-align:middle; }
tr:last-child td { border-bottom:0; }
tr.flagged td:first-child { box-shadow:inset 3px 0 0 var(--oxblood); }
td.r { text-align:right; }
.bar { display:flex; height:6px; width:104px; border-radius:2px; overflow:hidden;
  background:var(--rule-soft); border:1px solid var(--rule); }
.bar i { display:block; }
.bar i.d { background:var(--moss); }
.bar i.o { background:var(--amber); }
.bar i.s { background:var(--iron); }

/* ── Legend ───────────────────────────────────────────────────────────────── */
.legend { display:grid; grid-template-columns:repeat(auto-fit,minmax(280px,1fr)); gap:26px; margin-top:44px; }
.legend h3 { font-size:11px; letter-spacing:.15em; color:var(--text-faint); margin:0 0 10px; }
.legend dl { margin:0; display:grid; gap:9px; }
.legend dt { font-size:12px; margin-bottom:1px; }
.legend dd { margin:0; font-size:12.5px; color:var(--text-dim); max-width:62ch; }
footer { margin-top:44px; padding-top:16px; border-top:1px solid var(--rule-soft);
  font-size:12px; color:var(--text-faint); }
@media (max-width:640px) { .card { padding:14px; } .cell { padding:12px; } }
</style>

<header class="plaque">
  <div class="inner">
    <div>
      <div class="rule-pair"></div>
      <h1 class="disp">Spec Registry</h1>
      <p class="sub">Derived from <code>specs/</code> and the working tree — never hand-maintained</p>
    </div>
    <p class="sub" id="stamp"></p>
  </div>
</header>

<div class="wrap">
  <div class="ledger" id="ledger"></div>
  <div class="strip" id="strip" role="img" aria-label="Distribution of specs by status"></div>

  <section id="attention"></section>

  <h2 class="sect disp">The registry</h2>
  <div class="filters" id="filters"></div>
  <div class="tw">
    <table>
      <thead><tr>
        <th scope="col">Spec</th><th scope="col">Status</th><th scope="col">Progress</th>
        <th scope="col" class="r">Done</th><th scope="col" class="r">Open</th>
        <th scope="col" class="r">Sup.</th><th scope="col">Last touched</th><th scope="col">Findings</th>
      </tr></thead>
      <tbody id="rows"></tbody>
    </table>
  </div>

  <div class="legend">
    <div>
      <h3 class="disp">Status</h3>
      <dl>
        <dt><span class="pill active">active</span></dt>
        <dd>Open tasks, and CLAUDE.md points at it as current work.</dd>
        <dt><span class="pill blocked">blocked</span></dt>
        <dd>Every open task declares its own blocker — a missing tool, a missing asset.</dd>
        <dt><span class="pill dormant">dormant</span></dt>
        <dd>Open tasks, but nothing claims it is being worked on. Not necessarily wrong — just unattended.</dd>
        <dt><span class="pill done">done</span></dt>
        <dd>Every task ticked.</dd>
        <dt><span class="pill closed">closed</span></dt>
        <dd>Carries a <code>STATUS: CLOSED</code> banner. Kept for the record, not for work.</dd>
      </dl>
    </div>
    <div>
      <h3 class="disp">Findings</h3>
      <dl>
        <dt><span class="chip CLAIM">Claim</span></dt>
        <dd>CLAUDE.md calls the spec complete while unblocked tasks are open. Either the summary
            overstates or the boxes were never ticked — both have happened here.</dd>
        <dt><span class="chip MISSING">Missing</span></dt>
        <dd>An open task names a file that is not in the tree. Either the design was replaced
            underneath it, or the file is that task's own unbuilt deliverable.</dd>
        <dt><span class="chip LIKELY">Likely shipped</span></dt>
        <dd>An open task names only files that already exist. Strong hint the work landed in
            another session and nobody ticked the box.</dd>
        <dt><span class="chip STALE">Stale</span></dt>
        <dd>Open tasks, untouched for over __STALE__ days.</dd>
      </dl>
    </div>
  </div>

  <footer>
    Regenerate with <code>python3 tools/spec_status.py &amp;&amp; python3 tools/spec_status_html.py</code>.
    <code>--check</code> fails if the committed report has drifted; <code>--selftest</code> asserts the
    rules rather than any particular finding. Rationale in <code>docs/DECISION_LOG.md</code> TD-074.
  </footer>
</div>

<script>
const ROWS = __DATA__, BUILT = "__BUILT__";
const SEV = { CLAIM:"critical", MISSING:"warn", "LIKELY-SHIPPED":"good", STALE:"warn" };
const RANK = { critical:0, warn:1, good:2 };
const esc = s => String(s).replace(/[&<>"]/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;"}[c]));

document.getElementById("stamp").textContent = "Scanned " + BUILT;

/* Ledger */
const total = ROWS.length, flagged = ROWS.filter(r => r.flags.length);
const byStatus = s => ROWS.filter(r => r.status === s).length;
const openTasks = ROWS.reduce((n,r) => n + r.open, 0);
document.getElementById("ledger").innerHTML = [
  ["Specs", total, ""], ["Needing review", flagged.length, flagged.length ? "alert" : ""],
  ["Open tasks", openTasks, ""], ["Active", byStatus("active"), ""],
  ["Dormant", byStatus("dormant"), ""], ["Closed / done", byStatus("closed") + byStatus("done"), ""],
].map(([k,v,cls]) => `<div class="cell ${cls}"><div class="k">${k}</div><div class="v num">${v}</div></div>`).join("");

/* Distribution strip — width encodes count, so the shape of the project reads at a glance */
const ORDER = ["active","blocked","dormant","done","closed"];
const HUE = { active:"var(--gilt)", blocked:"var(--oxblood)", dormant:"var(--iron)",
              done:"var(--moss)", closed:"var(--rule)" };
document.getElementById("strip").innerHTML = ORDER.map(s => {
  const n = byStatus(s);
  return n ? `<span style="flex:${n};background:${HUE[s]}" title="${n} ${s}"></span>` : "";
}).join("");

/* Attention cards, worst first */
const worst = r => Math.min(...r.flags.map(f => RANK[SEV[f.kind]] ?? 3));
flagged.sort((a,b) => worst(a) - worst(b));
document.getElementById("attention").innerHTML = !flagged.length
  ? `<h2 class="sect disp">Needs attention</h2>
     <div class="card sev-good"><h3>Nothing disagrees.</h3>
     <p class="meta" style="margin:0">Every spec's task list matches the tree and CLAUDE.md's account of it.</p></div>`
  : `<h2 class="sect disp">Needs attention — ${flagged.length} of ${total}</h2>
     <div class="cards">` + flagged.map(r => `
      <article class="card sev-${["critical","warn","good","warn"][worst(r)]}">
        <h3><code>specs/${esc(r.name)}/</code></h3>
        <p class="meta"><span class="pill ${r.status}">${r.status}</span>
           &nbsp;·&nbsp; ${r.done} done, ${r.open} open &nbsp;·&nbsp; last touched ${esc(r.last)}</p>
        ${r.flags.map(f => `<div class="finding">
            <span class="chip ${f.kind === "LIKELY-SHIPPED" ? "LIKELY" : esc(f.kind)}">${esc(f.kind.replace("-"," "))}</span>
            <p>${esc(f.detail)}</p></div>`).join("")}
      </article>`).join("") + `</div>`;

/* Registry table + filters */
let filter = "all";
const draw = () => {
  document.getElementById("rows").innerHTML = ROWS
    .filter(r => filter === "all" || (filter === "flagged" ? r.flags.length : r.status === filter))
    .map(r => {
      const t = Math.max(1, r.done + r.open + r.superseded);
      const seg = (n,c) => n ? `<i class="${c}" style="flex:${n}"></i>` : "";
      return `<tr class="${r.flags.length ? "flagged" : ""}">
        <td><code>${esc(r.name)}</code></td>
        <td><span class="pill ${r.status}">${r.status}</span></td>
        <td><span class="bar" title="${r.done} done · ${r.open} open · ${r.superseded} superseded"
            >${seg(r.done,"d")}${seg(r.open,"o")}${seg(r.superseded,"s")}</span></td>
        <td class="r num">${r.done}</td><td class="r num">${r.open || "—"}</td>
        <td class="r num">${r.superseded || "—"}</td>
        <td class="num">${esc(r.last)}</td>
        <td>${r.flags.map(f => `<span class="chip ${f.kind === "LIKELY-SHIPPED" ? "LIKELY" : esc(f.kind)}">${esc(f.kind.replace("-"," "))}</span>`).join(" ") || "—"}</td>
      </tr>`;
    }).join("");
};
const opts = [["all","All"],["flagged","Needs review"],["active","Active"],["dormant","Dormant"],
              ["blocked","Blocked"],["done","Done"],["closed","Closed"]]
  .filter(([k]) => k === "all" || k === "flagged" || ROWS.some(r => r.status === k));
document.getElementById("filters").innerHTML = opts
  .map(([k,l]) => `<button data-f="${k}" aria-pressed="${k === "all"}">${l}</button>`).join("");
document.getElementById("filters").addEventListener("click", e => {
  const b = e.target.closest("button"); if (!b) return;
  filter = b.dataset.f;
  document.querySelectorAll("#filters button").forEach(x => x.setAttribute("aria-pressed", x === b));
  draw();
});
draw();
</script>
"""


def build() -> str:
    rows = collect()
    return (
        PAGE.replace("__DATA__", json.dumps(rows, separators=(",", ":")))
        .replace("__BUILT__", date.today().isoformat())
        .replace("__STALE__", str(STALE_DAYS))
    )


def main() -> int:
    out = DEFAULT_OUT
    if "--out" in sys.argv:
        out = sys.argv[sys.argv.index("--out") + 1]
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as fh:
        fh.write(build())
    print("wrote", out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
