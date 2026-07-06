// T98 [R88 / P43]: stepPlayer is pure and collision-safe. The post-step feet
// AABB never overlaps a solid tile (containment), diagonal input never grants a
// √2 speed bonus, wall contact slides (blocked axis reverts, free axis advances),
// and zero intent leaves the position untouched.
import { describe, it, expect } from 'vitest';
import {
  TILE_SIZE,
  SEEKER_SPEED,
  WALK_SPEED,
  SEEKER_FEET_HALF_WIDTH,
  SEEKER_FEET_HEIGHT,
} from '@testament/shared';
import type { SiteGrid, SiteLayout } from '@testament/shared';
import { stepPlayer } from './movement.js';
import { generateSite } from './generateSite.js';
import { createRng, hashSeed } from '../rng/seeded.js';

// Independent re-derivation of the feet-AABB / solid-tile overlap test, so the
// property assertion does not lean on stepPlayer's own internals. Out-of-bounds
// tiles count as solid.
function overlapsSolid(x: number, y: number, grid: SiteGrid): boolean {
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
      // Strict-inequality AABB overlap: merely touching an edge is not overlap.
      const tileLeft = tx * TILE_SIZE;
      const tileTop = ty * TILE_SIZE;
      const overlaps =
        left < tileLeft + TILE_SIZE &&
        tileLeft < right &&
        top < tileTop + TILE_SIZE &&
        tileTop < bottom;
      if (!overlaps) continue;
      const solid =
        tx < 0 || ty < 0 || tx >= grid.width || ty >= grid.height
          ? true
          : grid.rows[ty]![tx] !== '.';
      if (solid) return true;
    }
  }
  return false;
}

// Every floor tile's center, as a candidate spawn/start point (feet px).
function floorCenters(site: SiteLayout): Array<{ x: number; y: number }> {
  const pts: Array<{ x: number; y: number }> = [];
  for (let ty = 0; ty < site.grid.height; ty++) {
    for (let tx = 0; tx < site.grid.width; tx++) {
      if (site.grid.rows[ty]![tx] === '.') {
        pts.push({ x: tx * TILE_SIZE + TILE_SIZE / 2, y: ty * TILE_SIZE + TILE_SIZE / 2 });
      }
    }
  }
  return pts;
}

// A tiny hand-built grid: a solid border with a vertical wall down the middle
// (column 3) and floor either side, for deterministic slide/block assertions.
const WALL_GRID: SiteGrid = {
  width: 7,
  height: 5,
  rows: [
    '#######',
    '#..#..#',
    '#..#..#',
    '#..#..#',
    '#######',
  ],
};

describe('stepPlayer', () => {
  it('zero intent leaves the position identical', () => {
    const pos = { x: 40, y: 40 };
    const next = stepPlayer(pos, 0, 0, 50, WALL_GRID);
    expect(next).toEqual(pos);
  });

  it('diagonal input has no √2 speed advantage (normalized)', () => {
    // Open interior of WALL_GRID left chamber: tile (1,2) center = (24, 40).
    const start = { x: 24, y: 40 };
    const dt = 50;
    // Move up-left; both axes free here, so displacement magnitude == SEEKER_SPEED·dt.
    const next = stepPlayer(start, -1, -1, dt, WALL_GRID);
    const dist = Math.hypot(next.x - start.x, next.y - start.y);
    const cap = SEEKER_SPEED * (dt / 1000);
    expect(dist).toBeLessThanOrEqual(cap + 1e-9);
    // A naive un-normalized diagonal would travel cap·√2; assert we are near cap.
    expect(dist).toBeCloseTo(cap, 5);
  });

  it('walk register moves at WALK_SPEED; run (default) at SEEKER_SPEED', () => {
    // Open interior of WALL_GRID left chamber, moving right along a free axis.
    const start = { x: 24, y: 40 };
    const dt = 50;
    const runStep = stepPlayer(start, 1, 0, dt, WALL_GRID);
    const walkStep = stepPlayer(start, 1, 0, dt, WALL_GRID, true);
    expect(runStep.x - start.x).toBeCloseTo(SEEKER_SPEED * (dt / 1000), 6);
    expect(walkStep.x - start.x).toBeCloseTo(WALK_SPEED * (dt / 1000), 6);
    // Walk is strictly slower than run for the same intent.
    expect(walkStep.x - start.x).toBeLessThan(runStep.x - start.x);
  });

  it('P43 containment: post-step feet AABB never overlaps a solid tile', () => {
    const site = generateSite(createRng(hashSeed('move-site')));
    const starts = floorCenters(site);
    const rng = createRng(hashSeed('move-inputs'));
    for (const start of starts) {
      // Sanity: the start itself is collision-free.
      expect(overlapsSolid(start.x, start.y, site.grid)).toBe(false);
      for (let k = 0; k < 8; k++) {
        const dx = rng.float() * 2 - 1;
        const dy = rng.float() * 2 - 1;
        const dtMs = rng.int(1, 100);
        const next = stepPlayer(start, dx, dy, dtMs, site.grid);
        expect(overlapsSolid(next.x, next.y, site.grid)).toBe(false);
      }
    }
  });

  it('wall contact slides: blocked axis reverts, free axis advances', () => {
    // Left chamber, feet snug against the wall: right edge (x+5) at px 48, the
    // left face of wall column 3 (px 48..64). Push right+up: x is blocked by the
    // wall, y is free.
    const start = { x: 43, y: 40 };
    const next = stepPlayer(start, 1, -1, 50, WALL_GRID);
    // x cannot advance into the wall (feet right edge would cross px 48).
    expect(next.x).toBeLessThanOrEqual(start.x + 1e-9);
    // y still advances upward (decreasing y).
    expect(next.y).toBeLessThan(start.y);
    expect(overlapsSolid(next.x, next.y, WALL_GRID)).toBe(false);
  });

  it('moving straight into a wall stops on that axis but does not overshoot', () => {
    const start = { x: 40, y: 40 };
    // Straight right into the wall; a large dt would tunnel a naive integrator,
    // but the result must remain collision-free regardless.
    const next = stepPlayer(start, 1, 0, 1000, WALL_GRID);
    expect(overlapsSolid(next.x, next.y, WALL_GRID)).toBe(false);
    expect(next.y).toBe(start.y);
  });
});
