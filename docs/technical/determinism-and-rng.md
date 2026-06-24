# Technical — Determinism & Seeded RNG

> **Status:** Canon (summary — authoritative source is the code + DECISION_LOG.md)
> **Sources:** DECISION_LOG.md (seeded RNG, dungeon gen, per-floor seeding, spawn/loot seed namespaces)
> **See also:** [technical/netcode.md](netcode.md) (I3) · [systems/circulatory-board.md](../systems/circulatory-board.md) · [systems/extraction.md](../systems/extraction.md)

## Why it matters

Invariant **I3**: the run seed (`runId`) never leaves the server; all procedural generation is server-side and deterministic. Same `runId` → identical dungeon, identical loot sequence, always. This enables daily challenges and **bug reproduction from a run ID alone**.

## The RNG

`mulberry32` PRNG seeded by an `xfnv1a` string hash of the `runId`. Lives in `src/server/src/rng/seeded.ts`. Tiny, fast, dependency-free. `hashSeed` maps a UUID `runId` to a uint32 seed. This is the single randomness source for all server procedural systems. `Math.random()` is never used for game state.

## Seed namespaces (independent, never collide)

Each procedural system folds a distinct suffix into the seed so systems are independently reproducible:

| System | Seed |
|--------|------|
| Dungeon layout | `runId#floor` |
| Enemy spawns | `runId#floor#spawn` |
| Loot pool | `runId#floor#loot` |
| Combat RNG | per-run `combatRng` |

The dungeon's `runId` field stays the bare run id; folding `floor` into the seed (not the id) preserves per-floor reproducibility while keeping run identity in the payload. Floor 1 is unchanged for callers omitting the floor param (default 1).

## Dungeon generation

**BSP tree** dungeon generation, server-side only. <5ms generation, fully deterministic. The client never receives the seed — only the resulting rooms/corridors as events. BSP emits exactly `(roomCount − 1)` corridors = a spanning tree, so full connectivity holds by construction. Non-overlap, in-bounds, and connectivity are fuzzed across many seeds.

**Outside the mandate:** room codes use `node:crypto` (they need unpredictability, not reproducibility). See [netcode.md](netcode.md).
