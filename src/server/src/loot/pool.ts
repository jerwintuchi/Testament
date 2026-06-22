import type { RelicBoard, RelicId } from '@veins/shared';
import { createRng, hashSeed } from '../rng/seeded.js';

export const LOOT_POOL_SIZE = 3;

// Pure, server-only (I1, I3). Same (registryIds, board, runId, floor) always
// produces the same pool. Seed is namespaced so loot and spawn sequences are
// independent.
export function generateLootPool(
  registryIds: RelicId[],
  board: RelicBoard,
  runId: string,
  floor: number
): RelicId[] {
  const placed = new Set(
    Object.values(board.slots)
      .map(s => s.relicId)
      .filter((id): id is string => id !== null)
  );
  const available = registryIds.filter(id => !placed.has(id));

  if (available.length === 0) return [];

  const rng = createRng(hashSeed(`${runId}#${floor}#loot`));
  const shuffled = [...available];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = rng.int(0, i);
    [shuffled[i], shuffled[j]] = [shuffled[j]!, shuffled[i]!];
  }
  return shuffled.slice(0, LOOT_POOL_SIZE);
}
