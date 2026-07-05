import {
  TILE_SIZE,
  SEEKER_SPEED,
  SEEKER_FEET_HALF_WIDTH,
  SEEKER_FEET_HEIGHT,
  TILE_SOLID,
} from '@testament/shared';
import type { SiteGrid } from '@testament/shared';

// Authoritative movement integration (invariant I1/I5): pure and deterministic.
// A Seeker's collider is a small AABB at the feet — half `SEEKER_FEET_HALF_WIDTH`
// wide, `SEEKER_FEET_HEIGHT` tall measured up from the feet line — so the head
// can visually overlap a wall while the body stays out, matching the feet-anchor
// render convention (TD-033). Resolution is axis-separated: we commit each axis
// only if the resulting feet AABB is clear, so a blocked axis reverts while the
// free axis still advances (slide), and the returned position is *always*
// collision-free regardless of dt (a large step that would tunnel is simply
// rejected, never accepted).

type Pos = { x: number; y: number };

// Out-of-bounds tiles are treated as solid, so the border always contains.
function isSolidTile(grid: SiteGrid, tx: number, ty: number): boolean {
  if (tx < 0 || ty < 0 || tx >= grid.width || ty >= grid.height) return true;
  return grid.rows[ty]![tx] === TILE_SOLID;
}

// Does the feet AABB centered at (x, y) overlap any solid tile? Uses strict
// inequalities so merely touching a tile edge is not an overlap.
function feetOverlapsSolid(x: number, y: number, grid: SiteGrid): boolean {
  const left = x - SEEKER_FEET_HALF_WIDTH;
  const right = x + SEEKER_FEET_HALF_WIDTH;
  const top = y - SEEKER_FEET_HEIGHT;
  const bottom = y;
  const txMin = Math.floor(left / TILE_SIZE);
  const txMax = Math.floor(right / TILE_SIZE);
  const tyMin = Math.floor(top / TILE_SIZE);
  const tyMax = Math.floor(bottom / TILE_SIZE);
  for (let ty = tyMin; ty <= tyMax; ty++) {
    for (let tx = txMin; tx <= txMax; tx++) {
      const tileLeft = tx * TILE_SIZE;
      const tileTop = ty * TILE_SIZE;
      const overlaps =
        left < tileLeft + TILE_SIZE &&
        tileLeft < right &&
        top < tileTop + TILE_SIZE &&
        tileTop < bottom;
      if (overlaps && isSolidTile(grid, tx, ty)) return true;
    }
  }
  return false;
}

// Integrate one player's movement intent for `dtMs` against the grid. `dx`/`dy`
// are a direction (each in [-1, 1]); magnitudes above 1 are normalized so a
// diagonal gains no √2 speed bonus.
export function stepPlayer(pos: Pos, dx: number, dy: number, dtMs: number, grid: SiteGrid): Pos {
  let ndx = dx;
  let ndy = dy;
  const mag = Math.hypot(dx, dy);
  if (mag > 1) {
    ndx = dx / mag;
    ndy = dy / mag;
  }

  const dist = SEEKER_SPEED * (dtMs / 1000);
  let { x, y } = pos;

  const tryX = x + ndx * dist;
  if (!feetOverlapsSolid(tryX, y, grid)) x = tryX;

  const tryY = y + ndy * dist;
  if (!feetOverlapsSolid(x, tryY, grid)) y = tryY;

  return { x, y };
}
