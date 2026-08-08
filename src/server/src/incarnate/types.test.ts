// T40: Server-only trait types — TraitRoll, ACTIVE_AXES
import { describe, it, expect } from 'vitest';
import { ACTIVE_AXES } from './types.js';
import type { TraitRoll, TraitAxis } from './types.js';

// T40(a): TraitRoll requires aspect, frailty, tell (compile-time check).
const _minimalRoll = {
  aspect:  'EMBER',
  frailty: 'FLAME',
  tell:    'LUNGE',
} satisfies TraitRoll;

// Optional fields are not required (compile-time: Vigil roll is valid without ward etc.)
const _vigilRoll: TraitRoll = { aspect: 'FROST', frailty: 'COLD', tell: 'SWEEP' };

describe('ACTIVE_AXES', () => {
  it('VIGIL has exactly 3 axes', () => {
    expect(ACTIVE_AXES.VIGIL).toHaveLength(3);
  });

  it('INTERDICT has exactly 5 axes', () => {
    expect(ACTIVE_AXES.INTERDICT).toHaveLength(5);
  });

  it('ANATHEMA has exactly 6 axes', () => {
    expect(ACTIVE_AXES.ANATHEMA).toHaveLength(6);
  });

  it('every axis appears exactly once in ANATHEMA', () => {
    const masterAxes = ACTIVE_AXES.ANATHEMA;
    const unique = new Set(masterAxes);
    expect(unique.size).toBe(masterAxes.length);
  });

  it('VIGIL axes are a strict subset of ANATHEMA axes', () => {
    const masterSet = new Set<TraitAxis>(ACTIVE_AXES.ANATHEMA);
    for (const axis of ACTIVE_AXES.VIGIL) {
      expect(masterSet.has(axis)).toBe(true);
    }
    expect(ACTIVE_AXES.VIGIL.length).toBeLessThan(ACTIVE_AXES.ANATHEMA.length);
  });

  it('INTERDICT axes are a strict subset of ANATHEMA axes and a superset of VIGIL', () => {
    const masterSet = new Set<TraitAxis>(ACTIVE_AXES.ANATHEMA);
    const vigilSet = new Set<TraitAxis>(ACTIVE_AXES.VIGIL);
    for (const axis of ACTIVE_AXES.INTERDICT) {
      expect(masterSet.has(axis)).toBe(true);
    }
    for (const axis of ACTIVE_AXES.VIGIL) {
      expect(ACTIVE_AXES.INTERDICT).toContain(axis);
    }
    expect(ACTIVE_AXES.INTERDICT.length).toBeGreaterThan(vigilSet.size);
    expect(ACTIVE_AXES.INTERDICT.length).toBeLessThan(ACTIVE_AXES.ANATHEMA.length);
  });
});
