# Design — The Sign Lexicon (TD-093)

> Satisfies R339–R345. Properties P154–P157.
> **Blocked on four author rulings** (`requirements.md`). The migration below is costed from the tree,
> not estimated.

---

## Where the code is

| what | where |
|---|---|
| the table | `src/server/src/incarnate/lexicon.ts` — `SIGN_LEXICON`, 24 entries |
| ambient derivation | `src/server/src/incarnate/deriveSigns.ts` (finds by `axis` + `value`) |
| probe derivation | `src/server/src/incarnate/deriveReaction.ts` (exact ward match, else `NO_REACTION_SIGN`) |
| the wire type | `src/shared/src/signs.ts` — `SignToken = string`, `Sign = {channel, token}` |
| durable probe record | `src/server/src/rooms/types.ts` — `revealedSigns: Sign[]`, deduped by token |
| the raw prints | `client/scripts/main.gd` **:754** (probe result) and **:1183** (the sign list) |

`deriveSigns` and `deriveReaction` look entries up by `(axis, value)` and read `.token` off the
result — **neither hard-codes a token**. So the table is the only place tokens are authored, and
retokenising is a one-file change plus its assertions.

---

## The shape of the change

### 1 · The table

24 entries re-authored per `requirements.md`: **17 changed, 7 kept**. Nothing structural moves —
`LexiconEntry` keeps `{axis, value, channel, token}`.

### 2 · A lookup helper, so this never costs this much again

```ts
export function tokenFor(axis: TraitAxis, value: string): SignToken
```

Tests then assert `tokenFor('FRAILTY','FLAME')` instead of pinning `'flinch-from-flame'`. **This is
most of the mechanical work and all of the future saving**: after it, the only literals in the tree
are the lexicon and its own pinning test, and the next re-authoring is one file.

Not a violation of I4 — it lives in `src/server/`, beside the table it reads.

### 3 · P154 as a test, not a convention

```
for each entry:
  reject if token contains, case-insensitively:
    - any value of its own axis
    - any Stimulus literal (FLAME | COLD | SALT | LIGHT)
  reject duplicate tokens
  reject a missing or repeated (axis, value) pair
```

**This fails 11 of 24 entries today.** Write it first and watch it fail — that is the proof the
diagnosis is mechanical rather than aesthetic. `no-reaction` is exempt: it is not an axis value.

### 4 · The prose layer *(pending ruling 2)*

New `client/scripts/field/sign_prose.gd` — a preloaded `RefCounted` with a static table (canon S3.2;
never a global `class_name`, so `--headless` resolves it). Both raw prints are replaced.

```
main.gd:754   "%s presented %s: [%s] %s"  →  SignProse.note(sign)  (a field note, in hand)
main.gd:1183  "[%s]  %s"                  →  SignProse.note(sign)
```

Prose renders in the **writ idiom the client already speaks** (`writ_form.gd`, `Widgets`), not as a
log line — a log line is consumed as a label however carefully it is worded, which is half of why the
current output reads as a readout.

**Not codegen'd.** Codegen carries the contract; prose is presentation and changes under it.

### 5 · The honest wire assertion

`expect(json).not.toContain('"FLAME"')` → case-insensitive, unquoted, over every trait-value literal.
Applies wherever the containment tests live (`deploy.test.ts`, `probe.test.ts`,
`field.integration.test.ts`).

---

## Migration cost — counted, not estimated

`grep` over `src/**/src` and `client/` for the 24 tokens (build output under `dist/` excluded):

| file | pin sites |
|---|---:|
| `src/server/src/incarnate/lexicon.ts` *(the table itself)* | 20 |
| `src/server/src/rooms/snapshot.test.ts` | 5 |
| `src/server/src/rooms/perception.test.ts` | 5 |
| `src/server/src/rooms/handlers/probe.test.ts` | 4 |
| **`src/shared/src/signs.test.ts`** | 3 |
| `src/server/src/rooms/handlers/reconnect.test.ts` | 3 |
| `src/server/src/rooms/field.integration.test.ts` | 2 |
| `src/server/src/incarnate/deriveReaction.test.ts` | 2 |
| **`src/shared/src/fieldMessages.test.ts`** | 1 |

**8 test files, ~25 assertion sites.** Note two are in **`src/shared`**, which the design review
missed — and `deploy.test.ts` pins no token at all, so it was listed in error there. Docs citing
tokens: `docs/systems/sign-language.md`, `specs/incarnate-signs/design.md`, and
`specs/probe-handler/{design,requirements,tasks}.md` — **5 files**.

**No wire change.** `SignToken` is `string`; `CHANNELS`, `STIMULI` and `GEAR_CATALOG` are untouched;
no protocol regeneration.

**No Contract Board capture diff.** The board renders no signs, so the standing clean-tree diff ritual
does not apply here. Captures needed: the field screen and the probe log.

**Docs discipline.** `specs/incarnate-signs/` is **closed** — mark its token table superseded *in
place* with what replaced it (`spec-workflow.md`); do not rewrite it. `DECISION_LOG.md` is
append-only and correctly keeps the old tokens in TD-025 / TD-092 / TD-093.

---

## Ship order

**Two commits.**

1. **Server + shared + docs** — table, `tokenFor`, P154 test, detokenised assertions, honest wire
   assertion, superseded-in-place doc marks. Provable by suites alone.
2. **Client prose** — `sign_prose.gd`, both print sites, P155 check. Capture-verified.

**One coupling that must not be broken:** if ruling 1 takes the WARD *collapse* instead of the
reword, it **must** ship in the same commit as a durable probe record (a REACTION entry carrying the
stimulus, or a `probeLog`). `revealedSigns` dedupes by token, so with one shared token a reconnecting
player loses which ward matched — a silent regression on the one axis that costs exposure to learn.

---

## Performance budget (canon)

Nil by construction. The lexicon is a module-level constant; `tokenFor` is a lookup over 24 entries at
sign-derivation time (once per contract, per axis — never per tick). The prose table is static and
read on render. **No new particles, no additive layer, nothing in `_process`.**

## Correctness Properties

- **P154** a sign is an observation, not a conclusion — enforced by test; fails 11 of 24 today.
- **P155** no client string names an axis or trait value.
- **P156** the wire assertion is case-insensitive and unquoted.
- **P157** a reconnecting player still knows which ward matched — the constraint that forbids
  collapsing WARD without a durable probe record.

## Files

**Commit 1:** `src/server/src/incarnate/lexicon.ts` (+ `lexicon.test.ts`), the 8 test files above,
5 docs. **Commit 2:** `client/scripts/field/sign_prose.gd` (new), `client/scripts/main.gd`.
