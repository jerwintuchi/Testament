// T107 [R95]: spawnFanOut is pure/deterministic — distinct floor tiles fanned
// from an anchor by BFS, feet at tile center, stable order.
import { describe, it, expect } from 'vitest';
import type { SiteGrid } from '@testament/shared';
import { spawnFanOut } from './spawn.js';

// A 5×5 open room (floor cols 1..3, rows 1..3) with a solid border.
const GRID: SiteGrid = {
  width: 5,
  height: 5,
  rows: ['#####', '#...#', '#...#', '#...#', '#####'],
};
const ANCHOR = { x: 2, y: 2 };

describe('spawnFanOut (R95)', () => {
  it('places feet at tile centers', () => {
    const [p] = spawnFanOut(GRID, ANCHOR, 1);
    expect(p).toEqual({ x: 2 * 16 + 8, y: 2 * 16 + 8 });
  });

  it('the anchor is always the first spawn', () => {
    const spawns = spawnFanOut(GRID, ANCHOR, 4);
    expect(spawns[0]).toEqual({ x: 40, y: 40 });
  });

  it('returns distinct tiles for a party', () => {
    const spawns = spawnFanOut(GRID, ANCHOR, 4);
    expect(spawns).toHaveLength(4);
    const keys = new Set(spawns.map(s => `${s.x},${s.y}`));
    expect(keys.size).toBe(4);
  });

  it('is deterministic — same grid + anchor → identical order', () => {
    expect(spawnFanOut(GRID, ANCHOR, 4)).toEqual(spawnFanOut(GRID, ANCHOR, 4));
  });

  it('only lands on floor tiles', () => {
    for (const s of spawnFanOut(GRID, ANCHOR, 4)) {
      const tx = Math.floor(s.x / 16);
      const ty = Math.floor(s.y / 16);
      expect(GRID.rows[ty]![tx]).toBe('.');
    }
  });

  it('never returns more tiles than the floor holds', () => {
    // 9 floor tiles available; asking for 20 caps at 9.
    expect(spawnFanOut(GRID, ANCHOR, 20)).toHaveLength(9);
  });
});
