# Tasks — Tiers and Ranks (TD-094)

> T# continues global from T354. **Phase A is unblocked and mechanical.**
> **Phase B is blocked on the Mutation system** — canon (GLOSSARY) and entirely unbuilt.

## Phase A — the rename

- [x] T355 [R348, P158 / V3] — **The Rank ladder, in the GLOSSARY.** Five bands —
      Aspirant → Seeker → Witness → **Confessor** → **Hierophant** — each with the Tier it may accept,
      escalating in *authority over what is known* rather than combat power (TD-012, Pillar 2).
      `Seeker` unchanged: it is the baseline identity and load-bearing everywhere.
      **Docs-only** — Collegium Rank does not exist in code, so there is nothing to rename yet.
      Test: names checked against `generateContract.ts`'s NPC tables. `Magister` and `Archivist`
      were rejected on collision — both are already petitioner names/roles. **Done in TD-094.**

- [ ] T356 [R346, R349, P159 / V1] — **Rename the union and the axis tables.**
      `APPRENTICE → VIGIL`, `JOURNEYMAN → INTERDICT`, `MASTER → ANATHEMA` in
      `src/shared/src/signs.ts`, then `ACTIVE_AXES` / `AMBIENT_AXES` keys in
      `incarnate/types.ts`, then `generateTraitRoll.ts`, `generateBoard.ts`, `requisition.ts`.
      **No axis membership moves — this is a rename, not a rebalance.**
      Order: shared → server source → server tests → client. ~21 test files, ~124 sites total.
      Test: server + shared suites green; then **re-run `sim/sweep.ts` and diff the numbers against
      TD-094's table — they must be identical.** A moved number means a moved axis (P159).

- [ ] T357 [R346, R347 / V2] — **The client half, which the compiler does not check.**
      `client/scripts/board/notice.gd` (the `PLEA` table) and `client/scripts/main.gd` (preview
      fixtures). **This is the risky half:** `notice.gd:77` reads
      `PLEA.get(str(intel.get("tier", "APPRENTICE")), PLEA["APPRENTICE"])` — a **fallback**, so a
      missed rename silently degrades to the wrong flavour text instead of erroring.
      Also do R347's copy pass: the bands are now *declarations*, not an abstract difficulty ramp —
      a **Vigil**'s petitioner is asking the Collegium to look; an **Anathema** is the Collegium
      having already decided. Re-read all bands, don't just re-key them.
      Test: `--board-preview` capture per tier; headless parse clean; no fallback silently firing.

- [ ] T358 [R349] — **Prove containment.** `git diff` touches `src/`, `client/`, `specs/`, `docs/`
      and nothing generated. **No codegen run** — `Tier` never reaches `client/protocol/protocol.gd`
      (an earlier estimate saying otherwise was wrong; `MASTER` was matching `NOT_AT_QUARTERMASTER`).
      Test: suites green; `spec_status.py --check` and `asset_map.py --check` green.

## Phase B — APOCRYPHA (BLOCKED: needs the Mutation system)

- [ ] T359 [R350] — Add `'APOCRYPHA'` to `Tier` with the **same six axes** as `ANATHEMA` — there are
      no axes left to add, which is the whole reason the fourth tier escalates *trust* instead.
- [ ] T360 [R350] — The Mutation stack on the trait roll, consulted by `deriveSigns` /
      `deriveReaction`: **mask**, **invert**, **add**.
- [ ] T361 [R351] — **Resolve the masking collision.** A masked Ward and an absent Ward both present
      as `no-reaction`, which already carries deliberate ambiguity (R55/R56); a third meaning on one
      token makes it noise. A player must never be unable to tell *"the world had nothing to say"*
      from *"something ate the answer"* with no way to find out — that is the exact failure mode
      TD-092 recorded for Apprentice probe kits.

## Do not re-invent

- **The two ladders stay apart** (P158). A Tier names a *place*; a Rank names a *person*.
  `Aspirant / Seeker / Witness` was rejected for Tier despite being canon, for this reason.
- **A fourth tier is not a scarcity fix** (R352). The sweep measured `6 SLOTS SPARE` at a full party;
  Mutations need no extra instruments. Scarcity stays `specs/preparation/` R336.
- **Rank gates Tier and Rank does not exist** — so today every writ is one tier regardless of what
  the union is called (`generateBoard.ts:11`). Renaming does not change that.

## Standing constraints

- Server-authoritative; the trait roll never crosses the wire (I5); shared is types + constants (I4);
  determinism holds (I3).
- Budget stated in `design.md`: Phase A is nil by construction.
