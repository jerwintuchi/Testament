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
      **Follow-up it forced (T362b):** the mixed board made **five tests FLAKY, not failing** —
      `RoomManager` mints the board from `randomUUID()`, `acceptContract` takes `board[0]`, and five
      assertions hard-coded the tier that used to be guaranteed. A green run proved nothing; the
      failures surfaced only across repeated runs. Deploy tests now **pin their tier** in the shared
      setup (they exercise deploy, not board variety); the accept and lobby-integration tests
      **derive** it instead of assuming it. Verified by **10 consecutive green runs**, not one.

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

- [x] T364 [R355, P160] — **`Rank` + `RANK_ACCEPTS` in `src/shared`** (types + constants only, I4) and
      a server-owned `rank` on `ServerPlayerEntry`, assigned at create/join from a single named
      `DEFAULT_RANK`. **Never read from a client payload.**
      Shipped: `src/shared/src/rank.ts` (`Rank`, `RANKS`, `RANK_ACCEPTS` — an explicit map, not an
      ordinal comparison, so a future rank or tier must be placed deliberately) and
      `src/server/src/rooms/rank.ts` (`canAccept`, `DEFAULT_RANK`). The **decision** is server-side
      because `canAccept` is game logic and I4 keeps shared to types + constants.
      Test: `rank.test.ts` — 6 cases: an Aspirant accepts nothing; each rank accepts its own tier and
      below; the ladder is **monotonic**; every rank has an entry; no entry names a tier that does not
      exist. Plus `selectContract.test.ts` — an inbound `rank` in the payload is ignored **and does
      not stick**.

- [x] T365 [R356, R357, P161, P162 / V2] — **The gate, in both places.** In `selectContract`,
      immediately after the `isLeader` guard: refuse a contract above the actor's rank with
      `RANK_TOO_LOW`, mutating nothing, erroring only to the sender (I2). Then **the same check in
      Stage 1 of `handleDeploy`** against the *current* leader.
      **The second check is not redundant** — `reassignLeader` runs on leave, so a Confessor can
      select an Anathema, leave, and promote a Seeker who would otherwise deploy it. Same class as
      TD-092's `isSolo` counting ghosts: a check computed once that stops matching reality when the
      party changes underneath it.
      Test: `selectContract.test.ts` (4 cases) + `deploy.test.ts` (3 cases) — under-ranked actor
      refused with nothing mutated and the error to the sender only; sufficiently ranked succeeds;
      an Aspirant answers for nothing; and **the case the second check exists for**, built end to end:
      a Confessor selects an Anathema, calls `LEAVE_ROOM`, `reassignLeader` promotes a Seeker, and the
      Seeker's commit is refused. Every case sets rank **explicitly** (P162).
      **Proven to bite, not merely to pass:** disabling the deploy-side check makes exactly those two
      tests fail and nothing else — so they test the gate, not the scenery.

- [x] T366 [R358] — **Flag the stub so nobody ships it as balance.** `DEFAULT_RANK = 'HIEROPHANT'`
      carries a boxed comment at its declaration explaining that it is a development affordance, why
      no account layer exists to replace it, and that only its *source* changes at Phase 7.
      **Client affordance deliberately NOT built:** R355 makes shipping rank in the snapshot optional,
      and with a permissive stub every player may take everything — so a "what you may accept" marker
      would render nothing. It becomes meaningful at Phase 7 and belongs there.

- [x] T367 [R359 / V4] — **Prove containment.** No filesystem or database write is added — if a task
      finds itself building storage it has left this spec and entered Phase 7. Suites green; re-run
      `sim/sweep.ts` and **explain any change** rather than accepting it (the harness iterates tiers
      itself, so its numbers should hold; the board it samples does not).
      **The R333 coupling turns out NOT to apply here, and that is a consequence of T362's design.**
      The spec required the board-reroll fix to ship alongside, because rank-gating would turn
      create-read-leave-create into fishing for a tier you may take. But T362 composes a **guaranteed**
      5/2/1 spread, so **every board has identical tier composition** — rerolling cannot change which
      tiers are on offer, only which targets and trait rolls. There is no tier to fish for. The reroll
      exploit still exists for *intel* fishing, which is exactly where R333 lives (`preparation`
      Phase 1, blocked); it stays there rather than being pulled forward.
      Verified: server 380 → **393**, 8 consecutive green runs, no filesystem or database write added.

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
