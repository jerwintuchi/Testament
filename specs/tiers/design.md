# Design — Tiers and Ranks (TD-094)

> Satisfies R346–R352. Properties P158–P159.
> **Phase A is mechanical and shippable alone. Phase B is blocked on the Mutation system.**

---

## Where the code is

| what | where |
|---|---|
| the union | `src/shared/src/signs.ts` — `export type Tier = 'APPRENTICE' \| 'JOURNEYMAN' \| 'MASTER'` |
| axis gating | `src/server/src/incarnate/types.ts` — `ACTIVE_AXES`, `AMBIENT_AXES` (keyed by Tier) |
| the roll | `src/server/src/incarnate/generateTraitRoll.ts` — two tier comparisons |
| the board | `src/server/src/incarnate/generateBoard.ts` — the "all one tier until Rank exists" note |
| client copy | `client/scripts/board/notice.gd` — the `PLEA` table, keyed by tier string |
| client fixtures | `client/scripts/main.gd` — `--board-preview` writs |
| **not** involved | `client/protocol/protocol.gd` — `Tier` never reaches codegen |

## Phase A — the rename

**It is a literal substitution, and that is the whole point.** No axis membership moves, so the
sweep's numbers must come out identical afterwards (P159 — this is V1's real assertion, not a
formality).

```
APPRENTICE → VIGIL
JOURNEYMAN → INTERDICT
MASTER     → ANATHEMA
             APOCRYPHA   (Phase B — added to the union only when Mutations exist)
```

**Measured surface: 27 files, ~124 sites.** Distribution matters, because it says where the risk is:

| where | files | note |
|---|---|---|
| server tests | 18 | the bulk — `deriveSigns.test.ts` alone has 16 |
| server source | 4 | `types.ts`, `generateTraitRoll.ts`, `generateBoard.ts`, `requisition.ts` |
| shared | 3 | `signs.ts` (the union) + two test files |
| **client** | 2 | `board/notice.gd` (`PLEA`), `main.gd` (preview fixtures) — **hand-written, not generated** |

The risk is not the count; it is that **two of the sites are GDScript string keys**, which fail
silently. `notice.gd:77` does `PLEA.get(str(intel.get("tier", "APPRENTICE")), PLEA["APPRENTICE"])` —
a **fallback**, so a missed rename degrades to the wrong flavour text rather than erroring. That is
the one thing a suite cannot catch and a capture can.

**Order:** shared union → server source → server tests → client. Do the client last and verify by
capture, because it is the half the compiler does not check.

### R347's copy pass, which is not cosmetic

The `PLEA` table is the petitioner's voice, banded by tier. Under the old names the bands were an
abstract difficulty ramp; under the new ones each band is a **declaration with a meaning**, so the
copy should answer to it — a **Vigil** is someone asking the Collegium to *look*, an **Anathema** is
the Collegium having already decided. Re-read all four bands rather than only re-keying them.

## Phase B — APOCRYPHA

Shape only; blocked.

```
shared   Tier gains 'APOCRYPHA'
server   ACTIVE_AXES.APOCRYPHA = the same six as ANATHEMA   (no new axes — there are none left)
         + a Mutation stack on the trait roll
         deriveSigns / deriveReaction consult the stack: mask | invert | add
client   nothing structural — the signs simply stop being trustworthy
```

**The collision to design, not discover (R351):** a masked Ward and an absent Ward both present as
`no-reaction`, which already carries deliberate ambiguity (R55/R56). Stacking a third meaning onto
one token makes it noise. Options worth weighing when this unblocks: a distinct token for *"something
ate the answer"*; a second channel that betrays the mutation; or restricting masking to axes whose
absence is itself observable.

**Not a scarcity fix (R352).** Mutations need no extra instruments, so `6 SLOTS SPARE` at a full party
survives untouched. That stays R336's job.

## Performance budget (canon)

**Phase A: nil.** A literal rename adds no work at any tier of the stack — no allocation, no per-frame
cost, no new node. **Phase B** must state its own; a Mutation stack is consulted at sign-derivation
time (once per contract per axis, never per tick), so the expected cost is also nil, but it is the
Phase B author's job to say so and to check that mask/invert do not turn one lookup into a scan.

## Correctness Properties

- **P158 (two ladders, never merged):** no Tier name names a person; no Rank name names a place.
- **P159 (a rename is not a rebalance):** `sim/sweep.ts` reproduces TD-094's numbers exactly after
  Phase A. A moved number means a moved axis.

## Files

**Phase A:** `src/shared/src/signs.ts`, `src/server/src/incarnate/{types,generateTraitRoll,generateBoard}.ts`,
`src/server/src/rooms/handlers/requisition.ts`, ~21 test files, `client/scripts/board/notice.gd`,
`client/scripts/main.gd`, `docs/GLOSSARY.md` *(already done, TD-094)*.
**Phase B:** the above plus a Mutation module under `src/server/src/incarnate/`.
