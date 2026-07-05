# Encounter Flow

**Status:** Drafted. Defines the moment-to-moment cadence of an expedition. Establishes how investigation, combat, objectives, rituals, and extraction interleave throughout a hunt.
**Spine:** Observe → Hypothesize → Test → Record
**Index:** [../README.md](../README.md)
**See also:** [gameplay.md](../gameplay.md) · [combat.md](./combat.md) · [investigation-and-probing.md](./investigation-and-probing.md) · [contracts.md](./contracts.md) · [pressure-and-extraction.md](./pressure-and-extraction.md) · [loadout-economy.md](./loadout-economy.md) · [distributed-perception.md](./distributed-perception.md)

---

# Purpose

This document governs the rhythm of an expedition after deployment. It answers **how the party spends each minute of a hunt**, not just the overall expedition loop.

Testament is neither an investigation game interrupted by combat nor a combat game interrupted by investigation. Every system continuously reinforces the spine.

Observation continues during combat.

Combat continues during rituals.

Objectives continue the investigation.

The expedition never leaves the Observe → Hypothesize → Test → Record loop until extraction.

---

# Design Philosophy

## The investigation never ends

Investigation is not a discrete phase completed before engaging the Incarnate.

Instead, every stage of the expedition contributes evidence.

Initial exploration establishes a working theory.

Combat reveals hidden behaviors.

Objectives expose new observations.

Rituals confirm or overturn previous assumptions.

Extraction records the final interpretation.

The party is always reading.

The Incarnate is always revealing.

---

## Combat is another form of investigation

Combat is the highest-risk probe.

Some evidence intentionally cannot be discovered safely through passive observation alone.

Examples include:

- Stress-marks revealed only after particular wounds.
- Hidden Wards exposed through incorrect counters.
- Disposition changes when pressured.
- Omens only visible immediately before lethal attacks.
- Reactions that only occur after ritual interference.

Combat therefore continues the diagnosis rather than replacing it.

Understanding should increase throughout an encounter instead of concluding beforehand.

---

## The party chooses when evidence is sufficient

The game never declares that an investigation is complete.

Instead, players decide when they possess enough evidence to commit.

Examples:

- "We know enough. Begin the capture."
- "We're still missing the Rite-key."
- "The contract intel was wrong."
- "Commit before pressure gets worse."

Choosing to commit early carries risk.

Waiting too long increases field pressure.

This uncertainty is intentional and is one of Testament's primary sources of tension.

---

## Objectives are part of the hunt

Secondary objectives must never exist beside the Incarnate.

Every objective should either:

- produce additional evidence,
- alter the battlefield,
- introduce new pressure,
- or force a meaningful tradeoff.

Examples include:

- rescuing surviving witnesses,
- protecting clergy performing rites,
- recovering sacred relics before corruption spreads,
- escorting penitents through dangerous territory,
- defending ritual circles,
- preventing an Incarnate from consuming an objective.

Objectives exist to deepen the encounter, never distract from it.

---

## Rituals are active encounters

Capture, banishment, purification, and exorcism are encounters, not cutscenes.

Beginning a ritual should increase danger rather than pause it.

The Incarnate actively resists throughout the process.

Examples include:

- breaking ritual seals,
- corrupting holy symbols,
- interrupting chants,
- attacking ritualists,
- forcing repositioning,
- changing Disposition during the rite.

The ritual itself becomes another stage of combat.

---

## Rituals continue the investigation

A ritual is not merely execution.

It is another experiment.

Failure or success reveals additional information.

Examples include:

- rejected relics,
- unstable bindings,
- broken verses,
- corrupted seals,
- unexpected reactions to sacred objects.

These outcomes may confirm or refute the party's working theory.

The ritual is therefore both a resolution and a final test.

---

## Concurrency scales with party size

Party size changes tempo, not mechanics.

Every expedition should be fully playable by one, two, three, or four Seekers without removing systems.

A larger party solves simultaneous problems.

A smaller party solves the same problems sequentially.

Examples:

Four Seekers:

- one maintains the rite,
- one protects,
- one manipulates relics,
- one continues reading signs.

Solo:

- begin the rite,
- interrupt to defend,
- return to maintain the rite,
- reposition,
- continue the ritual.

The mechanics remain identical.

Only the player's available attention changes.

This principle applies to every gameplay system, including:

- investigation,
- combat,
- objectives,
- rituals,
- extraction,
- environmental hazards.

Solo relaxes concurrency.

It never lacks mechanics.

---

# Example Encounter

Preparation

↓

Working theory

↓

Deploy

↓

Passive observations

↓

Initial hypothesis

↓

First contact

↓

Combat

↓

New signs revealed

↓

Theory updated

↓

Objective begins

↓

Mid-fight investigation

↓

Rite-key confirmed

↓

Capture / Banishment / Exorcism

↓

Final observations

↓

Extraction

↓

Field Testament

Observe → Hypothesize → Test → Record remains active throughout the encounter instead of occurring as isolated phases.

---

# Non-negotiable Rules

- Investigation never truly ends until extraction.
- Combat is another method of gathering evidence.
- Rituals never replace gameplay with passive channeling.
- Secondary objectives must strengthen the central hunt.
- Players decide when evidence is sufficient to commit.
- Concurrency scales with party size; mechanics do not.
- Solo relaxes tempo and attention, never removes systems.
- Every encounter should continuously exercise the spine.

---

# Implementation Notes

Combat systems should expose additional signs through gameplay events instead of only through exploration.

Objectives should be authored as encounter modules capable of being inserted during active combat without interrupting the expedition flow.

Ritual systems should be modular rather than monolithic, allowing multiple independent actions to progress simultaneously for larger parties while remaining sequentially completable by solo players.

Pressure should evolve the encounter rather than merely increasing enemy aggression. Rising pressure may alter available evidence, environmental conditions, escape routes, or ritual stability.

The encounter controller should treat investigation, combat, objectives, and rituals as overlapping states rather than mutually exclusive phases.

---

# Future Expansion

- Encounter module library (rescues, escorts, relic recoveries, collapsing sanctuaries, rival Choir interventions).
- Dynamic ritual events that force adaptation mid-encounter.
- Environmental events that alter or erase evidence over time.
- Multi-stage Incarnates whose evolving behavior continues revealing information throughout prolonged encounters.
- Additional objective archetypes designed around diagnosis rather than combat alone.
