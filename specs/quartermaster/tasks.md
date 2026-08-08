# Tasks — The Quartermaster (TD-090)

> T# continues global from T330. **Phase A is client-only and can ship alone.**
> Phase B is blocked on the author answering the open questions in `requirements.md`.

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

## Phase B — the Stipend (blocked: needs the author's numbers)

- [ ] T334 [R322] — `price` + `description` on `GearItem` and every `GEAR_CATALOG` entry; shared
      stays types + constants only (I4).
      Test: `gear.test.ts` — every catalog entry has both, and prices are positive.

- [ ] T335 [R323, P148 / V3] — `stipend` on `RoomRecord`, initialised at `createRoom` from
      `STARTING_STIPEND`; `REQUISITION` validates **cost against the balance** as well as
      `BAG_SLOTS`, rejecting over-budget with a reason.
      Test: server suite — an over-budget bag is refused and state is unmutated; an affordable one
      applies; `BAG_SLOTS` still bounds it.

- [ ] T336 [R324, R325 / V4] — The client shows the remaining balance as something the player can
      feel, not a spreadsheet; protocol contract/codegen regenerated if shapes moved.
      Test: capture; suites green.

## Do not re-invent

`specs/station-ui/` T125–T130 already covers the Stipend economy. Its **server** half (T125/T126) is
the plan of record and is folded into Phase B above; its **client** half (T127–T129) predates the
writ idiom, the muster point (TD-088) and the popup restyle (TD-089), and is superseded here.

## Standing constraints

- **Do not touch the Contract Board or any finished spec** unless the work requires it or the author
  asks (`.claude/rules/spec-workflow.md`).
- The client sends intentions; the server validates (I1/I2).
- Budget stated in `design.md`: no new particles, no additive layer, nothing per frame.
