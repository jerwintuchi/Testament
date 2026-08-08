# Requirements — Tiers and Ranks (TD-094)

> **R346+**, **P158+**, **T355+**. Written to be picked up cold.
> **Phase A (the rename) is unblocked and mechanical. Phase B (the fourth tier) needs the
> Mutation system, which is canon and entirely unbuilt.**

---

## What a fresh session needs to know

**There are two ladders, and the whole spec turns on keeping them apart.**

| | measures | lives on | built? |
|---|---|---|---|
| **Tier** | how deep *this contract* goes — how much of the Incarnate is manifest | `ContractRecord.tier`, per writ | yes |
| **Collegium Rank** | *your* standing, which **gates which Tiers you may accept** | persistent account layer | **no** — `grep` finds nothing |

`generateBoard.ts:11` already states it: *"Collegium Rank gates tier (TD-012); until Rank exists the
whole board is APPRENTICE."* The mission carries a difficulty rating; the character carries a rank
that unlocks access to it.

**The naming rule that follows, and it is load-bearing:** a **Tier** name describes what the Collegium
has declared about **a place**. A **Rank** name describes **a person's** standing. Never borrow a word
across, or the ladders merge. `Aspirant / Seeker / Witness` was *rejected* for Tier despite being canon
and available, for exactly this reason.

---

## Phase A — the rename (unblocked, mechanical)

### R346 — Tier is named for the Collegium's declaration, not for a craftsman's rank

- AC: `Tier` becomes `'VIGIL' | 'INTERDICT' | 'ANATHEMA'` (+ `'APOCRYPHA'`, Phase B) in
  `src/shared/src/signs.ts`, replacing `APPRENTICE / JOURNEYMAN / MASTER`.
- AC: `ACTIVE_AXES` and `AMBIENT_AXES` keys move with it; **no axis membership changes** in Phase A.
  This is a rename, not a rebalance.
- **Why:** the old set is **craft-guild** vocabulary (blacksmiths, carpenters) in a game about
  hunter-scholars of an ecclesiastical order. It is the most off-register naming in the codebase.

| tier | the declaration | live axes |
|---|---|---|
| **VIGIL** | *we are sending someone to watch* | Aspect, Frailty, Tell |
| **INTERDICT** | *we forbid this place* | + Ward, Disposition |
| **ANATHEMA** | *we condemn this thing* | + Rite-key |
| **APOCRYPHA** *(Phase B)* | *we no longer trust our own record of it* | all six + Mutations |

### R347 — The name does the work a hidden rule was doing

- AC: no code change is required for this; it is the **justification** for R346 and should survive
  into the commit message.
- **What it fixes:** TD-092's A-register recorded that a probe kit at the lowest tier is a
  **guaranteed null**, with nothing distinguishing "no ward" from "ward inactive at this rank" — a bet
  against a hidden rule rather than against falsifiable intel. Naming that tier a **Vigil** converts
  the hidden rule into the premise: *you were sent to watch; of course there is nothing to test yet.*
- AC: the client's `PLEA` table (`board/notice.gd`) and any tier-facing copy are re-read in this
  light — a Vigil's petitioner should not sound like someone requesting an execution.

### R348 — The Rank ladder speaks escalating authority over what is known

- AC: `docs/GLOSSARY.md` carries five bands: **Aspirant → Seeker → Witness → Confessor → Hierophant**,
  with the Tier each may accept.
- AC: **`Seeker` is unchanged.** It is the baseline identity, tied to the creed
  (*"we seek truth, not certainty"*), and load-bearing across the entire codebase and UI.
- AC: the escalation is **authority**, never combat power (TD-012, Pillar 2). The apex of the order is
  not its best hunter but the Seeker whose account the Collegium **records as true**.
- AC: **docs-only in this spec** — Collegium Rank does not exist in code, so there is nothing to
  rename. When Rank is built, it uses these names.
- AC: names are checked against the authored NPC tables in `generateContract.ts` for collision.
  `Magister` and `Archivist` are **rejected**: both already appear as petitioner names/roles, and a
  rank that is also an NPC's job title reads as a bug.

### R349 (containment, Phase A) — a rename changes no behaviour

- AC: **no axis membership, no sign, no channel, no gear and no wire *shape* changes.** The `Tier`
  union's *values* change; its position in the protocol does not.
- AC: **no codegen regeneration** — `Tier` never reaches `client/protocol/protocol.gd`. (An earlier
  estimate claiming otherwise was wrong: `MASTER` was matching `NOT_AT_QUARTERMASTER`.)
- AC: server + shared suites green with only literal substitutions; the client parses headless.
- AC: no Contract Board capture diff needed — the board renders tier only through the `PLEA` table,
  which R347 covers deliberately.

---

## Phase B — APOCRYPHA (blocked on the Mutation system)

### R350 — The fourth tier escalates trust, not quantity

- AC: `APOCRYPHA` adds **no new axes** — all six are already live at `ANATHEMA`. A fourth tier
  *cannot* add more to read, so it must escalate differently.
- AC: it stacks **Mutations** — already canon, entirely unbuilt (GLOSSARY): *"a modifier stacked onto
  an Incarnate that **masks, inverts, or adds signs**."*
- AC: at this tier the player stops reading the Incarnate and starts reading **whether the reading can
  be trusted**. That is the correct apex for a diagnosis game, and `apocrypha` means writings *of
  doubtful authenticity* — the tier is named for its own mechanic.

### R351 — Masking must not silently collide with the null probe

- AC: a **masked** Ward and an **absent** Ward would both present as `no-reaction`, colliding with the
  deliberate ambiguity of R55/R56. This must be designed, not discovered.
- AC: whatever resolves it, a player must never be unable to distinguish *"the world had nothing to
  say"* from *"something ate the answer"* **without a way to find out** — otherwise Mutations are
  indistinguishable from a bug, which is the failure mode TD-092 recorded for Apprentice probe kits.

### R352 — A fourth tier is not a scarcity fix

- AC: recorded so it is not mistaken for one. The sweep measured `6 SLOTS SPARE` for a full party at
  the top tier; Mutations need no extra instruments, so the bag still does not bind.
  **Scarcity remains `specs/preparation/` R336's job.**

---

## Correctness Properties

- **P158 (two ladders, never merged):** no Tier name names a person; no Rank name names a place. A
  future contributor adding a fifth of either must obey the rule.
- **P159 (a rename is not a rebalance):** Phase A changes no axis membership. The sweep numbers in
  TD-094 must reproduce identically after it.

## Verification

- **V1 (R346, R349, P159):** server + shared suites green; re-run `sim/sweep.ts` and confirm the
  coverage/probe numbers are **unchanged** — a rename that moved a number moved an axis.
- **V2 (R347):** the `PLEA` copy is re-read per tier; a Vigil's petitioner reads as reporting, not as
  demanding an execution.
- **V3 (R348, P158):** GLOSSARY carries both ladders with the borrowing rule; no rank name appears in
  `generateContract.ts`'s NPC tables.
- **V4 (R350, R351):** Phase B only — a masked sign is distinguishable from an absent one by some
  means the player can reach.

## Open — Phase B needs these before it starts

1. **What can a Mutation do, concretely** — mask, invert, add, or all three? Each has a different cost
   to the reading loop, and *invert* is the most dangerous (it makes a correct read actively harmful).
2. **How does the player learn a Mutation is present at all?** If they cannot, Apocrypha is
   indistinguishable from bad luck.
3. **Does Rank get built first?** Tier is gated by Rank, and Rank does not exist — so today every writ
   is one tier regardless of what the union is called.
