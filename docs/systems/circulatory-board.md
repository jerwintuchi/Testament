# System — Circulatory Board

> **Status:** Canon
> **Sources:** GLOSSARY.md (Circulatory Board, Relic Slot, HexCoord, Synergy); DESIGN.md (Core Innovation); SYSTEM DESIGN DOC.md §2.1; LORE_DESIGN.md §3
> **See also:** [systems/relics.md](relics.md) · [systems/linked-fates.md](linked-fates.md) · [systems/solo-play.md](solo-play.md) · [technical/netcode.md](../technical/netcode.md)

## What it is

The **Circulatory Board** is the shared hexagonal relic board owned by the entire party (not individual players). It is the central mechanic of Veins.

> The party is a single organism, not separate characters.

- **19 hex cells** (a hex of radius 2). Every cell is owned by a player at run start.
- Each cell is a **Relic Slot**: a coordinate (HexCoord), an owner (PlayerId), and optionally a placed **Relic**.
- Ownership determines whose player border renders; synergy ignores ownership *except* to require different owners (relaxed for solo — see [solo-play.md](solo-play.md)).

## HexCoord

Axial coordinate pair `{ q, r }`. Six neighbors at offsets `(±1, 0)`, `(0, ±1)`, `(+1, −1)`, `(−1, +1)`.

## Synergy rule

A relic fires its **synergy** (strongest) effect when it is adjacent to another relic, **owned by a different player**, that shares at least one tag.

- Evaluated **server-side only**, as a pure function of board state (`evaluateSynergies`). Never computed on the client (invariant I5).
- The result is broadcast as part of `RELIC_PLACED` / `RELIC_REMOVED` deltas.
- **Solo exception:** on a single-owner board the different-owner requirement is relaxed (see [solo-play.md](solo-play.md)). The tag-overlap requirement always applies.

> Placement is decision, not inventory.

## Ownership — home quadrants

At `startRun`, the 18 outer cells are sorted by angle around the origin and split into N contiguous arcs (one per player); the center cell goes to the first player. Contiguous arcs give each player a coherent "home region" while guaranteeing cross-player borders, so cross-player adjacency (and therefore synergy) always exists for 2–4 players. Deterministic.

## Board operations (pure functions)

All board operations — `placeRelic`, `reviveWithLinkedFates`, `advanceFloor`, `evaluateSynergies` — are pure: they take current state + a request and return new state + a discriminated-union result (`{ ok: true, board, event } | { ok: false, error }`). They never mutate inputs and never touch Socket.io directly. Socket.io handlers are thin plumbing: validate via the pure function, then emit the returned event(s).

## Persistence across floors

The board persists across floors; descending carries it **by reference** (never cloned/rebuilt). See [systems/bleed-clock.md](bleed-clock.md) for what carries over on descent.

## Doctrine note

Adjacency patterns express doctrine ("theology syntax"): linear chains = Sanctum, web clusters = Tumor, mirror pairs = Chorus, isolation nodes = Penitent. See [../doctrines.md](../doctrines.md).
