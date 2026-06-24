# System — Combat

> **Status:** Canon
> **Sources:** SYSTEM DESIGN DOC.md §4; DECISION_LOG.md (Enemy System + Combat, Weapon/Attack, Collision + Pathfinding, Body Collision, Dungeon Ruleset entries)
> **See also:** [content/enemies.md](../content/enemies.md) · [systems/relics.md](relics.md) · [ui-style-guide.md](../ui-style-guide.md) · [technical/netcode.md](../technical/netcode.md)

## Format (design intent)

Top-down action combat: light/heavy or ability-based attacks; dodge/dash. Combat is **readable, but modified by doctrine systems**. Enemies are simple individually but complex in groups.

## Implemented combat loop

A server-side `runCombatTick` runs at `COMBAT_TICK_MS = 100ms` while in the combat phase. Per tick, in order:

1. **player move** — `move-player` stores intended direction; movement applied once per tick (rate-limit exploit closed).
2. **auto-fire** — `tryAutoFire` fires per-player on `WEAPON_COOLDOWN_MS`; the server auto-fires, clients cannot trigger shots (server authority). Aim direction comes from auto-aim or aim-override (see [ui-style-guide.md](../ui-style-guide.md)).
3. **step projectiles** — `stepProjectiles` advances positions, resolves collision, clamps HP, applies relic effects (ember-core splash, torch-brand fire, arc-bolt chain).
4. **stepCombat** — enemy AI tick (`tickEnemies`), attack resolution (`applyEnemyAttacks`), downed state, fire DoT, iron-skin reduction, body separation (`separateBodies`), wipe check, and combat→loot transition when the last enemy dies (`allEnemiesDead`).
5. **ENEMY_MOVED** — emitted for all alive enemies.
6. **auto-aim refresh** — re-targets nearest enemy; emits `PLAYER_AIM_CHANGED` only on change.

## Player state

`PlayerState` (per-player HP map) with `hp`, `maxHp`, `downed`, position. `PLAYER_MAX_HP` baseline. Players spawn at the center of the entry room on `startRun`.

## Movement, collision, pathfinding

- **Player:** wall-slide via `clampToWalkable`; a source-in-wall escape hatch prevents trapping.
- **Projectiles:** terminate on wall entry.
- **Enemies:** A* pathfinding (`findNextWaypoint`) on a 10-unit tile grid, Manhattan heuristic, `MAX_ITERATIONS = 5000`, with a line-of-sight shortcut that defers to direct-chase when the straight line is clear.
- **Walkable** = rooms ∪ corridor L-shapes; `CORRIDOR_HALF_WIDTH = 20`.

## Delta events

`ENEMY_SPAWNED` / `ENEMY_DAMAGED` / `ENEMY_DIED` / `ENEMY_MOVED` / `PLAYER_DAMAGED` / `PLAYER_DOWNED` / `PLAYER_REVIVED` / `PLAYER_MOVED` / `PHASE_CHANGED` / `PROJECTILE_FIRED` / `PROJECTILE_REMOVED`.

Enemy roster, spawn rules, and elites are in [content/enemies.md](../content/enemies.md). Bosses are in [content/bosses.md](../content/bosses.md).
