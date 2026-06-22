import type { PlayerState, DungeonLayout } from '@veins/shared';
import { PLAYER_SPEED } from '@veins/shared';

// Pure player movement. Normalizes the direction vector so diagonal movement
// is not faster than cardinal movement. Clamps result to dungeon bounds.
// Per-room wall collision is deferred to the collision spec.
export function movePlayer(
  playerState: PlayerState,
  dx: number,
  dy: number,
  dt: number,
  dungeon: DungeonLayout,
  speed: number = PLAYER_SPEED
): PlayerState {
  const mag = Math.sqrt(dx * dx + dy * dy);
  if (mag === 0) return playerState; // zero vector: no-op, return original (no mutation)

  const nx = playerState.x + (dx / mag) * speed * dt;
  const ny = playerState.y + (dy / mag) * speed * dt;

  return {
    ...playerState,
    x: Math.max(0, Math.min(dungeon.width, nx)),
    y: Math.max(0, Math.min(dungeon.height, ny)),
  };
}
