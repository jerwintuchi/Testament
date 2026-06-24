# System — Solo Play

> **Status:** Canon
> **Sources:** DESIGN.md (Solo Play); specs/solo-play/ (requirements.md, design.md); SYSTEM DESIGN DOC.md §8.4 (the tension this resolves); DECISION_LOG.md (2026-06-24 entries)
> **See also:** [systems/circulatory-board.md](circulatory-board.md) · [pitch.md](../pitch.md)

## Why solo needs special handling

Veins is designed as forced co-op: synergy fires only between relics owned by **different** players. In a 1-player run every cell is owned by the lone player, so no synergy could ever fire and the core build mechanic would be dead.

> **Resolved design tension:** the original paper design (SYSTEM §8.4) stated "co-op is structural; solo is degraded by design." The 2026-06-24 decision makes solo a **first-class, playable secondary mode** by relaxing the ownership rule for solo runs only. Co-op remains the intended/headline experience.

## The rule

On a **single-owner board** (a solo run), the different-owner requirement is relaxed: adjacent same-tag relics synergize regardless of owner. The tag-overlap requirement still applies. Co-op boards (≥2 owners) are unchanged.

## How it's detected (pure, board-derived)

`evaluateSynergies` derives solo-ness from the board itself:

```
owners   = distinct set of slot.ownerId across all 19 slots
soloBoard = owners.size <= 1
if (!soloBoard && neighbor.ownerId === slot.ownerId) continue;  // skip own-relic only in co-op
```

This is exact: `buildInitialBoard` assigns every cell an owner, so the distinct-owner count equals party size. No flag is threaded through the six call sites; no player-count parameter — the function stays pure (invariants I4/I5).

## Starting solo

`MIN_PLAYERS_TO_START = 1` (in `@veins/shared`) — the single source both the server gate (`RoomManager.startRun`) and the client lobby (`WaitingRoom`) read. The `DEV_MIN_PLAYERS` env override can now be set *higher* (e.g. 2) to force co-op-only behaviour for testing.

## Edge case — player leaves mid-run

Slot ownership is fixed at `startRun`. A 2-player run that drops to 1 connected player keeps its 2-owner board, so it retains co-op synergy rules. Solo relaxation applies only to runs *started* solo. Intended.

## Pitch conflict (flagged for product)

The tagline "a roguelike you literally cannot beat by yourself" still sits on the lobby. Co-op is the headline; solo is a relaxed secondary mode. The literal lobby wording is left as-is pending a product call. See [pitch.md](../pitch.md).
