# Tasks — The Quartermaster (TD-090)

> T# continues global from T330. **Phase A is client-only and can ship alone — it is the whole
> remaining spec.** Phase B (the Stipend) was **cut by the author on 2026-08-08, TD-091**; its tasks
> are marked superseded in place below.

## Phase A — the requisition form (client only)

- [ ] T331 [R319 / V1] — **The four slots read as slots.** Occupied and empty shown at once, at the
      top of the sheet, because bounded capacity is the mechanic (`loadout-economy` non-negotiable 3)
      and "2 of 4" makes the player parse a number to learn it.
      Test: capture against a live server (`--muster` is the existing precedent for a station capture
      flag; add `--quartermaster` the same way).

- [ ] T332 [R318, R320 / V1] — **The list becomes ink.** Each item is a marked row in the writ idiom
      — `WritForm.toggle`'s inked square, not a stock `CheckBox` — and states what it does in the
      player's language ("Reads Residue"), never the wire enum, never a rating.
      **Style in the builders, never in the popup `Theme`** — it cascades into the Contract Board
      (TD-089). This is the whole risk of the task.
      Test: capture; every row readable on parchment, no engine widget visible.

- [ ] T333 [R321 / V2] — **Prove the board is untouched.** Capture it from a stashed clean tree at
      HEAD and diff against the change; control noise floor ≈ 0.47% (torch particles + which writ
      holds hover-focus). Suites green, diff scoped to `client/ specs/ docs/`.

## Phase B — the Stipend — **CUT (TD-091, 2026-08-08)**

> The author cut the Stipend: `BAG_SLOTS` is the economy and there is **no currency in Testament**.
> The three tasks below are kept as the record and **will not be built**. Reasoning in TD-091 and in
> the Phase B banner of `requirements.md`; the short version is that gear items are *keys*, so a flat
> price is a no-op and a varied price is the ladder `loadout-economy.md` non-negotiable 2 forbids.

- [~] T334 **SUPERSEDED** (no prices exist; `GearItem` gains nothing) — [R322] — `price` +
      `description` on `GearItem` and every `GEAR_CATALOG` entry; shared stays types + constants
      only (I4).

- [~] T335 **SUPERSEDED** (no `stipend` on the room; `REQUISITION` keeps validating slots only) —
      [R323, P148 / V3] — `stipend` on `RoomRecord`, initialised at `createRoom` from
      `STARTING_STIPEND`; `REQUISITION` validates cost against the balance as well as `BAG_SLOTS`.

- [~] T336 **SUPERSEDED** (there is no balance to show) — [R324, R325 / V4] — The client shows the
      remaining balance as something the player can feel, not a spreadsheet.

## The open follow-up (not yet a task — needs an author ruling)

**Consumable charges on probe kits.** `generateTraitRoll` draws `ward` independently of `frailty`
from the same four values, and `deriveReaction` only ever fires on an exact match — so carrying all
four kits is a **guaranteed four-step lookup** of the one probe-gated axis, free at 3+ players. That
is a memorizable *procedure* standing in for a read. Charges fix it, need no pricing decision, and
are already implied by `docs/systems/investigation-and-probing.md` ("resupply of **consumable**
probes"). TD-091 also records three unfixed findings: `exposure` is written but read by nothing,
`deploy.ts:87`'s `isSolo` counts ghosts, and an Apprentice probe kit is a guaranteed null.

## Do not re-invent

`specs/station-ui/` T125–T130 already covers the Stipend economy. Its **server** half (T125/T126) is
the plan of record and is folded into Phase B above; its **client** half (T127–T129) predates the
writ idiom, the muster point (TD-088) and the popup restyle (TD-089), and is superseded here.

## Standing constraints

- **Do not touch the Contract Board or any finished spec** unless the work requires it or the author
  asks (`.claude/rules/spec-workflow.md`).
- The client sends intentions; the server validates (I1/I2).
- Budget stated in `design.md`: no new particles, no additive layer, nothing per frame.
