# Design — Rank-Gated Contracts (TD-095)

> Satisfies R353–R360. Properties P160–P163.
> **Phases A and B build now. Phase C is ROADMAP Phase 7 — do not attempt early.**

---

## Where the code is

| what | where |
|---|---|
| the hard-coded tier | `src/server/src/incarnate/generateBoard.ts` — `const BOARD_TIER: Tier = 'VIGIL'` |
| board minting | `src/server/src/rooms/RoomManager.ts:36` — `board: generateBoard(randomUUID())` |
| the player record | `src/server/src/rooms/types.ts` — `ServerPlayerEntry` |
| acceptance | `src/server/src/rooms/handlers/selectContract.ts` — phase, in-room, **leader**, then set |
| the commit | `src/server/src/rooms/handlers/deploy.ts` — Stage 1, `WAITING → DEPLOYING` |
| leader reassignment | `src/server/src/rooms/leaderElection.ts` — `reassignLeader`, called from `leaveRoom` |
| the ladder | `docs/GLOSSARY.md` — Aspirant → Seeker → Witness → Confessor → Hierophant |

`selectContract` already guards in-room → phase → **leader**. The rank check slots in directly after
the leader check, which is exactly where "may this actor accept this?" belongs.

---

## Phase A — a mixed board

Replace the constant with a **composed, shuffled pool** — see below for why not a per-entry draw.

**Shares** — a commission wall reads as mostly ordinary work with a few things nobody wants to touch:

```
VIGIL      5 of 8      ordinary petitions
INTERDICT  2 of 8      the parish is frightened
ANATHEMA   1 of 8      two wardens went to look and neither returned
```

Shares are **content**, tunable without touching shape. `APOCRYPHA` is excluded until
`specs/tiers/` Phase B ships it — adding a tier to the union does not automatically put it on the
wall.

**Shipped as a composed pool shuffled on a board-level stream** (`${expeditionSeed}:tiers`), not as a
per-entry draw. Two reasons, the second discovered while building it:

1. **Stream shape (P151).** A board-level stream touches **no entry rng at all**, so a contract is
   byte-identical to what `generateContract` yields directly from its entry seed — asserted by test,
   rather than merely argued. A per-entry `:tier` sub-stream would also have worked; this is stronger.
2. **A rolled board can be a dead board.** Once Rank gates acceptance, independent draws could leave a
   low-rank Seeker a wall with nothing they may take. A composed pool makes that unreachable.

`tierPool(size)` gives higher tiers their proportional share and fills the remainder with VIGIL, so
rounding at a non-canonical size can only ever make the wall *safer* — never leave it with fewer
acceptable contracts than planned.

**Expect the sweep to change, and check it deliberately.** `sim/sweep.ts` iterates tiers explicitly
so its own numbers should be unaffected — but the *board* it samples is not the same board, so any
board-facing measurement must be re-read rather than assumed (V4).

---

## Phase B — the gate

### The rank field

```ts
// ServerPlayerEntry
rank: Rank;          // server-owned; NEVER read from a client payload (P160)
```

`Rank` and the `RANK_ACCEPTS: Record<Rank, Tier[]>` mapping are **types + constants**, so they belong
in `src/shared` (I4) — the client needs the vocabulary to render what you may take. **The mapping
being shared does not make it trusted**: the server holds the authoritative `rank` value and
re-derives the decision itself.

### The stub

```ts
export const DEFAULT_RANK: Rank = 'HIEROPHANT';   // ← development affordance (R358, TD-095)
```

One named constant, permissive on purpose so all content is reachable before accounts exist, and
obvious enough at the call site that nobody mistakes it for balance. **Phase 7 changes only where the
value comes from.**

### The two checks, and why both

```
selectContract   after the isLeader guard:
                 RANK_ACCEPTS[sender.rank] includes contract.tier ?  else RANK_TOO_LOW
deploy Stage 1   the SAME check against the CURRENT leader, before WAITING → DEPLOYING
```

The second is not redundant. `reassignLeader` runs when a player leaves, so:

> A Confessor selects an Anathema → the Confessor leaves → a Seeker is promoted → the Seeker deploys
> a contract they could never have accepted.

This is TD-092's `isSolo`-counts-ghosts defect in another costume: **a check computed once that stops
matching reality when the party changes underneath it.** A test pins it (V2) so a future reader does
not delete the second check as duplication.

### What the client shows

The snapshot may carry each player's rank and the board's per-writ tier, so the wall can mark what
you may take. That is a **render affordance** — the server refuses regardless (I1). Nothing here
changes the wire *shape* beyond additive fields.

---

## Phase C — deferred

Rank moves to the account layer. Only the *source* changes; Phases A and B fix the shape. Two things
must exist first: an account layer (ROADMAP Phase 7), and a **stable identity** — `playerId` is
`randomUUID()` per join today, so there is nothing durable to attach a rank to.

**Do not build storage to get here early.** TD-082 declined to invent a persistence tier for one
string; a Rank is a *permission*, so it cannot even use TD-082's client-side stand-in.

---

## Performance budget (canon)

Nil. Phase A adds one seeded draw per board entry, at mint (once per room). Phase B adds an array
membership test on two already-guarded handler paths. No per-tick work, no allocation in a loop, no
client render change beyond text that already renders.

## Correctness Properties

- **P160** a permission is never client-supplied.
- **P161** the gate is re-checked wherever the party can change under it.
- **P162** the permissive stub cannot hide a broken gate — tests set rank explicitly.
- **P163** a mixed board stays deterministic.

## Files

**Phase A:** `src/server/src/incarnate/generateBoard.ts` (+ test).
**Phase B:** `src/shared/src/` (the `Rank` type + `RANK_ACCEPTS`), `src/server/src/rooms/types.ts`,
`RoomManager.ts` / `joinRoom.ts` (assign the default), `handlers/selectContract.ts`,
`handlers/deploy.ts`, their tests, and the board's writ rendering in `client/scripts/board/`.
**Ships with:** `specs/preparation/` R333, the board-reroll fix.
