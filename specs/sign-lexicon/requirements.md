# Requirements — The Sign Lexicon (TD-093)

> **R339+**, **P154+**, **T349+**. Written to be picked up cold.
> **BLOCKED on four author rulings** (see the end). The table below is proposed, not settled.

---

## What a fresh session needs to know

**The defect, measured rather than asserted.** Apply the rule *"no token may contain,
case-insensitively, a value of its own axis or any `Stimulus` literal"* to the 24-entry
`SIGN_LEXICON` and **11 of 24 entries fail**:

```
FRAILTY  flinch-from-flame / -cold / -salt / -light     (4 — the whole set)
WARD     drinks-flame / -cold / -salt / -light          (4 — the whole set)
ASPECT   frost-rime, rot-bloom                          (2)
RITE_KEY flame-rune                                     (1)
```

And `client/scripts/main.gd` prints the **raw token** at two sites (`:754`, `:1183`), so a player
literally reads `[STRESS_MARK] flinch-from-flame`. There is no inferential step to perform.
`vision.md` calls interpretation "the soul, and the hardest part" of Testament; for two of six axes it
is not implemented.

**What is NOT the problem** — and getting this wrong would wreck the design:

- **The 1:1 stable mapping is canon and correct.** `vision.md`: "the same sign always means the same
  thing; which Incarnate carries it changes every expedition." Do **not** propose randomising the
  sign→meaning map. A lookup table is the intended end state for a veteran (Pillar 2). The flaw is that
  two-thirds of the table is *self-translating*, so there is no vocabulary to acquire.
- **The `TELL`/OMEN set is the file's best work and must not be "fixed"** — see R341.

---

## R339 — A token names the observation, never the conclusion

- AC: **no token contains, case-insensitively, any value of its own axis, nor any `Stimulus`
  literal.** This is P154 and it is a test, not a style note.
- AC: every token names *what the Seeker saw*; the player supplies what it means. The remedy is never
  in the observation.
- AC: **one inferential step, recoverable by reasoning about the world.** A token needing no step is a
  label (`flinch-from-flame`); a token needing an unrecoverable step (`mark-VII`) is memorization of
  noise, which is Pillar 2's worst reading.
- AC: each (axis, value) pair appears exactly once; every token is unique across the table.

## R340 — The FRAILTY set carries a law, not four strings

- AC: the four Stress-mark tokens are derivable from one sentence — *a wound names the substance; the
  substance names the remedy.* A player who learns it derives all four, and the fifth when it ships.
- AC: this is the model for how the lexicon grows. New values are authored so the law still predicts
  them (TD-092: a **law of the world** is the intended progression; the entity's value is not).

## R341 — The interpretation budget follows the clock

- AC: how much inference a channel demands is bounded by how long the player has to do it.

| Read during | Channels | Budget |
|---|---|---|
| Approach — minutes, the party talking | RESIDUE, SPOOR, LITURGY | one to two steps, forensic |
| Mid-encounter — seconds | STRESS_MARK, REACTION | exactly one, and **material** rather than liturgical |
| The wind-up — milliseconds | OMEN | **zero. Transparent by design.** |

- AC: **the four OMEN tokens are kept verbatim.** `full-body-tremor` being a near-synonym of SHUDDER
  is correct: TD-013 makes the Tell the *survival* payoff, read while something is about to kill you,
  and a player cannot deduce during a wind-up. Anyone "fixing" this has misread the design.

## R342 — WARD is reworded, not collapsed *(pending ruling 1)*

- AC: Reaction is a **confirmation** channel — the party supplies the hypothesis by choosing the
  stimulus (which `PROBE_RESULT` echoes) and the world answers yes or no. No wording makes those four
  tokens informative; they are flavour and are labelled honestly as such.
- AC: tokens name **the instrument the party presented** (brand / rime / grain / lamp), never the
  element enum, so P154 holds.
- AC: **they are not collapsed to a single token in this spec.** `revealedSigns` stores bare
  `{channel, token}` deduped by token, and that is what a reconnecting player's snapshot restores — so
  the per-element token is currently the *only* durable record of which ward matched. Collapsing would
  silently lose the ward on reconnect (register item A8, TD-092).
- AC: `no-reaction` is **unchanged**. A null result is deliberately ambiguous evidence — ward-less or
  wrong stimulus, indistinguishable (R55/R56).

## R343 — Prose lives on the client; the token is a wire identifier *(pending ruling 2)*

- AC: the token stays a terse, opaque, stable slug. **The raw token is never printed to a player
  again** — `main.gd:754` and `:1183` both render authored prose instead.
- AC: prose lives in a preloaded `RefCounted` with a static table (canon S3.2, never a global
  `class_name`).
- AC: prose renders as a **field note in the Seeker's own hand**, in the writ idiom the client already
  speaks — not a line in a scrolling log, which is consumed as a label however it is worded.
- AC (P155): **no client string names an axis or a trait value.** Committing the sin on the client is
  committing it.
- **Why this split:** a token is a contract, prose is presentation. `sign-language.md` already commits
  to Origin as "a presentation modifier applied to the token" — impossible if the token *is* the string
  the player reads. A prose table on an untrusted client leaks nothing: the sign→meaning map is public
  game-truth by canon, and the trait roll still never crosses the wire (I5).

## R344 — The wire assertion means what it says

- AC: the containment tests assert absence of every trait-value literal **case-insensitively and
  unquoted**.
- **The gap being closed:** `expect(json).not.toContain('"FLAME"')` passes today only because
  `flinch-from-flame` carries `flame` lowercase and unquoted. The letter of I5 held while the spirit
  did not, and that is why nobody noticed the table was self-translating.

## R345 (containment) — no wire change, and the board is not involved

- AC: `SignToken` stays `string`; no protocol or codegen change; the prose table is **not** codegen'd
  (codegen is for the contract).
- AC: **no Contract Board capture diff is required** — the board renders no signs. Captures needed are
  the field screen and the probe log only.
- AC: `specs/incarnate-signs/` is a **closed** spec; its token table is marked superseded **in place**,
  not rewritten (`spec-workflow.md`).

---

## The proposed table

**17 changed, 7 kept.** Kept entries are marked ▪.

### ASPECT → RESIDUE — *what the fabric of the place remembers*

| Value | Token | What is seen | The step |
|---|---|---|---|
| EMBER | `run-wax` | candles slumped and pooled that were never lit | something here burned without a fire |
| FROST | `heaved-mortar` | joints split and pushed proud | water froze inside the wall and split it |
| ROT | `bloomed-iron` | nails and hinges flowered with rust a century early | matter here ages out of season |
| MIRE | ▪ `weeping-clay` | the floor gives up water it should not hold | it drags the bog with it; footing fails where it stood |

### FRAILTY → STRESS_MARK — *what a wound gives up* (all four replaced)

| Value | Token | What is seen | The step |
|---|---|---|---|
| FLAME | `tallow-sweat` | the wound beads a fatty film that will not dry | fat takes a flame |
| COLD | `fever-sweat` | it runs hot; steams in still air | it spends heat to hold its shape |
| SALT | `clear-weep` | thin, colourless, will not close | water held in a shape; salt draws water |
| LIGHT | `shadow-bleed` | smokes dark; a lamp will not reach the bottom | it is made of the dark it lives in |

### WARD → REACTION — *what it does with what you offered* (flavour, honestly labelled)

| Value | Token | What is seen |
|---|---|---|
| FLAME | `swallowed-the-brand` | the flame lies down into it and does not return |
| COLD | `swallowed-the-rime` | the chill goes in; the air is warmer after |
| SALT | `swallowed-the-grain` | the salt darkens, damps, and is gone |
| LIGHT | `swallowed-the-lamp` | the lamp dims toward it and steadies wrong |
| *(miss)* | ▪ `no-reaction` | nothing — deliberately ambiguous (R55/R56) |

### DISPOSITION → SPOOR — *what the ground records*

| Value | Token | What is seen | The step |
|---|---|---|---|
| STALKER | `prints-in-our-prints` | its tread inside the party's own, going their way | it is behind you, and has been for some time |
| AMBUSHER | ▪ `still-spoor` | presence, with no track of travel | it does not come to you; it waits where it is |
| TERRITORIAL | `tracks-turn-back` | every trail reaches the same reach and reverses | it holds ground rather than hunting — you can leave |
| FRENZIED | `broken-stride` | no two strides alike; ran through what it could have rounded | it does not pace itself; it costs itself everything |

### RITE_KEY → LITURGY — *the shape of its devotion*

| Value | Token | What is seen | The step |
|---|---|---|---|
| PENANCE | `worn-knee-stone` | two ovals polished into the flags where it stops | it kneels, and often; it is owed contrition, not force |
| IMMOLATION | `ash-offering` | what it takes is heaped and burnt — arranged, not scattered | fire is its sacrament, so fire is what ends it |
| INTERMENT | `covered-dead` | nothing it kills is left uncovered | it buries; it wants burial |
| SILENCE | ▪ `voided-glyph` | inscriptions scratched out, names struck through | it cannot bear to be named |

### TELL → OMEN — *the wind-up* (all four kept verbatim, R341)

| Value | Token |
|---|---|
| LUNGE | ▪ `drawn-breath-and-lean` |
| SWEEP | ▪ `wide-shoulder-coil` |
| RECOIL | ▪ `backward-step-brace` |
| SHUDDER | ▪ `full-body-tremor` |

**EMBER settled (author, 2026-08-08): `run-wax`.** `spalled-stone` was rejected on the spec's own
criterion rather than on taste — *spalling* is masonry jargon, so its inferential step is recoverable
only by domain knowledge, not "by reasoning about the world" (R339). `run-wax` is plain sight plus
common sense, and sits in the Collegium's ecclesiastical register rather than a forensics manual.
**The same test retires any future token that leans on a technical term.**

**COLD is still open** — see the note under FRAILTY.

---

## Correctness Properties

- **P154 (a sign is an observation, not a conclusion):** no token contains, case-insensitively, a
  value of its own axis or a `Stimulus` literal. **Fails 11 of 24 today** — which is the mechanical
  proof that this is a defect rather than a matter of taste.
- **P155 (the client does not commit the sin either):** no string in the prose table names an axis or
  a trait value.
- **P156 (the wire assertion is honest):** trait-value literals are absent case-insensitively and
  unquoted, not merely unquoted-with-quotes.
- **P157 (reconnect keeps what was learned):** a player who reconnects still knows which ward matched.
  This is what forbids the WARD collapse without a durable probe record.

## Verification

- **V1 (R339–R342 / P154):** `lexicon.test.ts` — the no-self-naming rule, completeness, uniqueness.
- **V2 (R343 / P155):** capture the field screen and probe log; no raw token visible, no axis or trait
  value in any client string.
- **V3 (R344 / P156):** the containment tests fail if a token regains its answer.
- **V4 (R345 / P157):** server + shared suites green; a reconnect test still recovers the ward.

---

## Blocking rulings — **ALL ANSWERED 2026-08-09 (author), all as recommended**

1. **WARD form** — **REWORD** (R342). The four tokens name the instrument presented
   (`swallowed-the-brand / -rime / -grain / -lamp`), never the element, so P154 holds. They stay
   per-element rather than collapsing, so P157 holds with no durable probe record needed.
2. **Prose split** — **TERSE TOKEN + CLIENT PROSE** (R343). The token is an opaque wire identifier a
   player never sees; `sign_prose.gd` authors what they read. This is what Origin and site dialect
   depend on: a presentation modifier cannot be applied to a token that *is* the displayed string.
3. **The Librarium** — **YES, NON-NEGOTIABLE.** A room printing `tallow-sweat = frail to flame`
   hands over the exact step this spec creates. It may hold laws, case histories, and which
   instrument reads which channel; **nothing else.** Recorded in `sign-language.md`'s
   non-negotiable rules, beside "no knowledge as a number".
4. **Coarse/fine ambiguity** — **DEFERRED, NOT DROPPED.** If built it must be a *different token*
   naming a coarser observation ("something beads at the wound"), never the same token with a
   confidence or clarity field — that is knowledge-as-a-number.

### Decided while building, on the spec's own criteria

- **COLD is `fever-sweat`**, not `will-not-clot`. R340 requires all four Stress-marks to follow one
  law — *a wound names the substance; the substance names the remedy*. `will-not-clot` names no
  substance, so it breaks the law it exists to obey. Same test that retired `spalled-stone`.
- **`src/shared`'s four pin sites are NOT routed through `tokenFor`** — shared cannot import the
  server without inverting the trust boundary (S1/I4). They were type-shape fixtures, not lexicon
  assertions, and now use a synthetic `'a-sign-token'`.

## Not in this spec, but named because it comes first

**The Field Testament at extraction is the real teacher** — the answer key delivered *after* the bet
is settled, which is Record closing the loop. It is currently a stub (`buildStubTestament` hard-codes
`outcome: 'success'`). Without it a failed hunt teaches nothing, and any Librarium becomes a crutch
for a missing loop. **Build the Testament reveal before the Librarium.**
