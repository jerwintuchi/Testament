// T106 [R94 / P48]: the fixed COLLEGIUM layout is structurally sound — border
// solid, exactly one of each station, stations + spawn on floor, and the whole
// floor reachable from the spawn anchor (no sealed pockets). Authored, not
// generated, so this guards against authoring typos in the one constant.
import { describe, it, expect } from 'vitest';
import { TILE_SOLID, TILE_FLOOR, STATION_KINDS } from '@testament/shared';
import type { SiteGrid } from '@testament/shared';
import { COLLEGIUM } from './collegium.js';

function tileAt(grid: SiteGrid, x: number, y: number): string {
  return grid.rows[y]![x]!;
}

// BFS over 4-neighbor floor tiles from an anchor; returns reached "x,y" keys.
function reachableFrom(grid: SiteGrid, sx: number, sy: number): Set<string> {
  const seen = new Set<string>([`${sx},${sy}`]);
  const queue: Array<[number, number]> = [[sx, sy]];
  while (queue.length > 0) {
    const [x, y] = queue.shift()!;
    for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]] as const) {
      const nx = x + dx;
      const ny = y + dy;
      const key = `${nx},${ny}`;
      if (nx < 0 || ny < 0 || nx >= grid.width || ny >= grid.height) continue;
      if (seen.has(key) || tileAt(grid, nx, ny) !== TILE_FLOOR) continue;
      seen.add(key);
      queue.push([nx, ny]);
    }
  }
  return seen;
}

describe('COLLEGIUM (R94)', () => {
  const { grid, stations, spawn } = COLLEGIUM;

  it('grid shape: rows.length === height, every row length === width', () => {
    expect(grid.rows).toHaveLength(grid.height);
    for (const row of grid.rows) expect(row).toHaveLength(grid.width);
  });

  it('P48: all border tiles are solid', () => {
    for (let x = 0; x < grid.width; x++) {
      expect(tileAt(grid, x, 0)).toBe(TILE_SOLID);
      expect(tileAt(grid, x, grid.height - 1)).toBe(TILE_SOLID);
    }
    for (let y = 0; y < grid.height; y++) {
      expect(tileAt(grid, 0, y)).toBe(TILE_SOLID);
      expect(tileAt(grid, grid.width - 1, y)).toBe(TILE_SOLID);
    }
  });

  it('P48: exactly one of each station kind', () => {
    for (const kind of STATION_KINDS) {
      expect(stations.filter(s => s.kind === kind)).toHaveLength(1);
    }
    expect(stations).toHaveLength(STATION_KINDS.length);
  });

  it('P48: every station and the spawn anchor sit on a floor tile', () => {
    for (const s of stations) expect(tileAt(grid, s.x, s.y)).toBe(TILE_FLOOR);
    expect(tileAt(grid, spawn.x, spawn.y)).toBe(TILE_FLOOR);
  });

  it('P48: every floor tile is reachable from spawn (no sealed pockets)', () => {
    const reached = reachableFrom(grid, spawn.x, spawn.y);
    let floorCount = 0;
    for (let y = 0; y < grid.height; y++) {
      for (let x = 0; x < grid.width; x++) {
        if (tileAt(grid, x, y) === TILE_FLOOR) floorCount++;
      }
    }
    expect(reached.size).toBe(floorCount);
  });

  it('stations are outside STATION_RADIUS of spawn (walking is required)', () => {
    // Sanity: a Seeker at spawn should not already be at any station.
    const spawnPx = { x: spawn.x * 16 + 8, y: spawn.y * 16 + 8 };
    for (const s of stations) {
      const sPx = { x: s.x * 16 + 8, y: s.y * 16 + 8 };
      expect(Math.hypot(spawnPx.x - sPx.x, spawnPx.y - sPx.y)).toBeGreaterThan(24);
    }
  });
});
