# Content — Enemies

> **Status:** Mixed (canon implemented roster + draft "pathologies")
> **Sources:** DECISION_LOG.md (Enemy System + Combat; Dungeon Ruleset); GPT_CHAT_HISTORY.txt (draft, enemy concepts)
> **See also:** [systems/combat.md](../systems/combat.md) · [content/bosses.md](bosses.md) · [content/biomes.md](biomes.md)

## Implemented enemies (current build)

`ENEMY_TYPES` defines stats per type:

- **Shambler** — melee approacher.
- **Spitter** — ranged attacker.

Both use A* pathfinding with a line-of-sight direct-chase shortcut. Behavior, attack resolution, and the combat tick are in [systems/combat.md](../systems/combat.md).

### Spawn rules (Dungeon Ruleset)

- **Counts scale with floor:** `extra = min(floor((floor-1)/2), 2)` → floors 1–2 give [1,2], floors 3–4 give [2,3], floor 5+ give [3,4] enemies per room.
- **Type distribution scales with floor:** `spitterProb = min(0.7, 0.15 + 0.1*(floor-1))` → 15% spitters on floor 1, capped at 70% from floor 7+.
- **Elite last room:** the last room in BSP traversal order spawns an elite — 2× HP, 1.5× damage, +1 count, stacked on top of floor multipliers. Deterministic (no extra RNG).
- **Entry room always clear:** no enemies spawn in room 0.
- Spawn seed `runId#floor#spawn` is independent of the dungeon-layout seed (see [technical/determinism-and-rng.md](../technical/determinism-and-rng.md)).

---

## Draft / Exploratory — Pathologies

> Mined from `GPT_CHAT_HISTORY.txt`. Enemies are **pathologies**, not monsters. Concepts only — not implemented.

- **Hematoma** — blob creatures that split when killed.
- **Clot Knights** — armored white-blood-cell guardians with charge attacks.
- **Parasites** — attach to players, reduce synergy radius, force teammates to save each other.
- **Carrion Choir** — floating angel-like masses whose singing increases Bleed Clock speed; must be interrupted.
