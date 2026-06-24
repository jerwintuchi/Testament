# System — Extraction & Failure

> **Status:** Canon
> **Sources:** SYSTEM DESIGN DOC.md §7 (Extract/Failure); DESIGN.md (extraction tension); DECISION_LOG.md (descend/extract handlers, floor progression)
> **See also:** [systems/bleed-clock.md](bleed-clock.md) · [progression.md](../progression.md) · [systems/circulatory-board.md](circulatory-board.md)

## The run loop tension

Every floor is a group negotiation: **extract now or push one more floor?** Loot scales with depth; the Bleed Clock drains faster the deeper you go. Extraction is the strategic counterweight to the clock.

## Extraction types

- **Normal extraction** — successful run, voluntary, during a loot phase.
- **Forced extraction** — Bleed Clock maxed.
- **Sacrificial extraction** — one player left behind.
- **Total wipe** — failure.

## Fail condition

At Bleed Clock 100%: the dungeon collapses → forced wipe OR an emergency extraction event. See [systems/bleed-clock.md](bleed-clock.md).

## Implemented flow

- **Loot phase only:** `descend` and `extract` handlers are valid during the loot phase; a phase guard rejects `descend` during combat (`WRONG_PHASE`).
- **Descend** (`descendFloor`): reuses pure `advanceFloor` for carry-over (board by reference, Bleed Clock `current` preserved, drain rate up), generates the new floor's dungeon (seed `runId#floor`), spawns enemies, and enters the combat phase. Broadcasts `FLOOR_ADVANCED`. If a floor spawns zero enemies, it goes straight to loot.
- **Extract** (`extractRun`): ends the run with an `EXTRACTED` outcome.
- **Outcome** is `RunOutcome | null` on Room; the run ends via `RUN_ENDED` (carries final floor + `enemiesKilled`).
- Client `DescendPanel` disables buttons on click to prevent double-tap; re-enables on `FLOOR_ADVANCED` / `RUN_ENDED` / `LOBBY_ERROR`.

## Rewards

Run-end rewards depend on depth reached, doctrine alignment strength, and boss outcome. See [progression.md](../progression.md).
