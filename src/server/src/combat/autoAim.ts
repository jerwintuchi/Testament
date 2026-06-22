import type { EnemyState, EnemyId } from './types.js';

// Units; wider than Spitter detectionRange (300) so the auto-aim indicator
// appears before the enemy starts moving toward the player.
export const AUTO_AIM_RANGE = 250;

// Pure function: returns the id of the nearest alive enemy within AUTO_AIM_RANGE,
// or null if none qualify. Same inputs always produce the same result (P2).
export function selectAutoAimTarget(
  playerPos: { x: number; y: number },
  enemies: Map<EnemyId, EnemyState>,
): string | null {
  let best: string | null = null;
  let bestDist = Infinity;

  for (const [id, enemy] of enemies) {
    if (!enemy.alive) continue;
    const dx = enemy.x - playerPos.x;
    const dy = enemy.y - playerPos.y;
    const dist = Math.sqrt(dx * dx + dy * dy);
    if (dist <= AUTO_AIM_RANGE && dist < bestDist) {
      best = id;
      bestDist = dist;
    }
  }

  return best;
}
