# Requirements — The Quartermaster as a Room (TD-101)

> **R361+**, **P164+**, **T369+**. Written to be picked up cold.
> Author brief, 2026-08-09, with a reference image. **Presentation + interaction only** — the
> inventory architecture is not replaced.

---

## What a fresh session needs to know

**The audit finding that reframes this work:** the Quartermaster's *architecture is already right,
and three of the brief's eight phases are already built.* This is not a rewrite.

| Layer | Where | Status |
|---|---|---|
| Item data | `src/shared/src/gear.ts` → codegen → `client/scripts/core/catalog.gd` | **Untouched.** 10 items, `kind: PERCEPTION\|PROBE`, `BAG_SLOTS = 4`. |
| Item prose | `stations/quartermaster/lore.gd` | **Kept verbatim.** Already `class`/`asks`/`note`/`care`. |
| Coordinator | `stations/quartermaster/register.gd` | Render + intent only, never touches `_net` (S3.5). Re-skinned, not replaced. |
| Flight animation | `pack.gd` — `fly_in()` | **Already exists** at the brief's own timings (lift 0.12 / carry 0.28 / settle 0.12). |
| Removal | `pack.gd` — a packed slot is a `Button` | **Already exists.** |
| Seal ceremony | `seal_rite.gd` | **Already exists** — wax press, squash, BACK settle, rite banner (TD-063 vocabulary). |

So the work is **the room** (the brief's Phase 2), the **objects on shelves** (Phase 3), the
**counter**, and the **icons** — plus lifting the frame out of an inset popup.

**Three conflicts between the reference image and the tree, and how each resolves:**

1. **The reference is painted; Testament is 640×360 NEAREST pixel art.** Precedent is exact —
   TD-075: *"the Contract Board is the visual authority; the concept art gives composition only."*
   TD-055 already rejected hi-res/LINEAR UI art and is not re-proposable. **Composition from the
   reference, render from the board and the Great Hall.**
2. **`PROVISIONS` / `RELICS` / `TOOLS` do not exist.** Testament has exactly two kinds: 6
   Instruments of Sight (`PERCEPTION`), 4 of Trial (`PROBE`). The brief's own §4 rule settles it —
   real categories only.
3. **`Uses ◆◆◆`, `Weight I`, `LOAD LIGHT` must not ship.** TD-091 cut the Stipend and
   `loadout-economy.md` non-negotiable 2 forbids the power ladder: gear are **keys**, not levels, and
   every instrument costs exactly one slot, so a weight is either a no-op or the forbidden ladder.
   `register._shape()` already carries this reasoning and reports the Observe/Test split instead.

**Standing constraints:** the Contract Board and every finished spec are closed work — style widgets
in the builders that create them, **never** in a cascading `Theme` (TD-089). Performance is budgeted
here, not tuned later (`performance.md`). Client sends intentions; the server validates (I1/I2).

---

## R361 — The Quartermaster is a room, not a menu with a background

- AC: it renders **full-screen** rather than inside the inset station popup. Only the
  `QUARTERMASTER` branch of the popup sizing changes; every other station keeps the shared frame.
- AC: **Esc still steps back exactly one layer** (T146 untouched), and the pause menu still sits
  above it at `CanvasLayer` 128 (P146).
- **Why:** the current sheet is `vp.x*0.86 × vp.y*0.62`, which is why the record's text clips at the
  right edge and the register is sliced mid-row. The composition cannot be fixed inside it.
- AC: the frame carries **architecture** — wall, floor, shelving, counter — so the player reads a
  location. Not a panel with a texture behind it.

## R362 — Instruments are physical objects on shelves, not a text list

- AC: each of the 10 catalog items renders as its **icon, placed on a shelf board**, with a contact
  shadow, at a position that is stable across rebuilds.
- AC: they are grouped by the **real** kinds — Instruments of Sight, Instruments of Trial — with
  shelf labels that name those and nothing else (no invented category).
- AC: an item's shelf position is **derived from the catalog order**, never hard-coded per id, so a
  new instrument appears without touching layout code.

## R363 — The shelf carries non-interactive stock *(author ruling, 2026-08-09)*

- AC: dimmer, smaller crates/bottles/ledgers fill the shelving around the 10 real instruments, so the
  room reads as an institution's stores rather than a rack of exactly ten things.
- AC: stock is **never hoverable, never focusable, never clickable**, and is visually subordinate —
  lower contrast and smaller than a real instrument, so the reachable objects are the lit ones.
- AC: stock is **seeded and deterministic**, so the room does not reshuffle between openings.

## R364 — Hover reads as the Quartermaster noticing you

- AC: a restrained response only — a small lift, a slight brightening, a contact-shadow shift, and
  the instrument's name appearing nearby.
- AC: **explicitly forbidden**: neon outlines, blue glows, large tooltips, particle bursts.
- AC: hover state is **Godot state driving presentation**, never baked into a texture (brief §18).

## R365 — Selecting brings the object to the counter

- AC: clicking a shelf instrument **moves it to the inspection counter** — lift, carry, settle — and
  it visibly leaves the shelf while it is on the counter.
- AC: timings follow the brief: lift 80–120 ms, carry 250–400 ms, settle 100–150 ms, eased as a
  handled object rather than a flying card.
- AC: selecting a **second** instrument returns the first to its shelf position before carrying the
  new one — the counter holds one object, and nothing is ever destroyed to make room.
- AC: under **reduced motion** the end state renders with no movement (the project honours this
  everywhere).

## R366 — The record is an institutional document

- AC: the record reads as a quartermaster's ledger entry, not a tooltip: name, class, the question it
  answers, the field note, and the care line — all already authored in `lore.gd` and **kept**.
- AC: it carries **no fabricated statistic** — no Uses, no Weight, no Load (see conflict 3 above).
- AC: it states the **party** fact that already exists (another Seeker carrying this) and the gate
  reason when the counter cannot issue.

## R367 — Packing and removal stay physical

- AC: `PACK` moves the object **from the counter into the pack**, reusing the existing `fly_in`.
- AC: the pack's count updates **when the object lands**, not when the button is pressed (already the
  behaviour — preserve it).
- AC: removing an instrument from the pack **returns it to its shelf position**; it never blinks out.

## R368 — The seal is the closing ritual

- AC: the existing wax press + rite banner is preserved. It commits **the pack**, not the deployment
  — requisition stays reversible until the leader deploys at the Deploy Gate, which is the server's
  phase gate (`seal_rite.gd` already says so and is correct).

## R369 (containment) — presentation only

- AC: **no change to** `src/**`, the gear catalog, bag rules, item descriptions, expedition logic,
  multiplayer behaviour, or any unrelated UI.
- AC: **no second inventory architecture.** The screen consumes `Catalog`; nothing about items is
  hard-coded in the presentation.
- AC: the Contract Board is **provably unchanged** — captured from a stashed clean tree and diffed,
  not judged by eye (TD-089's rule).

---

## Correctness Properties

- **P164 (state drives presentation):** an item is in exactly one of
  `AVAILABLE / HOVERED / SELECTED / ON_COUNTER / PACKING / PACKED / REMOVING`, held as Godot state.
  No interaction state is baked into a texture.
- **P165 (selection does not rebuild the screen):** choosing an instrument updates the record and the
  moved object only. This is the project's most repeated lesson — TD-064, TD-065, TD-068 are three
  separate fixes for exactly this defect, and the Quartermaster must not become the fourth.
- **P166 (the room is deterministic):** set dressing and shelf placement are seeded, so reopening the
  Quartermaster shows the same room.
- **P167 (nothing on a shelf lies):** every hoverable object is a real, requisitionable instrument;
  every non-interactive object is visibly subordinate and refuses hover.

## Performance budget (canon, `performance.md` P0)

Stated before building, and measured after:

| | budget |
|---|---|
| particles | **≤ 20** total (dust in the lamp-light only). Lantern flicker is a looping **tween on modulate**, not an emitter. |
| full-frame additive layers | **0** |
| per-frame work | **none** — no `_process`, no `_draw` loop. Every animation is a tween that frees with its node. |
| node count | **≤ 90** for the whole room (10 instruments + ≤ 30 dressing + counter props + 4 pack slots + chrome) |
| rebuild scope | selection/hover rebuild **nothing**; packing rebuilds the pack row only |
| idle animation | one lantern flicker + dust. Every other object is **static** (brief §20). |

## Verification

- **V1 (R361):** `--quartermaster` capture — full-screen room, no clipped text, Esc returns one layer.
- **V2 (R362, R363, P167):** capture — 10 instruments on labelled shelves among subordinate stock;
  a hover check proves stock is not focusable.
- **V3 (R364, R365, P164):** `--qm-pick` capture — the chosen instrument is on the counter and gone
  from its shelf slot; a second selection returns the first.
- **V4 (R366):** capture — the record shows the authored prose and **no Uses/Weight/Load**.
- **V5 (R367, R368):** `--qm-full` and the seal capture — pack fills as watched; wax press unchanged.
- **V6 (R369, P165):** `git diff` touches no `src/**`; board captured from a clean tree at HEAD and
  diffed (control floor ≈ 0.47%); a printed node/particle count checked against the budget.
- **V7 (P166):** two openings in one run produce an identical room.

## Open questions

None blocking. Two answered by the author on 2026-08-09: shelves **do** carry non-interactive stock,
and the frame **is** full-screen.
