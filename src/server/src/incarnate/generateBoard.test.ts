// T122 [R109 / P58]: the Contract Board is a seeded, deterministic pool of
// contracts (I3), and its wire handle (contractId) never embeds the expedition
// seed. Trait-roll containment on the *wire* is asserted in snapshot.test.ts.
import { describe, it, expect } from 'vitest';
import { generateBoard, BOARD_SIZE } from './generateBoard.js';

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
});
