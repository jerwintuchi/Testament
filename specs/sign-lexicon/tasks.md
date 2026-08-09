# Tasks — The Sign Lexicon (TD-093)

> T# continues global from T348. **ALL FOUR RULINGS ANSWERED 2026-08-09** (author, all as
> recommended) — see `requirements.md` "Blocking rulings". The spec is unblocked and **T349–T354
> are done**.

## Commit 1 — server + shared + docs

- [x] T349 [R339, P154 / V1] — **Write the test that fails first.** `lexicon.test.ts`: no token
      contains, case-insensitively, a value of its own axis or any `Stimulus` literal; every
      (axis, value) pair appears exactly once; tokens are unique. `no-reaction` is exempt — it is not
      an axis value.
      Test: it must **fail 11 of 24** against the current table before any token is touched. Record
      the failing list in the commit message; that list is the mechanical proof this is a defect and
      not a matter of taste.
      **Done, and it failed exactly 11 of 24 as predicted** — the whole FRAILTY set, the whole WARD
      set, `frost-rime`, `rot-bloom`, and `flame-rune` (which fails on the *Stimulus* clause, not its
      own axis). Failing list recorded in the commit message. `no-reaction` needed no exemption: it
      lives in `deriveReaction.ts`, outside the table — but the test now asserts it obeys the rule
      anyway, since it is a token a player reads.
      **One production change it forced:** the rule needs the axis→values map at RUN time and a union
      type cannot be walked, so `AXIS_VALUES` is now a real const in `types.ts` and
      `generateTraitRoll` draws from it. One list, so a new value is drawn, demanded of the lexicon,
      and forbidden from its own token all at once. Order is load-bearing (`rng.pick` indexes it);
      the trait-roll suite proves the seeded stream is unchanged.

- [x] T350 [R345] — **`tokenFor(axis, value)` in `lexicon.ts`, and detokenise the assertions.**
      Rewrite ~25 pin sites across **8** test files — `snapshot`(5), `perception`(5), `probe`(4),
      **`shared/signs`(3)**, `reconnect`(3), `field.integration`(2), `deriveReaction`(2),
      **`shared/fieldMessages`(1)** — to call `tokenFor('FRAILTY','FLAME')` instead of pinning a
      literal. `deriveSigns`/`deriveReaction` hard-code no token, so nothing else moves.
      Test: suites green **before** the table changes — this task must be behaviour-preserving.
      Why first: after it, the only literals in the tree are the lexicon and its own pinning test, and
      the next re-authoring is a one-file change.
      **Done — and it paid off immediately: T351 re-authored 17 tokens and NOT ONE assertion needed
      editing.** 397 tests green before the table changed (behaviour-preserving), 398 after.
      **The design's migration table was wrong about `src/shared`, and the correction matters.** It
      listed `shared/signs`(3) and `shared/fieldMessages`(1) among the files to route through
      `tokenFor` — but `src/shared` has no dependency on `src/server` and **must not gain one**
      (S1/I4); importing the lexicon there would invert the trust boundary to satisfy a test. Those
      four sites turned out not to be lexicon assertions at all: `SignToken` is `string`, so they are
      **type-shape fixtures** where the value is arbitrary. They now use a deliberately synthetic
      `'a-sign-token'`, with a comment saying why — a fixture that *looked* like a real token is what
      invited the mass edit in the first place.

- [x] T351 [R339–R342, R340] — **Re-author the 24 entries.** The proposed table is in
      `requirements.md`: 17 changed, 7 kept. **`TELL`/OMEN is kept verbatim** (R341 — zero
      interpretation budget at wind-up speed; anyone "fixing" it has misread the design).
      Test: T349 now passes 24 of 24; suites green via `tokenFor`.
      **Ruling 1 answered: REWORD** (author, 2026-08-09). The four WARD tokens name the instrument
      presented — `swallowed-the-brand / -rime / -grain / -lamp` — so P154 holds, and they stay
      per-element rather than collapsing, which keeps P157 (a reconnecting player still knows *which*
      ward matched) without needing a durable probe record.
      **The last coin-flip, COLD, settled on the spec's own criterion rather than taste:
      `fever-sweat`, not `will-not-clot`.** R340 requires the four Stress-marks to be derivable from
      one sentence — *a wound names the substance; the substance names the remedy*. `will-not-clot`
      names **no substance**, so it breaks the law it is supposed to obey; `fever-sweat` names spent
      heat, which points at cold the way tallow points at flame. Same test that retired
      `spalled-stone`: the criterion decides, not preference.

- [x] T352 [R344, P156 / V3] — **Make the wire assertion honest.** Trait-value literals asserted
      absent **case-insensitively and unquoted**, wherever containment is checked
      (`deploy.test.ts`, `probe.test.ts`, `field.integration.test.ts`).
      Test: the assertion fails if a token regains its answer. The old form passed only because
      `flinch-from-flame` carries `flame` lowercase and unquoted — which is why nobody noticed.
      Shipped as `incarnate/containment.testkit.ts` — **outside vitest's `*.test.ts` glob on purpose**,
      so it ships assertions rather than running any. `expectNoTraitValues(payload, allow)` checks
      *every* trait value, not just the one in the fixture; `allow` exists only for a value the party
      itself supplied (`PROBE_RESULT.stimulus` is the party's own choice echoed back).
      **The gap this actually closed was not where the spec pointed.** The three named sites all
      inspect *probe* payloads — but the token that leaked was FRAILTY, which rides `FIELD_STARTED`,
      and that payload had only ever been checked at KEY level (`Object.keys(...)`). Nothing had ever
      looked at its values. A value-level assertion now guards it, **scoped to `signs` rather than
      the whole payload**: `fieldData` carries authored names — *The Rot-Bloom*, *The Weeping Mire*,
      *The Salt Marsh* — drawn independently of the trait roll, so a name matching the aspect is
      coincidence, and asserting over them would fail on a fixture instead of a defect.
      **Proven to bite, not merely to pass:** restoring `flinch-from-flame` fails the P154 test AND
      the new `FIELD_STARTED` containment test, and nothing else.

- [x] T353 [R345 / V4] — **Docs, superseded in place.** `docs/systems/sign-language.md` takes the new
      table; `specs/incarnate-signs/design.md` (a **closed** spec) and
      `specs/probe-handler/{design,requirements,tasks}.md` are marked superseded *in place* with what
      replaced them — not rewritten (`spec-workflow.md`). `DECISION_LOG.md` is append-only and keeps
      the old tokens where they stand.
      Test: `spec_status.py --check` and `--selftest` green; suites green.
      `sign-language.md` gains the P154 rule, the clock-bounded interpretation budget, the
      Stress-mark **law**, why Reaction is flavour-but-not-collapsible, the token/prose split, and
      **two new non-negotiables** (a token never names its own answer; the Librarium never holds a
      translation table). `specs/incarnate-signs/design.md` (a CLOSED spec) keeps its table with a
      banner naming the 11 failures and the 7 survivors; `specs/probe-handler/{requirements,design,
      tasks}.md` have their `drinks-flame` examples marked in place — rules unchanged, tokens
      re-authored. `DECISION_LOG.md` is append-only and keeps the old tokens where they stand.

## Commit 2 — the client prose

- [x] T354 [R343, P155 / V2] — **Prose replaces the raw token.** New
      `client/scripts/field/sign_prose.gd` (preloaded `RefCounted`, static table, never a global
      `class_name`). Both raw prints go: `main.gd:754` (probe result) and `main.gd:1183` (the sign
      list). Renders as a **field note in the Seeker's own hand**, in the writ idiom — not a log line,
      which is consumed as a label however it is worded.
      **Ruling 2 answered: TOKEN + CLIENT PROSE** (author, 2026-08-09).
      Test: capture the field screen and probe log — no raw token visible; a check over
      `sign_prose.gd` that no string names an axis or trait value (P155).
      **The check is `tools/lexicon_check.py`** (stdlib, `--selftest` green on 6 fixtures). It guards
      the one seam neither suite can reach — the table is TypeScript, the prose is GDScript, so it
      parses both — and asserts **coverage** as well as P155: every token has prose and the prose
      invents none. Coverage matters because the fallback is deliberately *not* the raw token, so a
      missing entry would ship silently as "Something here, and no words for it yet."
      **V2 was not verifiable as written**, so a `--field-preview` flag was added (plus `--field-foot`
      for the probe log, which sits below the fold — the `--reader-foot` problem again): the field
      page needs a live server and a deployed room, which the capture harness has neither of.
      Captured: prose under hand-written channel headings, both probe-log branches (a miss and a
      match), no raw token anywhere.
      **Two findings beyond the task.** (1) `you perceive: RESIDUE, STRESS_MARK, …` was printing wire
      identifiers straight to the player — the same defect as the tokens, one line away from the code
      fixing it — so it now goes through the same prose layer. (2) Doing that **broke TD-098**: six
      sentence-length headings ran off the right edge. Fixed the canon's way — a short one-word form
      and an **explicit** `\n` every three, never autowrap — and re-captured to prove it.

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
