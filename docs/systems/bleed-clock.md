# System — Bleed Clock

> **Status:** Canon
> **Sources:** GLOSSARY.md (Bleed Clock); DESIGN.md (Supporting Mechanics); SYSTEM DESIGN DOC.md §2.2; DECISION_LOG.md (2026-06-22 stage escalation)
> **See also:** [systems/extraction.md](extraction.md) · [cosmology.md](../cosmology.md) · [content/biomes.md](../content/biomes.md)

## What it is

The dungeon's **global HP bar**. It drains in real time; the drain rate multiplies with floor depth. Hitting zero ends the run. Creates the "extract or descend?" group tension — FTL-style dread, but shared and vocal.

In fiction it represents the **interpretive instability of reality** (see [cosmology.md](../cosmology.md)).

## Behavior

- Starts full (`DUNGEON_START_HP = 1000`, placeholder tuning).
- Drains over time; deeper floors drain faster (depth multiplies the base rate).
- Implemented server-side as a pure tick `tickBleedClock(clock, dt)`; clamped at `>= 0`; broadcast to clients as the `BLEED_CLOCK_TICK` delta (never a full state push).
- On descent, the drain rate rises but the **current value is preserved** — tension carries over.
- Depletion ends the run (wipe); an already-ended room is never re-ended ("terminal once").

## Stage escalation

`bleedStageOf(current, max)` returns a stage by percent bled:

| Stage | % bled | Effect |
|------:|--------|--------|
| 0 | 0–30% | normal |
| 1 | 30–60% | enemies attack 30% faster (`AGGRESSION_COOLDOWN_MULT = 0.7`) |
| 2 | 60–80% | drain bonus ×1.5 |
| 3 | 80–100% | drain bonus ×2.0 |

- Stage is computed before/after each tick in `runBleedTick` (no Room schema field).
- Aggression applies as a cooldown multiplier on enemy attack reset; drain bonus is separate from floor scaling (stages activate *within* a floor as the clock depletes; depth multiplies the base rate).
- `BLEED_CLOCK_TICK` carries the current `stage`; a `BLEED_STAGE_CHANGED` delta fires on escalation (client plays a `bleedWarning` sound).

> Original paper design (SYSTEM §2.2) framed stages as: 30–60% aggression, 60–80% room modifiers, 80–100% forced-extraction pressure. The implemented stages above are the realized version; "room modifiers" remain a future option.

## Voluntary extraction

Players may extract voluntarily at any loot phase — the strategic counterweight to the clock. See [systems/extraction.md](extraction.md).
