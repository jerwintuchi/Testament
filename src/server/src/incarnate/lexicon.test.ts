// T41: SIGN_LEXICON — completeness, uniqueness, shape
// T349 (TD-093): P154 — a sign names the observation, never the conclusion.
import { describe, it, expect } from 'vitest';
import { STIMULI } from '@testament/shared';
import { SIGN_LEXICON } from './lexicon.js';
import { NO_REACTION_SIGN } from './deriveReaction.js';
import { AXIS_VALUES } from './types.js';
import type { TraitAxis } from './types.js';

const AXIS_VALUE_LITERALS = Object.values(AXIS_VALUES).flat();

describe('SIGN_LEXICON', () => {
  it('has exactly 24 entries (4 values × 6 axes)', () => {
    expect(SIGN_LEXICON).toHaveLength(24);
  });

  it('all token values are unique (P14)', () => {
    const tokens = SIGN_LEXICON.map(e => e.token);
    const unique = new Set(tokens);
    expect(unique.size).toBe(tokens.length);
  });

  it('every entry channel is a valid Channel string', () => {
    const validChannels = new Set(['RESIDUE', 'STRESS_MARK', 'REACTION', 'SPOOR', 'LITURGY', 'OMEN']);
    for (const entry of SIGN_LEXICON) {
      expect(validChannels.has(entry.channel)).toBe(true);
    }
  });

  it('groups by axis yield exactly 6 axes each with exactly 4 entries', () => {
    const byAxis = new Map<TraitAxis, number>();
    for (const entry of SIGN_LEXICON) {
      byAxis.set(entry.axis, (byAxis.get(entry.axis) ?? 0) + 1);
    }
    expect(byAxis.size).toBe(6);
    for (const [, count] of byAxis) {
      expect(count).toBe(4);
    }
  });

  it('no token string equals any axis value literal (P12 data-level guard)', () => {
    const axisValueSet = new Set(AXIS_VALUE_LITERALS);
    for (const entry of SIGN_LEXICON) {
      expect(axisValueSet.has(entry.token)).toBe(false);
    }
  });
});

// ── P154 — a sign names the observation, never the conclusion (T349, TD-093) ──
//
// The rule that makes interpretation exist at all. A token carrying its own answer
// ("flinch-from-flame") is a label, not a sign: the player performs no inferential
// step, so there is no vocabulary to acquire and Pillar 3 is unimplemented on that
// axis. `no-reaction` is not an axis value and needs no exemption — it lives in
// deriveReaction.ts, outside the table.
describe('P154 — a token names what was seen, not what it means', () => {
  const namesAnAnswer = (axis: TraitAxis, token: string): string[] => {
    const haystack = token.toLowerCase();
    // Its own axis's values, plus every Stimulus literal: a RITE_KEY token reading
    // `flame-rune` hands over the probe as surely as a FRAILTY one does.
    const forbidden = [...AXIS_VALUES[axis], ...STIMULI];
    return [...new Set(forbidden)].filter(word => haystack.includes(word.toLowerCase()));
  };

  it('no token contains a value of its own axis, or any Stimulus literal', () => {
    const offenders = SIGN_LEXICON
      .map(e => ({ e, hits: namesAnAnswer(e.axis, e.token) }))
      .filter(({ hits }) => hits.length > 0)
      .map(({ e, hits }) => `${e.axis}/${e.value} → ${e.token} (names ${hits.join(', ')})`);

    expect(offenders).toEqual([]);
  });

  it('the null probe result obeys the rule too', () => {
    expect(namesAnAnswer('WARD', NO_REACTION_SIGN.token)).toEqual([]);
  });

  it('every (axis, value) pair appears exactly once', () => {
    for (const [axis, values] of Object.entries(AXIS_VALUES)) {
      for (const value of values) {
        const matches = SIGN_LEXICON.filter(e => e.axis === axis && e.value === value);
        expect(matches, `${axis}/${value}`).toHaveLength(1);
      }
    }
  });
});
