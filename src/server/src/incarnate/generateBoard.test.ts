// T122 [R109 / P58]: the Contract Board is a seeded, deterministic pool of
// contracts (I3), and its wire handle (contractId) never embeds the expedition
// seed. Trait-roll containment on the *wire* is asserted in snapshot.test.ts.
import { describe, it, expect } from 'vitest';
import { generateBoard, BOARD_SIZE, tierPool } from './generateBoard.js';
import { generateContract } from './generateContract.js';
import { createRng, hashSeed } from '../rng/seeded.js';

describe('generateBoard (R109)', () => {
  it('same seed yields an identical board (determinism, I3)', () => {
    expect(generateBoard('seed-xyz')).toEqual(generateBoard('seed-xyz'));
  });

  it('different seeds yield different boards', () => {
    expect(generateBoard('seed-a')).not.toEqual(generateBoard('seed-b'));
  });

  it('produces BOARD_SIZE contracts by default, honoring an explicit size', () => {
    expect(generateBoard('s')).toHaveLength(BOARD_SIZE);
    expect(generateBoard('s', 6)).toHaveLength(6);
  });

  it('contractIds are distinct and never embed the expedition seed (I3)', () => {
    const seed = 'super-secret-expedition-seed';
    const ids = generateBoard(seed).map(c => c.contractId);
    expect(new Set(ids).size).toBe(ids.length);           // distinct handles
    for (const id of ids) expect(id).not.toContain(seed); // the seed never leaks into a wire handle
  });

  it('each entry is a full server-side record (own trait roll + seed)', () => {
    for (const c of generateBoard('s')) {
      expect(c.traitRoll).toBeDefined();
      expect(c.expeditionSeed).toBeDefined();
    }
  });

  // T362 (R353, P163, TD-095) — the wall offers a spread of danger.
  describe('tier spread', () => {
    it('a board is not all one tier', () => {
      const tiers = new Set(generateBoard('spread-seed').map(c => c.tier));
      expect(tiers.size).toBeGreaterThan(1);
    });

    it('composes exactly 5 Vigil / 2 Interdict / 1 Anathema at the canonical size', () => {
      // A GUARANTEED composition, not an independent draw per entry: once Rank gates
      // acceptance (TD-095 Phase B), independent draws could leave a low-rank Seeker a
      // board with nothing they may take. Every board must be workable.
      for (const seed of ['a', 'b', 'c', 'd', 'e']) {
        const counts: Record<string, number> = {};
        for (const c of generateBoard(seed)) counts[c.tier] = (counts[c.tier] ?? 0) + 1;
        expect(counts).toEqual({ VIGIL: 5, INTERDICT: 2, ANATHEMA: 1 });
      }
    });

    it('the same seed reproduces the same tiers in the same order (I3)', () => {
      const a = generateBoard('determinism').map(c => c.tier);
      const b = generateBoard('determinism').map(c => c.tier);
      expect(a).toEqual(b);
    });

    it('different seeds place the dangerous writs differently', () => {
      const orders = new Set(
        ['s1', 's2', 's3', 's4', 's5', 's6'].map(s => generateBoard(s).map(c => c.tier).join()),
      );
      expect(orders.size).toBeGreaterThan(1);   // the shuffle actually shuffles
    });

    it('never emits a tier outside the union, and never APOCRYPHA', () => {
      const legal = new Set(['VIGIL', 'INTERDICT', 'ANATHEMA']);
      for (const seed of ['x', 'y', 'z']) {
        for (const c of generateBoard(seed)) expect(legal.has(c.tier)).toBe(true);
      }
    });

    it('rounding at other sizes spills into VIGIL, never below the planned count', () => {
      // The remainder is VIGIL by construction, so an odd size can only ever make the
      // wall safer — it can never silently drop the accessible contracts.
      for (const size of [1, 3, 4, 6, 8, 16]) {
        const pool = tierPool(size);
        expect(pool).toHaveLength(size);
        expect(pool.filter(t => t === 'VIGIL').length).toBeGreaterThan(0);
      }
      expect(tierPool(16).filter(t => t === 'ANATHEMA')).toHaveLength(2);
    });

    it('adding the tier shuffle did not disturb any entry stream (P151)', () => {
      // The shuffle rides its own `:tiers` stream. A contract at a FIXED tier must be
      // byte-identical to what generateContract yields directly from the entry seed.
      const seed = 'stream-shape';
      const board = generateBoard(seed);
      for (let i = 0; i < board.length; i++) {
        const entrySeed = `${seed}:contract:${i}`;
        const direct = generateContract(createRng(hashSeed(entrySeed)), board[i]!.tier, board[i]!.contractId, entrySeed);
        expect(board[i]).toEqual(direct);
      }
    });
  });
});
