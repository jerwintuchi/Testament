// T97 [R83, R84 / P41, P42]: generateSite is pure/deterministic and produces a
// structurally sound layout (border solid, correct node multiplicities, nodes on
// floor, every floor tile reachable from APPROACH).
import { describe, it, expect } from 'vitest';
import { TILE_SOLID, TILE_FLOOR } from '@testament/shared';
import type { SiteLayout } from '@testament/shared';
import { generateSite } from './generateSite.js';
import { createRng, hashSeed } from '../rng/seeded.js';

const SEEDS = Array.from({ length: 120 }, (_, i) => hashSeed(`site-${i}`));

function tileAt(site: SiteLayout, x: number, y: number): string {
  return site.grid.rows[y]![x]!;
}

// BFS over 4-neighbor floor tiles from the APPROACH node; returns the set of
// reached "x,y" keys.
function reachableFrom(site: SiteLayout, sx: number, sy: number): Set<string> {
  const seen = new Set<string>();
  const queue: Array<[number, number]> = [[sx, sy]];
  seen.add(`${sx},${sy}`);
  while (queue.length > 0) {
    const [x, y] = queue.shift()!;
    for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]] as const) {
      const nx = x + dx;
      const ny = y + dy;
      const key = `${nx},${ny}`;
      if (nx < 0 || ny < 0 || nx >= site.grid.width || ny >= site.grid.height) continue;
      if (seen.has(key)) continue;
      if (tileAt(site, nx, ny) !== TILE_FLOOR) continue;
      seen.add(key);
      queue.push([nx, ny]);
    }
  }
  return seen;
}

describe('generateSite', () => {
  it('determinism (P41/R83): same rng seed → deep-equal layout', () => {
    for (const seed of [hashSeed('a'), hashSeed('b'), hashSeed('c')]) {
      const a = generateSite(createRng(seed));
      const b = generateSite(createRng(seed));
      expect(a).toEqual(b);
    }
  });

  it('grid shape: rows.length === height, every row length === width', () => {
    for (const seed of SEEDS) {
      const { grid } = generateSite(createRng(seed));
      expect(grid.rows).toHaveLength(grid.height);
      for (const row of grid.rows) expect(row).toHaveLength(grid.width);
    }
  });

  it('P42: all border tiles are solid', () => {
    for (const seed of SEEDS) {
      const site = generateSite(createRng(seed));
      const { width, height } = site.grid;
      for (let x = 0; x < width; x++) {
        expect(tileAt(site, x, 0)).toBe(TILE_SOLID);
        expect(tileAt(site, x, height - 1)).toBe(TILE_SOLID);
      }
      for (let y = 0; y < height; y++) {
        expect(tileAt(site, 0, y)).toBe(TILE_SOLID);
        expect(tileAt(site, width - 1, y)).toBe(TILE_SOLID);
      }
    }
  });

  it('P42: node multiplicities — 1 APPROACH / 1 LAIR / 1 EXTRACTION / ≥2 SIGN_SOURCE', () => {
    for (const seed of SEEDS) {
      const { nodes } = generateSite(createRng(seed));
      const count = (kind: string) => nodes.filter(n => n.kind === kind).length;
      expect(count('APPROACH')).toBe(1);
      expect(count('LAIR')).toBe(1);
      expect(count('EXTRACTION')).toBe(1);
      expect(count('SIGN_SOURCE')).toBeGreaterThanOrEqual(2);
    }
  });

  it('P42: every node sits on a floor tile', () => {
    for (const seed of SEEDS) {
      const site = generateSite(createRng(seed));
      for (const node of site.nodes) {
        expect(tileAt(site, node.x, node.y)).toBe(TILE_FLOOR);
      }
    }
  });

  it('P42: every floor tile is reachable from APPROACH (no sealed pockets)', () => {
    for (const seed of SEEDS) {
      const site = generateSite(createRng(seed));
      const approach = site.nodes.find(n => n.kind === 'APPROACH')!;
      const reached = reachableFrom(site, approach.x, approach.y);

      let floorCount = 0;
      for (let y = 0; y < site.grid.height; y++) {
        for (let x = 0; x < site.grid.width; x++) {
          if (tileAt(site, x, y) === TILE_FLOOR) floorCount++;
        }
      }
      expect(reached.size).toBe(floorCount);
    }
  });
});
