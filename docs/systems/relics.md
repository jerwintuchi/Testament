# System — Relics

> **Status:** Canon
> **Sources:** GLOSSARY.md (Relic); SYSTEM DESIGN DOC.md §2.4; LORE_DESIGN.md §8
> **See also:** [content/relic-roster.md](../content/relic-roster.md) (the concrete list) · [systems/circulatory-board.md](circulatory-board.md) · [doctrines.md](../doctrines.md)

This file is the relic *system*. The concrete relics live in [content/relic-roster.md](../content/relic-roster.md).

## Definition

A **Relic** is an item placed on the Circulatory Board. It has:

- a **base effect** (always active),
- a **synergy effect** (fires only when adjacency conditions are met — see [circulatory-board.md](circulatory-board.md)),
- one or more **tags** (e.g. `fire`, `aoe`, `party`, `poison`, plus doctrine tags `sanctum` / `tumor` / `chorus` / `penitent`).

In design terms relics are **modular rule modifiers applied to board slots**. In fiction they are **arguments about how reality works** (see [doctrines.md](../doctrines.md)).

## Relic types (paper design)

- Passive
- Conditional
- Synergy-triggered

## Slot rules

- 1 relic = 1 board node.
- Adjacency modifies effect.
- Cross-player adjacency = amplified (synergy) effect.

## Combat effects (implemented)

Relic effects resolve in combat via pure functions `evaluateRelicHit` / `evaluateIncomingDamage`. Examples currently wired:

- **ember-core** — bonus damage + splash.
- **torch-brand** — applies fire DoT (`fireDurations` per enemy).
- **arc-bolt** — chain lightning to nearby enemies.
- **iron-skin** — incoming damage reduction.

These emit `ENEMY_DAMAGED` deltas for splash, chain, and fire-DoT hits. See [systems/combat.md](combat.md).

## Loot

Per-floor loot pools offer `min(3, unplaced)` relic IDs via a seeded Fisher-Yates shuffle (deterministic per `runId#floor#loot`). A relic must be in the current loot pool to be placed. See [systems/extraction.md](extraction.md) for the run loop and [technical/determinism-and-rng.md](../technical/determinism-and-rng.md) for seeding.
