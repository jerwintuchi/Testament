// T45: ContractIntel and PrimaryVerb shared types
import { describe, it, expect } from 'vitest';
import type { ContractIntel, Origin, PrimaryVerb } from './contract.js';
import type { Tier } from './signs.js';

// T45(a): PrimaryVerb is a union of exactly 4 literals.
function assertPrimaryVerbExhaustive(v: PrimaryVerb): string {
  switch (v) {
    case 'INVESTIGATE': return v;
    case 'ELIMINATE':   return v;
    case 'CAPTURE':     return v;
    case 'BANISH':      return v;
  }
}

// @ts-expect-error — 'OBSERVE' is not a valid PrimaryVerb
const _badVerb: PrimaryVerb = 'OBSERVE';

// T45(b): ContractIntel satisfies its shape.
const _intel = {
  contractId:  'abc-123',
  tier:        'VIGIL' as Tier,
  origin:      'SIN' as Origin,
  requester:   { name: 'Aldis Vane', role: 'Reliquary-Steward', place: 'Ashfen' },
  targetName:  'The Ashen Warden',
  siteName:    'The Collapsed Chancel',
  primaryVerb: 'INVESTIGATE' as PrimaryVerb,
} satisfies ContractIntel;

// T45(c): ContractIntel has no expeditionSeed or traitRoll field.
// @ts-expect-error — expeditionSeed is not a field of ContractIntel
const _badIntel: ContractIntel = { ..._intel, expeditionSeed: 'abc' };

describe('PrimaryVerb', () => {
  it('covers exactly 4 values', () => {
    const verbs: PrimaryVerb[] = ['INVESTIGATE', 'ELIMINATE', 'CAPTURE', 'BANISH'];
    expect(verbs).toHaveLength(4);
    verbs.forEach(v => expect(assertPrimaryVerbExhaustive(v)).toBe(v));
  });
});

describe('ContractIntel', () => {
  it('has exactly 7 fields', () => {
    const intel: ContractIntel = {
      contractId:  'test-id',
      tier:        'INTERDICT',
      origin:      'BELIEF',
      requester:   { name: 'Sister Wren', role: 'Parish-Priest', place: 'Gall' },
      targetName:  'The Weeping Mire',
      siteName:    'The Salt Marsh',
      primaryVerb: 'BANISH',
    };
    expect(Object.keys(intel).sort()).toEqual(
      ['contractId', 'origin', 'primaryVerb', 'requester', 'siteName', 'targetName', 'tier']
    );
  });

  it('does not allow expeditionSeed (structural type check — see compile-time assertion above)', () => {
    // Runtime enforcement: no seed field on a plain ContractIntel object.
    const intel: ContractIntel = {
      contractId: 'x', tier: 'ANATHEMA', origin: 'RELIC',
      requester: { name: '', role: 'penitent', place: 'Low Fen' },
      targetName: 'Y', siteName: 'Z', primaryVerb: 'CAPTURE',
    };
    expect(Object.keys(intel)).not.toContain('expeditionSeed');
    expect(Object.keys(intel)).not.toContain('traitRoll');
  });
});
