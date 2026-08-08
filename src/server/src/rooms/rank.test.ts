// T364-T365 (R355-R358, P160-P162, TD-095): Collegium Rank as a PERMISSION.
import { describe, it, expect } from 'vitest';
import { RANKS, RANK_ACCEPTS } from '@testament/shared';
import type { Rank, Tier } from '@testament/shared';
import { canAccept, DEFAULT_RANK } from './rank.js';

const TIERS: Tier[] = ['VIGIL', 'INTERDICT', 'ANATHEMA'];

describe('Collegium Rank (TD-095)', () => {
  it('an Aspirant may accept nothing — they are not yet a Seeker', () => {
    for (const t of TIERS) expect(canAccept('ASPIRANT', t)).toBe(false);
  });

  it('each rank accepts its own tier and every tier below it', () => {
    expect(canAccept('SEEKER', 'VIGIL')).toBe(true);
    expect(canAccept('SEEKER', 'INTERDICT')).toBe(false);
    expect(canAccept('SEEKER', 'ANATHEMA')).toBe(false);

    expect(canAccept('WITNESS', 'VIGIL')).toBe(true);
    expect(canAccept('WITNESS', 'INTERDICT')).toBe(true);
    expect(canAccept('WITNESS', 'ANATHEMA')).toBe(false);

    for (const t of TIERS) expect(canAccept('CONFESSOR', t)).toBe(true);
  });

  it('the ladder is monotonic — a higher rank never accepts less than a lower one', () => {
    for (let i = 1; i < RANKS.length; i++) {
      const lower = RANK_ACCEPTS[RANKS[i - 1]!];
      const higher = RANK_ACCEPTS[RANKS[i]!];
      for (const t of lower) expect(higher).toContain(t);
    }
  });

  it('every rank in the ladder has an entry — a new rank must be placed deliberately', () => {
    for (const r of RANKS) expect(RANK_ACCEPTS[r]).toBeDefined();
    expect(Object.keys(RANK_ACCEPTS).sort()).toEqual([...RANKS].sort());
  });

  it('the stub is permissive, and that is recorded as a development affordance', () => {
    // R358: content must stay reachable before an account layer exists. This asserts
    // the CURRENT deliberate state; when Phase 7 lands, this test changes with it.
    expect(canAccept(DEFAULT_RANK, 'ANATHEMA')).toBe(true);
  });

  it('RANK_ACCEPTS names only tiers that exist', () => {
    const legal = new Set<string>(TIERS);
    for (const r of RANKS) for (const t of RANK_ACCEPTS[r]) expect(legal.has(t)).toBe(true);
  });
});
