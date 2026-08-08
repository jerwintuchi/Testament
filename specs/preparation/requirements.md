# Requirements — Preparation (TD-092)

> **R326+**, **P150+**, **T337+**. Written to be picked up cold.
>
> Decision record: **TD-091** (the Stipend is cut — there is no currency in Testament) and
> **TD-092** (charges do not fix the brute-force; the abuse register; this spec's authorisation).

---

## What a fresh session needs to know

**The problem, in one sentence:** preparation is a solved packing problem — the optimal bag is
computable from **tier alone**, before anything about the Incarnate is known, and it is the same
every expedition.

**Why** (all verified in the tree, not remembered):

- `ACTIVE_AXES` / `AMBIENT_AXES` (`src/server/src/incarnate/types.ts`) are **fixed by tier** and
  public. `AXIS_TO_CHANNEL` (`rooms/perception.ts`) is a **bijection**, and each channel has exactly
  **one** lens in `GEAR_CATALOG`. So axis → channel → item is a lookup, not a choice.
- The contract cannot inform the choice: `generateContract` draws `origin`, `targetName` and
  `siteName` independently of the trait roll, and `origin` is referenced **nowhere else** in
  `src/server/`. It is noise, not the "partial, sometimes-wrong intel" that
  `loadout-economy.md` non-negotiable 4 requires.
- At **APPRENTICE** — the only tier that ships — three of ten catalog items can do anything at all,
  and for a solo Seeker **the empty bag is optimal**.

**The test this spec applies** (canon, TD-092): *memorizing a **law of the world** is the intended
progression (Pillar 2); memorizing **which entity carries which value** is forbidden (Pillar 3). A
procedure that yields certainty without inference is a wiki with extra steps — make it impossible,
or make it expensive, but never leave it free.*

**Standing constraints:**

- **No currency** (TD-091). Bounds are expressed in slots, charges, instruments or exposure — never
  coin, which would state an exchange rate between reading and winning.
- **No knowledge as a number** (vision.md): no research %, no gear ratings, no confidence value on a
  `Sign`. A coarse read is a *different word*, never the same word at 60%.
- Server-authoritative; the trait roll never crosses the wire (I5). `src/shared` is types and
  constants only (I4). Seeded determinism holds (I3).
- **Requisition's reversibility is correct and must be preserved.** `DEPLOYING`-only, at-station,
  own-bag, replace-not-merge, and ambient signs do not arrive until `FIELD_STARTED` — so a party may
  re-pack while deciding but cannot re-pack after seeing a sign. The commitment boundary is already
  in the right place.

---

## Phase 0 — the honest floor (no new systems; authorised, TD-092)

Makes the shipped code stop contradicting the shipped docs, and closes two live exploits. Every item
here is a designer's call — none needed an author ruling.

### R326 — A thing is never warded against what it is frail to

- AC: `generateTraitRoll` never produces a roll where `ward === frailty`, at any tier that rolls a
  Ward.
- AC: determinism holds (I3) — the same seed still yields the same roll, and the rejection is part of
  the seeded stream, not a post-hoc mutation.
- AC: every `WardValue` remains reachable across seeds. The rule removes one option, it must not bias
  the distribution toward any particular value.
- **Why this earns its place:** it converts an *ambient* channel (Stress-mark, read by a lens) into a
  falsifiable prediction about a *probe-gated* one (Reaction). The party's first genuinely
  load-bearing sentence becomes "Stress-mark says salt, so don't waste the salt probe." This is the
  cross-channel inference `distributed-perception.md` lists under Future Expansion, for one line.
- **Why it is not memorization:** it is a **law of the world** (Pillar 2), learned once and
  permanent. It shrinks the search; it never hands over the answer.

### R327 — The party cannot be deployed unprepared

- AC: `handleDeploy` refuses while any **connected** player is not ready, with a reason.
- AC: a **ghost** (a disconnected player holding a seat, TD-032) does not block deployment — that is
  what `allReady` in `readyCheck.ts` already implements, and it is reused rather than re-derived.
- AC: nothing is mutated on refusal, and the error goes only to the requesting socket (I2).
- **The gap being closed (A5):** `allReady` is imported by exactly one file — `acceptContract.ts`,
  the *legacy* handler whose own comment says the new client flow does not use it. The live path
  checks in-room, phase, leader, at-station and contract-selected, and **nothing about readiness**.
  TD-088 called the ready toggle load-bearing; on the live path it is decorative, and preparation
  cannot "have teeth" while a leader can deploy four empty bags.

### R328 — Leaving must not beat dropping — **BLOCKED, needs an author ruling**

**The incentive (A7):** a *disconnected* partner leaves you strictly worse than solo (you lose the
free full-channel read **and** their channels go unread), while a partner who deliberately sends
`LEAVE_ROOM` during `DEPLOYING` makes you strictly **better** — the party shrinks to one, the solo
grant fires, and you get free coverage plus four probe slots. Leaving beats dropping, which is
backwards.

**Why the obvious fix is wrong, proven by test, not by argument.** Computing `isSolo` over
*connected* players opens a strictly worse hole. `handleDeploy` assigns `perceivedChannels` to
**every listed player, ghosts included**, and `reconnect.ts` **never recomputes it** (A9). So a duo
where one player deliberately disconnects during `DEPLOYING` would deploy with `isSolo === true` and
**both** players would hold every tier channel — the ghost keeping its snapshot through reconnect.
That defeats distributed perception outright. This was found by writing the test first; the naive fix
was reverted, and `deploy.test.ts` now pins the current behaviour plus a regression guard on the
ghost snapshot so the trap cannot be walked into again.

**The two admissible fixes, both larger than Phase 0:**

- **(a) Freeze party size at the Stage-1 commit.** `WAITING → DEPLOYING` records the connected count;
  perception reads *that*, so neither leaving nor dropping after the commit changes anything. Good
  fiction (the Collegium issued the writ to a party of N), closes the exploit half cleanly, and does
  **not** help a genuine drop — the survivor stays worse off than a true solo.
- **(b) Recompute perception whenever the connected set changes.** Fixes A7 *and* A9 and helps
  genuine drops, but perception stops being a deploy-time snapshot, which touches reconnect, the
  field tick and anything that later makes gear droppable.

- AC (either fix): a partner leaving during `DEPLOYING` grants the survivor **nothing**.
- AC (either fix): no path lets two connected players both read every channel.

### R329 — Solo's free read is preserved as-is

- AC: a true solo still reads every tier channel regardless of gear (TD-008 is untouched by Phase 0).
- AC: the tier channel list includes `REACTION` unconditionally — even at APPRENTICE, where
  `deriveReaction` can only ever return `no-reaction`. Pinned by test so it is not mistaken for a bug.

### R338 (containment, Phase 0) — server only

- AC: no client change, no wire-shape change, no `src/shared` change.
- AC: server + shared suites green.

---

## Phase 1 — packing becomes a bet (designed, not yet authorised)

The minimum change that makes preparation a real decision. Creates uncertainty at pack time with
**zero new content**, at the tier that ships today.

### R330 — Which axes are live varies per expedition

- AC: tier sets a **count** of live axes; the seeded RNG picks **which**. `ACTIVE_AXES` stops being a
  fixed per-tier table.
- AC: determinism holds (I3); the selection is part of the seeded stream.
- AC: a dead axis emits **no sign on its channel** — it is a diagnosis with consequences, not a
  silent absence. (No Tell means it never telegraphs, which should change how the party fights.)

### R331 — A contract is never unachievable

- AC: the **primary verb forces liveness** — `BANISH`/`CAPTURE` ⇒ `RITE_KEY` live; `ELIMINATE` ⇒
  `FRAILTY` live. Otherwise a dead axis makes the contract impossible, which is a trap, not a bet.
- AC: this is the contract axis doing real work (TD-015): the Collegium only issues a banishment writ
  against something banishable.

### R332 — Origin becomes a prior, not decoration

- AC: `origin` biases **which axes are live** (not which values sit on them — lenses key on axes, and
  the value-level payoff lives in counters and rites, which are unbuilt).
- AC: the bias is **shallow** — following the assertion is right more often than not and **never
  safe**. A strong prior would make Origin memorizable (Pillar 3).
- AC: `origin` stops being referenced nowhere; the assertion becomes genuinely falsifiable, as
  `contracts.md` already claims it is.

### R333 — The board cannot be rerolled for free

- AC: creating, reading and abandoning a room to re-mint `generateBoard` is closed.
- AC: **ships in the same commit as R330–R332.** Harmless while intel is noise; the day intel carries
  signal it is contract-scumming (A6).

---

## Phase 2 — the bet costs something

### R334 — Probing is priced, and refusing to think is priced steeply

- AC: probe exposure **escalates within an expedition** (1, 2, 4, 8 …), so the four-step Ward sweep
  costs ~15 against an inferred single test at 1 — a **15× premium on refusing to think**.
- AC: exposure remains a **room** value, so four people brute-forcing pay what one pays. Larger
  parties are never punished for owning more kits, only for using them thoughtlessly.
- AC: brute force stays **available**. Pricing beats forbidding: a party that has read nothing and is
  out of time can still buy the answer at a terrible price, which is a legible, dramatic decision.

### R335 — Exposure has a consumer

- AC: exposure changes something the party can feel. First consumer: **route closure at thresholds**
  — the way home gets longer. Diegetic and spatial, never a clock (vision.md non-negotiable 3).
- AC: it **never degrades sign quality**. Taxing the Observe verb is the one thing this design may
  not do.
- AC: **R334 and R335 ship together.** R334 alone is the same lie with a bigger number — the entry
  would say "probing has a price" while the tree still says otherwise (A3).

---

## Phase 3 — scarcity binds at every party size (author is open; needs numbers)

### R336 — No party can ever read every channel

- AC: a **party-wide** bound on *reading instruments only* (lenses and probe kits), set **strictly
  below the channel count**. The bag stays per-Seeker at `BAG_SLOTS = 4` for everything else.
- AC: the **inequality is the design**; the number is the author's. It auto-scales when channels are
  added.
- AC: it is a **lending bound, not a currency** (TD-091) — the Collegium's reliquary lends
  instruments against a writ. The Quartermaster becomes a gatekeeper with a reason to say no.
- **Why the bag alone cannot do this:** `BAG_SLOTS` is per-Seeker and therefore linear in party size.
  The reading catalog is permanently bounded at six channels and four stimuli, so a trio's 12 slots
  hold all ten instruments. Blindness must be guaranteed; its *location* is the party's choice.
- **This reverses the cost TD-091 explicitly accepted.** Note it in the entry that ships it.

### R337 — Solo does not become the most complete configuration

- AC: **ships with R336, never after.** Under a party bound, solo would otherwise be the only
  configuration that reads every channel — inverting Pillar 4.
- AC: solo keeps its free channel read (TD-008) but receives a **smaller instrument allowance**, so
  solo reads broadest and tests shallowest.
- AC: the honest limit is recorded — while solo reads free, solo remains the most informationally
  complete configuration. Changing that is canon surgery (TD-008) and the author's call.

---

## Correctness Properties

- **P150 (a law, not an answer):** `ward !== frailty` shrinks the search space; it never reveals the
  Ward. A player who knows the law still has to read the Stress-mark.
- **P151 (determinism survives every roll change):** same seed → same trait roll, same axis set, same
  contract (I3). Rejection sampling and seeded selection are part of the stream, not post-hoc edits.
- **P152 (preparation is gated on preparation):** the party cannot enter the field without every
  connected member declaring ready. Ghosts never block (TD-032).
- **P153 (no procedure yields certainty for free):** any path that resolves an axis without inference
  must be impossible or expensive. Enumerating four stimuli is the known instance.

## Verification

- **V1 (R326, P150/P151):** `generateTraitRoll.test.ts` — over many seeds `ward !== frailty` always;
  every `WardValue` still occurs; the same seed reproduces the same roll exactly.
- **V2 (R327, P152):** `deploy.test.ts` — deployment is refused while a connected player is unready
  and nothing mutates; a ghost does not block; a fully ready party deploys.
- **V3 (R328):** `deploy.test.ts` — a duo with one dropped player does not take the solo path.
- **V4 (R329):** `git diff` touches `src/server/` and `specs/` only; server + shared suites green.

---

## Open questions for the author

Phase 0 needs none. These gate Phase 3 and parts of Phase 1:

1. **The instrument allowance number.** The inequality (`< |CHANNELS|`) is the design; 5 of 6 is the
   proposal.
2. **Solo's allowance**, and whether TD-008's free read survives at all.
3. **Exposure's first consumer** — route closure now, or wait for combat?
4. **Tier axis counts** under R330 (proposed 3 / 4 / 5–6) and how strong the Origin prior may be.
