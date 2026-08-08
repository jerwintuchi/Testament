# Requirements — Rank-Gated Contracts (TD-095)

> **R353+**, **P160+**, **T362+**. Written to be picked up cold.
> **Phases A and B build now. Phase C is deferred to ROADMAP Phase 7 and must not be attempted early.**

---

## What a fresh session needs to know

**The rule is canon and already written** — `docs/systems/contracts.md` §*"The board is free, the
rank is the gate"*: Seekers see every contract; **Collegium Rank gates acceptance, not display**.

**Why that matters mechanically, not just tonally:** the board is minted inside `createRoom`,
**before any other player has joined**. Gating *what appears* by party composition is therefore
incoherent — the party does not exist yet, and leadership can reassign afterwards. Gating
*acceptance* has no timing problem at all.

**The blocker on real Rank, and why the obvious workaround is wrong:**

- `grep` finds **no filesystem or database write anywhere in `src/server/`**.
- Identity is not stable either: `playerId` is a fresh `randomUUID()` per join.
- TD-082 parked the display name in `user://display-name.txt` under the ruling that *"persists" is
  not "persist it server-side now."* **That precedent does not transfer.** A display name is a
  *convenience* — the server validates shape and never asks who owns it. A Rank is an
  **authorization token**: it decides what content you may access. A client-supplied rank is exactly
  what **I2** forbids. You cannot put a permission in `user://rank.txt`.
- ROADMAP **Phase 7 — Persistence & account layer** owns real Rank. We are in Phase 5.

**The ladder** (TD-094). Rank names a *person*; Tier names a *place*. Never borrow across.

| Rank | may accept |
|---|---|
| Aspirant | nothing |
| Seeker | Vigil |
| Witness | Interdict |
| Confessor | Anathema |
| Hierophant | Apocrypha |

---

## Phase A — the board offers a spread of danger (unblocked)

### R353 — The board is not all one tier

- AC: `generateBoard` mints a **mix** of tiers instead of the hard-coded
  `const BOARD_TIER: Tier = 'VIGIL'`.
- AC: the mix is **seeded and deterministic** (I3) — the same board seed yields the same tiers.
- AC: every tier in the mix is one the `Tier` union actually carries. `APOCRYPHA` is **excluded**
  until `specs/tiers/` Phase B ships it.
- AC: the spread is a **guaranteed composition, not an independent draw per entry** — 5 Vigil /
  2 Interdict / 1 Anathema at the canonical size of 8, shuffled into position.
  **Why composed rather than rolled** (decided during T362): once Rank gates acceptance (Phase B),
  independent per-entry draws could produce a board with **nothing a low-rank Seeker may accept** — a
  dead wall, by luck. Composing then shuffling makes that unreachable: a Seeker always has work, and
  always sees what they cannot yet take. Exact shares are content and live in `design.md`.
- **Why this is worth doing on its own:** the simulator measured **no packing decision at any party
  size**, and this constant is why. At Vigil only three of ten catalog items can do anything, so a
  board of nothing but Vigils means the preparation pillar never activates. A spread gives the game
  its Interdict and Anathema content immediately, with no persistence involved.

### R354 — A writ says how deep it goes

- AC: the tier is legible on the writ, in the Collegium's language — *Vigil*, *Interdict*,
  *Anathema* — never a difficulty number or a star rating (vision.md, "no knowledge as a number").
- AC: the tier-banded petitioner plea already exists (`notice.gd`'s `PLEA`) and now actually varies,
  because the board is no longer uniform. No new copy is required.

---

## Phase B — acceptance is gated (unblocked; rank is stubbed)

### R355 — Rank lives on the server and never crosses the wire inbound

- AC: `rank` is a field on the **server** player record, set server-side.
- AC: it is **never read from a client payload** (I1/I2). A client that sends a rank is ignored, not
  trusted.
- AC: it *may* be sent outbound in the snapshot so the client can render what you may take — that is
  a render affordance, and the server still validates every acceptance.

### R356 — Rank gates what you may LEAD, not what you may JOIN *(author ruling, TD-095)*

- AC: only the **accepting player** is rank-checked. Party members' ranks are irrelevant.
- AC: a Seeker may **join** an Anathema hunt led by a Confessor. They may not **accept** one.
- **Why:** it matches the fiction — the Collegium issues the writ to whoever takes responsibility —
  and it protects Pillar 4. Gating by the *lowest* rank present would mean a veteran can never play
  their own content with a friend, which is the opposite of a cooperative design. A veteran bringing
  a newcomer along is also how the sign vocabulary gets taught out loud.

### R357 — The gate is checked at acceptance AND at the deploy commit

- AC: `SELECT_CONTRACT` refuses a contract above the actor's rank, with a reason, mutating nothing
  and erroring only to the sender (I2).
- AC: **Stage 1 of `handleDeploy` re-validates** the committed contract against the *current* leader's
  rank.
- **The edge case this exists for:** leadership is reassigned on leave (`reassignLeader`). A Confessor
  may select an Anathema and then leave, promoting a Seeker who could otherwise deploy it. This is the
  same class of defect as TD-092's `isSolo` counting ghosts — a check computed once that stopped
  matching reality when the party changed underneath it. **Do not remove the second check as
  redundant; it is not.**

### R358 — The stub is permissive, deliberately, and the tests do not rely on it

- AC: with no account layer, the server assigns a **default rank** to every player. It defaults to the
  **top** rank so all content stays reachable during development.
- AC: this is a **development affordance, not a design statement.** It must be a single named
  constant, obvious at the call site, and flagged so nobody ships it as balance.
- AC: **tests must prove the gate rejects a low rank** by setting rank explicitly — never by relying
  on the default. A gate that is only ever exercised in its permissive state is untested.

### R359 (containment, Phases A+B) — server-side, no persistence invented

- AC: **no filesystem or database write is added.** If a task finds itself building storage, it has
  left this spec and entered Phase 7 (TD-082, TD-095).
- AC: server + shared suites green; the sweep's numbers are re-checked, since a mixed-tier board
  changes what the harness samples.
- AC: ships with the **board-reroll fix** (`specs/preparation/` R333). Rank-gating makes TD-092's
  **A6** worse: create-read-leave-create becomes fishing for a tier you are allowed to take.

---

## Phase C — real Collegium Rank — **DEFERRED TO ROADMAP PHASE 7**

### R360 — Rank persists; expeditions stay ephemeral

- AC: Rank moves to the account layer when one exists. Only *where the value comes from* changes —
  Phases A and B fix the shape, so this is a source swap, not a redesign.
- AC: **Do not attempt this early.** TD-082 declined to build a persistence tier to hold one string;
  this is the same reasoning applied to a harder case, because a Rank is a permission and therefore
  cannot use TD-082's client-side stand-in.
- AC: identity must become stable first. `playerId` is currently `randomUUID()` per join, so there is
  nothing durable to attach a rank *to*.
- AC: how Rank is **earned** is out of scope here and unspecified. It grants *access and options,
  never raw combat power* (TD-012).

---

## Correctness Properties

- **P160 (a permission is never client-supplied):** rank is server-owned; an inbound rank is ignored.
- **P161 (the gate is re-checked when the party can change under it):** acceptance and the deploy
  commit both validate, because leadership can be reassigned between them.
- **P162 (the stub cannot hide a broken gate):** every gate test sets rank explicitly.
- **P163 (a mixed board stays deterministic):** the same board seed yields the same tiers (I3).

## Verification

- **V1 (R353, P163):** `generateBoard.test.ts` — a board contains more than one tier; the same seed
  reproduces the same tiers exactly; no tier outside the `Tier` union appears.
- **V2 (R356, R357, P160/P161/P162):** `selectContract.test.ts` + `deploy.test.ts` — an under-ranked
  actor is refused with nothing mutated and the error sent only to them; a sufficiently ranked one
  succeeds; **a leader demoted by reassignment between select and deploy is refused at the commit**;
  an inbound `rank` in the payload is ignored.
- **V3 (R354):** `--board-preview` capture — the tier reads in the Collegium's language, and the
  petitioner pleas visibly differ across the wall.
- **V4 (R359):** `git diff` adds no storage; suites green; sweep re-run and its change explained.

---

## Open questions

1. **The tier weights** for R353 — content, and yours. `design.md` proposes a default so this is not
   a blocker.
2. **How Rank is earned** — out of scope until Phase 7, but it will need answering then, and
   "expeditions survived" is not automatically the right answer for an order that values *reading*.
