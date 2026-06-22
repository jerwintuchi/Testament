import { describe, it, expect } from 'vitest';
import { generateLootPool, LOOT_POOL_SIZE } from './pool.js';
import type { RelicBoard } from '@veins/shared';

const EMPTY_BOARD: RelicBoard = { slots: {} };

const ALL_IDS = ['blooming-wound', 'systemic-rot', 'resonant-cord', 'synaptic-filament', 'calcified-shell', 'votive-tissue'];

describe('generateLootPool (T1, R1)', () => {
  it('is deterministic: same inputs produce the same pool', () => {
    const a = generateLootPool(ALL_IDS, EMPTY_BOARD, 'run-1', 1);
    const b = generateLootPool(ALL_IDS, EMPTY_BOARD, 'run-1', 1);
    expect(a).toEqual(b);
  });

  it('different floor yields a different pool', () => {
    const floor1 = generateLootPool(ALL_IDS, EMPTY_BOARD, 'run-1', 1);
    const floor2 = generateLootPool(ALL_IDS, EMPTY_BOARD, 'run-1', 2);
    expect(floor1).not.toEqual(floor2);
  });

  it('different runId yields a different pool', () => {
    const a = generateLootPool(ALL_IDS, EMPTY_BOARD, 'run-A', 1);
    const b = generateLootPool(ALL_IDS, EMPTY_BOARD, 'run-B', 1);
    expect(a).not.toEqual(b);
  });

  it('pool size is min(LOOT_POOL_SIZE, unplacedCount)', () => {
    const pool = generateLootPool(ALL_IDS, EMPTY_BOARD, 'run-1', 1);
    expect(pool).toHaveLength(LOOT_POOL_SIZE);
  });

  it('pool contains only unplaced relics', () => {
    const board: RelicBoard = {
      slots: {
        '0,0': { coord: { q: 0, r: 0 }, ownerId: 'p1', relicId: 'blooming-wound' },
        '1,0': { coord: { q: 1, r: 0 }, ownerId: 'p2', relicId: 'systemic-rot' },
        '-1,0': { coord: { q: -1, r: 0 }, ownerId: 'p1', relicId: 'resonant-cord' },
      },
    };
    const pool = generateLootPool(ALL_IDS, board, 'run-1', 1);
    expect(pool).not.toContain('blooming-wound');
    expect(pool).not.toContain('systemic-rot');
    expect(pool).not.toContain('resonant-cord');
  });

  it('pool is smaller than LOOT_POOL_SIZE when fewer unplaced relics remain', () => {
    const onlyTwo = ['calcified-shell', 'votive-tissue'];
    const pool = generateLootPool(onlyTwo, EMPTY_BOARD, 'run-1', 1);
    expect(pool).toHaveLength(2);
    expect(pool).toContain('calcified-shell');
    expect(pool).toContain('votive-tissue');
  });

  it('returns empty array when all relics are placed', () => {
    const board: RelicBoard = {
      slots: {
        '0,0': { coord: { q: 0, r: 0 }, ownerId: 'p1', relicId: 'calcified-shell' },
      },
    };
    const pool = generateLootPool(['calcified-shell'], board, 'run-1', 1);
    expect(pool).toEqual([]);
  });

  it('all pool entries are unique', () => {
    const pool = generateLootPool(ALL_IDS, EMPTY_BOARD, 'run-1', 1);
    expect(new Set(pool).size).toBe(pool.length);
  });
});
