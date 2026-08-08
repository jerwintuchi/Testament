# Tasks — The Sign Lexicon (TD-093)

> T# continues global from T348. **BLOCKED on four author rulings** in `requirements.md` — T351 and
> T354 name which. T349–T350 are unblocked and can be written first; in fact T349 *should* be, because
> watching it fail is the proof.

## Commit 1 — server + shared + docs

- [ ] T349 [R339, P154 / V1] — **Write the test that fails first.** `lexicon.test.ts`: no token
      contains, case-insensitively, a value of its own axis or any `Stimulus` literal; every
      (axis, value) pair appears exactly once; tokens are unique. `no-reaction` is exempt — it is not
      an axis value.
      Test: it must **fail 11 of 24** against the current table before any token is touched. Record
      the failing list in the commit message; that list is the mechanical proof this is a defect and
      not a matter of taste.

- [ ] T350 [R345] — **`tokenFor(axis, value)` in `lexicon.ts`, and detokenise the assertions.**
      Rewrite ~25 pin sites across **8** test files — `snapshot`(5), `perception`(5), `probe`(4),
      **`shared/signs`(3)**, `reconnect`(3), `field.integration`(2), `deriveReaction`(2),
      **`shared/fieldMessages`(1)** — to call `tokenFor('FRAILTY','FLAME')` instead of pinning a
      literal. `deriveSigns`/`deriveReaction` hard-code no token, so nothing else moves.
      Test: suites green **before** the table changes — this task must be behaviour-preserving.
      Why first: after it, the only literals in the tree are the lexicon and its own pinning test, and
      the next re-authoring is a one-file change.

- [ ] T351 [R339–R342, R340] — **Re-author the 24 entries.** The proposed table is in
      `requirements.md`: 17 changed, 7 kept. **`TELL`/OMEN is kept verbatim** (R341 — zero
      interpretation budget at wind-up speed; anyone "fixing" it has misread the design).
      **BLOCKED on ruling 1** (the WARD form) and the two coin-flips (`spalled-stone` vs `run-wax`;
      `fever-sweat` vs `will-not-clot`).
      Test: T349 now passes 24 of 24; suites green via `tokenFor`.

- [ ] T352 [R344, P156 / V3] — **Make the wire assertion honest.** Trait-value literals asserted
      absent **case-insensitively and unquoted**, wherever containment is checked
      (`deploy.test.ts`, `probe.test.ts`, `field.integration.test.ts`).
      Test: the assertion fails if a token regains its answer. The old form passed only because
      `flinch-from-flame` carries `flame` lowercase and unquoted — which is why nobody noticed.

- [ ] T353 [R345 / V4] — **Docs, superseded in place.** `docs/systems/sign-language.md` takes the new
      table; `specs/incarnate-signs/design.md` (a **closed** spec) and
      `specs/probe-handler/{design,requirements,tasks}.md` are marked superseded *in place* with what
      replaced them — not rewritten (`spec-workflow.md`). `DECISION_LOG.md` is append-only and keeps
      the old tokens where they stand.
      Test: `spec_status.py --check` and `--selftest` green; suites green.

## Commit 2 — the client prose

- [ ] T354 [R343, P155 / V2] — **Prose replaces the raw token.** New
      `client/scripts/field/sign_prose.gd` (preloaded `RefCounted`, static table, never a global
      `class_name`). Both raw prints go: `main.gd:754` (probe result) and `main.gd:1183` (the sign
      list). Renders as a **field note in the Seeker's own hand**, in the writ idiom — not a log line,
      which is consumed as a label however it is worded.
      **BLOCKED on ruling 2** (the prose split).
      Test: capture the field screen and probe log — no raw token visible; a check over
      `sign_prose.gd` that no string names an axis or trait value (P155).

## Blocking rulings

1. **WARD form** — reword (R342, recommended) or collapse? **If collapse:** it must ship in the same
   commit as a durable probe record. `revealedSigns` dedupes by token, so one shared token loses which
   ward matched on reconnect (P157) — a silent regression on the one axis that costs exposure to learn.
2. **Prose split** — terse token + client prose (R343, recommended), or a readable token?
3. **The Librarium's no-translation-table rule** — recorded as a non-negotiable?
4. **Coarse/fine ambiguity** — deferred, not dropped?

## Do not re-invent

- **The 1:1 sign→meaning map is canon.** Do not randomise it per expedition. A veteran's lookup table
  is the intended end state (Pillar 2); the flaw is only that two-thirds of the table is
  *self-translating*.
- **The OMEN set is not broken.** `full-body-tremor` ≈ SHUDDER is deliberate (R341).
- **No confidence/clarity/strength field on a `Sign`** — that is knowledge-as-a-number. If coarse
  reads are ever built they are a *different token*.
- **No Contract Board capture diff** — the board renders no signs. The standing ritual does not apply.

## Named, but not this spec's work

**The Field Testament at extraction is the real teacher** — the answer key delivered after the bet is
settled (Record closing the loop). Currently a stub: `buildStubTestament` hard-codes
`outcome: 'success'`. **Build it before any Librarium**, or a failed hunt teaches nothing and the room
becomes a crutch for a missing loop.
