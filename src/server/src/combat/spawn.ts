import type { DungeonLayout } from '@veins/shared';
import { ENEMY_TYPES } from '@veins/shared';
import { hashSeed, createRng, type Rng } from '../rng/seeded.js';
import type { EnemyId, EnemyState } from './types.js';

// Pad enemy spawns away from room edges so they don't clip walls.
const SPAWN_PADDING = 8;

// Enemy type pool. Deterministically chosen per enemy slot.
const ENEMY_TYPE_POOL = ['shambler', 'spitter'] as const;

// HP and damage scale up with floor depth so deeper runs feel meaningfully harder.
// Floor 1 = ×1.0, Floor 3 = ×1.4, Floor 5 = ×1.8.
function floorHpMultiplier(floor: number): number  { return 1 + 0.2 * (floor - 1); }
function floorDmgMultiplier(floor: number): number { return 1 + 0.15 * (floor - 1); }

// Pure, server-only (I1, I3). Same (runId, floor, dungeon) always yields the
// same enemy map. Seed is distinct from the dungeon layout seed (runId#floor),
// so spawns and geometry are independently reproducible without collision.
export function spawnEnemies(
  runId: string,
  floor: number,
  dungeon: DungeonLayout,
  rng: Rng = createRng(hashSeed(`${runId}#${floor}#spawn`))
): Map<EnemyId, EnemyState> {
  const result = new Map<EnemyId, EnemyState>();

  // Skip the first room (room-0) — that is where the party enters. All other
  // rooms receive 1-2 enemies.
  const spawnRooms = dungeon.rooms.slice(1);

  for (const room of spawnRooms) {
    const count = rng.int(1, 2);
    for (let i = 0; i < count; i++) {
      const typeId = rng.pick(ENEMY_TYPE_POOL);
      const def = ENEMY_TYPES[typeId];
      const id: EnemyId = `${runId}-${floor}-${room.id}-${i}`;

      const xMin = room.rect.x + SPAWN_PADDING;
      const xMax = room.rect.x + room.rect.width - SPAWN_PADDING;
      const yMin = room.rect.y + SPAWN_PADDING;
      const yMax = room.rect.y + room.rect.height - SPAWN_PADDING;

      const x = rng.int(xMin, xMax);
      const y = rng.int(yMin, yMax);
      const scaledHp  = Math.round(def.baseHp * floorHpMultiplier(floor));
      const scaledDmg = Math.round(def.damage  * floorDmgMultiplier(floor));

      result.set(id, {
        id,
        typeId,
        x,
        y,
        hp:     scaledHp,
        maxHp:  scaledHp,
        damage: scaledDmg,
        alive: true,
        attackCooldownRemaining: 0,
      });
    }
  }

  return result;
}
