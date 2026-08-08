# Requirements — The Quartermaster (TD-090)

> Written to be picked up cold. **Read this section first** — a fresh session cannot see the
> conversation this came out of.
>
> **R318+**, **P148+**, **T331+**.

---

## What a fresh session needs to know

**What exists today** (verified in the tree, not remembered):

- `src/shared/src/gear.ts` — `GEAR_CATALOG` (perception gear, one per channel; probe gear, one per
  stimulus) and `BAG_SLOTS = 4`. `GearItem` has **`id`, `name`, `kind`, and either `channel` or
  `stimulus`** — there is **no `price` and no `description`**.
- The server's `REQUISITION` handler validates **`BAG_SLOTS` only**. There is no Stipend anywhere:
  `grep -rn "stipend\|price" src/` returns nothing.
- The client Quartermaster (in `main.gd`, `_station_body`, case `"QUARTERMASTER"`) is a **plain
  `CheckBox` list** over `Catalog.GEAR`, a slot-count `Label`, and one "Requisition (replaces your
  bag)" button.
- Since **TD-089** the station popup is **parchment with ink Cinzel and ruled actions**. The
  Quartermaster's stock `CheckBox`es now sit on that paper looking exactly like the engine widgets
  they are — the same mismatch TD-084 fixed on the options writ.

**What is already specced elsewhere and must not be re-invented:** `specs/station-ui/` T125–T130
covers the Stipend economy. It was written before the writ idiom, before the Deploy Gate became the
party's muster point (TD-088), and before the popup restyle, so its *client* half (T127–T129) is
superseded by this spec; its *server* half (T125/T126) is still the plan of record.

**Standing constraints that bind this work:**
- **Do not touch the Contract Board or any finished spec** (`.claude/rules/spec-workflow.md`,
  "Finished work is closed"). The board shares the station popup: style widgets in the builders that
  create them, never in a cascading `Theme`. TD-089 explains why in detail.
- **Performance is budgeted in the spec** (`.claude/rules/performance.md`).
- The client sends intentions; the server validates (I1/I2). Nothing here changes that.

---

## Phase A — The Quartermaster reads as a writ (client only)

### R318 — It is a requisition form, not a settings screen

- AC: the gear list is **ink on the station's parchment** — Cinzel, ruled lines, the idiom
  `writ_form.gd` and `popup_theme.gd` already establish. No stock `CheckBox`.
- AC: a chosen item is **marked**, in the same visual language as the options writ's inked box and
  the title menu's laurel. Consistency here is the point: three screens already speak it.
- AC: styling is applied by the builders that create the widgets — **never** via the popup `Theme`,
  which cascades into the Contract Board.

### R319 — The bag's scarcity is legible

- AC: the **four slots** are shown as slots — occupied and empty — not as a number in a sentence.
  Bounded capacity is the mechanic (`loadout-economy` non-negotiable 3), so it should be the first
  thing the eye reads.
- AC: choosing a fifth item is refused with a reason, as it already is.

### R320 — What an item *does* is readable before taking it

- AC: each item states its **channel** or **stimulus** in the player's language, not the wire enum —
  the `StationNames.of` precedent (R224). "Reads Residue", not `RESIDUE`.
- AC: **no numbers, no ratings, no "power"**. Pillar 2 and vision.md's "no knowledge as a number"
  apply to gear exactly as they apply to Incarnates: the player judges fit from what a tool *does*.

### R321 (containment, Phase A) — client render only

- AC: no `src/**` change and no wire change. `REQUISITION` is sent with its existing payload.
- AC: the Contract Board is **proven** unchanged — capture from a stashed clean tree at HEAD and
  diff, per the standing rule (control noise floor ≈ 0.47%).

---

## Phase B — The Stipend (server + shared + client)

**This phase needs an author decision before it starts** (see Open questions). Do not invent prices.

### R322 — Gear carries a price and a description

- AC: `GearItem` gains `price` and `description` in `src/shared/src/gear.ts`; every catalog entry is
  given both. Shared stays **types + constants only** (I4) — no pricing logic there.

### R323 — The room carries a Stipend

- AC: `RoomRecord` gains `stipend`, initialised at `createRoom` from a `STARTING_STIPEND` constant.
- AC: `REQUISITION` validates **cost against the remaining Stipend** as well as `BAG_SLOTS`, and
  rejects an over-budget bag with a reason. The server remains the only authority (I2).
- AC: the Stipend is **expedition state** — it lives in server memory and is never persisted (I7,
  TD-006, and the reasoning recorded in TD-082).

### R324 — Preparation has teeth without becoming arithmetic

- AC: the Stipend is shown as a **remaining balance the player can feel**, not a spreadsheet. It is
  the deliberate, skill-based layer of preparation (GLOSSARY: *Stipend*), so the tension is
  "which four", not "optimise a sum".
- AC: still no ratings on gear. Price is a cost, not a quality score.

### R325 (containment, Phase B) — the wire changes, so it is checked

- AC: `src/shared` and `src/server` suites cover price validation and the over-budget rejection.
- AC: the protocol contract and codegen are regenerated if message shapes move.

---

## Correctness Properties

- **P148 (the bag is the server's):** slot count and cost are validated server-side; the client's
  list is an affordance. A client that lies is refused, not trusted.
- **P149 (no number stands for knowledge):** gear is described by what it does. Price is the only
  number, and it is a cost, never a rating.

## Verification

- **V1 (R318–R320):** capture the Quartermaster against a live server; it reads as paper, the four
  slots read as slots, each item says what it does.
- **V2 (R321):** board diffed against a stashed clean tree at HEAD; suites green.
- **V3 (R322/R323):** server suites — an over-budget requisition is rejected, an affordable one is
  applied, and `BAG_SLOTS` still bounds it.
- **V4 (R324):** capture; the balance is legible without arithmetic.

---

## Open questions for the author (ask before building Phase B)

1. **What does gear cost, and what is `STARTING_STIPEND`?** Pricing is content and a balance
   decision — 12 catalog entries need numbers that make "which four" a real choice. Do not invent
   these silently.
2. **Is the Stipend per-party or per-Seeker?** GLOSSARY says "the Collegium's per-contract
   allowance, spent to requisition the loadout **and to place the Surety**", which reads
   party-wide — but the bag is per-Seeker, and `REQUISITION` is sent by one player.
3. **Does the Surety come out of the same Stipend?** It is named in the same GLOSSARY line, and it
   is the mechanism that gives acceptance teeth (vision.md non-negotiable 4). If so, spending it all
   on gear is itself a decision — which is interesting, and worth being deliberate about.
