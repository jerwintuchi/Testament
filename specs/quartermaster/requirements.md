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

## Phase B — The Stipend — **CLOSED, NOT BUILT (TD-091, 2026-08-08)**

> **The author cut the Stipend.** `BAG_SLOTS` is the loadout economy; there is **no currency in
> Testament**. R322–R325 below are kept as the record of what was specced and are **superseded in
> place** — do not implement them, and do not re-propose a price on gear without reading TD-091.
>
> **The reasoning, in one paragraph, so it is not re-derived:** every catalog item is a *key* (a
> channel you can read, a stimulus you can present), not a power level. So a price has two possible
> forms and both fail — **flat** prices are a literal no-op (any four items cost what any other four
> cost, so the budget never binds), and **varied** prices are the "bigger numbers shopping ladder"
> that `loadout-economy.md` non-negotiable 2 and TD-017 forbid. The strongest surviving case was a
> *party-wide* allowance that does not scale with headcount — because the reading catalog is
> permanently bounded at six channels and four stimuli, so a trio (12 slots) carries all ten
> instruments and no future content can change that. The author weighed it and declined: a currency
> costs eleven authored numbers and an exchange rate between reading and winning that must be
> defended forever once combat tools carry prices beside lenses.
>
> **Accepted consequence:** scarcity binds at solo and duo, and stops binding at trio and quartet.
>
> **Still open, and the next thing to decide:** consumable **charges** on probe kits. Ward is drawn
> independently of Frailty from the same four values and is readable only by probing, so four kits
> are a guaranteed four-step lookup — a memorizable *procedure* standing in for a read. Charges are
> already implied by `docs/systems/investigation-and-probing.md` ("resupply of **consumable**
> probes") and need no pricing decision. See TD-091 for the three other findings it surfaced
> (`exposure` is inert; `isSolo` counts ghosts; an Apprentice probe kit is a guaranteed null).

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

## Open questions — **ANSWERED (TD-091, 2026-08-08)**

1. ~~**What does gear cost, and what is `STARTING_STIPEND`?**~~ **Moot.** Nothing costs anything;
   there is no Stipend. This question was the vise itself — see the Phase B banner.
2. ~~**Is the Stipend per-party or per-Seeker?**~~ **Moot, but recorded:** had it been kept it would
   have been **per-party**. Per-Seeker was disqualified outright, because a per-Seeker budget scales
   linearly with headcount and so fails the only job a currency could have done.
3. **Does the Surety come out of the Stipend?** **Deferred — genuinely undecided.** With no currency
   the default is that the Surety is a flat cost in **Collegium standing** (already persistent,
   already access-not-power per TD-012), but the author is still weighing a **variable stake you
   size**. Do not treat this as settled; GLOSSARY's *Surety* carries the same open marker.
