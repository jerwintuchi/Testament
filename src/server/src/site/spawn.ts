import { TILE_SIZE, TILE_FLOOR } from '@testament/shared';
import type { SiteGrid } from '@testament/shared';

// Distinct feet spawn points (px, tile centers) drawn from floor tiles nearest an
// anchor by 4-neighbor BFS — so a party lands together around the anchor. Pure and
// deterministic (fixed neighbor order): same grid + anchor → same spawn order, so
// the Nth player to spawn always lands on the Nth tile (R85/R95). Shared by field
// deploy (anchor = APPROACH node) and Collegium entry (anchor = COLLEGIUM.spawn).
export function spawnFanOut(
  grid: SiteGrid,
  anchor: { x: number; y: number },
  count: number,
): Array<{ x: number; y: number }> {
  const { width, height, rows } = grid;
  const seen = new Set<string>([`${anchor.x},${anchor.y}`]);
  const order: Array<{ x: number; y: number }> = [{ x: anchor.x, y: anchor.y }];
  const queue: Array<{ x: number; y: number }> = [{ x: anchor.x, y: anchor.y }];
  while (queue.length > 0 && order.length < count) {
    const { x, y } = queue.shift()!;
    for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]] as const) {
      const nx = x + dx;
      const ny = y + dy;
      const key = `${nx},${ny}`;
      if (nx < 0 || ny < 0 || nx >= width || ny >= height || seen.has(key)) continue;
      if (rows[ny]![nx] !== TILE_FLOOR) continue;
      seen.add(key);
      order.push({ x: nx, y: ny });
      queue.push({ x: nx, y: ny });
    }
  }
  return order.slice(0, count).map(t => ({
    x: t.x * TILE_SIZE + TILE_SIZE / 2,
    y: t.y * TILE_SIZE + TILE_SIZE / 2,
  }));
}
