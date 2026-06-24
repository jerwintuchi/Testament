# System — Linked Fates (Revive)

> **Status:** Canon
> **Sources:** GLOSSARY.md (Linked Fates); DESIGN.md (Supporting Mechanics); DECISION_LOG.md (linked-fates-ui, board-logic entries)
> **See also:** [systems/circulatory-board.md](circulatory-board.md) · [systems/combat.md](combat.md)

## What it is

The revive mechanic. Reviving a downed teammate **costs the reviver one relic** from their board slots, which transfers into the downed player's slot. Death reshapes the party build mid-fight.

> Every revive is a strategic trade-off.

## Rules

- A downed player has `downed: true` and `hp: 0` in their `PlayerState`.
- Revive is only legal during the **combat** phase (phase guard).
- The reviver's identity is forced to the **authenticated socket** (never trusted from the payload — invariant I2).
- On success: the source relic is removed from the reviver's slot and placed into the downed player's slot; the revived player is restored with a *new* `PlayerState` object (`{ ...ps, hp: maxHp, downed: false }`, immutability convention).

## Event ordering

`reviveWithLinkedFates` returns its two events as an ordered tuple type `[RELIC_REMOVED, RELIC_PLACED]`, making the required emit order impossible to violate at compile time, not just at test time.

## Client flow

Two-step revive UI (see [ui-style-guide.md](../ui-style-guide.md)): the revive panel appears for teammates on `PLAYER_DOWNED`; the reviver selects a source relic, then the downed player's empty slot; the server validates and emits. `LINKED_FATES_ERROR` surfaces inline. Slots are highlighted via `data-revive-source` / `data-revive-target`.

## Cross-floor note

A downed player who is not revived carries over downed into the next floor's combat phase and must be revived there. Intended design: players should revive (costing a relic) before descending, or accept the risk.
