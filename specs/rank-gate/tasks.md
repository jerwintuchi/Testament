# Tasks — Rank-Gated Contracts (TD-095)

> T# continues global from T361. **Phases A and B are unblocked and build now.**
> **Phase C is ROADMAP Phase 7 — do not attempt early (TD-082, TD-095).**

## Phase A — the board offers a spread of danger

- [x] T362 [R353, P163 / V1] — **Retire `const BOARD_TIER: Tier = 'VIGIL'`.** `generateBoard` composes
      5 Vigil / 2 Interdict / 1 Anathema and **shuffles them on a board-level stream**
      (`${expeditionSeed}:tiers`) — deliberately *not* an independent per-entry draw, for two reasons:
      a rolled board could leave a low-rank Seeker nothing to accept once Phase B lands, and a
      board-level stream touches **no entry rng at all** (a stronger form of the P151 stream-shape
      lesson from `ward !== frailty`). `APOCRYPHA` is excluded until `specs/tiers/` Phase B ships it.
      Test: `generateBoard.test.ts` — **7 new cases, green (server 373 → 380)**: a board is not all one
      tier; every board is exactly 5/2/1; same seed reproduces the same order; different seeds place the
      dangerous writs differently; never a tier outside the union and never APOCRYPHA; rounding at other
      sizes spills into VIGIL; and **every contract is byte-identical to a direct `generateContract`
      call on its entry seed**, proving the shuffle disturbed no entry stream (P151).
      **Why this alone is worth shipping:** the simulator measured *no packing decision at any party
      size*, and this constant is why — at Vigil only three of ten catalog items can do anything.

- [x] T363 [R354 / V3] — **The writ says how deep it goes**, in the Collegium's language (*Vigil*,
      *Interdict*, *Anathema*) — never a number or a star rating. The tier-banded petitioner plea
      already exists in `notice.gd`; it simply starts varying now that the wall is mixed.
      Shipped in the **reader**, not the grid card: the card is laid out by `_fit_writ`, which measures
      each writ against the font it will be drawn in, and that is precisely what TD-089 broke. The
      declaration reads as a declaration — *"This thing is declared anathema."* — never a tier number
      or a star. Marking what you may not *accept* belongs to Phase B, where it has a reason to exist.
      Test: `--board-preview --reader` capture — the declaration sits between site and Origin.
      **Grid proven unchanged** by capture from a stashed clean tree at HEAD: **0.042%** of pixels
      differ against a ~0.47% control floor, confined to the two torch gutters (particle noise).

## Phase B — acceptance is gated (rank stubbed server-side)

- [ ] T364 [R355, P160] — **`Rank` + `RANK_ACCEPTS` in `src/shared`** (types + constants only, I4) and
      a server-owned `rank` on `ServerPlayerEntry`, assigned at create/join from a single named
      `DEFAULT_RANK`. **Never read from a client payload.**
      Test: a `rank` field in an inbound payload is ignored, not trusted.

- [ ] T365 [R356, R357, P161, P162 / V2] — **The gate, in both places.** In `selectContract`,
      immediately after the `isLeader` guard: refuse a contract above the actor's rank with
      `RANK_TOO_LOW`, mutating nothing, erroring only to the sender (I2). Then **the same check in
      Stage 1 of `handleDeploy`** against the *current* leader.
      **The second check is not redundant** — `reassignLeader` runs on leave, so a Confessor can
      select an Anathema, leave, and promote a Seeker who would otherwise deploy it. Same class as
      TD-092's `isSolo` counting ghosts: a check computed once that stops matching reality when the
      party changes underneath it.
      Test: `selectContract.test.ts` + `deploy.test.ts` — under-ranked actor refused, state unmutated;
      sufficiently ranked succeeds; **a leader demoted by reassignment between select and deploy is
      refused at the commit**. Every case sets rank **explicitly** — never relying on `DEFAULT_RANK`
      (P162), or the gate is only ever exercised in its permissive state.

- [ ] T366 [R358] — **Flag the stub so nobody ships it as balance.** `DEFAULT_RANK` is permissive
      (top rank) on purpose, so content stays reachable before accounts exist. One named constant,
      commented at the declaration, cited in TD-095.

- [ ] T367 [R359 / V4] — **Prove containment.** No filesystem or database write is added — if a task
      finds itself building storage it has left this spec and entered Phase 7. Suites green; re-run
      `sim/sweep.ts` and **explain any change** rather than accepting it (the harness iterates tiers
      itself, so its numbers should hold; the board it samples does not).
      **Ships with `specs/preparation/` R333**, the board-reroll fix — rank-gating turns
      create-read-leave-create into fishing for a tier you are allowed to take (TD-092 A6).

## Phase C — real Collegium Rank — **DEFERRED, ROADMAP PHASE 7**

- [ ] T368 [R360] — Rank moves to the account layer. Only the *source* changes; T364–T365 fix the
      shape. **Blocked on two things**: an account layer, and a **stable identity** — `playerId` is
      `randomUUID()` per join today, so there is nothing durable to attach a rank to.

## Do not re-invent

- **The board is free; the rank is the gate** (`contracts.md`, TD-012). Rank gates **acceptance**,
  never display. The board is minted in `createRoom` *before anyone else joins*, so gating what
  *appears* by party composition is incoherent.
- **Rank gates what you may LEAD, not what you may JOIN** (author ruling, TD-095). Only the accepting
  player is checked. Gating by the lowest rank present would mean a veteran can never play their own
  content with a friend — the opposite of a cooperative design.
- **A Rank is a permission, so TD-082's client-side stand-in does not transfer.** A display name is a
  convenience the server validates for shape; a rank decides what content you may access. You cannot
  put a permission in `user://rank.txt` (I2).
- **Do not build a persistence tier to get Phase C early.** TD-082 declined exactly this.

## Standing constraints

- Server-authoritative (I1/I2); shared is types + constants (I4); determinism holds (I3);
  nothing about an expedition is persisted (I7).
- Budget stated in `design.md`: nil by construction.
