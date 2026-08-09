# Sign Language

> **Status:** Drafted. Builds on the trait schema in [incarnates.md](incarnates.md) (TD-015).
> **Spine:** Observe → Hypothesize → Test → Record  ·  **Index:** [../README.md](../README.md)
> **See also:** [distributed-perception.md](distributed-perception.md) · [investigation-and-probing.md](investigation-and-probing.md) · [../lore/bestiary-fiction.md](../lore/bestiary-fiction.md)

## Purpose

How a hidden Incarnate trait becomes an observable **sign** the party can read, while
the underlying trait never leaves the server. This is the mechanism that makes
"interpretation, not memorization" (Pillar 3) a property of the code, not a hope.

## Design Philosophy

### The language is a fixed map, the carrier is not

Every trait axis emits one sign in one **perception channel**:

| Axis | Channel | A sign looks like |
|------|---------|-------------------|
| Aspect | **Residue** | run wax, heaved mortar, bloomed iron on the stone |
| Frailty | **Stress-mark** | what the wound gives up when it is opened |
| Ward | **Reaction** | how it answers a probe (see [investigation-and-probing.md](investigation-and-probing.md)) |
| Disposition | **Spoor** | tracks, spacing, the cadence of its movement |
| Rite-key | **Liturgy** | sigils, resonance, the shape of its devotions |
| Tell | **Omen** | the wind-up, the held breath before the lethal blow |

The **map from a trait value to its sign is fixed game-truth**: a wound that beads a
fatty film always means the same thing, every expedition, for every player. What changes
is *which Incarnate carries it*, because the trait roll is re-rolled (TD-015). So players
never memorize monsters; they learn a **vocabulary**, and that vocabulary is genuine,
transferable skill (Pillar 2). A Seeker is a doctor: learn the language of symptoms,
diagnose each new patient.

### A sign names the observation, never the conclusion (TD-093)

The first table shipped tokens like `flinch-from-flame` and `drinks-salt`. Those are not
signs — they are **labels**. The token performed the inferential step for the player, so
there was no vocabulary to acquire and Pillar 3 was, for two of six axes, unimplemented.
Measured rather than argued: the rule below failed **11 of 24 entries**.

> **The rule (P154, enforced by `lexicon.test.ts`):** no token may contain, case-
> insensitively, a value of its own axis, nor any `Stimulus` literal.

Two constraints keep the fix from over-correcting:

- **One inferential step, recoverable by reasoning about the world.** A token needing no
  step is a label; a token needing an unrecoverable step (`mark-VII`) is memorization of
  noise, which is Pillar 2's worst reading. `spalled-stone` was rejected for this reason —
  *spalling* is masonry jargon, recoverable only by domain knowledge. **The same test
  retires any future token that leans on a technical term.**
- **The interpretation budget follows the clock.** How much inference a channel may demand
  is bounded by how long the player has to do it:

  | Read during | Channels | Budget |
  |---|---|---|
  | Approach — minutes, the party talking | Residue, Spoor, Liturgy | one to two steps, forensic |
  | Mid-encounter — seconds | Stress-mark, Reaction | exactly one, and material rather than liturgical |
  | The wind-up — milliseconds | Omen | **zero. Transparent by design.** |

  So the **Omen set is deliberately near-synonymous with its trait** (`full-body-tremor` for
  SHUDDER) and must not be "fixed": TD-013 makes the Tell the *survival* payoff, read while
  something is about to kill you, and a player cannot deduce during a wind-up.

### The Stress-mark set is a law, not four strings

> **A wound names the substance; the substance names the remedy.**

Tallow takes a flame; spent heat wants cold; water held in a shape is drawn out by salt; a
thing made of dark is undone by light. A player who learns the **sentence** derives all
four tokens — and the fifth when it ships. **This is the model for how the lexicon grows:**
author new values so the law still predicts them. A law of the world is the intended
progression (Pillar 2); the entity's value never is.

### Reaction is a confirmation channel, and its tokens are flavour

The party supplies the hypothesis by *choosing the stimulus*, which `PROBE_RESULT` echoes
back. No wording can make those four tokens informative, so they are labelled honestly as
flavour: they name the **instrument presented** (brand, rime, grain, lamp), never the
element. They are nonetheless kept **per-element rather than collapsed** to one token,
because `revealedSigns` dedupes by token and is what a reconnecting player's snapshot
restores — one shared token would silently lose *which* ward matched (P157).

`no-reaction` is unchanged and deliberately ambiguous: ward-less or wrong stimulus,
indistinguishable (R55/R56).

### The token is a wire identifier; the prose lives on the client

A token is a **contract**; prose is **presentation**. The raw token is never rendered to a
player — `client/scripts/field/sign_prose.gd` holds an authored observation for each one,
written as a field note in the Seeker's own hand. This is what makes *Origin as dialect*
(below) possible at all: a presentation modifier cannot be applied to a token if the token
**is** the string the player reads.

A prose table on an untrusted client leaks nothing — the sign→meaning map is public
game-truth by canon, and the trait roll still never crosses the wire (I5). Two rules hold
it in place, both checked by `tools/lexicon_check.py`:

- **P155** — no string in the prose table names an axis or a trait value. Committing the
  sin on the client is committing it.
- **Coverage** — every token has prose, and the prose invents no token. The fallback is
  deliberately *not* the raw token, so a missing entry would otherwise ship silently.

### The Librarium may never hold a translation table — NON-NEGOTIABLE

*(Author ruling, TD-093.)* A room that prints `tallow-sweat = frail to flame` hands over
the exact inferential step this whole system exists to create — the direct heir of the
"no doctrine meter" rule (vision.md, "no knowledge as a number"). The Librarium **may**
hold laws (the wound/substance sentence above), case histories, and which instrument reads
which channel. **Nothing else.**

### Coarse and fine reads are deferred, not dropped

If sign fidelity is ever varied, a coarse read is a **different token naming a coarser
observation** ("something beads at the wound"), never the same token with a
confidence/clarity field. A confidence number is knowledge-as-a-number.

### Origin is the dialect

An Incarnate's **Origin** (Belief / Sin / Relic) colors *how* its signs present without
changing what they mean: a Sin-born's heat-residue reads as scorched penitence, a
Relic-born's as wax bled from a reliquary. Same meaning, different accent. This is where
the lore families become the texture of the reading (TD-015).

### Mutations bend the language

At higher tiers, a **mutation** can mask a sign (it is absent), invert it (it lies), or
add a phantom one. This is what turns a master-tier read into forensics: you can no
longer trust a sign at face value, and the falsifiable Origin (TD-015) may itself be the lie.

## Non-negotiable Rules

1. The trait roll **never crosses the wire**; only derived signs do (CLAUDE.md invariant 3, netcode I5).
2. A sign is **never a label or a percentage** (vision.md non-negotiable 2). "The wound beads a fatty film", never "weakness: fire 80%".
3. The map is **stable game-truth**: the same trait value always yields the same sign meaning. The language is consistent across all expeditions and players.
4. The language is **never persisted as an unlock** (TD-006). Mastery lives in the player's skill and the session Archive, not in the account.
5. **A token never names its own answer** (P154, TD-093), and the **raw token is never shown to a player** (P155). The observation is what ships; the conclusion is the player's.
6. **The Librarium never holds a translation table** (author ruling, TD-093). Laws, case histories, and which instrument reads which channel — nothing else.

## Implementation Notes

- **Data shape (server-only):** `Sign = { channel: Channel, token: SignToken, intensity?: number }`. `deriveSigns(incarnate): Sign[]` is a pure function over the trait roll; it is the only thing that reads traits and the only producer of signs.
- The **map is data** (a table from `{ axis, value }` to a `SignToken`), so the lexicon scales to hundreds of entries without code changes.
- **Origin dialect** is a presentation modifier applied to the token, not a change of meaning.
- **Mutation operators** (`mask`, `invert`, `add`) are applied after derivation, before broadcast.
- **Per-player filtering:** a player only receives signs for channels they perceive (see [distributed-perception.md](distributed-perception.md)); the server filters per recipient. This is new code; no prototype logic is reused.
- Tier (TD-014) gates which channels are active for a given Incarnate.

## Future Expansion

- The **sign lexicon catalog** (the full value-to-token table) as data in [../content/](../content/).
- **Origin dialects** authored per family.
- **Compound and ambiguous signs** at master tier, where one observation supports two readings.
