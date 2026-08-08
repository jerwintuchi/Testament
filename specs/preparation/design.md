# Design — Preparation (TD-092)

> Satisfies R326–R337. **Phase 0 is server-only and shippable alone**; later phases are designed
> here but not authorised. Properties P150–P153.

---

## Where the code is

| what | where |
|---|---|
| the trait roll | `src/server/src/incarnate/generateTraitRoll.ts` |
| axis tables | `src/server/src/incarnate/types.ts` (`ACTIVE_AXES`, `AMBIENT_AXES`) |
| reaction derivation | `src/server/src/incarnate/deriveReaction.ts` |
| the contract | `src/server/src/incarnate/generateContract.ts` |
| deploy (both stages) | `src/server/src/rooms/handlers/deploy.ts` |
| the ready predicate | `src/server/src/rooms/readyCheck.ts` — **already correct, just unused on the live path** |
| perception | `src/server/src/rooms/perception.ts` |
| the seeded RNG | `src/server/src/rng/seeded.ts` |

---

## Phase 0

### R326 — `ward !== frailty`

**Pick from a filtered set, not by rejection sampling.**

```ts
roll.ward = rng.pick(WARD_VALUES.filter(w => w !== roll.frailty));
```

`WardValue` and `FrailtyValue` are the same four tokens (`FLAME | COLD | SALT | LIGHT`), and
`frailty` is drawn before `ward` in the existing order, so the filter is available at that point
without reordering the stream.

**Why filtering beats rejection.** A rejection loop (`do { … } while (ward === frailty)`) consumes a
*variable* number of draws, so every downstream value in the same stream shifts depending on what was
rejected. Filtering consumes **exactly one** draw, as today — the stream keeps its shape and only
this value changes. Determinism (I3) holds either way; the filtered form keeps the diff to one axis
and makes the property easy to state: uniform over the three values the Incarnate is not frail to.

**This changes the worlds a given seed produces.** That is intended — it is a rules change, not a
refactor. Any test pinning a literal ward value for a fixed seed must be re-pinned, and re-pinning is
the correct response, not a reason to preserve the old draw.

### R327 — `allReady` on the live deploy path

`readyCheck.allReady` already filters to connected players (`disconnectedAt === null`), so a ghost
cannot deadlock the gate — exactly the TD-032 behaviour R327 requires. Nothing new is written; it is
imported and called in **stage 2** of `handleDeploy`, beside the existing `NO_CONTRACT_SELECTED`
check, and refuses with a reason. Stage 1 (the `WAITING → DEPLOYING` commit) is untouched: packing
happens *during* `DEPLOYING`, so a readiness gate there would fire before anyone could pack.

### R328 — `isSolo` over connected players

```ts
const isSolo = room.players.filter(p => p.disconnectedAt === null).length === 1;
```

Same predicate the ready check uses, so "who is present" has one definition in the file rather than
two. Ordering note: this must be computed **before** the per-player loop that assigns
`perceivedChannels`, which is where it already sits.

---

## Later phases — shape only

```
Phase 1  ACTIVE_AXES: Record<Tier, Axis[]>  →  count per tier + seeded selection
         primary verb forces liveness (BANISH/CAPTURE ⇒ RITE_KEY, ELIMINATE ⇒ FRAILTY)
         origin biases WHICH AXES are live — shallow weights, never safe
         board reroll closed in the SAME commit (A6 becomes live on any intel fix)
Phase 2  PROBE_EXPOSURE_COST: constant → f(probes taken this expedition), 1/2/4/8
         exposure gains a consumer: route closure at thresholds (never sign quality)
Phase 3  a party-wide bound on reading instruments, < |CHANNELS|   [author's number]
         + a smaller solo allowance, shipped together or Pillar 4 inverts
```

**Dependencies that are not optional** (TD-092): Phase 1 must carry the board-reroll fix or it ships
the exploit it enables. Phase 3 must carry the solo allowance or it inverts the cooperation pillar.
Charges are **late** work and are not the anti-brute-force fix — four kits are four *different*
stimuli, and `requisition.ts:32` already rejects duplicates, so one charge each is exactly the sweep.

---

## Performance budget (canon, `.claude/rules/performance.md`)

Phase 0 is server-side and adds **no per-tick work**: one array `filter` at contract generation
(once per contract, not per frame), one predicate at deploy (once per expedition), one array filter
at deploy. No allocation enters the 20Hz movement tick, no client render work, no new particles or
layers. Later phases must state their own budget; Phase 2's exposure consumer touches site geometry
and will need one.

---

## Correctness Properties

- **P150 (a law, not an answer):** the rule shrinks the search space and never reveals the Ward. A
  player who knows `ward !== frailty` still has to read the Stress-mark to use it.
- **P151 (determinism survives):** same seed → same roll. The filtered pick consumes exactly one
  draw, so stream shape is preserved.
- **P152 (preparation is gated on preparation):** no connected player is left behind at deploy;
  ghosts never block.
- **P153 (no free certainty):** any path resolving an axis without inference is impossible or
  expensive. Phase 2 prices the known instance rather than forbidding it.

## Files

**Phase 0:** `src/server/src/incarnate/generateTraitRoll.ts` (+ `.test.ts`),
`src/server/src/rooms/handlers/deploy.ts` (+ its test). No client, no shared, no wire change.
