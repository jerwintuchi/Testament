# System — Doctrine Tracking (Hidden Scoring)

> **Status:** Canon
> **Sources:** SYSTEM DESIGN DOC.md §2.3; DECISION_LOG.md (2026-06-22 doctrine tracking system, R8–R11)
> **See also:** [doctrines.md](../doctrines.md) (concept) · [factions.md](../factions.md) (the four personified) · [cosmology.md](../cosmology.md)

This is the *implementation* of doctrine. For the concept see [doctrines.md](../doctrines.md); for the four as factions see [factions.md](../factions.md).

## The four hidden scores

Each run tracks four hidden integer values on Room state:

- **Sanctum** (stability)
- **Tumor** (mutation volatility)
- **Chorus** (sync strength)
- **Penitent** (sacrifice tendency)

> The system does NOT show these values. Only effects are visible. (No score is ever sent to the client.)

## Influence sources

Scoring hooks into **existing events only** — no new event is needed for scoring itself:

| Action / event | Effect |
|----------------|--------|
| stable adjacency usage (`RELIC_PLACED`) | Sanctum + |
| mutation relic usage | Tumor + |
| coordinated timing / kills (`ENEMY_DIED`) | Chorus + |
| sacrificing relics (`RELIC_REMOVED` via Linked Fates) | Penitent + |
| extract / wipe outcome | resolves alignment strength |

## Threshold effects (R8–R11)

All expressible as server-side number changes — no art/animation required:

- **Sanctum** threshold → drain-rate multiplier reduction.
- **Tumor** threshold → enemy attack-speed multiplier.
- **Chorus** threshold → ward protection doubling.
- **Penitent** threshold → free-revive flag.

## BOARD_DOCTRINE_SHIFT event

When a threshold is crossed, the server emits `BOARD_DOCTRINE_SHIFT` — a **flavor-text toast only**. The doctrine name is intentionally omitted from the payload (preserving "no explicit doctrine UI"; see [ui-style-guide.md](../ui-style-guide.md)).

## Tagging

Doctrine tags (`sanctum`, `tumor`, `chorus`, `penitent`) are part of the `RelicTag` union and applied to the 10 existing relics; `void-lens` is intentionally left neutral (no doctrine tag).

## Decay (future option, not in v1)

Scores do not decay in v1. A documented future balance option is to multiply each score by 0.85 on floor descent.
