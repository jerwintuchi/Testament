import { describe, it, expect } from 'vitest';
import { hexNeighbors, hexCoordKey } from './board.js';

describe('hexNeighbors', () => {
  it('returns exactly 6 neighbors for any coord', () => {
    expect(hexNeighbors({ q: 0, r: 0 })).toHaveLength(6);
    expect(hexNeighbors({ q: 5, r: -3 })).toHaveLength(6);
    expect(hexNeighbors({ q: -99, r: 99 })).toHaveLength(6);
  });

  it('returns the correct 6 axial offsets from origin', () => {
    const neighbors = hexNeighbors({ q: 0, r: 0 });
    expect(neighbors).toEqual(
      expect.arrayContaining([
        { q: 1, r: 0 },
        { q: -1, r: 0 },
        { q: 0, r: 1 },
        { q: 0, r: -1 },
        { q: 1, r: -1 },
        { q: -1, r: 1 },
      ])
    );
  });

  it('applies offsets correctly from a non-origin coord', () => {
    const neighbors = hexNeighbors({ q: 2, r: 3 });
    expect(neighbors).toEqual(
      expect.arrayContaining([
        { q: 3, r: 3 },
        { q: 1, r: 3 },
        { q: 2, r: 4 },
        { q: 2, r: 2 },
        { q: 3, r: 2 },
        { q: 1, r: 4 },
      ])
    );
  });

  it('adjacency is symmetric: if B is in neighbors(A), A is in neighbors(B)', () => {
    const a = { q: 1, r: -1 };
    const neighborsOfA = hexNeighbors(a);
    for (const b of neighborsOfA) {
      const neighborsOfB = hexNeighbors(b);
      expect(neighborsOfB).toContainEqual(a);
    }
  });
});

describe('hexCoordKey', () => {
  it('produces a stable comma-separated format', () => {
    expect(hexCoordKey({ q: 1, r: 2 })).toBe('1,2');
    expect(hexCoordKey({ q: -1, r: 0 })).toBe('-1,0');
    expect(hexCoordKey({ q: 0, r: -3 })).toBe('0,-3');
    expect(hexCoordKey({ q: 0, r: 0 })).toBe('0,0');
  });

  it('is injective: 441 distinct coords produce 441 distinct keys', () => {
    const keys = new Set<string>();
    for (let q = -10; q <= 10; q++) {
      for (let r = -10; r <= 10; r++) {
        keys.add(hexCoordKey({ q, r }));
      }
    }
    expect(keys.size).toBe(21 * 21);
  });

  it('round-trips with hexNeighbors: neighbor keys are all distinct', () => {
    const neighborKeys = hexNeighbors({ q: 0, r: 0 }).map(hexCoordKey);
    const unique = new Set(neighborKeys);
    expect(unique.size).toBe(6);
  });
});
