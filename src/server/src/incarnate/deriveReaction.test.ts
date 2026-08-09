// T56: deriveReaction — probe reaction from the hidden Ward (R55, R56, P20, P21)
import { describe, it, expect } from 'vitest';
import { deriveReaction, NO_REACTION_SIGN, PROBE_EXPOSURE_COST } from './deriveReaction.js';
import { expectNoTraitValues } from './containment.testkit.js';
import type { TraitRoll } from './types.js';
import type { Stimulus } from '@testament/shared';
import { STIMULI } from '@testament/shared';
import { tokenFor } from './lexicon.js';

const FULL_ROLL: TraitRoll = {
  aspect:      'EMBER',
  frailty:     'FLAME',
  tell:        'LUNGE',
  ward:        'COLD',
  disposition: 'STALKER',
  riteKey:     'PENANCE',
};

describe('deriveReaction', () => {
  it('matching stimulus at Interdict returns the ward lexicon REACTION sign', () => {
    const sign = deriveReaction(FULL_ROLL, 'INTERDICT', 'COLD');
    expect(sign).toEqual({ channel: 'REACTION', token: tokenFor('WARD', 'COLD') });
  });

  it('matching stimulus at Anathema returns the ward lexicon REACTION sign', () => {
    const roll: TraitRoll = { ...FULL_ROLL, ward: 'SALT' };
    const sign = deriveReaction(roll, 'ANATHEMA', 'SALT');
    expect(sign).toEqual({ channel: 'REACTION', token: tokenFor('WARD', 'SALT') });
  });

  it('non-matching stimulus returns NO_REACTION_SIGN (a miss reveals nothing)', () => {
    const sign = deriveReaction(FULL_ROLL, 'INTERDICT', 'FLAME');
    expect(sign).toEqual(NO_REACTION_SIGN);
  });

  it('Vigil tier (no ward axis) returns NO_REACTION_SIGN for every stimulus', () => {
    for (const stimulus of STIMULI) {
      expect(deriveReaction(FULL_ROLL, 'VIGIL', stimulus)).toEqual(NO_REACTION_SIGN);
    }
  });

  it('a miss is indistinguishable from no-ward (R56)', () => {
    const miss   = deriveReaction(FULL_ROLL, 'INTERDICT', 'LIGHT');
    const noWard = deriveReaction(FULL_ROLL, 'VIGIL', 'LIGHT');
    expect(miss).toEqual(noWard);
  });

  it('same inputs produce identical output (P20)', () => {
    const a = deriveReaction(FULL_ROLL, 'ANATHEMA', 'COLD');
    const b = deriveReaction(FULL_ROLL, 'ANATHEMA', 'COLD');
    expect(a).toEqual(b);
  });

  it('output has exactly the keys channel and token, and a miss never names the ward (P21)', () => {
    const stimuli: Stimulus[] = ['FLAME', 'SALT', 'LIGHT']; // ward is COLD
    for (const stimulus of stimuli) {
      const sign = deriveReaction(FULL_ROLL, 'INTERDICT', stimulus);
      expect(Object.keys(sign).sort()).toEqual(['channel', 'token']);
      // Every trait value, case-insensitive and unquoted (P156) — not just the ward's.
      expectNoTraitValues(sign);
    }
  });
});

describe('constants', () => {
  it('NO_REACTION_SIGN is a REACTION-channel sign with the fixed no-reaction token', () => {
    expect(NO_REACTION_SIGN).toEqual({ channel: 'REACTION', token: 'no-reaction' });
  });

  it('PROBE_EXPOSURE_COST is 1', () => {
    expect(PROBE_EXPOSURE_COST).toBe(1);
  });
});
